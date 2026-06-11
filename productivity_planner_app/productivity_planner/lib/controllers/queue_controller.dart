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
    {OrderMode orderMode = OrderMode.preferred, String? description}) async {
  final queue = Queue(name: name, orderModeIndex: orderMode.index, description: description);
  await _db.insertQueue(queue);
  loadQueues();
}

  Future<void> toggleArchive(Queue queue) async {
    queue.isArchived = !queue.isArchived;
    await _db.updateQueue(queue);
    loadQueues();
  }

  Future<void> toggleComplete(Queue queue) async {
    queue.isComplete = !queue.isComplete;
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