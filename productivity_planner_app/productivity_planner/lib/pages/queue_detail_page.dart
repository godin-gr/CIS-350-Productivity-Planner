import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/task_controller.dart';
import '../controllers/queue_controller.dart';
import '../models/queue_model.dart';
import '../models/task_model.dart';

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
                          firstDate: DateTime.now(),
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
                  final updated = task.copyWith(
                    title: title,
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    dueDate: selectedDate == null
                        ? null
                        : _formatDate(selectedDate!),
                  );
                  context.read<TaskController>().updateTask(updated);
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

  List<Task> _sortedTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    if (widget.queue.orderMode == OrderMode.dueDate) {
      sorted.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      sorted.sort((a, b) => a.preferredOrder.compareTo(b.preferredOrder));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final queueController = context.read<QueueController>();
    final tasks = _sortedTasks(taskController.tasks);
    final queue = widget.queue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(queue.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'complete':
                  queueController.toggleComplete(queue);
                  break;
                case 'archive':
                  queueController.toggleArchive(queue);
                  Navigator.pop(context);
                  break;
                case 'preferred':
                  queueController.setOrderMode(queue, OrderMode.preferred);
                  break;
                case 'dueDate':
                  queueController.setOrderMode(queue, OrderMode.dueDate);
                  break;
                case 'showArchived':
                  setState(() => _showArchived = !_showArchived);
                  taskController.loadTasksForQueue(queue.id!,
                      includeArchived: _showArchived);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'complete',
                child: Text(
                    queue.isComplete ? 'Mark incomplete' : 'Mark complete'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(
                    queue.isArchived ? 'Unarchive queue' : 'Archive queue'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'preferred',
                child: Row(children: [
                  Icon(
                      queue.orderMode == OrderMode.preferred
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18),
                  const SizedBox(width: 8),
                  const Text('Preferred order'),
                ]),
              ),
              PopupMenuItem(
                value: 'dueDate',
                child: Row(children: [
                  Icon(
                      queue.orderMode == OrderMode.dueDate
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18),
                  const SizedBox(width: 8),
                  const Text('Due date order'),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'showArchived',
                child: Text(_showArchived
                    ? 'Hide archived tasks'
                    : 'Show archived tasks'),
              ),
            ],
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks yet. Tap + to add one.'))
          : queue.orderMode == OrderMode.preferred
              ? ReorderableListView.builder(
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
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskTile(
                      key: ValueKey(task.id),
                      task: task,
                      onEdit: () => _showEditTaskDialog(task),
                    );
                  },
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
          color: task.isArchived ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty)
            Text(task.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (task.dueDate != null)
            Text('Due: ${task.dueDate}',
                style: const TextStyle(fontSize: 12)),
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
              controller.deleteTask(task.key as int, task.queueId);
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