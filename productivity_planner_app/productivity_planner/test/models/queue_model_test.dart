import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_planner/models/queue_model.dart';

void main() {
  group('Queue model', () {
    test('creates a queue with default values', () {
      final queue = Queue(name: 'School');

      expect(queue.id, null);
      expect(queue.name, 'School');
      expect(queue.isArchived, false);
      expect(queue.isComplete, false);
      expect(queue.orderModeIndex, 1);
      expect(queue.orderMode, OrderMode.dueDate);
      expect(queue.description, null);
      expect(queue.sortOrder, 0);
      expect(queue.hiddenFromHome, false);
    });

    test('creates a queue with custom values', () {
      final queue = Queue(
        id: 5,
        name: 'Work',
        isArchived: true,
        isComplete: true,
        orderModeIndex: OrderMode.preferred.index,
        description: 'Tasks for work',
        sortOrder: 2,
        hiddenFromHome: true,
      );

      expect(queue.id, 5);
      expect(queue.name, 'Work');
      expect(queue.isArchived, true);
      expect(queue.isComplete, true);
      expect(queue.orderMode, OrderMode.preferred);
      expect(queue.description, 'Tasks for work');
      expect(queue.sortOrder, 2);
      expect(queue.hiddenFromHome, true);
    });

    test('orderMode setter updates orderModeIndex', () {
      final queue = Queue(name: 'Personal');

      queue.orderMode = OrderMode.preferred;

      expect(queue.orderMode, OrderMode.preferred);
      expect(queue.orderModeIndex, OrderMode.preferred.index);
    });

    test('copyWith changes only the provided fields', () {
      final queue = Queue(
        id: 1,
        name: 'Original',
        description: 'Original description',
        sortOrder: 3,
      );

      final copy = queue.copyWith(
        name: 'Updated',
        isComplete: true,
      );

      expect(copy.id, 1);
      expect(copy.name, 'Updated');
      expect(copy.description, 'Original description');
      expect(copy.sortOrder, 3);
      expect(copy.isComplete, true);
      expect(copy.isArchived, false);
      expect(copy.hiddenFromHome, false);
    });
  });
}