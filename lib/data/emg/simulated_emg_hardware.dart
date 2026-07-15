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
  bool get isSimulated => true;

  @override
  Future<void> connect(String macAddress) async {
    _connected = true;
  }

  @override
  Future<void> startAcquisition({
    List<int> channels = const <int>[1, 3],
    int sampleRate = 1000,
  }) async {
    _timer?.cancel();
    const int displayRate = 50;
    final int stepMs = (1000 / displayRate).round();
    final startTime = DateTime.now();
    _timer = Timer.periodic(Duration(milliseconds: stepMs), (_) {
      if (!_connected) {
        return;
      }
      final elapsedSec = DateTime.now().difference(startTime).inSeconds;
      _phase += 0.25;
      final baseWave = sin(_phase) * 0.35 + sin(_phase * 2.3) * 0.18;
      final burst = sin(_phase / 6).abs() > 0.75 ? 0.45 : 0.0;
      final noise = (_random.nextDouble() - 0.5) * 0.08;
      final activation = ((baseWave + burst + noise) * (1 - asymmetry * 0.15))
          .clamp(-1.0, 1.0);
      final value =
          SignalProcessor.adcMidpoint +
          (activation * SignalProcessor.adcMidpoint).round();

      // Simulate channel 3 (left trapezius)
      final baseWave3 =
          sin(_phase + 1.0) * 0.35 + sin((_phase + 1.0) * 2.3) * 0.18;
      final burst3 = sin((_phase + 1.0) / 6).abs() > 0.75 ? 0.45 : 0.0;
      final noise3 = (_random.nextDouble() - 0.5) * 0.08;
      final activation3 =
          ((baseWave3 + burst3 + noise3) * (1 + asymmetry * 0.15)).clamp(
            -1.0,
            1.0,
          );
      int value3 =
          SignalProcessor.adcMidpoint +
          (activation3 * SignalProcessor.adcMidpoint).round();

      // Programmatic 15s to 25s flatline simulation on CH3
      if (elapsedSec >= 15 && elapsedSec <= 25) {
        value3 = SignalProcessor.adcMidpoint + _random.nextInt(3) - 1;
      }

      _controller.add(
        EmgFrame(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          ch1: value.clamp(0, SignalProcessor.fullScale).toInt(),
          ch3: value3.clamp(0, SignalProcessor.fullScale).toInt(),
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
