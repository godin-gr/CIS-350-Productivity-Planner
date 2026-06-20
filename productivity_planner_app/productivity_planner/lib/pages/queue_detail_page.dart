import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/task_controller.dart';
import '../controllers/queue_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/queue_model.dart';
import '../models/task_model.dart';
import '../utils/date_format.dart';

class QueueDetailPage extends StatefulWidget {
  final Queue queue;

  const QueueDetailPage({super.key, required this.queue});

  @override
  State<QueueDetailPage> createState() => _QueueDetailPageState();
}

class _QueueDetailPageState extends State<QueueDetailPage> {
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskController>().loadTasksForQueue(
            widget.queue.id!,
            includeArchived: _showArchived,
          );
    });
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? 'Set due date (optional)'
                            : _formatDate(selectedDate!),
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () =>
                            setDialogState(() => selectedDate = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  context.read<TaskController>().createTask(
                        widget.queue.id!,
                        title,
                        dueDate:
                            selectedDate == null ? null : _formatDate(selectedDate!),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    DateTime? selectedDate = task.dueDate != null
        ? DateTime.tryParse(task.dueDate!)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Text(
                        selectedDate == null
                            ? 'Set due date (optional)'
                            : _formatDate(selectedDate!),
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () =>
                            setDialogState(() => selectedDate = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
  onPressed: () {
    final title = titleController.text.trim();
    if (title.isNotEmpty) {
      context.read<TaskController>().updateTask(
        task,
        title: title,
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        dueDate: selectedDate != null ? _formatDate(selectedDate!) : null,
        clearDueDate: selectedDate == null && task.dueDate != null,
      );
      Navigator.pop(context);
    }
  },
  child: const Text('Save'),
),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Active list = tasks not yet filed into the Completed section. In Preferred
  // mode, completed tasks stay in their dragged position (Remove Completed
  // Tasks files them). In Due date mode they sort by date like everything else.
  List<Task> _sortedTasks(List<Task> tasks) {
    final active = tasks.where((t) => !t.isFiled).toList();
    if (widget.queue.orderMode == OrderMode.dueDate) {
      active.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      active.sort((a, b) => a.preferredOrder.compareTo(b.preferredOrder));
    }
    return active;
  }

  // Tasks filed into the Completed section for this queue, newest first.
  List<Task> _filedTasks(List<Task> tasks) {
    final filed = tasks.where((t) => t.isFiled).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filed;
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final queueController = context.read<QueueController>();
    final settings = context.watch<SettingsController>();
    final tasks = _sortedTasks(taskController.tasks);
    final filed = _filedTasks(taskController.tasks);
    final queue = widget.queue;
    // Completed-but-unfiled tasks currently sitting in the active list; the
    // "Move Completed Tasks" button only appears when there are some.
    final hasCompletedToMove = tasks.any((t) => t.isComplete);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(queue.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(builder: (context) {
                      final primary = Theme.of(context).colorScheme.primary;
                      final onPrimary =
                          Theme.of(context).colorScheme.onPrimary;
                      return SegmentedButton<OrderMode>(
                        segments: const [
                          ButtonSegment(
                              value: OrderMode.dueDate,
                              label: Text('Due Next',
                                  style: TextStyle(fontSize: 12))),
                          ButtonSegment(
                              value: OrderMode.preferred,
                              label: Text('Preferred',
                                  style: TextStyle(fontSize: 12))),
                        ],
                        selected: {queue.orderMode},
                        onSelectionChanged: (s) {
                          queueController.setOrderMode(queue, s.first);
                          setState(() {});
                        },
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
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showArchived = !_showArchived);
                        taskController.loadTasksForQueue(queue.id!,
                            includeArchived: _showArchived);
                      },
                      icon: Icon(
                          _showArchived
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18),
                      label: Text(_showArchived
                          ? 'Hide archived'
                          : 'Show archived'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    TextButton.icon(
                      onPressed: hasCompletedToMove
                          ? () {
                              taskController.fileCompleted(queue.id!);
                            }
                          : null,
                      icon: const Icon(Icons.playlist_add_check, size: 18),
                      label: const Text('Move Completed Tasks'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: (tasks.isEmpty && filed.isEmpty)
                ? const Center(child: Text('No tasks yet. Tap + to add one.'))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      if (tasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No active tasks.'),
                        )
                      else if (queue.orderMode == OrderMode.preferred)
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            final reordered = List<Task>.from(tasks);
                            final item = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, item);
                            taskController.reorderTasks(reordered);
                          },
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _TaskTile(
                              key: ValueKey(task.id),
                              task: task,
                              onEdit: () => _showEditTaskDialog(task),
                            );
                          },
                        )
                      else
                        ...tasks.map((task) => _TaskTile(
                              key: ValueKey(task.id),
                              task: task,
                              onEdit: () => _showEditTaskDialog(task),
                            )),
                      if (filed.isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            children: [
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: settings.textColor.withOpacity(0.6),
                                ),
                              ),
                              const Spacer(),
                              if (filed.any((t) => !t.isArchived))
                                TextButton.icon(
                                  onPressed: () {
                                    taskController.archiveFiled(queue.id!);
                                  },
                                  icon: const Icon(Icons.archive_outlined,
                                      size: 16),
                                  label: const Text('Archive all',
                                      style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...filed.map((task) => _TaskTile(
                              key: ValueKey(task.id),
                              task: task,
                              onEdit: () => _showEditTaskDialog(task),
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;

  const _TaskTile({super.key, required this.task, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TaskController>();
    final textColor = context.watch<SettingsController>().textColor;

    return ListTile(
      leading: IconButton(
        icon: Icon(
          task.isComplete ? Icons.check_circle : Icons.circle_outlined,
          color: task.isComplete
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => controller.toggleComplete(task),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isComplete ? TextDecoration.lineThrough : null,
          color: task.isArchived ? textColor.withOpacity(0.4) : textColor,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty)
            Text(task.description!,
                style: TextStyle(
                    fontSize: 12, color: textColor.withOpacity(0.6))),
          if (task.dueDate != null)
            Text(dueLabel(task.dueDate!),
                style: TextStyle(
                    fontSize: 12, color: textColor.withOpacity(0.7))),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'archive':
              controller.toggleArchive(task);
              break;
            case 'delete':
              _confirmDelete(
                context,
                title: 'Delete task?',
                message:
                    'Are you sure you want to delete "${task.title}"? This can\'t be undone.',
                onConfirm: () =>
                    controller.deleteTask(task.key as int, task.queueId),
              );
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'archive',
            child: Text(task.isArchived ? 'Unarchive' : 'Archive'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
// Shared confirmation dialog for destructive actions.
Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) onConfirm();
}