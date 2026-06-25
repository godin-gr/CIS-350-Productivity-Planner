import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/queue_model.dart';

/// Controls all queue-related app logic.
///
/// This class connects the UI to the local database for creating, loading,
/// editing, reordering, archiving, completing, hiding, and deleting queues.
class QueueController extends ChangeNotifier {
  /// Local database helper used to read and update queue records.
  final DatabaseHelper _db = DatabaseHelper();

  /// List of queues currently loaded from the database.
  List<Queue> queues = [];

  /// Loads queues from the database and updates the UI.
  ///
  /// If [includeArchived] is true, archived queues are included in the list.
  void loadQueues({bool includeArchived = false}) {
    queues = _db.getQueues(includeArchived: includeArchived);
    notifyListeners();
  }

  /// Creates a new queue and saves it to the database.
  ///
  /// New queues default to due date ordering unless another [orderMode] is given.
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

  /// Saves a new queue order after the user rearranges queues.
  ///
  /// Each queue is assigned a new [sortOrder] based on its position in the
  /// reordered list.
  Future<void> reorderQueues(List<Queue> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].sortOrder = i;
      await _db.updateQueue(reordered[i]);
    }
    queues = reordered;
    notifyListeners();
  }

  /// Updates an existing queue's editable details.
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

  /// Archives or unarchives a queue.
  Future<void> toggleArchive(Queue queue) async {
    queue.isArchived = !queue.isArchived;
    await _db.updateQueue(queue);
    loadQueues();
  }

  /// Archives every completed queue that has not already been archived.
  ///
  /// Used by the Completed section's archive button.
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

  /// Marks a queue as complete or incomplete.
  Future<void> toggleComplete(Queue queue) async {
    queue.isComplete = !queue.isComplete;
    await _db.updateQueue(queue);
    loadQueues();
  }

  /// Shows or hides a queue from the Home page.
  Future<void> toggleHiddenFromHome(Queue queue) async {
    queue.hiddenFromHome = !queue.hiddenFromHome;
    await _db.updateQueue(queue);
    loadQueues();
  }

  /// Changes how tasks inside a queue are ordered.
  Future<void> setOrderMode(Queue queue, OrderMode mode) async {
    queue.orderMode = mode;
    await _db.updateQueue(queue);
    loadQueues();
  }

  /// Deletes a queue from the database.
  Future<void> deleteQueue(int id) async {
    await _db.deleteQueue(id);
    loadQueues();
  }
}