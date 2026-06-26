import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:productivity_planner/database/backup_service.dart';
import 'package:productivity_planner/database/database_helper.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory downloadsDir;
  late DatabaseHelper db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_service_test_');
    downloadsDir =
        await Directory.systemTemp.createTemp('backup_downloads_test_');

    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QueueAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskAdapter());
    }

    await Hive.openBox<Queue>('queues');
    await Hive.openBox<Task>('tasks');
    await Hive.openBox('settings');

    PathProviderPlatform.instance = _FakePathProviderPlatform(downloadsDir.path);

    // FilePicker.platform is not automatically initialized in unit tests.
    FilePicker.platform = _FakeFilePicker(null);

    db = DatabaseHelper();
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    if (await downloadsDir.exists()) {
      await downloadsDir.delete(recursive: true);
    }
  });

  group('BackupService', () {
    test('saveToDownloads writes a backup JSON file', () async {
      final queueId = await db.insertQueue(Queue(name: 'School'));
      await db.insertTask(Task(queueId: queueId, title: 'Finish homework'));

      final path = await BackupService().saveToDownloads();
      final file = File(path);

      expect(await file.exists(), true);
      expect(path, contains('productivity_planner_backup_'));
      expect(path, endsWith('.json'));

      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      expect(data['version'], 1);
      expect((data['queues'] as List).length, 1);
      expect((data['tasks'] as List).length, 1);
      expect((data['queues'] as List).first['name'], 'School');
      expect((data['tasks'] as List).first['title'], 'Finish homework');
    });

    test('importFromFile returns false when user cancels picker', () async {
      FilePicker.platform = _FakeFilePicker(null);

      final result = await BackupService().importFromFile();

      expect(result, false);
    });

    test('importFromFile imports backup data from picked bytes', () async {
      final backup = {
        'version': 1,
        'queues': [
          {
            'key': 1,
            'name': 'Imported queue',
            'isArchived': false,
            'isComplete': false,
            'orderModeIndex': OrderMode.dueDate.index,
            'description': 'Imported description',
            'sortOrder': 0,
            'hiddenFromHome': false,
          }
        ],
        'tasks': [
          {
            'queueKey': 1,
            'title': 'Imported task',
            'dueDate': '2026-06-25',
            'isComplete': false,
            'isArchived': false,
            'preferredOrder': 0,
            'description': 'Imported task description',
            'homeOrder': -1,
            'completedAt': 0,
            'isFiled': false,
          }
        ],
      };

      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(backup)));

      FilePicker.platform = _FakeFilePicker(
        FilePickerResult([
          PlatformFile(
            name: 'backup.json',
            size: bytes.length,
            bytes: bytes,
          ),
        ]),
      );

      final result = await BackupService().importFromFile();

      final queues = db.getQueues(includeArchived: true);
      final tasks = db.getAllTasks(includeArchived: true);

      expect(result, true);
      expect(queues.length, 1);
      expect(queues.first.name, 'Imported queue');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Imported task');
      expect(tasks.first.queueId, queues.first.id);
    });
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;

  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getDownloadsPath() async {
    return path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    return path;
  }
}

class _FakeFilePicker extends FilePicker {
  final FilePickerResult? result;

  _FakeFilePicker(this.result);

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}