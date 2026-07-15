import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider {
  static const _colorBlindKey = 'color_blind_mode';

  static final ValueNotifier<bool> colorBlindNotifier = ValueNotifier<bool>(
    false,
  );

  static bool get colorBlindMode => colorBlindNotifier.value;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      colorBlindNotifier.value = prefs.getBool(_colorBlindKey) ?? false;
    } catch (_) {
      colorBlindNotifier.value = false;
    }
  }

  static Future<void> setColorBlindMode(bool enabled) async {
    colorBlindNotifier.value = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_colorBlindKey, enabled);
    } catch (_) {
      // Keep the in-memory preference for the current app session.
    }
  }
}
