import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/database/database_helper.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('database_helper_test_');
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
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('DatabaseHelper settings', () {
    test('sets and gets a setting', () async {
      await db.setSetting('isDarkMode', true);

      final value = db.getSetting('isDarkMode', defaultValue: false);

      expect(value, true);
    });

    test('returns default value when setting does not exist', () {
      final value = db.getSetting('missingSetting', defaultValue: 'default');

      expect(value, 'default');
    });
  });

  group('DatabaseHelper queues', () {
    test('inserts a queue and assigns its id', () async {
      final queue = Queue(name: 'School');

      final id = await db.insertQueue(queue);
      final queues = db.getQueues();

      expect(id, queue.id);
      expect(queues.length, 1);
      expect(queues.first.name, 'School');
    });

    test('gets queues sorted by sortOrder', () async {
      await db.insertQueue(Queue(name: 'Second', sortOrder: 1));
      await db.insertQueue(Queue(name: 'First', sortOrder: 0));

      final queues = db.getQueues();

      expect(queues[0].name, 'First');
      expect(queues[1].name, 'Second');
    });

    test('does not include archived queues by default', () async {
      await db.insertQueue(Queue(name: 'Active queue'));
      await db.insertQueue(Queue(name: 'Archived queue', isArchived: true));

      final queues = db.getQueues();

      expect(queues.length, 1);
      expect(queues.first.name, 'Active queue');
    });

    test('includes archived queues when requested', () async {
      await db.insertQueue(Queue(name: 'Active queue'));
      await db.insertQueue(Queue(name: 'Archived queue', isArchived: true));

      final queues = db.getQueues(includeArchived: true);

      expect(queues.length, 2);
    });

    test('updates a queue', () async {
      final queue = Queue(name: 'Original');
      await db.insertQueue(queue);

      queue.name = 'Updated';
      await db.updateQueue(queue);

      final queues = db.getQueues();

      expect(queues.first.name, 'Updated');
    });

    test('deletes a queue and its tasks', () async {
      final queueId = await db.insertQueue(Queue(name: 'School'));

      await db.insertTask(Task(queueId: queueId, title: 'Task one'));
      await db.insertTask(Task(queueId: queueId, title: 'Task two'));

      await db.deleteQueue(queueId);

      expect(db.getQueues(), isEmpty);
      expect(db.getTasksForQueue(queueId), isEmpty);
    });
  });

  group('DatabaseHelper tasks', () {
    test('inserts a task and assigns its id', () async {
      final task = Task(queueId: 1, title: 'Finish homework');

      final id = await db.insertTask(task);
      final tasks = db.getTasksForQueue(1);

      expect(id, task.id);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Finish homework');
    });

    test('gets tasks for only the selected queue', () async {
      await db.insertTask(Task(queueId: 1, title: 'Queue 1 task'));
      await db.insertTask(Task(queueId: 2, title: 'Queue 2 task'));

      final tasks = db.getTasksForQueue(1);

      expect(tasks.length, 1);
      expect(tasks.first.title, 'Queue 1 task');
    });

    test('does not include archived tasks by default', () async {
      await db.insertTask(Task(queueId: 1, title: 'Active task'));
      await db.insertTask(
        Task(queueId: 1, title: 'Archived task', isArchived: true),
      );

      final tasks = db.getTasksForQueue(1);

      expect(tasks.length, 1);
      expect(tasks.first.title, 'Active task');
    });

    test('includes archived tasks when requested', () async {
      await db.insertTask(Task(queueId: 1, title: 'Active task'));
      await db.insertTask(
        Task(queueId: 1, title: 'Archived task', isArchived: true),
      );

      final tasks = db.getTasksForQueue(1, includeArchived: true);

      expect(tasks.length, 2);
    });

    test('gets all tasks', () async {
      await db.insertTask(Task(queueId: 1, title: 'Task one'));
      await db.insertTask(Task(queueId: 2, title: 'Task two'));

      final tasks = db.getAllTasks();

      expect(tasks.length, 2);
    });

    test('updates a task', () async {
      final task = Task(queueId: 1, title: 'Original');
      await db.insertTask(task);

      task.title = 'Updated';
      await db.updateTask(task);

      final tasks = db.getTasksForQueue(1);

      expect(tasks.first.title, 'Updated');
    });

    test('deletes a task', () async {
      final task = Task(queueId: 1, title: 'Finish homework');
      final id = await db.insertTask(task);

      await db.deleteTask(id);

      expect(db.getTasksForQueue(1), isEmpty);
    });
  });

  group('DatabaseHelper cleanup', () {
    test('resetAllData clears queues, tasks, and settings', () async {
      final queueId = await db.insertQueue(Queue(name: 'School'));
      await db.insertTask(Task(queueId: queueId, title: 'Finish homework'));
      await db.setSetting('isDarkMode', true);

      await db.resetAllData();

      expect(db.getQueues(includeArchived: true), isEmpty);
      expect(db.getAllTasks(includeArchived: true), isEmpty);
      expect(db.getSetting('isDarkMode', defaultValue: false), false);
    });

    test('deleteArchived removes archived tasks and archived queues', () async {
      final activeQueueId = await db.insertQueue(Queue(name: 'Active queue'));
      final archivedQueueId = await db.insertQueue(
        Queue(name: 'Archived queue', isArchived: true),
      );

      await db.insertTask(Task(queueId: activeQueueId, title: 'Active task'));
      await db.insertTask(
        Task(
          queueId: activeQueueId,
          title: 'Archived task',
          isArchived: true,
        ),
      );
      await db.insertTask(
        Task(queueId: archivedQueueId, title: 'Task in archived queue'),
      );

      final removed = await db.deleteArchived();

      expect(removed, 3);

      final queues = db.getQueues(includeArchived: true);
      final tasks = db.getAllTasks(includeArchived: true);

      expect(queues.length, 1);
      expect(queues.first.name, 'Active queue');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Active task');
    });
  });

  group('DatabaseHelper backup and restore', () {
    test('exportData exports queues and tasks', () async {
      final queueId = await db.insertQueue(
        Queue(
          name: 'School',
          description: 'Class tasks',
          sortOrder: 2,
        ),
      );

      await db.insertTask(
        Task(
          queueId: queueId,
          title: 'Finish homework',
          dueDate: '2026-06-25',
          description: 'Complete assignment',
        ),
      );

      final data = db.exportData();

      expect(data['version'], 1);
      expect(data['queues'], isA<List>());
      expect(data['tasks'], isA<List>());
      expect((data['queues'] as List).length, 1);
      expect((data['tasks'] as List).length, 1);
    });

    test('importData replaces current data and restores queues and tasks', () async {
      final originalQueueId = await db.insertQueue(
        Queue(name: 'Original queue'),
      );
      await db.insertTask(
        Task(queueId: originalQueueId, title: 'Original task'),
      );

      final backup = {
        'version': 1,
        'queues': [
          {
            'key': 100,
            'name': 'Imported queue',
            'isArchived': false,
            'isComplete': false,
            'orderModeIndex': OrderMode.preferred.index,
            'description': 'Imported description',
            'sortOrder': 0,
            'hiddenFromHome': true,
          }
        ],
        'tasks': [
          {
            'queueKey': 100,
            'title': 'Imported task',
            'dueDate': '2026-07-01',
            'isComplete': true,
            'isArchived': false,
            'preferredOrder': 1,
            'description': 'Imported task description',
            'homeOrder': 2,
            'completedAt': 12345,
            'isFiled': true,
          }
        ],
      };

      await db.importData(backup);

      final queues = db.getQueues(includeArchived: true);
      final tasks = db.getAllTasks(includeArchived: true);

      expect(queues.length, 1);
      expect(queues.first.name, 'Imported queue');
      expect(queues.first.orderMode, OrderMode.preferred);
      expect(queues.first.hiddenFromHome, true);

      expect(tasks.length, 1);
      expect(tasks.first.title, 'Imported task');
      expect(tasks.first.queueId, queues.first.id);
      expect(tasks.first.dueDate, '2026-07-01');
      expect(tasks.first.isComplete, true);
      expect(tasks.first.isFiled, true);
    });
  });
}