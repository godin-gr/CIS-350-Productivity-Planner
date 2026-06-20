import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/queue_model.dart';

class QueueController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Queue> queues = [];

  void loadQueues({bool includeArchived = false}) {
    queues = _db.getQueues(includeArchived: includeArchived);
    notifyListeners();
  }

  Future<void> createQueue(String name,
      {OrderMode orderMode = OrderMode.dueDate, String? description}) async {
    final queue = Queue(
        name: name,
        orderModeIndex: orderMode.index,
        description: description,
        sortOrder: queues.length);
    await _db.insertQueue(queue);
    loadQueues();
  }

  Future<void> reorderQueues(List<Queue> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].sortOrder = i;
      await _db.updateQueue(reordered[i]);
    }
    queues = reordered;
    notifyListeners();
  }

  Future<void> editQueue(Queue queue,
      {required String name,
      String? description,
      required OrderMode orderMode}) async {
    queue.name = name;
    queue.description = description;
    queue.orderMode = orderMode;
    await _db.updateQueue(queue);
    loadQueues();
  }

  Future<void> toggleArchive(Queue queue) async {
    queue.isArchived = !queue.isArchived;
    await _db.updateQueue(queue);
    loadQueues();
  }

  // Archive every queue currently in the Completed section
  // (complete but not yet archived). Used by the Completed header button.
  Future<void> archiveCompletedQueues() async {
    final all = _db.getQueues(includeArchived: true);
    for (final q in all) {
      if (q.isComplete && !q.isArchived) {
        q.isArchived = true;
        await _db.updateQueue(q);
      }
    }
    loadQueues();
  }

  Future<void> toggleComplete(Queue queue) async {
    queue.isComplete = !queue.isComplete;
    await _db.updateQueue(queue);
    loadQueues();
  }

  Future<void> toggleHiddenFromHome(Queue queue) async {
    queue.hiddenFromHome = !queue.hiddenFromHome;
    await _db.updateQueue(queue);
    loadQueues();
  }

  Future<void> setOrderMode(Queue queue, OrderMode mode) async {
    queue.orderMode = mode;
    await _db.updateQueue(queue);
    loadQueues();
  }

  Future<void> deleteQueue(int id) async {
    await _db.deleteQueue(id);
    loadQueues();
  }
}