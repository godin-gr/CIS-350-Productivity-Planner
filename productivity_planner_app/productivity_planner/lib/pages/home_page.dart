import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/settings_controller.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import '../models/queue_model.dart';
import '../utils/date_format.dart';

/// Home page showing the user's productivity summary.
///
/// Displays task counts, due today/past due totals, a combined task list, and
/// completed tasks that have been moved into the Completed section.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State for [HomePage].
///
/// Loads task data, tracks the selected combined queue mode, and builds the
/// filtered task lists shown on the Home page.
class _HomePageState extends State<HomePage> {
  /// All non-archived tasks currently loaded from the database.
  List<Task> _allTasks = [];

  /// Prevents the initial data load from running more than once.
  bool _loaded = false;

  /// Whether the Combined Queue is shown in Preferred mode.
  ///
  /// false = Due Next, true = Preferred/interleaved.
  bool _preferredMode = false; // false = Due Next, true = Preferred (interleaved)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _preferredMode = DatabaseHelper()
          .getSetting('homePreferredMode', defaultValue: false) as bool;
      _loadStats();
      // Defer the queue reload until after this build frame: loadQueues()
      // notifies listeners, and calling it during build (this widget watches
      // the controller) throws "setState() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<QueueController>().loadQueues();
      });
    }
  }

  /// Updates and saves the selected Combined Queue display mode.
  void _setPreferredMode(bool v) {
    setState(() => _preferredMode = v);
    DatabaseHelper().setSetting('homePreferredMode', v);
  }

  /// Reloads task data used by the Home page stats and lists.
  Future<void> _loadStats() async {
    final tasks = DatabaseHelper().getAllTasks();
    if (mounted) setState(() => _allTasks = tasks);
  }

  /// Shows a confirmation dialog before resetting the Preferred order.
  ///
  /// Returns true if the user confirms the reset.
  Future<bool> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset order?'),
        content: const Text(
            'Are you sure you want to reset the Preferred order? Your custom arrangement will be cleared and the default order restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // The default interleave: round-robin across queues by preferred order.
  // Completed-but-unfiled tasks stay in their natural preferred position (they
  // are NOT pulled to the bottom — Remove Completed Tasks handles that). Filed
  // tasks are excluded; they live in the Completed section.

  /// Creates the default Preferred task order.
  ///
  /// Tasks are pulled round-robin from each active queue based on each task's
  /// preferred order.
  List<Task> _interleaveByQueue(List<Queue> queues) {
    final perQueue = <List<Task>>[];
    for (final q in queues) {
      final qTasks = _allTasks
          .where((t) =>
              t.queueId == q.id && !t.isArchived && !t.isFiled)
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

  // The list shown in Preferred mode. If the user has set a custom home order
  // (any task has homeOrder >= 0), respect it; otherwise fall back to the
  // default interleave. Filed tasks are excluded.

  /// Builds the task list used when the Home page is in Preferred mode.
  ///
  /// If the user has manually reordered tasks on the Home page, that saved
  /// order is used. Otherwise, tasks are interleaved by queue.
  List<Task> _combinedPreferred(List<Queue> queues) {
    final activeIds = queues.map((q) => q.id).toSet();
    final tasks = _allTasks
        .where((t) =>
            !t.isArchived &&
            !t.isFiled &&
            activeIds.contains(t.queueId))
        .toList();
    final hasCustom = tasks.any((t) => t.homeOrder >= 0);
    if (!hasCustom) {
      return _interleaveByQueue(queues);
    }
    // Tasks with a custom order sort by it; brand-new tasks (homeOrder < 0)
    // float to the top.
    tasks.sort((a, b) {
      final ao = a.homeOrder < 0 ? -1 : a.homeOrder;
      final bo = b.homeOrder < 0 ? -1 : b.homeOrder;
      return ao.compareTo(bo);
    });
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.watch<SettingsController>().textColor;
    final allQueues = context.watch<QueueController>().queues;
    // Active queues drive the home screen: not archived and not marked complete.
    final queues = allQueues
        .where((q) => !q.isArchived && !q.isComplete && !q.hiddenFromHome)
        .toList();
    final activeQueueIds = queues.map((q) => q.id).toSet();
    final queueNames = {for (final q in queues) q.id: q.name};
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Tasks that "count" as live work: not archived, and belonging to an
    // active queue (not archived, not complete).
    bool counts(Task t) => !t.isArchived && activeQueueIds.contains(t.queueId);

    final toComplete =
        _allTasks.where((t) => counts(t) && !t.isComplete).length;
    final dueToday = _allTasks
        .where((t) => counts(t) && !t.isComplete && t.dueDate == todayStr)
        .length;
    final pastDue = _allTasks
        .where((t) =>
            counts(t) &&
            !t.isComplete &&
            t.dueDate != null &&
            t.dueDate!.compareTo(todayStr) < 0)
        .length;
    // Completed = every non-archived task that's marked complete. This is the
    // exact set shown in the Completed section below, so the number and the
    // visible list always match and can be counted by hand.
    final completedTasks = _allTasks
        .where((t) => !t.isArchived && t.isComplete)
        .toList();
    final completed = completedTasks.length;

    // Due Next: all countable, unfiled tasks in one stable order — those with
    // a due date first (soonest first), then those without (by preferred
    // order). Completion does NOT change a task's position: a checked task
    // stays exactly where it was until the user files it with the button.
    final dueNext = _allTasks
        .where((t) => counts(t) && !t.isFiled)
        .toList()
      ..sort((a, b) {
        final aHas = a.dueDate != null;
        final bHas = b.dueDate != null;
        if (aHas && bHas) return a.dueDate!.compareTo(b.dueDate!);
        if (aHas) return -1; // tasks with a due date come first
        if (bHas) return 1;
        return a.preferredOrder.compareTo(b.preferredOrder);
      });

    // Preferred (interleaved by default, or custom home order if the user
    // has dragged tasks around).
    final combinedPreferred = _combinedPreferred(queues);

    final displayList = _preferredMode ? combinedPreferred : dueNext;

    // Completed section: tasks the user has moved here via the button (filed),
    // newest-completed first. Note this is a SUBSET of the Completed count —
    // the count also includes completed-but-unfiled tasks still sitting inline.
    final filedList = _allTasks
        .where((t) => counts(t) && t.isFiled)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    // Any completed-but-unfiled task currently inline can be moved down.
    final hasCompleted = displayList.any((t) => t.isComplete && !t.isFiled);

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
              _StatCard(
                  label: 'Tasks To Complete',
                  value: '$toComplete',
                  icon: Icons.task),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Due Today',
                  value: '$dueToday',
                  icon: Icons.today,
                  highlightColor: dueToday > 0 ? Colors.yellow.shade700 : null),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Past Due',
                  value: '$pastDue',
                  icon: Icons.warning_amber_rounded,
                  highlightColor:
                      pastDue > 0 ? Colors.red : null),
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
              Builder(builder: (context) {
                final primary = Theme.of(context).colorScheme.primary;
                final onPrimary = Theme.of(context).colorScheme.onPrimary;
                return SegmentedButton<bool>(
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
                  onSelectionChanged: (s) => _setPreferredMode(s.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? primary
                          : Colors.transparent;
                    }),
                    foregroundColor:
                        WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? onPrimary
                          : primary;
                    }),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_preferredMode)
                TextButton.icon(
                  onPressed: displayList.isEmpty
                      ? null
                      : () async {
                          final ok = await _confirmReset(context);
                          if (!ok) return;
                          await context
                              .read<TaskController>()
                              .resetHomeOrder();
                          await _loadStats();
                        },
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset order'),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: hasCompleted
                    ? () async {
                        await context
                            .read<TaskController>()
                            .fileCompletedAll();
                        await _loadStats();
                      }
                    : null,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Move Completed Tasks'),
              ),
            ],
          ),
          if (displayList.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Create a queue and add tasks to get started.',
                    style: TextStyle(color: textColor.withOpacity(0.6))),
              ),
            )
          else if (_preferredMode)
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: true,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final reordered = List<Task>.from(displayList);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                await context
                    .read<TaskController>()
                    .saveHomeOrder(reordered);
                await _loadStats();
              },
              children: [
                for (final task in displayList)
                  _DueNextCard(
                    key: ValueKey(task.id),
                    task: task,
                    queueName: queueNames[task.queueId],
                    onToggleComplete: () async {
                      await context
                          .read<TaskController>()
                          .toggleComplete(task);
                      await _loadStats();
                    },
                  ),
              ],
            )
          else
            ...displayList.map((task) => _DueNextCard(
                  task: task,
                  queueName: queueNames[task.queueId],
                  onToggleComplete: () async {
                    await context
                        .read<TaskController>()
                        .toggleComplete(task);
                    await _loadStats();
                  },
                )),
          if (filedList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Completed',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.6))),
            const SizedBox(height: 4),
            ...filedList.map((task) => _DueNextCard(
                  task: task,
                  queueName: queueNames[task.queueId],
                  onToggleComplete: () async {
                    await context
                        .read<TaskController>()
                        .toggleComplete(task);
                    await _loadStats();
                  },
                )),
          ],
        ],
      ),
    );
  }
}

/// Small summary card used for Home page statistics.
class _StatCard extends StatelessWidget {
  /// Label shown under the stat value.
  final String label;

  /// Main stat value shown on the card.
  final String value;

  /// Icon shown above the stat value.
  final IconData icon;

  /// Optional color used to highlight important stats.
  final Color? highlightColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final bg = settings.backgroundColor;
    final textColor = settings.textColor;
    final accent = highlightColor ?? textColor;
    return Expanded(
      child: Card(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: textColor.withOpacity(0.15)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: accent),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accent)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: textColor.withOpacity(0.7)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Task card used in the Home page combined queue.
///
/// Shows completion state, task title, optional queue name, description, and due
/// date status.
class _DueNextCard extends StatelessWidget {
  /// Task displayed by this card.
  final Task task;

  /// Optional name of the queue this task belongs to.
  final String? queueName;

  /// Callback used when the task completion icon is tapped.
  final Future<void> Function()? onToggleComplete;

  const _DueNextCard(
      {super.key, required this.task, this.queueName, this.onToggleComplete});

  @override
  Widget build(BuildContext context) {
    final textColor = context.watch<SettingsController>().textColor;
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final isPastDue = !task.isComplete &&
        task.dueDate != null &&
        task.dueDate!.compareTo(todayStr) < 0;
    final isDueToday = !task.isComplete && task.dueDate == todayStr;
    final Color dueColor = isPastDue
        ? Colors.red
        : isDueToday
            ? Colors.yellow.shade700
            : textColor.withOpacity(0.7);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(
                task.isComplete
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: task.isComplete
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed:
                  onToggleComplete == null ? null : () => onToggleComplete!(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          decoration: task.isComplete
                              ? TextDecoration.lineThrough
                              : null),
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
                                fontSize: 12,
                                color: textColor.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ],
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
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
                        dueLabel(task.dueDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: dueColor,
                          fontWeight: (isPastDue || isDueToday)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}