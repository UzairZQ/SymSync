import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/domain/models/session_summary.dart';
import 'package:sym_sync/domain/models/target_muscle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('clear permanently removes all saved session summaries', () async {
    final store = SessionHistoryStore();
    final startedAt = DateTime(2026, 6, 20, 10);

    await store.save(<SessionSummary>[
      SessionSummary(
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 2)),
        durationSeconds: 120,
        peakRaw: 2300,
        averageActivation: 0.42,
        averageSymmetryIndex: 8.5,
        averageLeftActivation: 0.38,
        averageRightActivation: 0.46,
        note: 'Dummy participant session',
      ),
    ]);

    expect(await store.load(), hasLength(1));

    await store.clear();

    expect(await store.load(), isEmpty);
  });

  test('clear is safe when no session history exists', () async {
    final store = SessionHistoryStore();

    await store.clear();

    expect(await store.load(), isEmpty);
  });

  test('load skips corrupted records without losing valid sessions', () async {
    final startedAt = DateTime(2026, 6, 20, 10);
    final valid = SessionSummary(
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 1)),
      durationSeconds: 60,
      peakRaw: 2400,
      averageActivation: 0.5,
      note: 'Valid session',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'sym_sync.session_history.v1': <String>[
        '{not-json',
        jsonEncode(valid.toJson()),
        jsonEncode(<String, Object>{'unexpected': true}),
      ],
    });

    final result = await SessionHistoryStore().loadWithReport();

    expect(result.sessions, <SessionSummary>[valid]);
    expect(result.rejectedEntryCount, 2);
  });

  test('session target muscle is backward compatible', () {
    final startedAt = DateTime(2026, 7, 15, 10);
    final legacy = <String, dynamic>{
      'startedAt': startedAt.toIso8601String(),
      'endedAt': startedAt.add(const Duration(seconds: 10)).toIso8601String(),
      'durationSeconds': 10,
      'peakRaw': 2200,
      'averageActivation': 0.2,
      'note': 'legacy',
    };
    expect(SessionSummary.fromJson(legacy).targetMuscle, isNull);

    final current = SessionSummary.fromJson(<String, dynamic>{
      ...legacy,
      'targetMuscleId': 'biceps',
    });
    expect(current.targetMuscle, TargetMuscle.biceps);
    expect(current.toJson()['targetMuscleId'], 'biceps');
  });
}
