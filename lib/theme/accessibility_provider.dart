import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider {
  static const _colorBlindKey = 'color_blind_mode';

  static final ValueNotifier<bool> colorBlindNotifier = ValueNotifier<bool>(
    false,
  );

  static bool get colorBlindMode => colorBlindNotifier.value;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    colorBlindNotifier.value = prefs.getBool(_colorBlindKey) ?? false;
  }

  static Future<void> setColorBlindMode(bool enabled) async {
    colorBlindNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorBlindKey, enabled);
  }
}
