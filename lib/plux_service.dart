import 'package:flutter/services.dart';

import 'domain/models/emg_frame.dart';

class PluxService {
  final MethodChannel _methodChannel = const MethodChannel('com.symsync/plux');

  late final Stream<EmgFrame> _frameStream =
      const EventChannel('com.symsync/plux/stream')
          .receiveBroadcastStream()
          .map((event) => EmgFrame.fromMap(event as Map<dynamic, dynamic>));

  Stream<EmgFrame> get frameStream => _frameStream;

  Future<void> connect(String mac) {
    return _methodChannel.invokeMethod<void>('connect', mac);
  }

  Future<void> startAcquisition({List<int> channels = const <int>[1, 3]}) {
    return _methodChannel.invokeMethod<void>('startAcquisition', {
      'channels': channels,
      'sampleRate': 1000,
    });
  }

  Future<void> stop() {
    return _methodChannel.invokeMethod<void>('stopAcquisition');
  }

  Future<void> disconnect() {
    return _methodChannel.invokeMethod<void>('disconnect');
  }
}
