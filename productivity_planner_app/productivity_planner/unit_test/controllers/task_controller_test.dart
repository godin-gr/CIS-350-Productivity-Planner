import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/controllers/task_controller.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';

void main() {
  late Directory tempDir;
  late TaskController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('task_controller_test_');
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

    controller = TaskController();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('TaskController', () {
    test('starts with an empty task list for a queue', () {
      controller.loadTasksForQueue(1);

      expect(controller.tasks, isEmpty);
    });

    test('creates a task and loads it for the queue', () async {
      await controller.createTask(
        1,
        'Finish homework',
        dueDate: '2026-06-25',
        description: 'Complete the assignment',
      );

      expect(controller.tasks.length, 1);
      expect(controller.tasks.first.queueId, 1);
      expect(controller.tasks.first.title, 'Finish homework');
      expect(controller.tasks.first.dueDate, '2026-06-25');
      expect(controller.tasks.first.description, 'Complete the assignment');
      expect(controller.tasks.first.isComplete, false);
      expect(controller.tasks.first.isArchived, false);
      expect(controller.tasks.first.preferredOrder, 0);
    });

    test('new tasks are added in order', () async {
      await controller.createTask(1, 'First task');
      await controller.createTask(1, 'Second task');

      expect(controller.tasks.length, 2);
      expect(controller.tasks[0].title, 'First task');
      expect(controller.tasks[1].title, 'Second task');
    });

    test('toggles complete status', () async {
      await controller.createTask(1, 'Finish homework');

      final task = controller.tasks.first;

      await controller.toggleComplete(task);

      expect(controller.tasks.first.isComplete, true);
      expect(controller.tasks.first.completedAt, greaterThan(0));

      await controller.toggleComplete(controller.tasks.first);

      expect(controller.tasks.first.isComplete, false);
      expect(controller.tasks.first.completedAt, 0);
      expect(controller.tasks.first.isFiled, false);
    });

    test('files completed tasks for one queue', () async {
      await controller.createTask(1, 'Task one');
      await controller.createTask(1, 'Task two');

      await controller.toggleComplete(controller.tasks.first);
      await controller.fileCompleted(1);

      final filedTasks = controller.tasks.where((task) => task.isFiled).toList();

      expect(filedTasks.length, 1);
      expect(filedTasks.first.isComplete, true);
    });

    test('toggles archive status and hides archived tasks by default', () async {
      await controller.createTask(1, 'Finish homework');

      final task = controller.tasks.first;

      await controller.toggleArchive(task);

      expect(controller.tasks, isEmpty);

      controller.loadTasksForQueue(1, includeArchived: true);

      expect(controller.tasks.length, 1);
      expect(controller.tasks.first.isArchived, true);
    });

    test('archives filed tasks', () async {
      await controller.createTask(1, 'Finish homework');

      await controller.toggleComplete(controller.tasks.first);
      await controller.fileCompleted(1);
      await controller.archiveFiled(1);

      expect(controller.tasks, isEmpty);

      controller.loadTasksForQueue(1, includeArchived: true);

      expect(controller.tasks.length, 1);
      expect(controller.tasks.first.isArchived, true);
    });

    test('reorders tasks by updating preferredOrder', () async {
      await controller.createTask(1, 'First task');
      await controller.createTask(1, 'Second task');

      final reordered = [
        controller.tasks[1],
        controller.tasks[0],
      ];

      await controller.reorderTasks(reordered);

      expect(controller.tasks[0].title, 'Second task');
      expect(controller.tasks[0].preferredOrder, 0);
      expect(controller.tasks[1].title, 'First task');
      expect(controller.tasks[1].preferredOrder, 1);
    });

    test('updates task fields', () async {
      await controller.createTask(1, 'Original title');

      final task = controller.tasks.first;

      await controller.updateTask(
        task,
        title: 'Updated title',
        description: 'Updated description',
        dueDate: '2026-07-01',
      );

      expect(controller.tasks.first.title, 'Updated title');
      expect(controller.tasks.first.description, 'Updated description');
      expect(controller.tasks.first.dueDate, '2026-07-01');
    });

    test('clears due date when clearDueDate is true', () async {
      await controller.createTask(
        1,
        'Task with due date',
        dueDate: '2026-06-25',
      );

      final task = controller.tasks.first;

      await controller.updateTask(
        task,
        clearDueDate: true,
      );

      expect(controller.tasks.first.dueDate, null);
    });

    test('deletes a task', () async {
      await controller.createTask(1, 'Finish homework');

      final task = controller.tasks.first;

      await controller.deleteTask(task.key as int, task.queueId);

      expect(controller.tasks, isEmpty);
    });
  });
}