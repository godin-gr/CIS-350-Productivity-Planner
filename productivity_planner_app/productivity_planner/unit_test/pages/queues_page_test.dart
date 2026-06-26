import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/controllers/queue_controller.dart';
import 'package:productivity_planner/database/database_helper.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';
import 'package:productivity_planner/pages/queues_page.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper db;
  late QueueController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('queues_page_test_');
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
    controller = QueueController();
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('QueuesPage', () {
    test('can be created', () {
      const page = QueuesPage();

      expect(page, isA<QueuesPage>());
    });

    test('loads active queues separately from completed queues', () async {
      await db.insertQueue(
        Queue(
          name: 'School',
          description: 'Class tasks',
          sortOrder: 0,
        ),
      );

      await db.insertQueue(
        Queue(
          name: 'Completed queue',
          isComplete: true,
          sortOrder: 1,
        ),
      );

      controller.loadQueues();

      final activeQueues =
          controller.queues.where((queue) => !queue.isComplete).toList();
      final completedQueues =
          controller.queues.where((queue) => queue.isComplete).toList();

      expect(activeQueues.length, 1);
      expect(activeQueues.first.name, 'School');
      expect(activeQueues.first.description, 'Class tasks');

      expect(completedQueues.length, 1);
      expect(completedQueues.first.name, 'Completed queue');
    });

    test('hides archived queues by default', () async {
      await db.insertQueue(Queue(name: 'Active queue'));
      await db.insertQueue(
        Queue(
          name: 'Archived queue',
          isArchived: true,
        ),
      );

      controller.loadQueues();

      expect(controller.queues.length, 1);
      expect(controller.queues.first.name, 'Active queue');
    });

    test('can include archived queues like the show archived button does', () async {
      await db.insertQueue(Queue(name: 'Active queue'));
      await db.insertQueue(
        Queue(
          name: 'Archived queue',
          isArchived: true,
        ),
      );

      controller.loadQueues(includeArchived: true);

      expect(controller.queues.length, 2);
      expect(
        controller.queues.any((queue) => queue.name == 'Archived queue'),
        true,
      );
    });

    test('can mark a queue complete', () async {
      await db.insertQueue(Queue(name: 'School'));

      controller.loadQueues();

      await controller.toggleComplete(controller.queues.first);

      controller.loadQueues();

      expect(controller.queues.first.name, 'School');
      expect(controller.queues.first.isComplete, true);
    });

    test('can hide a queue from home', () async {
      await db.insertQueue(Queue(name: 'School'));

      controller.loadQueues();

      await controller.toggleHiddenFromHome(controller.queues.first);

      controller.loadQueues();

      expect(controller.queues.first.name, 'School');
      expect(controller.queues.first.hiddenFromHome, true);
    });

    test('can archive a queue', () async {
      await db.insertQueue(Queue(name: 'School'));

      controller.loadQueues();

      await controller.toggleArchive(controller.queues.first);

      controller.loadQueues();

      expect(controller.queues, isEmpty);

      controller.loadQueues(includeArchived: true);

      expect(controller.queues.length, 1);
      expect(controller.queues.first.name, 'School');
      expect(controller.queues.first.isArchived, true);
    });
  });
}