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
    final task = Task(
      queueId: queueId,
      title: title,
      dueDate: dueDate,
      description: description,
      preferredOrder: tasks.length,
    );
    await _db.insertTask(task);
    loadTasksForQueue(queueId);
  }

  Future<void> toggleComplete(Task task) async {
    task.isComplete = !task.isComplete;
    await _db.updateTask(task);
    loadTasksForQueue(task.queueId);
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