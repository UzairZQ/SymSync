class SignalProcessor {
  const SignalProcessor();

  static const int adcMidpoint = 32768;
  static const int fullScale = 65535;

  double activationFromRaw(int raw) {
    final normalized = (raw - adcMidpoint).abs() / adcMidpoint;
    return normalized.clamp(0.0, 1.0);
  }

  double symmetryIndexFromLevels(double left, double right) {
    final denominator = (left + right) / 2.0;
    if (denominator == 0) {
      return 0;
    }
    return ((left - right) / denominator) * 100.0;
  }

  double tiltDegreesFromSymmetry(double symmetryIndex) {
    return (symmetryIndex / 3.0).clamp(-20.0, 20.0);
  }

  String correctiveInstruction(double? symmetryIndex) {
    if (symmetryIndex == null) {
      return 'Connect the second leg channel to unlock bilateral symmetry feedback.';
    }
    final value = symmetryIndex.abs();
    if (value < 8) {
      return 'Nice and even. Keep the stair rhythm steady.';
    }
    if (symmetryIndex > 0) {
      return 'Right side is doing more work. Let the left leg catch up.';
    }
    return 'Left side is doing more work. Smooth out the load on the right.';
  }

  String trendLabel(double? symmetryIndex) {
    if (symmetryIndex == null) {
      return 'Single-channel mode';
    }
    final value = symmetryIndex.abs();
    if (value < 8) {
      return 'Balanced';
    }
    if (value < 20) {
      return 'Slight drift';
    }
    return 'Strong asymmetry';
  }
}
