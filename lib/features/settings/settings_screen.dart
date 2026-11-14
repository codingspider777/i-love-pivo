import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/settings/providers/settings_providers.dart';
import 'package:salamanca/features/tasks/widgets/task_tile.dart';

const List<Color> kPalette = [
  Color(0xFF4F46E5),
  Color(0xFF0EA5E9),
  Color(0xFF14B8A6),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF64748B),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cats = ref.watch(categoriesProvider);
    final custom = ref.watch(priorityColorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _Section('Категории'),
          Card(
            child: Column(
              children: [
                for (final c in cats)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.color.withValues(alpha: 0.15),
                      child: Icon(c.icon, color: c.color),
                    ),
                    title: Text(c.name),
                    subtitle: const Text('Название, цвет и иконка'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => _CategoryEditor(category: c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Section('Цвета приоритетов'),
          Card(
            child: Column(
              children: [
                for (final p in TaskPriority.values)
                  ListTile(
                    leading: Icon(Icons.circle,
                        color: priorityColor(scheme, p, custom)),
                    title: Text(p.label),
                    subtitle: Text(
                        custom.containsKey(p) ? 'Свой цвет' : 'По умолчанию'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _PriorityPicker(priority: p),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.selected, required this.onPick});
  final Color? selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in kPalette)
          GestureDetector(
            onTap: () => onPick(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: selected?.toARGB32() == c.toARGB32()
                    ? Border.all(color: onSurface, width: 3)
                    : null,
              ),
              child: selected?.toARGB32() == c.toARGB32()
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.category});
  final TaskCategory category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.category.name);
  late Color _color = widget.category.color;
  late String _icon = widget.category.iconKey;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    await ref.read(settingsActionsProvider).updateCategory(
          widget.category.id,
          name: name,
          color: _color,
          iconKey: _icon,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Название'),
          ),
          const SizedBox(height: 12),
          Text('Цвет', style: labelStyle),
          const SizedBox(height: 8),
          _ColorPalette(
              selected: _color, onPick: (c) => setState(() => _color = c)),
          const SizedBox(height: 20),
          Text('Иконка', style: labelStyle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final e in kCategoryIcons.entries)
                GestureDetector(
                  onTap: () => setState(() => _icon = e.key),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: e.key == _icon
                          ? _color.withValues(alpha: 0.2)
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: e.key == _icon
                          ? Border.all(color: _color, width: 2)
                          : null,
                    ),
                    child: Icon(e.value,
                        color:
                            e.key == _icon ? _color : scheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}

class _PriorityPicker extends ConsumerWidget {
  const _PriorityPicker({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final custom = ref.watch(priorityColorsProvider);
    final actions = ref.read(settingsActionsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Приоритет: ${priority.label}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _ColorPalette(
            selected: priorityColor(scheme, priority, custom),
            onPick: (c) => actions.setPriorityColor(priority, c),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => actions.resetPriorityColor(priority),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Сбросить цвет'),
          ),
        ],
      ),
    );
  }
}
