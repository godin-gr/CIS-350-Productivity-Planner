import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:productivity_planner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App navigation integration test', () {
    testWidgets('opens app and navigates between main pages', (tester) async {
      app.main();

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Productivity Planner'), findsOneWidget);
      expect(find.text('Hello! 👋'), findsOneWidget);
      expect(find.text('Combined Queue'), findsOneWidget);

      await tester.tap(find.text('Queues'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('My Queues'), findsOneWidget);
      expect(find.text('Show archived queues'), findsOneWidget);

      await tester.tap(find.text('Settings').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Font size'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Hello! 👋'), findsOneWidget);
      expect(find.text('Combined Queue'), findsOneWidget);
    });
  });
}