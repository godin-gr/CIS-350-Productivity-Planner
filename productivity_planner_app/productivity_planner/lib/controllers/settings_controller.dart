import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool showCompletedByDefault = false;
  bool showArchivedByDefault = false;
  Color primaryColor = Colors.deepPurple;
  Color backgroundColor = Colors.white;
  Color textColor = Colors.black;

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

  static const List<Color> backgroundOptions = [
    Colors.white,
    Color(0xFFF5F5F5),
    Color(0xFFFFF9C4),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFF212121),
  ];

  static const List<Color> textOptions = [
    Colors.black,
    Color(0xFF212121),
    Color(0xFF37474F),
    Colors.indigo,
    Colors.deepPurple,
    Colors.white,
  ];

  void setPrimaryColor(Color c) {
    primaryColor = c;
    notifyListeners();
  }

  void setBackgroundColor(Color c) {
    backgroundColor = c;
    notifyListeners();
  }

  void setTextColor(Color c) {
    textColor = c;
    notifyListeners();
  }

  void setShowCompleted(bool v) {
    showCompletedByDefault = v;
    notifyListeners();
  }

  void setShowArchived(bool v) {
    showArchivedByDefault = v;
    notifyListeners();
  }
}