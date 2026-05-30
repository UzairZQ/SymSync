package com.symsync.emgvalidator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var pluxBridge: PluxBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pluxBridge = PluxBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        ).also { it.register() }
    }

    override fun onDestroy() {
        pluxBridge?.dispose()
        pluxBridge = null
        super.onDestroy()
    }
}
