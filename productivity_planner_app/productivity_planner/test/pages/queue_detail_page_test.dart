import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:productivity_planner/database/database_helper.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';
import 'package:productivity_planner/pages/queue_detail_page.dart';

void main() {
  late Directory tempDir;
  late DatabaseHelper db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('queue_detail_page_test_');
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

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('QueueDetailPage', () {
    test('can be created with a saved queue', () async {
      final queueId = await db.insertQueue(
        Queue(
          name: 'School',
          description: 'Class tasks',
        ),
      );

      final queue = db.getQueues(includeArchived: true).first;
      final page = QueueDetailPage(queue: queue);

      expect(page.queue.id, queueId);
      expect(page.queue.name, 'School');
      expect(page.queue.description, 'Class tasks');
      expect(page.queue.isArchived, false);
      expect(page.queue.isComplete, false);
    });

    test('keeps queue display and ordering settings', () {
      final queue = Queue(
        id: 3,
        name: 'Work',
        description: 'Work tasks',
        isArchived: true,
        isComplete: true,
        orderModeIndex: OrderMode.preferred.index,
        hiddenFromHome: true,
      );

      final page = QueueDetailPage(queue: queue);

      expect(page.queue.id, 3);
      expect(page.queue.name, 'Work');
      expect(page.queue.description, 'Work tasks');
      expect(page.queue.isArchived, true);
      expect(page.queue.isComplete, true);
      expect(page.queue.orderMode, OrderMode.preferred);
      expect(page.queue.hiddenFromHome, true);
    });

    test('uses its queue id to connect to the correct tasks', () async {
      final schoolId = await db.insertQueue(Queue(name: 'School'));
      final workId = await db.insertQueue(Queue(name: 'Work'));

      await db.insertTask(
        Task(
          queueId: schoolId,
          title: 'Finish homework',
        ),
      );

      await db.insertTask(
        Task(
          queueId: workId,
          title: 'Send email',
        ),
      );

      final schoolQueue = db
          .getQueues(includeArchived: true)
          .firstWhere((queue) => queue.id == schoolId);

      final page = QueueDetailPage(queue: schoolQueue);
      final pageTasks = db.getTasksForQueue(page.queue.id!);

      expect(page.queue.name, 'School');
      expect(pageTasks.length, 1);
      expect(pageTasks.first.title, 'Finish homework');
      expect(pageTasks.first.queueId, schoolId);
    });
  });
}