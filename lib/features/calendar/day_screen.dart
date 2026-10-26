import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/widgets/task_tile.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = dateOnly(date);
    final tasks = ref.watch(tasksForDayProvider(day));
    final notifier = ref.read(tasksProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text(formatDayTitle(day, locale))),
      body: tasks.isEmpty
          ? const _EmptyState()
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
            onDismissed: (_) {
              notifier.removeTask(task.id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Задача удалена'),
                    action: SnackBarAction(
                      label: 'Отменить',
                      onPressed: () => notifier.addTask(task),
                    ),
                  ),
                );
            },
            child: TaskTile(
              task: task,
              onTap: () => context.push('/task/${task.id}'),
              onToggle: () => notifier.toggleDone(task.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/task/new?date=${dateToParam(day)}'),
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available,
              size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 12),
          Text('На этот день задач нет', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Нажмите «Задача», чтобы добавить',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
