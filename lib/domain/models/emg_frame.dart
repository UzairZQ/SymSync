class EmgFrame {
  const EmgFrame({
    required this.timestamp,
    required this.ch1,
    required this.ch3,
  });

  final int timestamp;
  final int ch1;
  final int ch3;

  factory EmgFrame.fromMap(Map<dynamic, dynamic> map) {
    return EmgFrame(
      timestamp: (map['timestamp'] as num).toInt(),
      ch1: map.containsKey('ch1') ? (map['ch1'] as num).toInt() : 0,
      ch3: map.containsKey('ch3') ? (map['ch3'] as num).toInt() : 0,
    );
  }
}
