import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Text(
            'Hello! 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Here\'s your productivity summary.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Stat Cards
          Row(
            children: [
              _StatCard(label: 'Total Tasks', value: '0', icon: Icons.task),
              const SizedBox(width: 8),
              _StatCard(label: 'Due Today', value: '0', icon: Icons.today),
              const SizedBox(width: 8),
              _StatCard(label: 'Completed', value: '0', icon: Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),

          // Up Next
          const Text(
            'Up Next',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const _UpNextCard(taskName: 'No tasks yet', queueName: ''),
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
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
        leading: Icon(Icons.circle_outlined, color: Theme.of(context).colorScheme.primary),
        title: Text(taskName),
        subtitle: queueName.isNotEmpty ? Text(queueName) : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}