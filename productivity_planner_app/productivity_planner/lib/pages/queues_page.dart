import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/queue_model.dart';
import 'queue_detail_page.dart';

/// Page that displays and manages the user's queues.
class QueuesPage extends StatefulWidget {
  const QueuesPage({super.key});

  @override
  State<QueuesPage> createState() => _QueuesPageState();
}

/// State for [QueuesPage].
///
/// Handles loading queues, showing archived queues, creating queues, editing
/// queues, and building the active and completed queue sections.
class _QueuesPageState extends State<QueuesPage> {
  /// Whether archived queues should be included in the list.
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueController>().loadQueues(includeArchived: _showArchived);
    });
  }

  /// Opens the dialog used to create a new queue.
  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Queue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Queue name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<QueueController>().createQueue(
                        name,
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

  /// Opens the dialog used to edit an existing queue.
  void _showEditDialog(Queue queue) {
    final nameController = TextEditingController(text: queue.name);
    final descController =
        TextEditingController(text: queue.description ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Queue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Queue name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)'),
                  maxLines: 2,
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<QueueController>().editQueue(
                        queue,
                        name: name,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        orderMode: queue.orderMode,
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

  @override
  Widget build(BuildContext context) {
    final queueController = context.watch<QueueController>();
    final allLoaded = queueController.queues;
    final activeQueues = allLoaded.where((q) => !q.isComplete).toList();
    final completedQueues = allLoaded.where((q) => q.isComplete).toList();
    final textColor = context.watch<SettingsController>().textColor;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Queues',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showArchived = !_showArchived);
                    context
                        .read<QueueController>()
                        .loadQueues(includeArchived: _showArchived);
                  },
                  icon: Icon(_showArchived
                      ? Icons.visibility_off
                      : Icons.visibility),
                  label:
                      Text(_showArchived ? 'Hide archived queues' : 'Show archived queues'),
                ),
              ],
            ),
          ),
          Expanded(
            child: (activeQueues.isEmpty && completedQueues.isEmpty)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Create a queue and add tasks to get started.\nTap + to make your first queue.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: activeQueues.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          final reordered = List<Queue>.from(activeQueues);
                          final item = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, item);
                          // Append completed queues so their saved order is
                          // preserved after the active ones.
                          context
                              .read<QueueController>()
                              .reorderQueues([...reordered, ...completedQueues]);
                        },
                        itemBuilder: (context, index) {
                          final queue = activeQueues[index];
                          return _QueueTile(
                            key: ValueKey(queue.id),
                            index: index,
                            queue: queue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QueueDetailPage(queue: queue),
                              ),
                            ).then((_) => context
                                .read<QueueController>()
                                .loadQueues(includeArchived: _showArchived)),
                            onEdit: () => _showEditDialog(queue),
                          );
                        },
                      ),
                      if (completedQueues.isNotEmpty) ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            children: [
                              Text('Completed',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withOpacity(0.6))),
                              const Spacer(),
                              if (completedQueues.any((q) => !q.isArchived))
                                TextButton.icon(
                                  onPressed: () {
                                    context
                                        .read<QueueController>()
                                        .archiveCompletedQueues();
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
                        ...completedQueues.map((queue) => _QueueTile(
                              key: ValueKey(queue.id),
                              index: -1,
                              queue: queue,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QueueDetailPage(queue: queue),
                                ),
                              ).then((_) => context
                                  .read<QueueController>()
                                  .loadQueues(includeArchived: _showArchived)),
                              onEdit: () => _showEditDialog(queue),
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// List tile used to display a queue.
class _QueueTile extends StatelessWidget {
  /// Queue displayed by this tile.
  final Queue queue;

  /// Position of the queue in the reorderable active queue list.
  ///
  /// A value below 0 means the queue should not show a drag handle.
  final int index;

  /// Callback used when the queue tile is tapped.
  final VoidCallback onTap;

  /// Callback used when the user selects the edit action.
  final VoidCallback onEdit;

  const _QueueTile(
      {super.key,
      required this.queue,
      required this.index,
      required this.onTap,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<QueueController>();
    final textColor = context.watch<SettingsController>().textColor;

    return ListTile(
      title: Text(
        queue.name,
        style: TextStyle(
          decoration: queue.isComplete ? TextDecoration.lineThrough : null,
          color: queue.isArchived ? textColor.withOpacity(0.4) : textColor,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (queue.description != null && queue.description!.isNotEmpty)
            Text(queue.description!,
                style: TextStyle(
                    fontSize: 12, color: textColor.withOpacity(0.6))),
          if (queue.isArchived || queue.isComplete || queue.hiddenFromHome)
            Text(
              [
                if (queue.isArchived) 'Archived',
                if (queue.isComplete) 'Complete',
                if (queue.hiddenFromHome) 'Hidden from home',
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7)),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'home':
                  controller.toggleHiddenFromHome(queue);
                  break;
                case 'complete':
                  controller.toggleComplete(queue);
                  break;
                case 'archive':
                  controller.toggleArchive(queue);
                  break;
                case 'delete':
                  _confirmDeleteQueue(
                    context,
                    queueName: queue.name,
                    onConfirm: () => controller.deleteQueue(queue.key as int),
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'home',
                child: Text(queue.hiddenFromHome
                    ? 'Show on home'
                    : 'Hide from home'),
              ),
              PopupMenuItem(
                value: 'complete',
                child: Text(
                    queue.isComplete ? 'Mark incomplete' : 'Mark complete'),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Text(queue.isArchived ? 'Unarchive' : 'Archive'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          if (index >= 0)
            ReorderableDragStartListener(
              index: index,
              child:
                  Icon(Icons.drag_handle, color: textColor.withOpacity(0.5)),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// Confirmation dialog before deleting a queue (and all its tasks).

/// Shows a confirmation dialog before deleting a queue and its tasks.
Future<void> _confirmDeleteQueue(
  BuildContext context, {
  required String queueName,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete queue?'),
      content: Text(
          'Are you sure you want to delete "$queueName" and all of its tasks? This can\'t be undone.'),
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