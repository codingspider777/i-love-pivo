import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/settings/providers/settings_providers.dart';

/// [custom] — пользовательские цвета из настроек (могут быть пустыми).
Color priorityColor(ColorScheme scheme, TaskPriority priority,
    [Map<TaskPriority, Color>? custom]) {
  final own = custom?[priority];
  if (own != null) return own;
  return switch (priority) {
    TaskPriority.low => scheme.secondary,
    TaskPriority.medium => scheme.primary,
    TaskPriority.high => scheme.error,
  };
}

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.isDone;
    final time = task.time;
    final cat = categoryOf(ref.watch(categoriesProvider), task.categoryId);
    final custom = ref.watch(priorityColorsProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Цветная полоска категории
            Container(width: 5, color: cat.color),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(value: done, onChanged: (_) => onToggle()),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration:
                                  done ? TextDecoration.lineThrough : null,
                                  color: done ? scheme.onSurfaceVariant : null,
                                ),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (time != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.schedule,
                                            size: 16,
                                            color: scheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Text(time.format(context),
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  _Pill(
                                    color: priorityColor(
                                        scheme, task.priority, custom),
                                    label: task.priority.label,
                                  ),
                                  _Pill(
                                    color: cat.color,
                                    label: cat.name,
                                    icon: cat.icon,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
