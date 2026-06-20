import 'package:flutter/material.dart';
import '../database/database_helper.dart';

enum AppFontSize { verySmall, small, medium, large }

class SettingsController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  Color primaryColor = Colors.deepPurple;
  bool isDarkMode = false;
  AppFontSize fontSize = AppFontSize.medium;

  SettingsController() {
    _load();
  }

  void _load() {
    final colorValue =
        _db.getSetting('primaryColor', defaultValue: Colors.deepPurple.value);
    primaryColor = Color(colorValue as int);
    isDarkMode = _db.getSetting('isDarkMode', defaultValue: false) as bool;
    final fontIndex =
        _db.getSetting('fontSize', defaultValue: AppFontSize.medium.index)
            as int;
    fontSize = AppFontSize.values[
        fontIndex.clamp(0, AppFontSize.values.length - 1)];
  }

  static const List<Color> primaryOptions = [
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
  ];

  // Background and text are derived from the light/dark mode so the rest of the
  // app can keep referring to settings.backgroundColor / settings.textColor.
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF121212) : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black;

  // A multiplier applied to all text via MediaQuery's textScaler.
  double get fontScale {
    switch (fontSize) {
      case AppFontSize.verySmall:
        return 0.85;
      case AppFontSize.small:
        return 0.95;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.15;
    }
  }

  String get fontSizeLabel {
    switch (fontSize) {
      case AppFontSize.verySmall:
        return 'Very small';
      case AppFontSize.small:
        return 'Small';
      case AppFontSize.medium:
        return 'Medium';
      case AppFontSize.large:
        return 'Large';
    }
  }

  void setPrimaryColor(Color c) {
    primaryColor = c;
    _db.setSetting('primaryColor', c.value);
    notifyListeners();
  }

  void setDarkMode(bool v) {
    isDarkMode = v;
    _db.setSetting('isDarkMode', v);
    notifyListeners();
  }

  void setFontSize(AppFontSize v) {
    fontSize = v;
    _db.setSetting('fontSize', v.index);
    notifyListeners();
  }

  // Re-read all settings from storage (used after a full data reset, when the
  // settings box has been cleared and values should revert to defaults).
  void reload() {
    _load();
    notifyListeners();
  }
}