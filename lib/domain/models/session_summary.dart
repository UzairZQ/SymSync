import 'package:equatable/equatable.dart';

class SessionSummary extends Equatable {
  const SessionSummary({
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.peakRaw,
    required this.averageActivation,
    required this.note,
    this.averageSymmetryIndex,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int peakRaw;
  final double averageActivation;
  final double? averageSymmetryIndex;
  final String note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'peakRaw': peakRaw,
      'averageActivation': averageActivation,
      'averageSymmetryIndex': averageSymmetryIndex,
      'note': note,
    };
  }

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      peakRaw: (json['peakRaw'] as num).toInt(),
      averageActivation: (json['averageActivation'] as num).toDouble(),
      averageSymmetryIndex: (json['averageSymmetryIndex'] as num?)?.toDouble(),
      note: (json['note'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[
    startedAt,
    endedAt,
    durationSeconds,
    peakRaw,
    averageActivation,
    averageSymmetryIndex,
    note,
  ];
}
