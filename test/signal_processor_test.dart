import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sym_sync/domain/services/signal_processor.dart';

void main() {
  const processor = SignalProcessor();

  group('SignalProcessor', () {
    test('computes signed bilateral symmetry', () {
      expect(processor.symmetryIndexFromLevels(10, 10), 0);
      expect(processor.symmetryIndexFromLevels(10, 30), closeTo(50, 0.001));
      expect(processor.symmetryIndexFromLevels(30, 10), closeTo(-50, 0.001));
    });

    test('suppresses symmetry when combined signal is below threshold', () {
      expect(
        processor.symmetryIndexFromLevels(0.2, 0.3, minimumCombinedLevel: 1),
        isNull,
      );
    });

    test('subtracts baseline in the RMS power domain', () {
      expect(processor.baselineCorrectedRms(5, 5), 0);
      expect(processor.baselineCorrectedRms(5, 3), closeTo(4, 0.001));
    });

    test('maps full symmetry range to the balance track', () {
      expect(processor.balancePositionFromSymmetry(-100), 0);
      expect(processor.balancePositionFromSymmetry(0), 0.5);
      expect(processor.balancePositionFromSymmetry(100), 1);
    });
  });

  test('filter rejects DC and retains an EMG-band waveform', () {
    final filter = SignalFilterState();

    for (var i = 0; i < 1500; i++) {
      filter.processRms(filter.filter(SignalProcessor.adcMidpoint + 1200));
    }
    final dcOutput = filter.filter(SignalProcessor.adcMidpoint + 1200).abs();

    final activeFilter = SignalFilterState();
    var rms = 0.0;
    for (var i = 0; i < 1500; i++) {
      final sample =
          SignalProcessor.adcMidpoint +
          (1200 * math.sin(2 * math.pi * 100 * i / 1000));
      rms = activeFilter.processRms(activeFilter.filter(sample));
    }

    expect(dcOutput, lessThan(1));
    expect(rms, greaterThan(100));
  });
}
