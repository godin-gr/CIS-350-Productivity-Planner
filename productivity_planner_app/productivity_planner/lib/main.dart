import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/queue_controller.dart';
import 'controllers/task_controller.dart';
import 'controllers/settings_controller.dart';
import 'database/database_helper.dart';
import '../pages/home_page.dart';
import 'pages/queues_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QueueController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Productivity Planner',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: settings.primaryColor,
                background: settings.backgroundColor,
              ),
              scaffoldBackgroundColor: settings.backgroundColor,
              textTheme: Typography.material2021().black.apply(
                    bodyColor: settings.textColor,
                    displayColor: settings.textColor,
                  ),
            ),
            home: const MyHomePage(title: 'Productivity Planner'),
          );
        },
      ),
    );
  }
}

enum AppPage { home, queues, settings }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AppPage currentPage = AppPage.home;

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (currentPage) {
      case AppPage.home:
        body = const HomePage();
        break;
      case AppPage.queues:
        body = const QueuesPage();
        break;
      case AppPage.settings:
        body = const SettingsPage();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: AppPage.values.indexOf(currentPage),
        onTap: (index) {
          setState(() {
            currentPage = AppPage.values[index];
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Queues'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}