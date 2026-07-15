import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sym_sync/data/export/research_data_export_service.dart';
import 'package:sym_sync/domain/models/research_context.dart';
import 'package:sym_sync/domain/models/feedback_view.dart';
import 'package:sym_sync/domain/models/session_summary.dart';
import 'package:sym_sync/domain/models/target_muscle.dart';

void main() {
  const service = ResearchDataExportService();
  final exportedAt = DateTime(2026, 7, 10, 14, 30);
  final startedAt = DateTime(2026, 7, 9, 10);
  final participant = ParticipantProfile(
    id: 'P012',
    createdAt: DateTime(2026, 7, 9, 9),
    baselineReferences: <BaselineReference>[
      BaselineReference(
        position: BaselineReferencePosition.straightAhead,
        leftRms: 12.5,
        rightRms: 13.5,
        recordedAt: DateTime(2026, 7, 9, 9, 45),
      ),
    ],
  );
  final session = SessionSummary(
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(seconds: 95)),
    durationSeconds: 95,
    peakRaw: 2410,
    averageActivation: 0.48,
    averageSymmetryIndex: -7.5,
    averageLeftActivation: 0.52,
    averageRightActivation: 0.44,
    note: 'Saved, complete',
    channelMapping: const <String, String>{
      'CH1': 'Left upper trapezius',
      'CH3': 'Right upper trapezius',
    },
    participantId: participant.id,
    scenarioId: UsageScenario.everydayStairs.id,
    feedbackView: FeedbackView.anatomicalHeatmap,
    targetMuscle: TargetMuscle.biceps,
    simulatedInput: false,
  );

  test('exports historical scenario duration and summary metrics to CSV', () {
    final bundle = service.buildBundle(
      participants: <ParticipantProfile>[participant],
      sessions: <SessionSummary>[session],
      exportedAt: exportedAt,
    );

    final sessionFile = bundle.files.firstWhere(
      (file) => file.name.contains('sessions'),
    );
    final csv = utf8.decode(sessionFile.bytes).replaceFirst('\u{feff}', '');

    expect(csv, contains('duration_seconds,duration_minutes'));
    expect(csv, contains('feedback_view_id,feedback_view_label'));
    expect(csv, contains('target_muscle_id,target_muscle_label'));
    expect(csv, contains('simulated_input'));
    expect(csv, contains('P012,everydayStairs,Backpack Stair Climb'));
    expect(csv, contains('anatomical_heatmap,Anatomical Heatmap'));
    expect(csv, contains('biceps,Biceps'));
    expect(csv, contains(',95,1.583,2410,0.48,-7.5,7.5,'));
    expect(csv, contains('"Saved, complete"'));
  });

  test('JSON export preserves existing session and participant records', () {
    final originalParticipant = participant.toJson();
    final originalSession = session.toJson();

    final bundle = service.buildBundle(
      participants: <ParticipantProfile>[participant],
      sessions: <SessionSummary>[session],
      exportedAt: exportedAt,
    );
    final jsonFile = bundle.files.firstWhere(
      (file) => file.name.endsWith('.json'),
    );
    final decoded = jsonDecode(utf8.decode(jsonFile.bytes));

    expect(decoded['participantCount'], 1);
    expect(decoded['sessionCount'], 1);
    expect(decoded['sessions'][0]['durationSeconds'], 95);
    expect(decoded['sessions'][0]['scenarioLabel'], 'Backpack Stair Climb');
    expect(decoded['sessions'][0]['feedbackViewLabel'], 'Anatomical Heatmap');
    expect(decoded['sessions'][0]['targetMuscleLabel'], 'Biceps');
    expect(participant.toJson(), originalParticipant);
    expect(session.toJson(), originalSession);
  });

  test('exports calibration baseline values with position and timestamp', () {
    final bundle = service.buildBundle(
      participants: <ParticipantProfile>[participant],
      sessions: <SessionSummary>[session],
      exportedAt: exportedAt,
    );
    final participantFile = bundle.files.firstWhere(
      (file) => file.name.contains('participants'),
    );
    final csv = utf8.decode(participantFile.bytes).replaceFirst('\u{feff}', '');

    expect(
      csv,
      contains(
        'P012,2026-07-09T09:00:00.000,straightAhead,12.5,13.5,'
        '2026-07-09T09:45:00.000',
      ),
    );
  });

  test('empty data still produces auditable CSV and JSON files', () {
    final bundle = service.buildBundle(
      participants: const <ParticipantProfile>[],
      sessions: const <SessionSummary>[],
      exportedAt: exportedAt,
    );

    expect(bundle.participantCount, 0);
    expect(bundle.sessionCount, 0);
    expect(bundle.files, hasLength(3));
    expect(utf8.decode(bundle.files.first.bytes), contains('duration_seconds'));
  });
}
