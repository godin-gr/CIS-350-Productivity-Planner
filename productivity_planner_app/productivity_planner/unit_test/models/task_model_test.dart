import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_planner/models/task_model.dart';

void main() {
  group('Task model', () {
    test('creates a task with default values', () {
      final task = Task(
        queueId: 1,
        title: 'Finish homework',
      );

      expect(task.id, null);
      expect(task.queueId, 1);
      expect(task.title, 'Finish homework');
      expect(task.dueDate, null);
      expect(task.isComplete, false);
      expect(task.isArchived, false);
      expect(task.preferredOrder, 0);
      expect(task.description, null);
      expect(task.homeOrder, -1);
      expect(task.completedAt, 0);
      expect(task.isFiled, false);
    });

    test('creates a task with custom values', () {
      final task = Task(
        id: 10,
        queueId: 2,
        title: 'Study for exam',
        dueDate: '2026-06-25',
        isComplete: true,
        isArchived: true,
        preferredOrder: 3,
        description: 'Review chapters 1-4',
        homeOrder: 5,
        completedAt: 123456789,
        isFiled: true,
      );

      expect(task.id, 10);
      expect(task.queueId, 2);
      expect(task.title, 'Study for exam');
      expect(task.dueDate, '2026-06-25');
      expect(task.isComplete, true);
      expect(task.isArchived, true);
      expect(task.preferredOrder, 3);
      expect(task.description, 'Review chapters 1-4');
      expect(task.homeOrder, 5);
      expect(task.completedAt, 123456789);
      expect(task.isFiled, true);
    });

    test('copyWith changes only the provided fields', () {
      final task = Task(
        id: 1,
        queueId: 4,
        title: 'Original task',
        dueDate: '2026-06-25',
        description: 'Original description',
        preferredOrder: 2,
      );

      final copy = task.copyWith(
        title: 'Updated task',
        isComplete: true,
        homeOrder: 0,
      );

      expect(copy.id, 1);
      expect(copy.queueId, 4);
      expect(copy.title, 'Updated task');
      expect(copy.dueDate, '2026-06-25');
      expect(copy.description, 'Original description');
      expect(copy.preferredOrder, 2);
      expect(copy.isComplete, true);
      expect(copy.isArchived, false);
      expect(copy.homeOrder, 0);
      expect(copy.completedAt, 0);
      expect(copy.isFiled, false);
    });
  });
}