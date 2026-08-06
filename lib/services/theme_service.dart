import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'selected_theme';

  static Future<ThemeMode> loadThemeMode() async {
    final preferences =
    await SharedPreferences.getInstance();

    final savedTheme =
    preferences.getString(_themeKey);

    switch (savedTheme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(
      ThemeMode themeMode,
      ) async {
    final preferences =
    await SharedPreferences.getInstance();

    switch (themeMode) {
      case ThemeMode.light:
        await preferences.setString(
          _themeKey,
          'light',
        );
      case ThemeMode.dark:
        await preferences.setString(
          _themeKey,
          'dark',
        );
      case ThemeMode.system:
        await preferences.setString(
          _themeKey,
          'system',
        );
    }
  }
}