package com.symsync.emgvalidator

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.bluetooth.BluetoothDevice
import info.plux.pluxapi.Communication
import info.plux.pluxapi.Constants
import info.plux.pluxapi.bioplux.BiopluxCommunication
import info.plux.pluxapi.bioplux.BiopluxCommunicationFactory
import info.plux.pluxapi.bioplux.OnBiopluxDataAvailable
import info.plux.pluxapi.bioplux.bth.BTHCommunication
import info.plux.pluxapi.bioplux.utils.BiopluxFrame
import info.plux.pluxapi.bioplux.utils.Source
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.PrintWriter
import java.io.StringWriter
import java.lang.reflect.Field
import java.util.concurrent.CountDownLatch

class PluxBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, OnBiopluxDataAvailable {
    private val tag = "PluxBridge"
    // Flutter channels keep the Dart side tiny: one method channel for commands and one event channel for frames.
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pluxContext = object : ContextWrapper(activity) {
        override fun registerReceiver(
            receiver: BroadcastReceiver?,
            filter: IntentFilter?,
        ): Intent? {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                super.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                super.registerReceiver(receiver, filter)
            }
        }
    }

    private var eventSink: EventChannel.EventSink? = null
    private var communication: BiopluxCommunication? = null
    private var connectedMac: String? = null
    private var isAcquiring = false
    private var connectionLatch: CountDownLatch? = null
    private var connectionReceiverRegistered = false
    private var connectionWaitLoggedSeconds = 0
    private var loggedInternalState = false
    @Volatile
    private var lastConnectionState: Constants.States = Constants.States.NO_CONNECTION

    private val connectionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != Constants.ACTION_STATE_CHANGED) {
                return
            }

            val stateId = intent.getIntExtra(Constants.EXTRA_STATE_CHANGED, Constants.States.NO_CONNECTION.id)
            val state = Constants.States.getStates(stateId)
            lastConnectionState = state
            Log.d(tag, "PLUX state changed: ${state.name} ($stateId)")

            if (state == Constants.States.CONNECTED) {
                connectionLatch?.countDown()
            } else if (state == Constants.States.DISCONNECTED || state == Constants.States.ENDED) {
                connectionLatch?.countDown()
            }
        }
    }

    fun register() {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        stopInternal()
        disconnectInternal()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // The EventChannel only needs to keep a single active sink, because this app shows one live stream.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // The Dart side calls these four commands to keep the hardware flow explicit and easy to follow.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "connect" -> {
                    val mac = call.arguments as? String
                        ?: throw IllegalArgumentException("Missing MAC address")
                    Thread {
                        try {
                            connect(mac)
                            mainHandler.post { result.success(null) }
                        } catch (error: Exception) {
                            logException("connect-thread", error)
                            mainHandler.post {
                                result.error(
                                    "PLUX_ERROR",
                                    error.message ?: error.toString(),
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                "startAcquisition" -> {
                    val args = call.arguments as? Map<*, *>
                    val channels = parseChannels(args?.get("channels"))
                    val sampleRate = (args?.get("sampleRate") as? Number)?.toInt() ?: 1000
                    startAcquisition(channels, sampleRate)
                    result.success(null)
                }

                "stopAcquisition" -> {
                    stopInternal()
                    result.success(null)
                }

                "disconnect" -> {
                    disconnectInternal()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            logException("method:${call.method}", error)
            result.error(
                "PLUX_ERROR",
                error.message ?: error.toString(),
                null,
            )
        }
    }

    // Connect first so the device can be started and stopped without recreating the bridge.
    private fun connect(mac: String) {
        val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
            ?: throw IllegalStateException("Bluetooth is not available on this device")
        if (!adapter.isEnabled) {
            throw IllegalStateException("Bluetooth is off")
        }

        val device: BluetoothDevice = try {
            adapter.getRemoteDevice(mac)
        } catch (error: IllegalArgumentException) {
            throw IllegalStateException(
                "Not found check Bluetooth is on and device is powered",
                error,
            )
        }
        Log.d(
            tag,
            "Connecting to device name=${device.name} address=${device.address} bondState=${device.bondState} enabled=${adapter.isEnabled}",
        )
        adapter.cancelDiscovery()

        val factory = BiopluxCommunicationFactory()
        val newCommunication = factory.getCommunication(Communication.BTH, pluxContext, this) as BTHCommunication
        newCommunication.init()
        communication = newCommunication
        registerConnectionReceiver()
        connectionLatch = CountDownLatch(1)
        connectionWaitLoggedSeconds = 0
        loggedInternalState = false
        lastConnectionState = Constants.States.NO_CONNECTION

        try {
            newCommunication.connect(device)
            val connected = waitForConnection(30_000)
            if (!connected || lastConnectionState != Constants.States.CONNECTED) {
                throw IllegalStateException(
                    "PLUX connect timed out or ended in state ${lastConnectionState.name}",
                )
            }
        } catch (error: Exception) {
            logException("native-connect", error)
            communication?.runCatching { unregisterReceivers() }
            communication?.runCatching { disconnect() }
            unregisterConnectionReceiver()
            connectionLatch = null
            communication = null
            if (error is info.plux.pluxapi.bioplux.BiopluxException) {
                throw IllegalStateException("PLUX ${error.message}", error)
            }
            throw error
        }

        connectedMac = mac
        isAcquiring = false
        connectionLatch = null
    }

    // Start the stream on CH1 at the requested rate, using a single 16-bit source because this is an EMG proof of concept.
    private fun startAcquisition(channels: List<Int>, sampleRate: Int) {
        val controller = communication ?: throw IllegalStateException("Connect first")
        val ports = channels.ifEmpty { listOf(1) }.distinct()
        val sources = ports.map { port ->
            Source(port, 16, 0x01.toByte(), 1)
        }

        if (!controller.start(sampleRate.toFloat(), sources)) {
            throw IllegalStateException("Could not start acquisition")
        }

        isAcquiring = true
    }

    // Stop cleanly before disconnecting so the device does not keep streaming in the background.
    private fun stopInternal() {
        val controller = communication ?: return
        if (isAcquiring) {
            try {
                controller.stop()
            } catch (_: Exception) {
                // Device may have already dropped — best-effort stop
            }
        }
        isAcquiring = false
    }

    private fun disconnectInternal() {
        stopInternal()
        val controller = communication ?: return
        try {
            controller.disconnect()
        } finally {
            controller.unregisterReceivers()
            communication = null
            connectedMac = null
            unregisterConnectionReceiver()
        }
    }

    private fun parseChannels(value: Any?): List<Int> {
        val values = value as? List<*> ?: return listOf(1)
        val channels = values.mapNotNull { item -> (item as? Number)?.toInt() }
        return if (channels.isEmpty()) listOf(1) else channels
    }

    // Forwards both channels to the Dart side. When only one source is configured
    // the second value gracefully defaults to 0.
    private fun emitSample(ch1: Int, ch3: Int) {
        val sink = eventSink ?: return
        val timestamp = System.currentTimeMillis()
        mainHandler.post {
            Log.d(tag, "Frame ch1=$ch1 ch3=$ch3")
            sink.success(
                mapOf(
                    "timestamp" to timestamp,
                    "ch1" to ch1,
                    "ch3" to ch3,
                ),
            )
        }
    }

    override fun onBiopluxDataAvailable(frame: BiopluxFrame) {
        val data = frame.getAnalogData()
        emitSample(
            data.getOrElse(0) { 0 },
            data.getOrElse(1) { 0 },
        )
    }

    override fun onBiopluxDataAvailable(identifier: String, data: IntArray) {
        emitSample(
            data.getOrElse(0) { 0 },
            data.getOrElse(1) { 0 },
        )
    }

    private companion object {
        const val METHOD_CHANNEL = "com.symsync/plux"
        const val EVENT_CHANNEL = "com.symsync/plux/stream"
    }

    private fun registerConnectionReceiver() {
        if (connectionReceiverRegistered) {
            return
        }

        val filter = IntentFilter(Constants.ACTION_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(connectionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            activity.registerReceiver(connectionReceiver, filter)
        }
        connectionReceiverRegistered = true
        Log.d(tag, "Connection receiver registered")
    }

    private fun unregisterConnectionReceiver() {
        if (!connectionReceiverRegistered) {
            return
        }

        try {
            activity.unregisterReceiver(connectionReceiver)
        } catch (_: IllegalArgumentException) {
            // Receiver may already be gone during teardown.
        } finally {
            connectionReceiverRegistered = false
            Log.d(tag, "Connection receiver unregistered")
        }
    }

    private fun logException(where: String, error: Exception) {
        Log.e(tag, "PLUX $where failed: ${error::class.java.name}: ${error.message}")
        val writer = StringWriter()
        error.printStackTrace(PrintWriter(writer))
        Log.e(tag, writer.toString())
    }

    private fun waitForConnection(timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            val internalState = getInternalConnectionState()
            if (internalState != null) {
                lastConnectionState = runCatching { Constants.States.valueOf(internalState) }
                    .getOrNull()
                    ?: lastConnectionState
            }

            if (!loggedInternalState && internalState != null) {
                Log.d(tag, "Internal PLUX state=$internalState")
                loggedInternalState = true
            }

            if (lastConnectionState == Constants.States.CONNECTED) {
                Log.d(tag, "PLUX connect completed with CONNECTED")
                return true
            }

            val remainingMs = deadline - System.currentTimeMillis()
            if (remainingMs <= 0) {
                break
            }

            val stepMs = minOf(1000L, remainingMs)
            val signalled = connectionLatch?.await(stepMs, java.util.concurrent.TimeUnit.MILLISECONDS) == true
            if (signalled && lastConnectionState == Constants.States.CONNECTED) {
                Log.d(tag, "PLUX connect completed after latch signal")
                return true
            }

            connectionWaitLoggedSeconds += 1
            Log.d(tag, "Waiting for PLUX connect... state=${lastConnectionState.name} elapsed=${connectionWaitLoggedSeconds}s")
        }

        return lastConnectionState == Constants.States.CONNECTED
    }

    private fun getInternalConnectionState(): String? {
        val controller = communication ?: return null
        return try {
            val field: Field = controller.javaClass.superclass.getDeclaredField("currentState")
            field.isAccessible = true
            val state = field.get(controller)
            state?.toString()
        } catch (error: Exception) {
            Log.d(tag, "Unable to read internal PLUX state: ${error.message}")
            null
        }
    }
}
