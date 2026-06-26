import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:productivity_planner/controllers/queue_controller.dart';
import 'package:productivity_planner/controllers/settings_controller.dart';
import 'package:productivity_planner/controllers/task_controller.dart';
import 'package:productivity_planner/models/queue_model.dart';
import 'package:productivity_planner/models/task_model.dart';
import 'package:productivity_planner/pages/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('home_page_test_');
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
  });

  tearDown(() async {
    await Hive.close();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HomePage', () {
    testWidgets('renders the home page summary sections', (tester) async {
      await _pumpHomePage(tester);

      expect(find.text('Hello! 👋'), findsOneWidget);
      expect(find.text('Here\'s your productivity summary.'), findsOneWidget);
      expect(find.text('Tasks To Complete'), findsOneWidget);
      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('Past Due'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Combined Queue'), findsOneWidget);
      expect(find.text('Due Next'), findsOneWidget);
      expect(find.text('Preferred'), findsOneWidget);
    });

    testWidgets('shows empty message when there are no tasks', (tester) async {
      await _pumpHomePage(tester);

      expect(
        find.text('Create a queue and add tasks to get started.'),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpHomePage(WidgetTester tester) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QueueController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: HomePage(),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}