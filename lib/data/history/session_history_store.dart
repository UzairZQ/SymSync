import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/session_summary.dart';

class SessionHistoryLoadResult {
  const SessionHistoryLoadResult({
    required this.sessions,
    required this.rejectedEntryCount,
  });

  final List<SessionSummary> sessions;
  final int rejectedEntryCount;
}

class SessionHistoryStore {
  static const String _historyKey = 'sym_sync.session_history.v1';

  Future<List<SessionSummary>> load() async {
    return (await loadWithReport()).sessions;
  }

  Future<SessionHistoryLoadResult> loadWithReport() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    final sessions = <SessionSummary>[];
    var rejectedEntryCount = 0;
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is! Map<String, dynamic>) {
          rejectedEntryCount++;
          continue;
        }
        sessions.add(SessionSummary.fromJson(decoded));
      } on Object {
        rejectedEntryCount++;
      }
    }
    return SessionHistoryLoadResult(
      sessions: List<SessionSummary>.unmodifiable(sessions),
      rejectedEntryCount: rejectedEntryCount,
    );
  }

  Future<void> save(List<SessionSummary> summaries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = summaries
        .map((summary) => jsonEncode(summary.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_historyKey, encoded);
  }

  Future<void> append(SessionSummary summary) async {
    final items = await load();
    items.insert(0, summary);
    await save(items.take(500).toList(growable: false));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
