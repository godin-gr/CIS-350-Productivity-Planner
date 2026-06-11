import 'package:hive_flutter/hive_flutter.dart';
import '../models/queue_model.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static const String _queueBox = 'queues';
  static const String _taskBox = 'tasks';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(QueueAdapter());
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Queue>(_queueBox);
    await Hive.openBox<Task>(_taskBox);
  }

  Box<Queue> get _queues => Hive.box<Queue>(_queueBox);
  Box<Task> get _tasks => Hive.box<Task>(_taskBox);

  // Queue operations
  Future<int> insertQueue(Queue queue) async {
    final id = await _queues.add(queue);
    queue.id = id;
    await queue.save();
    return id;
  }

  List<Queue> getQueues({bool includeArchived = false}) {
    return _queues.values
        .where((q) => includeArchived || !q.isArchived)
        .toList();
  }

  Future<void> updateQueue(Queue queue) async {
    await queue.save();
  }

  Future<void> deleteQueue(int hiveKey) async {
    final tasksToDelete = _tasks.values
        .where((t) => t.queueId == hiveKey)
        .toList();
    for (final task in tasksToDelete) {
      await task.delete();
    }
    await _queues.delete(hiveKey);
  }

  // Task operations
  Future<int> insertTask(Task task) async {
    final id = await _tasks.add(task);
    task.id = id;
    await task.save();
    return id;
  }

  List<Task> getTasksForQueue(int queueId, {bool includeArchived = false}) {
    return _tasks.values
        .where((t) =>
            t.queueId == queueId && (includeArchived || !t.isArchived))
        .toList();
  }

  List<Task> getAllTasks({bool includeArchived = false}) {
    return _tasks.values
        .where((t) => includeArchived || !t.isArchived)
        .toList();
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(int hiveKey) async {
    await _tasks.delete(hiveKey);
  }
}