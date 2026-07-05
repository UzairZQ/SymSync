import 'dart:math' as math;

class SignalProcessor {
  const SignalProcessor();

  static const int adcMidpoint = 32768;
  static const int fullScale = 65535;
  static const double sampleRateHz = 1000.0;
  static const double highPassCutoffHz = 20.0;
  static const double lowPassCutoffHz = 400.0;

  double activationFromRaw(int raw) {
    final normalized = (raw - adcMidpoint).abs() / adcMidpoint;
    return normalized.clamp(0.0, 1.0);
  }

  double baselineCorrectedRms(double rms, double baselineRms) {
    final signalPower = (rms * rms) - (baselineRms * baselineRms);
    return signalPower <= 0 ? 0.0 : math.sqrt(signalPower);
  }

  double? symmetryIndexFromLevels(
    double left,
    double right, {
    double minimumCombinedLevel = 0.0,
  }) {
    final denominator = left + right;
    if (denominator <= minimumCombinedLevel) {
      return null;
    }
    return ((right - left) / denominator) * 100.0;
  }

  double balancePositionFromSymmetry(double symmetryIndex) {
    return ((symmetryIndex.clamp(-100.0, 100.0) + 100.0) / 200.0).clamp(
      0.0,
      1.0,
    );
  }

  String correctiveInstruction(double? symmetryIndex) {
    if (symmetryIndex == null) {
      return 'Move a little more so both sensors can compare the shoulders.';
    }
    final value = symmetryIndex.abs();
    if (value < 8) {
      return 'Both sides look balanced. Keep your shoulders relaxed and steady.';
    }
    if (symmetryIndex > 0) {
      return 'Right side is working more. Try relaxing the right shoulder.';
    }
    return 'Left side is working more. Try relaxing the left shoulder.';
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
  SignalFilterState({
    this.sampleRateHz = SignalProcessor.sampleRateHz,
    this.highPassCutoffHz = SignalProcessor.highPassCutoffHz,
    this.lowPassCutoffHz = SignalProcessor.lowPassCutoffHz,
    this.rmsWindowMilliseconds = 100,
  });

  final double sampleRateHz;
  final double highPassCutoffHz;
  final double lowPassCutoffHz;
  final int rmsWindowMilliseconds;

  double _hpPrevX = 0;
  double _hpPrevY = 0;
  double _lpPrevY = 0;
  final List<double> _rmsWindow = <double>[];

  int get _rmsWindowSize =>
      math.max(1, (sampleRateHz * rmsWindowMilliseconds / 1000).round());

  double get _highPassAlpha {
    final dt = 1.0 / sampleRateHz;
    final rc = 1.0 / (2.0 * math.pi * highPassCutoffHz);
    return rc / (rc + dt);
  }

  double get _lowPassAlpha {
    final dt = 1.0 / sampleRateHz;
    final rc = 1.0 / (2.0 * math.pi * lowPassCutoffHz);
    return dt / (rc + dt);
  }

  void reset() {
    _hpPrevX = 0;
    _hpPrevY = 0;
    _lpPrevY = 0;
    _rmsWindow.clear();
  }

  double filter(double raw) {
    final x = raw - SignalProcessor.adcMidpoint;

    final yHp = _highPassAlpha * (_hpPrevY + x - _hpPrevX);
    _hpPrevX = x;
    _hpPrevY = yHp;

    final yLp = _lpPrevY + _lowPassAlpha * (yHp - _lpPrevY);
    _lpPrevY = yLp;

    return yLp;
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
