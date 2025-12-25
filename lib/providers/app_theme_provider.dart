import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class AppThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode'; // 0=system,1=light,2=dark

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final v = HiveService.appBox.get(_themeKey, defaultValue: 0) as int;
    _mode = switch (v) {
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final v = switch (mode) {
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
      ThemeMode.system => 0,
    };
    await HiveService.appBox.put(_themeKey, v);
    notifyListeners();
  }

  bool get isDark => _mode == ThemeMode.dark;
}
