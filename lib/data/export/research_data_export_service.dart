import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../../domain/models/research_context.dart';
import '../../domain/models/session_summary.dart';

class ResearchExportFile {
  const ResearchExportFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

class ResearchExportBundle {
  const ResearchExportBundle({
    required this.createdAt,
    required this.participantCount,
    required this.sessionCount,
    required this.files,
  });

  final DateTime createdAt;
  final int participantCount;
  final int sessionCount;
  final List<ResearchExportFile> files;
}

class ResearchDataExportService {
  const ResearchDataExportService();

  ResearchExportBundle buildBundle({
    required List<ParticipantProfile> participants,
    required List<SessionSummary> sessions,
    DateTime? exportedAt,
  }) {
    final createdAt = exportedAt ?? DateTime.now();
    final sortedParticipants = List<ParticipantProfile>.from(participants)
      ..sort((a, b) => a.id.compareTo(b.id));
    final sortedSessions = List<SessionSummary>.from(sessions)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final suffix = _fileTimestamp(createdAt);

    final sessionCsv = _buildSessionCsv(sortedSessions, createdAt);
    final participantCsv = _buildParticipantCsv(sortedParticipants, createdAt);
    final jsonBackup = const JsonEncoder.withIndent('  ').convert(<
      String,
      dynamic
    >{
      'schemaVersion': 1,
      'application': 'SymSync',
      'exportedAt': createdAt.toIso8601String(),
      'participantCount': sortedParticipants.length,
      'sessionCount': sortedSessions.length,
      'measurementNotes': <String>[
        'durationSeconds is elapsed recording-session wall-clock time.',
        'Feedback view was not persisted for historical sessions.',
        'Activation values are within-session relative summaries, not percent MVC.',
        'The export contains summary data, not raw EMG samples.',
      ],
      'participants': sortedParticipants
          .map((participant) => participant.toJson())
          .toList(growable: false),
      'sessions': sortedSessions
          .map(
            (session) => <String, dynamic>{
              ...session.toJson(),
              'durationMinutes': session.durationSeconds / 60,
              'scenarioLabel': UsageScenarioX.fromId(session.scenarioId).label,
            },
          )
          .toList(growable: false),
    });

    return ResearchExportBundle(
      createdAt: createdAt,
      participantCount: sortedParticipants.length,
      sessionCount: sortedSessions.length,
      files: <ResearchExportFile>[
        ResearchExportFile(
          name: 'symsync_sessions_$suffix.csv',
          mimeType: 'text/csv',
          bytes: Uint8List.fromList(utf8.encode('\u{feff}$sessionCsv')),
        ),
        ResearchExportFile(
          name: 'symsync_participants_$suffix.csv',
          mimeType: 'text/csv',
          bytes: Uint8List.fromList(utf8.encode('\u{feff}$participantCsv')),
        ),
        ResearchExportFile(
          name: 'symsync_research_backup_$suffix.json',
          mimeType: 'application/json',
          bytes: Uint8List.fromList(utf8.encode(jsonBackup)),
        ),
      ],
    );
  }

  Future<ShareResult> share(ResearchExportBundle bundle) {
    return SharePlus.instance.share(
      ShareParams(
        subject: 'SymSync research data export',
        text:
            'SymSync export: ${bundle.participantCount} participants and '
            '${bundle.sessionCount} saved sessions.',
        files: bundle.files
            .map((file) => XFile.fromData(file.bytes, mimeType: file.mimeType))
            .toList(growable: false),
        fileNameOverrides: bundle.files
            .map((file) => file.name)
            .toList(growable: false),
      ),
    );
  }

  String _buildSessionCsv(List<SessionSummary> sessions, DateTime exportedAt) {
    const headers = <String>[
      'exported_at',
      'participant_id',
      'scenario_id',
      'scenario_label',
      'started_at',
      'ended_at',
      'duration_seconds',
      'duration_minutes',
      'peak_raw',
      'average_activation_ratio',
      'average_symmetry_index',
      'absolute_symmetry_imbalance',
      'average_left_activation_ratio',
      'average_right_activation_ratio',
      'channel_mapping_json',
      'note',
    ];
    final rows = <List<Object?>>[
      headers,
      ...sessions.map((session) {
        final scenario = UsageScenarioX.fromId(session.scenarioId);
        return <Object?>[
          exportedAt.toIso8601String(),
          session.participantId,
          session.scenarioId,
          scenario.label,
          session.startedAt.toIso8601String(),
          session.endedAt.toIso8601String(),
          session.durationSeconds,
          (session.durationSeconds / 60).toStringAsFixed(3),
          session.peakRaw,
          session.averageActivation,
          session.averageSymmetryIndex,
          session.averageSymmetryIndex?.abs(),
          session.averageLeftActivation,
          session.averageRightActivation,
          session.channelMapping == null
              ? null
              : jsonEncode(session.channelMapping),
          session.note,
        ];
      }),
    ];
    return rows.map(_csvRow).join('\r\n');
  }

  String _buildParticipantCsv(
    List<ParticipantProfile> participants,
    DateTime exportedAt,
  ) {
    const headers = <String>[
      'exported_at',
      'participant_id',
      'created_at',
      'baseline_position',
      'baseline_left_rms',
      'baseline_right_rms',
      'baseline_recorded_at',
    ];
    final rows = <List<Object?>>[headers];
    for (final participant in participants) {
      if (participant.baselineReferences.isEmpty) {
        rows.add(<Object?>[
          exportedAt.toIso8601String(),
          participant.id,
          participant.createdAt.toIso8601String(),
          null,
          null,
          null,
          null,
        ]);
        continue;
      }
      for (final baseline in participant.baselineReferences) {
        rows.add(<Object?>[
          exportedAt.toIso8601String(),
          participant.id,
          participant.createdAt.toIso8601String(),
          baseline.position.id,
          baseline.leftRms,
          baseline.rightRms,
          baseline.recordedAt.toIso8601String(),
        ]);
      }
    }
    return rows.map(_csvRow).join('\r\n');
  }

  String _csvRow(List<Object?> values) => values.map(_csvCell).join(',');

  String _csvCell(Object? value) {
    if (value == null) return '';
    final text = value.toString();
    if (!text.contains(RegExp('[,\"\r\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }

  String _fileTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}
