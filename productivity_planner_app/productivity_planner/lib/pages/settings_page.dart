import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../controllers/queue_controller.dart';
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
            'Export your tasks and queues to a file you can move to another device, or import a file to restore them.',
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
                  label: const Text('Export'),
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
        ],
      ),
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