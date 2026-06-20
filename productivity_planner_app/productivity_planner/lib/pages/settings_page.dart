import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../controllers/queue_controller.dart';
import '../database/database_helper.dart';
import '../database/backup_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: settings.textColor)),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Dark mode',
                style: TextStyle(color: settings.textColor)),
            value: settings.isDarkMode,
            onChanged: (v) => settings.setDarkMode(v),
          ),
          const SizedBox(height: 16),
          Text('Font size',
              style: TextStyle(fontSize: 14, color: settings.textColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppFontSize.values.map((size) {
              final selected = settings.fontSize == size;
              return ChoiceChip(
                label: Text(_labelFor(size)),
                selected: selected,
                onSelected: (_) => settings.setFontSize(size),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Theme',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: settings.textColor)),
          const SizedBox(height: 12),
          _ColorPickerRow(
            label: 'Primary color',
            selected: settings.primaryColor,
            colors: SettingsController.primaryOptions,
            onPicked: (c) => settings.setPrimaryColor(c),
          ),
          const SizedBox(height: 24),
          Text('Backup & Sync',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: settings.textColor)),
          const SizedBox(height: 4),
          Text(
            'Share a backup of your tasks and queues to another device or app, or save it straight to your Downloads folder. Import a saved backup to restore them (this replaces all current tasks and queues).',
            style: TextStyle(
                fontSize: 12, color: settings.textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportData(context),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _importData(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Import'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _saveToDownloads(context),
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Save to Downloads'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Danger Zone',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400)),
          const SizedBox(height: 4),
          Text(
            'Clean up or wipe your data. These actions cannot be undone.',
            style: TextStyle(
                fontSize: 12, color: settings.textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _deleteArchived(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Delete archived items'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _resetAllData(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Reset all data'),
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation before permanently deleting archived tasks and queues.
  Future<void> _deleteArchived(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete archived items?'),
        content: const Text(
            'This will permanently delete every archived task, and every archived queue along with all of its tasks. Items that are not archived are kept. This cannot be undone.'),
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
    if (confirmed != true) return;
    if (!context.mounted) return;

    final removed = await DatabaseHelper().deleteArchived();
    if (!context.mounted) return;
    context.read<QueueController>().loadQueues();
    messenger.showSnackBar(
      SnackBar(
        content: Text(removed == 0
            ? 'No archived items to delete.'
            : 'Deleted $removed archived item${removed == 1 ? '' : 's'}.'),
      ),
    );
  }

  // Two-step confirmation before wiping everything.
  Future<void> _resetAllData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
            'This will permanently delete ALL of your queues, tasks, and settings. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true) return;
    if (!context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
            'Last chance. Everything will be erased and you will start fresh with an empty app. There is no way to recover this data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (second != true) return;
    if (!context.mounted) return;

    await DatabaseHelper().resetAllData();
    if (!context.mounted) return;
    context.read<SettingsController>().reload();
    context.read<QueueController>().loadQueues();
    messenger.showSnackBar(
      const SnackBar(content: Text('All data has been reset.')),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupService().exportToShare();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _saveToDownloads(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await BackupService().saveToDownloads();
      messenger.showSnackBar(
        SnackBar(content: Text('Saved to: $path')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _importData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import data?'),
        content: const Text(
            'Importing will REPLACE all current tasks and queues with the contents of the file. This can\'t be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final didImport = await BackupService().importFromFile();
      if (!didImport) return;
      // Refresh the in-memory controllers so the UI reflects imported data.
      if (context.mounted) {
        context.read<QueueController>().loadQueues();
        messenger.showSnackBar(
          const SnackBar(content: Text('Import complete.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  String _labelFor(AppFontSize size) {
    switch (size) {
      case AppFontSize.verySmall:
        return 'Very small';
      case AppFontSize.small:
        return 'Small';
      case AppFontSize.medium:
        return 'Medium';
      case AppFontSize.large:
        return 'Large';
    }
  }
}

class _ColorPickerRow extends StatelessWidget {
  final String label;
  final Color selected;
  final List<Color> colors;
  final ValueChanged<Color> onPicked;

  const _ColorPickerRow({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.watch<SettingsController>().textColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: textColor)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = selected.value == color.value;
            return GestureDetector(
              onTap: () => onPicked(color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? textColor : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check,
                        size: 18,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}