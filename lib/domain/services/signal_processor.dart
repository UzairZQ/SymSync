import 'dart:math' as math;

class SignalProcessor {
  const SignalProcessor();

  static const int adcMidpoint = 32768;
  static const int fullScale = 65535;

  double activationFromRaw(int raw) {
    final normalized = (raw - adcMidpoint).abs() / adcMidpoint;
    return normalized.clamp(0.0, 1.0);
  }

  double symmetryIndexFromLevels(double left, double right) {
    final denominator = left + right;
    if (denominator == 0) {
      return 0;
    }
    return ((right - left) / denominator) * 100.0;
  }

  double tiltDegreesFromSymmetry(double symmetryIndex) {
    return (symmetryIndex / 3.0).clamp(-20.0, 20.0);
  }

  String correctiveInstruction(double? symmetryIndex) {
    if (symmetryIndex == null) {
      return 'Awaiting bilateral sensor data';
    }
    final value = symmetryIndex.abs();
    if (value < 8) {
      return 'Balanced activation. Keep your shoulder and upper back movement steady.';
    }
    if (symmetryIndex > 0) {
      return 'Right side is more active. Let the left side catch up.';
    }
    return 'Left side is more active. Let the right side catch up.';
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

class SignalFilterState {
  double _hpPrevX = 0;
  double _hpPrevY = 0;
  double _lpPrevY = 0;
  final List<double> _rmsWindow = [];
  static const int _rmsWindowSize = 100;

  void reset() {
    _hpPrevX = 0;
    _hpPrevY = 0;
    _lpPrevY = 0;
    _rmsWindow.clear();
  }

  double filter(double raw) {
    final x = raw - 32768.0;

    // Highpass filter (approx 20Hz cutoff at 1000Hz)
    const double alphaHp = 0.88;
    final yHp = alphaHp * (_hpPrevY + x - _hpPrevX);
    _hpPrevX = x;
    _hpPrevY = yHp;

    // Lowpass filter (approx 400Hz cutoff at 1000Hz)
    const double alphaLp = 0.7;
    final yLp = _lpPrevY + alphaLp * (yHp - _lpPrevY);
    _lpPrevY = yLp;

    return (yLp / 65.5).clamp(-500.0, 500.0);
  }

  double processRms(double filteredValue) {
    final squared = filteredValue * filteredValue;
    _rmsWindow.add(squared);
    if (_rmsWindow.length > _rmsWindowSize) {
      _rmsWindow.removeAt(0);
    }
    double sumSq = 0;
    for (final val in _rmsWindow) {
      sumSq += val;
    }
    final meanSq = sumSq / _rmsWindow.length;
    return math.sqrt(meanSq);
  }
}
