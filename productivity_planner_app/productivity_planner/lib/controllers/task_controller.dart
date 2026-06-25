import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';

/// Controls all task-related app logic.
///
/// This class connects the UI to the local database for creating, loading,
/// updating, completing, filing, archiving, reordering, and deleting tasks.
class TaskController extends ChangeNotifier {
  /// Local database helper used to read and update task records.
  final DatabaseHelper _db = DatabaseHelper();

  /// List of tasks currently loaded for the selected queue.
  List<Task> tasks = [];

  /// Loads tasks for a specific queue and updates the UI.
  ///
  /// If [includeArchived] is true, archived tasks are included in the list.
  void loadTasksForQueue(int queueId, {bool includeArchived = false}) {
    tasks = _db.getTasksForQueue(queueId, includeArchived: includeArchived);
    notifyListeners();
  }

  /// Creates a new task in the given queue.
  ///
  /// New tasks are placed at the top of the preferred order list by shifting
  /// existing tasks down one position before inserting the new task.
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

  /// Saves a custom preferred task order for the Home page.
  ///
  /// This order can include tasks from multiple queues.
  Future<void> saveHomeOrder(List<Task> ordered) async {
    for (int i = 0; i < ordered.length; i++) {
      ordered[i].homeOrder = i;
      await _db.updateTask(ordered[i]);
    }
    notifyListeners();
  }

  /// Clears the custom Home page order.
  ///
  /// After this runs, the Home page returns to its default interleaved order.
  Future<void> resetHomeOrder() async {
    for (final t in _db.getAllTasks(includeArchived: true)) {
      if (t.homeOrder != -1) {
        t.homeOrder = -1;
        await _db.updateTask(t);
      }
    }
    notifyListeners();
  }

  /// Marks a task as complete or incomplete.
  ///
  /// Completing a task stores the completion time. Unchecking a task clears the
  /// completion time and moves it back into the active task list.
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

  /// Moves completed tasks in one queue into that queue's Completed section.
  ///
  /// Filed tasks leave the active task list but remain available in the
  /// Completed section.
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

  /// Moves every completed task across all queues into its Completed section.
  ///
  /// Used by the Home page's move completed tasks button.
  Future<void> fileCompletedAll() async {
    for (final t in _db.getAllTasks(includeArchived: true)) {
      if (t.isComplete && !t.isFiled) {
        t.isFiled = true;
        await _db.updateTask(t);
      }
    }
    notifyListeners();
  }

  /// Archives or unarchives a task.
  Future<void> toggleArchive(Task task) async {
    task.isArchived = !task.isArchived;
    await _db.updateTask(task);
    loadTasksForQueue(task.queueId);
  }

  /// Archives every filed task in a queue's Completed section.
  ///
  /// This only archives tasks that are already filed and not yet archived.
  Future<void> archiveFiled(int queueId) async {
    final qTasks = _db.getTasksForQueue(queueId);
    for (final t in qTasks) {
      if (t.isFiled && !t.isArchived) {
        t.isArchived = true;
        await _db.updateTask(t);
      }
    }
    loadTasksForQueue(queueId);
  }

  /// Saves a new preferred order for tasks inside a queue.
  ///
  /// Each task is assigned a new [preferredOrder] based on its position in the
  /// reordered list.
  Future<void> reorderTasks(List<Task> reordered) async {
    for (int i = 0; i < reordered.length; i++) {
      reordered[i].preferredOrder = i;
      await _db.updateTask(reordered[i]);
    }
    tasks = reordered;
    notifyListeners();
  }

  /// Deletes a task from the database and reloads its queue.
  Future<void> deleteTask(int hiveKey, int queueId) async {
    await _db.deleteTask(hiveKey);
    loadTasksForQueue(queueId);
  }

  /// Updates an existing task's editable fields.
  ///
  /// The original task object is mutated directly so Hive can save the updated
  /// object correctly.
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