import '../../domain/models/emg_frame.dart';

abstract class EmgHardware {
  Stream<EmgFrame> get frames;
  bool get isSimulated;

  Future<void> connect(String macAddress);
  Future<void> startAcquisition({List<int> channels, int sampleRate});
  Future<void> stopAcquisition();
  Future<void> disconnect();
}
