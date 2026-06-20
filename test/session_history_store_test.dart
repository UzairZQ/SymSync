import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/history/session_history_store.dart';
import 'package:sym_sync/domain/models/session_summary.dart';

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
}
