import 'package:flutter/material.dart';
import '../database/database_helper.dart';

/// Font size options available in the app settings.
enum AppFontSize { verySmall, small, medium, large }

/// Controls all user-customizable app settings.
///
/// This class loads settings from the local database, stores updates, and
/// notifies the UI when theme, color, or font size settings change.
class SettingsController extends ChangeNotifier {
  /// Local database helper used to save and load app settings.
  final DatabaseHelper _db = DatabaseHelper();

  /// Main color used to build the app's color scheme.
  Color primaryColor = Colors.deepPurple;

  /// Whether the app should use dark mode.
  bool isDarkMode = false;

  /// Current font size option selected by the user.
  AppFontSize fontSize = AppFontSize.medium;

  /// Creates the settings controller and loads saved settings.
  SettingsController() {
    _load();
  }

  /// Loads saved settings from the database.
  ///
  /// If no saved value exists, default values are used instead.
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

  /// Color options that the user can choose from in settings.
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

  /// Background color based on the current theme mode.
  Color get backgroundColor =>
      isDarkMode ? const Color(0xFF121212) : Colors.white;

  /// Text color based on the current theme mode.
  Color get textColor => isDarkMode ? Colors.white : Colors.black;

  // A multiplier applied to all text via MediaQuery's textScaler.

  /// Text scaling value used across the app.
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

  /// Display label for the currently selected font size.
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

  /// Updates the app's primary color and saves it to the database.
  void setPrimaryColor(Color c) {
    primaryColor = c;
    _db.setSetting('primaryColor', c.value);
    notifyListeners();
  }

  /// Turns dark mode on or off and saves the setting.
  void setDarkMode(bool v) {
    isDarkMode = v;
    _db.setSetting('isDarkMode', v);
    notifyListeners();
  }

  /// Updates the selected font size and saves it to the database.
  void setFontSize(AppFontSize v) {
    fontSize = v;
    _db.setSetting('fontSize', v.index);
    notifyListeners();
  }

  // Re-read all settings from storage (used after a full data reset, when the
  // settings box has been cleared and values should revert to defaults).

  /// Reloads settings from storage and updates the UI.
  void reload() {
    _load();
    notifyListeners();
  }
}