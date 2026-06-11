import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
//import 'controllers/task_controller.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> _allTasks = [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadStats();
      context.read<QueueController>().loadQueues();
    }
  }

  Future<void> _loadStats() async {
    final tasks = await DatabaseHelper().getAllTasks();
    if (mounted) setState(() => _allTasks = tasks);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final total = _allTasks.where((t) => !t.isArchived).length;
    final dueToday = _allTasks
        .where((t) => !t.isArchived && !t.isComplete && t.dueDate == todayStr)
        .length;
    final completed = _allTasks.where((t) => t.isComplete).length;

    final upNext = _allTasks
        .where((t) => !t.isComplete && !t.isArchived)
        .toList()
      ..sort((a, b) => a.preferredOrder.compareTo(b.preferredOrder));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hello! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Here\'s your productivity summary.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(label: 'Total Tasks', value: '$total', icon: Icons.task),
              const SizedBox(width: 8),
              _StatCard(label: 'Due Today', value: '$dueToday', icon: Icons.today),
              const SizedBox(width: 8),
              _StatCard(label: 'Completed', value: '$completed', icon: Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Up Next',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          upNext.isEmpty
              ? const _UpNextCard(taskName: 'No tasks yet', queueName: '')
              : _UpNextCard(taskName: upNext.first.title, queueName: ''),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  final String taskName;
  final String queueName;

  const _UpNextCard({required this.taskName, required this.queueName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: Text(taskName),
        subtitle: queueName.isNotEmpty ? Text(queueName) : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}