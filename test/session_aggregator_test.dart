import 'package:flutter_test/flutter_test.dart';
import 'package:sym_sync/domain/models/session_summary.dart';
import 'package:sym_sync/domain/services/session_aggregator.dart';

void main() {
  group('SessionAggregator', () {
    test(
      'aggregateSessionHistory returns empty data when history is empty',
      () async {
        final result = await SessionAggregator.aggregateSessionHistory([]);

        expect(result.hasData, false);
        expect(result.sessionCount, 0);
        expect(result.averageSymmetry, 0.0);
        expect(result.leftIntensities.length, 14);
        expect(result.leftIntensities[0].length, 4);
      },
    );

    test('aggregateSessionHistory computes correct session count', () async {
      final sessions = List<SessionSummary>.generate(
        5,
        (i) => SessionSummary(
          startedAt: DateTime.now().subtract(Duration(days: i)),
          endedAt: DateTime.now().subtract(Duration(days: i, hours: 1)),
          durationSeconds: 3600,
          peakRaw: 2000,
          averageActivation: 0.5 + (i * 0.05),
          averageSymmetryIndex: 80.0 + (i * 2),
          note: 'Session $i',
        ),
      );

      final result = await SessionAggregator.aggregateSessionHistory(sessions);

      expect(result.sessionCount, 5);
      expect(result.hasData, true);
    });

    test(
      'aggregateSessionHistory computes average symmetry correctly',
      () async {
        final sessions = [
          SessionSummary(
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(hours: 1)),
            durationSeconds: 3600,
            peakRaw: 2000,
            averageActivation: 0.5,
            averageSymmetryIndex: 80.0,
            note: 'Session 1',
          ),
          SessionSummary(
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(hours: 1)),
            durationSeconds: 3600,
            peakRaw: 2000,
            averageActivation: 0.6,
            averageSymmetryIndex: 90.0,
            note: 'Session 2',
          ),
        ];

        final result = await SessionAggregator.aggregateSessionHistory(
          sessions,
        );

        expect(result.averageSymmetry, closeTo(85.0, 0.1));
      },
    );

    test(
      'aggregateSessionHistory handles sessions without symmetry index',
      () async {
        final sessions = [
          SessionSummary(
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(hours: 1)),
            durationSeconds: 3600,
            peakRaw: 2000,
            averageActivation: 0.5,
            averageSymmetryIndex: null,
            note: 'Session 1',
          ),
          SessionSummary(
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(hours: 1)),
            durationSeconds: 3600,
            peakRaw: 2000,
            averageActivation: 0.6,
            averageSymmetryIndex: 85.0,
            note: 'Session 2',
          ),
        ];

        final result = await SessionAggregator.aggregateSessionHistory(
          sessions,
        );

        expect(result.averageSymmetry, closeTo(85.0, 0.1));
      },
    );

    test('aggregateSessionHistory takes only recent 10 sessions', () async {
      final sessions = List<SessionSummary>.generate(
        15,
        (i) => SessionSummary(
          startedAt: DateTime.now().subtract(Duration(days: i)),
          endedAt: DateTime.now().subtract(Duration(days: i, hours: 1)),
          durationSeconds: 3600,
          peakRaw: 2000,
          averageActivation: 0.5,
          averageSymmetryIndex: 80.0,
          note: 'Session $i',
        ),
      );

      final result = await SessionAggregator.aggregateSessionHistory(sessions);

      expect(result.sessionCount, 10);
    });

    test('aggregateSessionHistory creates proper grid dimensions', () async {
      final sessions = [
        SessionSummary(
          startedAt: DateTime.now(),
          endedAt: DateTime.now().add(const Duration(hours: 1)),
          durationSeconds: 3600,
          peakRaw: 2000,
          averageActivation: 0.75,
          averageSymmetryIndex: 85.0,
          note: 'Session 1',
        ),
      ];

      final result = await SessionAggregator.aggregateSessionHistory(sessions);

      expect(result.leftIntensities.length, 14);
      expect(result.rightIntensities.length, 14);
      expect(result.leftIntensities[0].length, 4);
      expect(result.rightIntensities[0].length, 4);
    });

    test(
      'aggregateSessionHistory clamps intensities between 0 and 1',
      () async {
        final sessions = [
          SessionSummary(
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(hours: 1)),
            durationSeconds: 3600,
            peakRaw: 5000,
            averageActivation: 1.5,
            averageSymmetryIndex: 100.0,
            note: 'Session 1',
          ),
        ];

        final result = await SessionAggregator.aggregateSessionHistory(
          sessions,
        );

        for (final row in result.leftIntensities) {
          for (final intensity in row) {
            expect(intensity, greaterThanOrEqualTo(0.0));
            expect(intensity, lessThanOrEqualTo(1.0));
          }
        }
      },
    );

    test('SessionHeatmapData.empty creates zero-filled grid', () {
      final data = SessionHeatmapData.empty();

      expect(data.hasData, false);
      expect(data.sessionCount, 0);
      expect(data.averageSymmetry, 0.0);

      for (final row in data.leftIntensities) {
        for (final intensity in row) {
          expect(intensity, 0.0);
        }
      }
    });
  });
}
