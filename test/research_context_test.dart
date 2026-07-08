import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sym_sync/data/research/research_context_store.dart';
import 'package:sym_sync/domain/models/research_context.dart';
import 'package:sym_sync/domain/models/session_summary.dart';
import 'package:sym_sync/presentation/bloc/session_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'research context persists participant, scenario, and preferences',
    () async {
      final store = ResearchContextStore();
      final participant = ParticipantProfile(
        id: 'P001',
        createdAt: DateTime(2026, 6, 20),
      );
      const preferences = NotificationPreferences(
        enabled: true,
        imbalanceThreshold: 25,
        sustainedSeconds: 20,
        cooldownMinutes: 8,
      );

      await store.saveParticipants(<ParticipantProfile>[participant], 'P001');
      await store.saveScenario(UsageScenario.everydayStairs);
      await store.saveNotificationPreferences(preferences);

      final loaded = await store.load();
      expect(loaded.participants, <ParticipantProfile>[participant]);
      expect(loaded.activeParticipantId, 'P001');
      expect(loaded.scenario, UsageScenario.everydayStairs);
      expect(loaded.notificationPreferences, preferences);
    },
  );

  test('research reset removes participant registry and preferences', () async {
    final store = ResearchContextStore();
    final participant = ParticipantProfile(
      id: 'P001',
      createdAt: DateTime(2026, 6, 20),
    );
    await store.saveParticipants(<ParticipantProfile>[participant], 'P001');
    await store.saveScenario(UsageScenario.gymExercise);
    await store.saveNotificationPreferences(
      const NotificationPreferences(enabled: true),
    );

    await store.clear();

    final loaded = await store.load();
    expect(loaded.participants, isEmpty);
    expect(loaded.activeParticipantId, isNull);
    expect(loaded.scenario, UsageScenario.officeDesk);
    expect(loaded.notificationPreferences.enabled, isFalse);
  });

  test('participant JSON retains baseline reference recordings', () {
    final participant = ParticipantProfile(
      id: 'P003',
      createdAt: DateTime(2026, 6, 20),
      baselineReferences: <BaselineReference>[
        BaselineReference(
          position: BaselineReferencePosition.straightAhead,
          leftRms: 1020,
          rightRms: 980,
          recordedAt: DateTime(2026, 7, 8, 10),
        ),
        BaselineReference(
          position: BaselineReferencePosition.farRight,
          leftRms: 1350,
          rightRms: 1180,
          recordedAt: DateTime(2026, 7, 8, 10, 1),
        ),
      ],
    );

    final decoded = ParticipantProfile.fromJson(participant.toJson());

    expect(decoded, participant);
    expect(
      decoded.baselineFor(BaselineReferencePosition.straightAhead)?.leftRms,
      1020,
    );
    expect(decoded.baselineFor(BaselineReferencePosition.farLeft), isNull);
  });

  test('active history never mixes participant measurements', () {
    final first = _summary('P001', UsageScenario.officeDesk);
    final second = _summary('P002', UsageScenario.gymExercise);
    final state = SessionState.initial().copyWith(
      participants: <ParticipantProfile>[
        ParticipantProfile(id: 'P001', createdAt: DateTime(2026, 6, 20)),
        ParticipantProfile(id: 'P002', createdAt: DateTime(2026, 6, 20)),
      ],
      activeParticipantId: 'P002',
      history: <SessionSummary>[first, second],
    );

    expect(state.activeHistory, <SessionSummary>[second]);
    expect(state.displayName, 'Participant P002');
  });

  test('session JSON retains anonymous participant and scenario tags', () {
    final summary = _summary('P007', UsageScenario.everydayStairs);

    final decoded = SessionSummary.fromJson(summary.toJson());

    expect(decoded, summary);
    expect(decoded.participantId, 'P007');
    expect(decoded.scenarioId, UsageScenario.everydayStairs.id);
  });
}

SessionSummary _summary(String participantId, UsageScenario scenario) {
  final startedAt = DateTime(2026, 6, 20, 12);
  return SessionSummary(
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 2)),
    durationSeconds: 120,
    peakRaw: 2400,
    averageActivation: 0.5,
    averageSymmetryIndex: 8,
    averageLeftActivation: 0.45,
    averageRightActivation: 0.55,
    note: 'Research session',
    participantId: participantId,
    scenarioId: scenario.id,
  );
}
