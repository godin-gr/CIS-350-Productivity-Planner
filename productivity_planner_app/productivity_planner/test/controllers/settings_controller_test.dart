import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/controllers/settings_controller.dart';

void main() {
  late Directory tempDir;
  late SettingsController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_controller_test_');
    Hive.init(tempDir.path);

    await Hive.openBox('settings');

    controller = SettingsController();
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SettingsController', () {
    test('loads default settings when no saved settings exist', () {
      expect(controller.primaryColor.value, Colors.deepPurple.value);
      expect(controller.isDarkMode, false);
      expect(controller.fontSize, AppFontSize.medium);
      expect(controller.backgroundColor, Colors.white);
      expect(controller.textColor, Colors.black);
      expect(controller.fontScale, 1.0);
      expect(controller.fontSizeLabel, 'Medium');
    });

    test('setPrimaryColor updates the color and saves it', () {
      controller.setPrimaryColor(Colors.teal);

      expect(controller.primaryColor.value, Colors.teal.value);

      final reloaded = SettingsController();

      expect(reloaded.primaryColor.value, Colors.teal.value);
    });

    test('setDarkMode updates dark mode and saves it', () {
      controller.setDarkMode(true);

      expect(controller.isDarkMode, true);
      expect(controller.backgroundColor, const Color(0xFF121212));
      expect(controller.textColor, Colors.white);

      final reloaded = SettingsController();

      expect(reloaded.isDarkMode, true);
    });

    test('setFontSize updates font size and saves it', () {
      controller.setFontSize(AppFontSize.large);

      expect(controller.fontSize, AppFontSize.large);
      expect(controller.fontScale, 1.15);
      expect(controller.fontSizeLabel, 'Large');

      final reloaded = SettingsController();

      expect(reloaded.fontSize, AppFontSize.large);
    });

    test('fontScale matches each font size option', () {
      controller.setFontSize(AppFontSize.verySmall);
      expect(controller.fontScale, 0.85);

      controller.setFontSize(AppFontSize.small);
      expect(controller.fontScale, 0.95);

      controller.setFontSize(AppFontSize.medium);
      expect(controller.fontScale, 1.0);

      controller.setFontSize(AppFontSize.large);
      expect(controller.fontScale, 1.15);
    });

    test('fontSizeLabel matches each font size option', () {
      controller.setFontSize(AppFontSize.verySmall);
      expect(controller.fontSizeLabel, 'Very small');

      controller.setFontSize(AppFontSize.small);
      expect(controller.fontSizeLabel, 'Small');

      controller.setFontSize(AppFontSize.medium);
      expect(controller.fontSizeLabel, 'Medium');

      controller.setFontSize(AppFontSize.large);
      expect(controller.fontSizeLabel, 'Large');
    });

    test('reload reads updated values from storage', () async {
      final box = Hive.box('settings');

      await box.put('isDarkMode', true);
      await box.put('fontSize', AppFontSize.small.index);
      await box.put('primaryColor', Colors.orange.value);

      controller.reload();

      expect(controller.isDarkMode, true);
      expect(controller.fontSize, AppFontSize.small);
      expect(controller.primaryColor.value, Colors.orange.value);
    });

    test('setters notify listeners', () {
      var notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      controller.setDarkMode(true);
      controller.setFontSize(AppFontSize.large);
      controller.setPrimaryColor(Colors.blue);

      expect(notificationCount, 3);
    });
  });
}