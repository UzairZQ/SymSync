import 'package:equatable/equatable.dart';

enum UsageScenario { officeDesk, gymExercise, everydayStairs }

extension UsageScenarioX on UsageScenario {
  String get id => name;

  String get label => switch (this) {
    UsageScenario.officeDesk => 'Office / Desk',
    UsageScenario.gymExercise => 'Gym / Exercise',
    UsageScenario.everydayStairs => 'Everyday / Stairs',
  };

  String get shortLabel => switch (this) {
    UsageScenario.officeDesk => 'Office',
    UsageScenario.gymExercise => 'Gym',
    UsageScenario.everydayStairs => 'Stairs',
  };

  String get description => switch (this) {
    UsageScenario.officeDesk =>
      'Monitor sustained shoulder imbalance while seated at a desk.',
    UsageScenario.gymExercise =>
      'Measure bilateral trapezius activation during controlled exercise.',
    UsageScenario.everydayStairs =>
      'Observe upper-back symmetry while walking up a flight of stairs.',
  };

  int get defaultNotificationDelaySeconds => switch (this) {
    UsageScenario.officeDesk => 20,
    UsageScenario.gymExercise => 12,
    UsageScenario.everydayStairs => 8,
  };

  static UsageScenario fromId(String? value) {
    return UsageScenario.values.firstWhere(
      (scenario) => scenario.id == value,
      orElse: () => UsageScenario.officeDesk,
    );
  }
}

class ParticipantProfile extends Equatable {
  const ParticipantProfile({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;

  String get displayLabel => 'Participant $id';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ParticipantProfile.fromJson(Map<String, dynamic> json) {
    return ParticipantProfile(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => <Object?>[id, createdAt];
}

class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.enabled = false,
    this.imbalanceThreshold = 20,
    this.sustainedSeconds = 15,
    this.cooldownMinutes = 5,
  });

  final bool enabled;
  final int imbalanceThreshold;
  final int sustainedSeconds;
  final int cooldownMinutes;

  NotificationPreferences copyWith({
    bool? enabled,
    int? imbalanceThreshold,
    int? sustainedSeconds,
    int? cooldownMinutes,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      imbalanceThreshold: imbalanceThreshold ?? this.imbalanceThreshold,
      sustainedSeconds: sustainedSeconds ?? this.sustainedSeconds,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'imbalanceThreshold': imbalanceThreshold,
    'sustainedSeconds': sustainedSeconds,
    'cooldownMinutes': cooldownMinutes,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? false,
      imbalanceThreshold: (json['imbalanceThreshold'] as num?)?.toInt() ?? 20,
      sustainedSeconds: (json['sustainedSeconds'] as num?)?.toInt() ?? 15,
      cooldownMinutes: (json['cooldownMinutes'] as num?)?.toInt() ?? 5,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    enabled,
    imbalanceThreshold,
    sustainedSeconds,
    cooldownMinutes,
  ];
}
