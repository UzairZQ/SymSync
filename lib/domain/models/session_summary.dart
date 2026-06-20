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
    this.averageLeftActivation,
    this.averageRightActivation,
    this.channelMapping,
    this.participantId,
    this.scenarioId,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int peakRaw;
  final double averageActivation;
  final double? averageSymmetryIndex;
  final double? averageLeftActivation;
  final double? averageRightActivation;
  final String note;
  final Map<String, String>? channelMapping;
  final String? participantId;
  final String? scenarioId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'peakRaw': peakRaw,
      'averageActivation': averageActivation,
      'averageSymmetryIndex': averageSymmetryIndex,
      'averageLeftActivation': averageLeftActivation,
      'averageRightActivation': averageRightActivation,
      'note': note,
      'channelMapping': channelMapping,
      'participantId': participantId,
      'scenarioId': scenarioId,
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
      averageLeftActivation: (json['averageLeftActivation'] as num?)
          ?.toDouble(),
      averageRightActivation: (json['averageRightActivation'] as num?)
          ?.toDouble(),
      note: (json['note'] as String?) ?? '',
      channelMapping: (json['channelMapping'] as Map<String, dynamic>?)
          ?.cast<String, String>(),
      participantId: json['participantId'] as String?,
      scenarioId: json['scenarioId'] as String?,
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
    averageLeftActivation,
    averageRightActivation,
    note,
    channelMapping,
    participantId,
    scenarioId,
  ];
}
