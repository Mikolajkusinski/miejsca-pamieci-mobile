import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's theme preference (system / light / dark), persisted in
/// SharedPreferences. Load the saved mode with [loadSavedMode] before runApp
/// and pass it as [initialMode].
class ThemeProvider with ChangeNotifier {
  ThemeProvider({ThemeMode initialMode = ThemeMode.system})
      : _themeMode = initialMode;

  static const prefsKey = 'themeMode';

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<ThemeMode> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
    } on Exception {
      return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _persist(mode);
  }

  /// system → light → dark → system.
  void cycleThemeMode() {
    const order = ThemeMode.values; // [system, light, dark]
    setThemeMode(order[(order.indexOf(_themeMode) + 1) % order.length]);
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, mode.name);
    } on Exception {
      // Best effort — the in-memory mode is already applied.
    }
  }
}
