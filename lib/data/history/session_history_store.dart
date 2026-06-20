import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/session_summary.dart';

class SessionHistoryStore {
  static const String _historyKey = 'sym_sync.session_history.v1';

  Future<List<SessionSummary>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? <String>[];
    return raw
        .map(
          (entry) => SessionSummary.fromJson(
            jsonDecode(entry) as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
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
