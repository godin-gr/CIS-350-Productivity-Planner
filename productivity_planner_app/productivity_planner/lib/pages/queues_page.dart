import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/queue_model.dart';
import 'queue_detail_page.dart';

class QueuesPage extends StatefulWidget {
  const QueuesPage({super.key});

  @override
  State<QueuesPage> createState() => _QueuesPageState();
}

class _QueuesPageState extends State<QueuesPage> {
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueController>().loadQueues(includeArchived: _showArchived);
    });
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    OrderMode selectedMode = OrderMode.preferred;

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
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Default order',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
                Row(
                  children: [
                    Radio<OrderMode>(
                      value: OrderMode.preferred,
                      groupValue: selectedMode,
                      onChanged: (v) =>
                          setDialogState(() => selectedMode = v!),
                    ),
                    const Text('Preferred'),
                    const SizedBox(width: 16),
                    Radio<OrderMode>(
                      value: OrderMode.dueDate,
                      groupValue: selectedMode,
                      onChanged: (v) =>
                          setDialogState(() => selectedMode = v!),
                    ),
                    const Text('Due date'),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<QueueController>().createQueue(
                        name,
                        orderMode: selectedMode,
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

  void _showEditDialog(Queue queue) {
    final nameController = TextEditingController(text: queue.name);
    final descController =
        TextEditingController(text: queue.description ?? '');
    OrderMode selectedMode = queue.orderMode;

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
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Default order',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ),
                Row(
                  children: [
                    Radio<OrderMode>(
                      value: OrderMode.preferred,
                      groupValue: selectedMode,
                      onChanged: (v) =>
                          setDialogState(() => selectedMode = v!),
                    ),
                    const Text('Preferred'),
                    const SizedBox(width: 16),
                    Radio<OrderMode>(
                      value: OrderMode.dueDate,
                      groupValue: selectedMode,
                      onChanged: (v) =>
                          setDialogState(() => selectedMode = v!),
                    ),
                    const Text('Due date'),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<QueueController>().editQueue(
                        queue,
                        name: name,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        orderMode: selectedMode,
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
                    child: Text('No queues yet. Tap + to create one.'))
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
                          child: Text('Completed',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withOpacity(0.6))),
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

class _QueueTile extends StatelessWidget {
  final Queue queue;
  final int index;
  final VoidCallback onTap;
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
          Text(
            '${queue.orderMode == OrderMode.preferred ? 'Preferred' : 'Due date'} order'
            '${queue.isArchived ? ' · Archived' : ''}'
            '${queue.isComplete ? ' · Complete' : ''}',
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