enum TargetMuscle {
  trapezius,
  biceps;

  String get id => name;

  String get chipLabel => switch (this) {
    TargetMuscle.trapezius => 'Trapezius',
    TargetMuscle.biceps => 'Biceps',
  };

  String get leftShortLabel => switch (this) {
    TargetMuscle.trapezius => 'Left Trap',
    TargetMuscle.biceps => 'Left Biceps',
  };

  String get rightShortLabel => switch (this) {
    TargetMuscle.trapezius => 'Right Trap',
    TargetMuscle.biceps => 'Right Biceps',
  };

  String get leftLongLabel => switch (this) {
    TargetMuscle.trapezius => 'Left Trapezius',
    TargetMuscle.biceps => 'Left Biceps',
  };

  String get rightLongLabel => switch (this) {
    TargetMuscle.trapezius => 'Right Trapezius',
    TargetMuscle.biceps => 'Right Biceps',
  };

  String get bodyAreaLabel => switch (this) {
    TargetMuscle.trapezius => 'shoulder',
    TargetMuscle.biceps => 'arm',
  };

  String get balanceSubtitle => switch (this) {
    TargetMuscle.trapezius => 'Live shoulder balance',
    TargetMuscle.biceps => 'Live biceps balance',
  };

  String get anatomicalSubtitle => switch (this) {
    TargetMuscle.trapezius => 'See which shoulder is working more.',
    TargetMuscle.biceps => 'See which biceps is working more.',
  };

  String sideWorkingMoreLabel(bool rightSide) {
    final side = rightSide ? 'Right' : 'Left';
    return switch (this) {
      TargetMuscle.trapezius => '$side side is working more',
      TargetMuscle.biceps => '$side biceps is working more',
    };
  }

  String dominanceLabel(bool rightSide, {required bool slight}) {
    final side = rightSide ? 'Right' : 'Left';
    final muscle = switch (this) {
      TargetMuscle.trapezius => 'Trap',
      TargetMuscle.biceps => 'Biceps',
    };
    return slight
        ? '$side $muscle Slight Dominance'
        : '$side $muscle Dominance';
  }
}

TargetMuscle? targetMuscleFromId(String? id) {
  for (final muscle in TargetMuscle.values) {
    if (muscle.id == id) return muscle;
  }
  return null;
}
