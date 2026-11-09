import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/widgets/task_tile.dart';

/// Список задач выбранного дня (из Drift) + пустое состояние.
class DayTaskList extends ConsumerStatefulWidget {
  const DayTaskList({super.key, required this.day});
  final DateTime day;

  @override
  ConsumerState<DayTaskList> createState() => _DayTaskListState();
}

class _DayTaskListState extends ConsumerState<DayTaskList> {
  /// Скрываем удалённые сразу, пока Drift-поток не обновился
  /// (иначе Dismissible ругается на оставшийся в дереве виджет).
  final Set<int> _removed = {};

  void _onDismissed(Task task) {
    setState(() => _removed.add(task.id));
    final actions = ref.read(tasksActionsProvider);
    actions.remove(task.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Задача удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => actions.add(task),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(tasksForDayProvider(dateOnly(widget.day)));
    final tasks = all.where((t) => !_removed.contains(t.id)).toList();
    final scheme = Theme.of(context).colorScheme;
    final actions = ref.read(tasksActionsProvider);

    if (tasks.isEmpty) return const _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete_outline, color: scheme.onError),
          ),
          onDismissed: (_) => _onDismissed(task),
          child: TaskTile(
            task: task,
            onTap: () => context.push('/task/${task.id}'),
            onToggle: () => actions.toggleDone(task),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.event_available, size: 48, color: scheme.secondary),
          ),
          const SizedBox(height: 16),
          Text('На этот день задач нет', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Нажмите «+», чтобы добавить',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
