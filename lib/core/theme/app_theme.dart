import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

export 'status_colors_extension.dart';

/// CNG LIVE — Theme Entry Point
///
/// Single place `app.dart` reads from. Theme switching itself (light /
/// dark / system) is controlled by SettingsViewModel + ThemeModeController
/// below, persisted via core/utils app_preferences (Hive/SharedPreferences).
class AppTheme {
  AppTheme._();

  static final ThemeData light = buildLightTheme();
  static final ThemeData dark = buildDarkTheme();
}

/// App-wide ThemeMode holder, exposed via Provider at the root so any
/// widget can read/change it (consumed primarily by SettingsScreen).
class ThemeModeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    // Persistence: theme mode is in-memory only for this build. Wiring
    // SharedPreferences/Hive persistence here is a future enhancement,
    // not required by the current MVP scope.
  }
}
