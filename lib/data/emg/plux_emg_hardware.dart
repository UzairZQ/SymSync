import '../../plux_service.dart';
import '../../domain/models/emg_frame.dart';
import 'emg_hardware.dart';

class PluxEmgHardware implements EmgHardware {
  PluxEmgHardware(this._service);

  final PluxService _service;

  @override
  Stream<EmgFrame> get frames => _service.frameStream;

  @override
  Future<void> connect(String macAddress) => _service.connect(macAddress);

  @override
  Future<void> startAcquisition({
    List<int> channels = const <int>[1],
    int sampleRate = 1000,
  }) {
    return _service.startAcquisition();
  }

  @override
  Future<void> stopAcquisition() => _service.stop();

  @override
  Future<void> disconnect() => _service.disconnect();
}
