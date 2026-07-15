import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/research_context.dart';

class ResearchContextSnapshot {
  const ResearchContextSnapshot({
    required this.participants,
    required this.activeParticipantId,
    required this.scenario,
    required this.notificationPreferences,
    this.rejectedEntryCount = 0,
  });

  final List<ParticipantProfile> participants;
  final String? activeParticipantId;
  final UsageScenario scenario;
  final NotificationPreferences notificationPreferences;
  final int rejectedEntryCount;
}

class ResearchContextStore {
  static const _participantsKey = 'sym_sync.participants.v1';
  static const _activeParticipantKey = 'sym_sync.active_participant.v1';
  static const _scenarioKey = 'sym_sync.active_scenario.v1';
  static const _notificationKey = 'sym_sync.notification_preferences.v1';

  Future<ResearchContextSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final participantsRaw =
        prefs.getStringList(_participantsKey) ?? const <String>[];
    final participants = <ParticipantProfile>[];
    var rejectedEntryCount = 0;
    for (final entry in participantsRaw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) {
          rejectedEntryCount++;
          continue;
        }
        participants.add(ParticipantProfile.fromJson(decoded));
      } on Object {
        rejectedEntryCount++;
      }
    }
    final activeId = prefs.getString(_activeParticipantKey);
    final notificationRaw = prefs.getString(_notificationKey);

    var notificationPreferences = const NotificationPreferences();
    if (notificationRaw != null) {
      try {
        final decoded = jsonDecode(notificationRaw);
        if (decoded is Map<String, dynamic>) {
          notificationPreferences = NotificationPreferences.fromJson(decoded);
        } else {
          rejectedEntryCount++;
        }
      } on Object {
        rejectedEntryCount++;
      }
    }

    return ResearchContextSnapshot(
      participants: participants,
      activeParticipantId: participants.any((item) => item.id == activeId)
          ? activeId
          : participants.firstOrNull?.id,
      scenario: UsageScenarioX.fromId(prefs.getString(_scenarioKey)),
      notificationPreferences: notificationPreferences,
      rejectedEntryCount: rejectedEntryCount,
    );
  }

  Future<void> saveParticipants(
    List<ParticipantProfile> participants,
    String? activeParticipantId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _participantsKey,
      participants
          .map((participant) => jsonEncode(participant.toJson()))
          .toList(growable: false),
    );
    if (activeParticipantId == null) {
      await prefs.remove(_activeParticipantKey);
    } else {
      await prefs.setString(_activeParticipantKey, activeParticipantId);
    }
  }

  Future<void> saveScenario(UsageScenario scenario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scenarioKey, scenario.id);
  }

  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationKey, jsonEncode(preferences.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      prefs.remove(_participantsKey),
      prefs.remove(_activeParticipantKey),
      prefs.remove(_scenarioKey),
      prefs.remove(_notificationKey),
    ]);
  }
}
