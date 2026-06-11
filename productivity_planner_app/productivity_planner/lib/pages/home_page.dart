import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
import '../controllers/settings_controller.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/queue_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> _allTasks = [];
  bool _loaded = false;
  bool _preferredMode = false; // false = Due Next, true = Preferred (interleaved)

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
    final tasks = DatabaseHelper().getAllTasks();
    if (mounted) setState(() => _allTasks = tasks);
  }

  // Round-robin across queues: each queue's incomplete tasks in preferred
  // order, then take the 1st of every queue, then the 2nd of every queue, etc.
  List<Task> _interleaveByQueue(List<Queue> queues) {
    final perQueue = <List<Task>>[];
    for (final q in queues) {
      final qTasks = _allTasks
          .where((t) =>
              t.queueId == q.id && !t.isComplete && !t.isArchived)
          .toList()
        ..sort((a, b) => a.preferredOrder.compareTo(b.preferredOrder));
      if (qTasks.isNotEmpty) perQueue.add(qTasks);
    }
    final result = <Task>[];
    var index = 0;
    bool added = true;
    while (added) {
      added = false;
      for (final list in perQueue) {
        if (index < list.length) {
          result.add(list[index]);
          added = true;
        }
      }
      index++;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.watch<SettingsController>().textColor;
    final queues = context.watch<QueueController>().queues;
    final queueNames = {for (final q in queues) q.id: q.name};
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final total = _allTasks.where((t) => !t.isArchived).length;
    final dueToday = _allTasks
        .where((t) => !t.isArchived && !t.isComplete && t.dueDate == todayStr)
        .length;
    final pastDue = _allTasks
        .where((t) =>
            !t.isArchived &&
            !t.isComplete &&
            t.dueDate != null &&
            t.dueDate!.compareTo(todayStr) < 0)
        .length;
    final completed = _allTasks.where((t) => t.isComplete).length;

    // Due Next: all incomplete, non-archived tasks with a due date, soonest
    // first; tasks without due dates go at the bottom sorted by preferredOrder.
    final withDue = _allTasks
        .where((t) => !t.isComplete && !t.isArchived && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final withoutDue = _allTasks
        .where((t) => !t.isComplete && !t.isArchived && t.dueDate == null)
        .toList()
      ..sort((a, b) => a.preferredOrder.compareTo(b.preferredOrder));
    final dueNext = [...withDue, ...withoutDue];

    // Preferred (interleaved): take each queue's tasks in preferred order, then
    // round-robin across queues — T1, T3, T5, T2, T4, T6...
    final combinedPreferred = _interleaveByQueue(queues);

    final displayList = _preferredMode ? combinedPreferred : dueNext;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hello! 👋',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 4),
          Text('Here\'s your productivity summary.',
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6))),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(label: 'Total Tasks', value: '$total', icon: Icons.task),
              const SizedBox(width: 8),
              _StatCard(label: 'Due Today', value: '$dueToday', icon: Icons.today),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Past Due',
                  value: '$pastDue',
                  icon: Icons.warning_amber_rounded,
                  highlight: pastDue > 0),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Combined Queue',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text('Due Next',
                          style: TextStyle(fontSize: 12))),
                  ButtonSegment(
                      value: true,
                      label: Text('Preferred',
                          style: TextStyle(fontSize: 12))),
                ],
                selected: {_preferredMode},
                onSelectionChanged: (s) =>
                    setState(() => _preferredMode = s.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (displayList.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No pending tasks.',
                    style: TextStyle(color: textColor.withOpacity(0.6))),
              ),
            )
          else
            ...displayList.map((task) => _DueNextCard(
                  task: task,
                  queueName: queueNames[task.queueId],
                )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Expanded(
      child: Card(
        color: primary,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: highlight ? Colors.red : onPrimary),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: highlight ? Colors.red : onPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: onPrimary.withOpacity(0.85)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueNextCard extends StatelessWidget {
  final Task task;
  final String? queueName;
  const _DueNextCard({required this.task, this.queueName});

  @override
  Widget build(BuildContext context) {
    final textColor = context.watch<SettingsController>().textColor;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isPastDue =
        task.dueDate != null && task.dueDate!.compareTo(todayStr) < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor),
            ),
            if (queueName != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.list,
                      size: 12, color: textColor.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    queueName!,
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: TextStyle(
                    fontSize: 12, color: textColor.withOpacity(0.6)),
              ),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due: ${task.dueDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: isPastDue ? Colors.red : textColor.withOpacity(0.7),
                  fontWeight:
                      isPastDue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}