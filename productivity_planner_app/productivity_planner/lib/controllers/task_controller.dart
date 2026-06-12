import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';

class TaskController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Task> tasks = [];

  void loadTasksForQueue(int queueId, {bool includeArchived = false}) {
    tasks = _db.getTasksForQueue(queueId, includeArchived: includeArchived);
    notifyListeners();
  }

  Future<void> createTask(int queueId, String title,
      {String? dueDate, String? description}) async {
    // New tasks go to the top of the queue's preferred order: shift everyone
    // else down by one, then insert at 0.
    final existing = _db.getTasksForQueue(queueId);
    for (final t in existing) {
      t.preferredOrder = t.preferredOrder + 1;
      await _db.updateTask(t);
    }
    final task = Task(
      queueId: queueId,
      title: title,
      dueDate: dueDate,
      description: description,
      preferredOrder: 0,
    );
    await _db.insertTask(task);
    loadTasksForQueue(queueId);
  }

  // Persist a custom Home-screen preferred order across all queues.
  Future<void> saveHomeOrder(List<Task> ordered) async {
    for (int i = 0; i < ordered.length; i++) {
      ordered[i].homeOrder = i;
      await _db.updateTask(ordered[i]);
    }
    notifyListeners();
  }

  // Clear the custom Home order so the screen reverts to the interleaved
  // default.
  Future<void> resetHomeOrder() async {
    for (final t in _db.getAllTasks(includeArchived: true)) {
      if (t.homeOrder != -1) {
        t.homeOrder = -1;
        await _db.updateTask(t);
      }
    }
    notifyListeners();
  }

  Future<void> toggleComplete(Task task) async {
    task.isComplete = !task.isComplete;
    if (task.isComplete) {
      task.completedAt = DateTime.now().millisecondsSinceEpoch;
    } else {
      // Un-checking a task brings it back to the active list.
      task.completedAt = 0;
      task.isFiled = false;
    }
    await _db.updateTask(task);
    loadTasksForQueue(task.queueId);
  }

  // File away every currently-completed task in a queue: they leave the active
  // list and move into that queue's Completed section.
  Future<void> fileCompleted(int queueId) async {
    final qTasks = _db.getTasksForQueue(queueId);
    for (final t in qTasks) {
      if (t.isComplete && !t.isFiled) {
        t.isFiled = true;
        await _db.updateTask(t);
      }
    }
    loadTasksForQueue(queueId);
  }

  // File away every completed task across all queues (used by the Home button).
  Future<void> fileCompletedAll() async {
    for (final t in _db.getAllTasks(includeArchived: true)) {
      if (t.isComplete && !t.isFiled) {
        t.isFiled = true;
        await _db.updateTask(t);
      }
    }
    notifyListeners();
  }

  Future<void> toggleArchive(Task task) async {
    task.isArchived = !task.isArchived;
    await _db.updateTask(task);
    loadTasksForQueue(task.queueId);
  }

  Future<void> reorderTasks(List<Task> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].preferredOrder = i;
      await _db.updateTask(reordered[i]);
    }
    tasks = reordered;
    notifyListeners();
  }

  Future<void> deleteTask(int hiveKey, int queueId) async {
    await _db.deleteTask(hiveKey);
    loadTasksForQueue(queueId);
  }

  // Mutates the original object directly so Hive's save() works correctly
  Future<void> updateTask(Task original,
      {String? title, String? description, String? dueDate, bool clearDueDate = false}) async {
    if (title != null) original.title = title;
    if (description != null) original.description = description;
    if (clearDueDate) {
      original.dueDate = null;
    } else if (dueDate != null) {
      original.dueDate = dueDate;
    }
    await _db.updateTask(original);
    loadTasksForQueue(original.queueId);
  }
}