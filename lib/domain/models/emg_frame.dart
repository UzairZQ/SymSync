class EmgFrame {
  const EmgFrame({required this.timestamp, required this.ch1});

  final int timestamp;
  final int ch1;

  factory EmgFrame.fromMap(Map<dynamic, dynamic> map) {
    return EmgFrame(
      timestamp: (map['timestamp'] as num).toInt(),
      ch1: (map['ch1'] as num).toInt(),
    );
  }
}
