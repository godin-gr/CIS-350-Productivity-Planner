import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/controllers/settings_controller.dart';
import 'package:productivity_planner/database/database_helper.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';
import 'package:productivity_planner/pages/settings_page.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper db;
  late SettingsController settingsController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_page_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QueueAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskAdapter());
    }

    await Hive.openBox<Queue>('queues');
    await Hive.openBox<Task>('tasks');
    await Hive.openBox('settings');

    db = DatabaseHelper();
    settingsController = SettingsController();
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SettingsPage', () {
    test('can be created', () {
      const page = SettingsPage();

      expect(page, isA<SettingsPage>());
    });

    test('can save dark mode setting', () {
      settingsController.setDarkMode(true);

      final savedValue = db.getSetting('isDarkMode', defaultValue: false);

      expect(settingsController.isDarkMode, true);
      expect(settingsController.backgroundColor, const Color(0xFF121212));
      expect(settingsController.textColor, Colors.white);
      expect(savedValue, true);
    });

    test('can save font size setting', () {
      settingsController.setFontSize(AppFontSize.large);

      final savedValue = db.getSetting(
        'fontSize',
        defaultValue: AppFontSize.medium.index,
      );

      expect(settingsController.fontSize, AppFontSize.large);
      expect(settingsController.fontSizeLabel, 'Large');
      expect(settingsController.fontScale, 1.15);
      expect(savedValue, AppFontSize.large.index);
    });

    test('can save primary color setting', () {
      settingsController.setPrimaryColor(Colors.teal);

      final savedValue = db.getSetting(
        'primaryColor',
        defaultValue: Colors.deepPurple.value,
      );

      expect(settingsController.primaryColor.value, Colors.teal.value);
      expect(savedValue, Colors.teal.value);
    });

    test('delete archived behavior keeps active data', () async {
      final activeQueueId = await db.insertQueue(Queue(name: 'Active queue'));

      final archivedQueueId = await db.insertQueue(
        Queue(
          name: 'Archived queue',
          isArchived: true,
        ),
      );

      await db.insertTask(
        Task(
          queueId: activeQueueId,
          title: 'Active task',
        ),
      );

      await db.insertTask(
        Task(
          queueId: activeQueueId,
          title: 'Archived task',
          isArchived: true,
        ),
      );

      await db.insertTask(
        Task(
          queueId: archivedQueueId,
          title: 'Task inside archived queue',
        ),
      );

      final removed = await db.deleteArchived();

      final queues = db.getQueues(includeArchived: true);
      final tasks = db.getAllTasks(includeArchived: true);

      expect(removed, 3);
      expect(queues.length, 1);
      expect(queues.first.name, 'Active queue');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Active task');
    });

    test('reset all data behavior clears queues tasks and settings', () async {
      final queueId = await db.insertQueue(Queue(name: 'School'));

      await db.insertTask(
        Task(
          queueId: queueId,
          title: 'Finish homework',
        ),
      );

      settingsController.setDarkMode(true);

      await db.resetAllData();
      settingsController.reload();

      expect(db.getQueues(includeArchived: true), isEmpty);
      expect(db.getAllTasks(includeArchived: true), isEmpty);
      expect(settingsController.isDarkMode, false);
      expect(settingsController.fontSize, AppFontSize.medium);
      expect(settingsController.primaryColor.value, Colors.deepPurple.value);
    });
  });
}