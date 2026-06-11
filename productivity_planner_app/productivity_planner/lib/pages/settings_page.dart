import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

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
          const SizedBox(height: 12),
          _ColorPickerRow(
            label: 'Background color',
            selected: settings.backgroundColor,
            colors: SettingsController.backgroundOptions,
            onPicked: (c) => settings.setBackgroundColor(c),
          ),
          const SizedBox(height: 12),
          _ColorPickerRow(
            label: 'Text color',
            selected: settings.textColor,
            colors: SettingsController.textOptions,
            onPicked: (c) => settings.setTextColor(c),
          ),
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
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
                    color: isSelected ? Colors.black : Colors.transparent,
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