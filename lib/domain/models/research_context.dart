import 'package:equatable/equatable.dart';

enum UsageScenario { officeDesk, gymExercise, everydayStairs }

extension UsageScenarioX on UsageScenario {
  String get id => name;

  String get label => switch (this) {
    UsageScenario.officeDesk => 'Desk Work',
    UsageScenario.gymExercise => 'Dumbbell Shoulder Shrug',
    UsageScenario.everydayStairs => 'Backpack Stair Climb',
  };

  String get shortLabel => switch (this) {
    UsageScenario.officeDesk => 'Desk',
    UsageScenario.gymExercise => 'Dumbbell',
    UsageScenario.everydayStairs => 'Stairs',
  };

  String get description => switch (this) {
    UsageScenario.officeDesk =>
      'Monitor shoulder tension while using a mouse and keyboard at a desk.',
    UsageScenario.gymExercise =>
      'Measure left-right upper trapezius activation during controlled dumbbell shrugs.',
    UsageScenario.everydayStairs =>
      'Check shoulder-load symmetry while climbing stairs with a backpack.',
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

enum BaselineReferencePosition { straightAhead, farRight, farLeft }

extension BaselineReferencePositionX on BaselineReferencePosition {
  String get id => name;

  String get label => switch (this) {
    BaselineReferencePosition.straightAhead => 'Straight ahead',
    BaselineReferencePosition.farRight => 'Far right',
    BaselineReferencePosition.farLeft => 'Far left',
  };

  String get instruction => switch (this) {
    BaselineReferencePosition.straightAhead =>
      'Relax shoulders and face forward.',
    BaselineReferencePosition.farRight =>
      'Turn head comfortably right; keep shoulders still.',
    BaselineReferencePosition.farLeft =>
      'Turn head comfortably left; keep shoulders still.',
  };

  static BaselineReferencePosition fromId(String? value) {
    return BaselineReferencePosition.values.firstWhere(
      (position) => position.id == value,
      orElse: () => BaselineReferencePosition.straightAhead,
    );
  }
}

class BaselineReference extends Equatable {
  const BaselineReference({
    required this.position,
    required this.leftRms,
    required this.rightRms,
    required this.recordedAt,
  });

  final BaselineReferencePosition position;
  final double leftRms;
  final double rightRms;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'position': position.id,
    'leftRms': leftRms,
    'rightRms': rightRms,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory BaselineReference.fromJson(Map<String, dynamic> json) {
    return BaselineReference(
      position: BaselineReferencePositionX.fromId(json['position'] as String?),
      leftRms: (json['leftRms'] as num?)?.toDouble() ?? 0,
      rightRms: (json['rightRms'] as num?)?.toDouble() ?? 0,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  List<Object?> get props => <Object?>[position, leftRms, rightRms, recordedAt];
}

class ParticipantProfile extends Equatable {
  const ParticipantProfile({
    required this.id,
    required this.createdAt,
    this.baselineReferences = const <BaselineReference>[],
  });

  final String id;
  final DateTime createdAt;
  final List<BaselineReference> baselineReferences;

  String get displayLabel => 'Participant $id';

  BaselineReference? baselineFor(BaselineReferencePosition position) {
    for (final reference in baselineReferences) {
      if (reference.position == position) return reference;
    }
    return null;
  }

  ParticipantProfile copyWithBaseline(BaselineReference reference) {
    final references =
        baselineReferences
            .where((item) => item.position != reference.position)
            .toList(growable: true)
          ..add(reference);
    references.sort((a, b) => a.position.index.compareTo(b.position.index));
    return ParticipantProfile(
      id: id,
      createdAt: createdAt,
      baselineReferences: List<BaselineReference>.unmodifiable(references),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'baselineReferences': baselineReferences
        .map((reference) => reference.toJson())
        .toList(growable: false),
  };

  factory ParticipantProfile.fromJson(Map<String, dynamic> json) {
    return ParticipantProfile(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      baselineReferences:
          (json['baselineReferences'] as List<dynamic>?)
              ?.map(
                (entry) =>
                    BaselineReference.fromJson(entry as Map<String, dynamic>),
              )
              .toList(growable: false) ??
          const <BaselineReference>[],
    );
  }

  @override
  List<Object?> get props => <Object?>[id, createdAt, baselineReferences];
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
      imbalanceThreshold: ((json['imbalanceThreshold'] as num?)?.toInt() ?? 20)
          .clamp(10, 50),
      sustainedSeconds: ((json['sustainedSeconds'] as num?)?.toInt() ?? 15)
          .clamp(5, 60),
      cooldownMinutes: ((json['cooldownMinutes'] as num?)?.toInt() ?? 5).clamp(
        1,
        30,
      ),
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
