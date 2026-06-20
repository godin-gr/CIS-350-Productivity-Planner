import 'package:hive_flutter/hive_flutter.dart';
import '../models/queue_model.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static const String _queueBox = 'queues';
  static const String _taskBox = 'tasks';
  static const String _settingsBox = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(QueueAdapter());
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Queue>(_queueBox);
    await Hive.openBox<Task>(_taskBox);
    await Hive.openBox(_settingsBox);
  }

  Box<Queue> get _queues => Hive.box<Queue>(_queueBox);
  Box<Task> get _tasks => Hive.box<Task>(_taskBox);
  Box get _settings => Hive.box(_settingsBox);

  // Settings operations (simple key/value).
  dynamic getSetting(String key, {dynamic defaultValue}) =>
      _settings.get(key, defaultValue: defaultValue);

  Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  // Queue operations
  Future<int> insertQueue(Queue queue) async {
    final id = await _queues.add(queue);
    queue.id = id;
    await queue.save();
    return id;
  }

  List<Queue> getQueues({bool includeArchived = false}) {
    final list = _queues.values
        .where((q) => includeArchived || !q.isArchived)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
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

  // Wipe everything: all queues, all tasks, and all settings. Used by the
  // "Reset all data" option. Irreversible.
  Future<void> resetAllData() async {
    await _queues.clear();
    await _tasks.clear();
    await _settings.clear();
  }

  // Permanently delete everything that's been archived: archived tasks, plus
  // archived queues and ALL of their tasks (archived or not). Returns the
  // number of items removed (queues + tasks) so the UI can report it.
  Future<int> deleteArchived() async {
    var removed = 0;

    // Archived queues: delete the queue and every task belonging to it.
    final archivedQueueKeys = _queues.toMap().entries
        .where((e) => e.value.isArchived)
        .map((e) => e.key)
        .toList();
    final archivedQueueIds =
        archivedQueueKeys.map((k) => k as int).toSet();

    for (final task in _tasks.values.toList()) {
      // Remove if the task itself is archived, or it belongs to an archived
      // queue that's about to be deleted.
      if (task.isArchived || archivedQueueIds.contains(task.queueId)) {
        await task.delete();
        removed++;
      }
    }
    for (final key in archivedQueueKeys) {
      await _queues.delete(key);
      removed++;
    }
    return removed;
  }

  // ---- Backup / restore ----------------------------------------------------

  // Serialize every queue and task into a plain map (JSON-encodable). Queues
  // are keyed by their current Hive key so tasks can be re-linked on import.
  Map<String, dynamic> exportData() {
    final queueList = _queues.toMap().entries.map((e) {
      final q = e.value;
      return {
        'key': e.key,
        'name': q.name,
        'isArchived': q.isArchived,
        'isComplete': q.isComplete,
        'orderModeIndex': q.orderModeIndex,
        'description': q.description,
        'sortOrder': q.sortOrder,
        'hiddenFromHome': q.hiddenFromHome,
      };
    }).toList();

    final taskList = _tasks.values.map((t) {
      return {
        'queueKey': t.queueId,
        'title': t.title,
        'dueDate': t.dueDate,
        'isComplete': t.isComplete,
        'isArchived': t.isArchived,
        'preferredOrder': t.preferredOrder,
        'description': t.description,
        'homeOrder': t.homeOrder,
        'completedAt': t.completedAt,
        'isFiled': t.isFiled,
      };
    }).toList();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'queues': queueList,
      'tasks': taskList,
    };
  }

  // Replace all current data with the contents of a previously-exported map.
  // Old queue keys are remapped to the new keys so tasks stay linked.
  Future<void> importData(Map<String, dynamic> data) async {
    await _queues.clear();
    await _tasks.clear();

    final keyRemap = <int, int>{};

    final queues = (data['queues'] as List?) ?? [];
    for (final raw in queues) {
      final q = raw as Map;
      final oldKey = q['key'] as int;
      final queue = Queue(
        name: q['name'] as String,
        isArchived: (q['isArchived'] as bool?) ?? false,
        isComplete: (q['isComplete'] as bool?) ?? false,
        orderModeIndex: (q['orderModeIndex'] as int?) ?? 0,
        description: q['description'] as String?,
        sortOrder: (q['sortOrder'] as int?) ?? 0,
        hiddenFromHome: (q['hiddenFromHome'] as bool?) ?? false,
      );
      final newKey = await _queues.add(queue);
      queue.id = newKey;
      await queue.save();
      keyRemap[oldKey] = newKey;
    }

    final tasks = (data['tasks'] as List?) ?? [];
    for (final raw in tasks) {
      final t = raw as Map;
      final oldQueueKey = t['queueKey'] as int;
      final newQueueKey = keyRemap[oldQueueKey];
      if (newQueueKey == null) continue; // orphaned task; skip
      final task = Task(
        queueId: newQueueKey,
        title: t['title'] as String,
        dueDate: t['dueDate'] as String?,
        isComplete: (t['isComplete'] as bool?) ?? false,
        isArchived: (t['isArchived'] as bool?) ?? false,
        preferredOrder: (t['preferredOrder'] as int?) ?? 0,
        description: t['description'] as String?,
        homeOrder: (t['homeOrder'] as int?) ?? -1,
        completedAt: (t['completedAt'] as int?) ?? 0,
        isFiled: (t['isFiled'] as bool?) ?? false,
      );
      final newKey = await _tasks.add(task);
      task.id = newKey;
      await task.save();
    }
  }
}