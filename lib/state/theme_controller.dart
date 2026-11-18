import 'package:flutter/material.dart';

import '../data/database.dart';

enum ThemeModeChoice { light, dark, system }

/// Persists and applies the Light / Dark / System choice.
class ThemeController extends ChangeNotifier {
  ThemeModeChoice _choice = ThemeModeChoice.system;

  ThemeModeChoice get choice => _choice;

  ThemeMode get themeMode => switch (_choice) {
        ThemeModeChoice.light => ThemeMode.light,
        ThemeModeChoice.dark => ThemeMode.dark,
        ThemeModeChoice.system => ThemeMode.system,
      };

  void load() {
    final raw = DatabaseService.instance
        .getSetting<String>(SettingsKeys.theme, fallback: 'system');
    _choice = ThemeModeChoice.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => ThemeModeChoice.system,
    );
    notifyListeners();
  }

  Future<void> setChoice(ThemeModeChoice c) async {
    if (c == _choice) return;
    _choice = c;
    await DatabaseService.instance.setSetting(SettingsKeys.theme, c.name);
    notifyListeners();
  }
}
