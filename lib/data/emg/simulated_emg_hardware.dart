import 'dart:async';
import 'dart:math';

import '../../domain/models/emg_frame.dart';
import '../../domain/services/signal_processor.dart';
import 'emg_hardware.dart';

class SimulatedEmgHardware implements EmgHardware {
  SimulatedEmgHardware({this.asymmetry = 0.18});

  final double asymmetry;

  final StreamController<EmgFrame> _controller =
      StreamController<EmgFrame>.broadcast();
  Timer? _timer;
  final Random _random = Random();
  double _phase = 0;
  bool _connected = false;

  @override
  Stream<EmgFrame> get frames => _controller.stream;

  @override
  Future<void> connect(String macAddress) async {
    _connected = true;
  }

  @override
  Future<void> startAcquisition({
    List<int> channels = const <int>[1],
    int sampleRate = 1000,
  }) async {
    _timer?.cancel();
    const int displayRate = 50;
    final int stepMs = (1000 / displayRate).round();
    _timer = Timer.periodic(Duration(milliseconds: stepMs), (_) {
      if (!_connected) {
        return;
      }
      _phase += 0.25;
      final baseWave = sin(_phase) * 0.35 + sin(_phase * 2.3) * 0.18;
      final burst = sin(_phase / 6).abs() > 0.75 ? 0.45 : 0.0;
      final noise = (_random.nextDouble() - 0.5) * 0.08;
      final activation = ((baseWave + burst + noise) * (1 - asymmetry * 0.15))
          .clamp(-1.0, 1.0);
      final value =
          SignalProcessor.adcMidpoint +
          (activation * SignalProcessor.adcMidpoint).round();
      _controller.add(
        EmgFrame(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          ch1: value.clamp(0, SignalProcessor.fullScale).toInt(),
        ),
      );
    });
  }

  @override
  Future<void> stopAcquisition() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stopAcquisition();
    await _controller.close();
  }
}
