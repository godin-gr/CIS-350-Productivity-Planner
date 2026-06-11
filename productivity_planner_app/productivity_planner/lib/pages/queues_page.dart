import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/queue_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final queueController = context.watch<QueueController>();
    final queues = queueController.queues;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Queues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showArchived = !_showArchived);
                    context.read<QueueController>().loadQueues(includeArchived: !_showArchived);
                  },
                  icon: Icon(_showArchived ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showArchived ? 'Hide archived' : 'Show archived'),
                ),
              ],
            ),
          ),
          Expanded(
            child: queues.isEmpty
                ? const Center(child: Text('No queues yet. Tap + to create one.'))
                : ListView.builder(
                    itemCount: queues.length,
                    itemBuilder: (context, index) {
                      final queue = queues[index];
                      return _QueueTile(
                        queue: queue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QueueDetailPage(queue: queue),
                          ),
                        ).then((_) => context.read<QueueController>().loadQueues(includeArchived: _showArchived)),
                      );
                    },
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
  final VoidCallback onTap;

  const _QueueTile({required this.queue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<QueueController>();

    return ListTile(
      leading: IconButton(
        icon: Icon(
          queue.isComplete ? Icons.check_circle : Icons.circle_outlined,
          color: queue.isComplete
              ? Colors.green
              : Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => controller.toggleComplete(queue),
      ),
      title: Text(
        queue.name,
        style: TextStyle(
          decoration: queue.isComplete ? TextDecoration.lineThrough : null,
          color: queue.isArchived ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (queue.description != null && queue.description!.isNotEmpty)
            Text(queue.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            '${queue.orderMode == OrderMode.preferred ? 'Preferred' : 'Due date'} order'
            '${queue.isArchived ? ' · Archived' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'archive':
              controller.toggleArchive(queue);
              break;
            case 'delete':
              controller.deleteQueue(queue.key as int);
              break;
          }
        },
        itemBuilder: (_) => [
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
      onTap: onTap,
    );
  }
}