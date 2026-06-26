import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/controllers/queue_controller.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';

void main() {
  late Directory tempDir;
  late QueueController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('queue_controller_test_');
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

    controller = QueueController();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('QueueController', () {
    test('starts with an empty queue list', () {
      controller.loadQueues();

      expect(controller.queues, isEmpty);
    });

    test('creates a queue and loads it', () async {
      await controller.createQueue(
        'School',
        description: 'Class assignments',
      );

      expect(controller.queues.length, 1);
      expect(controller.queues.first.name, 'School');
      expect(controller.queues.first.description, 'Class assignments');
      expect(controller.queues.first.orderMode, OrderMode.dueDate);
      expect(controller.queues.first.isArchived, false);
      expect(controller.queues.first.isComplete, false);
    });

    test('edits a queue', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.editQueue(
        queue,
        name: 'Work',
        description: 'Work tasks',
        orderMode: OrderMode.preferred,
      );

      expect(controller.queues.length, 1);
      expect(controller.queues.first.name, 'Work');
      expect(controller.queues.first.description, 'Work tasks');
      expect(controller.queues.first.orderMode, OrderMode.preferred);
    });

    test('toggles complete status', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.toggleComplete(queue);

      expect(controller.queues.first.isComplete, true);

      await controller.toggleComplete(controller.queues.first);

      expect(controller.queues.first.isComplete, false);
    });

    test('toggles hidden from home status', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.toggleHiddenFromHome(queue);

      expect(controller.queues.first.hiddenFromHome, true);

      await controller.toggleHiddenFromHome(controller.queues.first);

      expect(controller.queues.first.hiddenFromHome, false);
    });

    test('toggles archive status and hides archived queues by default', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.toggleArchive(queue);

      expect(controller.queues, isEmpty);

      controller.loadQueues(includeArchived: true);

      expect(controller.queues.length, 1);
      expect(controller.queues.first.isArchived, true);
    });

    test('sets order mode', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.setOrderMode(queue, OrderMode.preferred);

      expect(controller.queues.first.orderMode, OrderMode.preferred);
    });

    test('reorders queues by updating sortOrder', () async {
      await controller.createQueue('First');
      await controller.createQueue('Second');

      final reordered = [
        controller.queues[1],
        controller.queues[0],
      ];

      await controller.reorderQueues(reordered);

      expect(controller.queues[0].name, 'Second');
      expect(controller.queues[0].sortOrder, 0);
      expect(controller.queues[1].name, 'First');
      expect(controller.queues[1].sortOrder, 1);
    });

    test('deletes a queue', () async {
      await controller.createQueue('School');

      final queue = controller.queues.first;

      await controller.deleteQueue(queue.key as int);

      expect(controller.queues, isEmpty);
    });
  });
}