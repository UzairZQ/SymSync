import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  
  static const String _key = 'theme_mode';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_key);
      if (savedMode == 'light') {
        themeNotifier.value = ThemeMode.light;
      } else if (savedMode == 'dark') {
        themeNotifier.value = ThemeMode.dark;
      } else if (savedMode == 'system') {
        themeNotifier.value = ThemeMode.system;
      } else {
        themeNotifier.value = ThemeMode.dark; // Default is dark
      }
    } catch (_) {
      themeNotifier.value = ThemeMode.dark;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}
