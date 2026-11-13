import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/core/utils/date_utils.dart';

class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key, required this.taskId});
  final String taskId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(tasksStreamProvider);
    final task = stream.value
        ?.where((t) => t.id.toString() == taskId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          if (task != null)
            IconButton(
              tooltip: 'Редактировать',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/task/$taskId/edit'),
            ),
        ],
      ),
      body: stream.isLoading && task == null
          ? const Center(child: CircularProgressIndicator())
          : stream.hasError
          ? const Center(child: Text('Не удалось загрузить задачу'))
          : task == null
          ? const Center(child: Text('Задача не найдена'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SelectableText(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (task.description.isNotEmpty)
                  SelectableText(task.description),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(formatLongDate(task.date, Localizations.localeOf(context).toString())),
                  subtitle: Text(task.time?.format(context) ?? 'Без времени'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text('Приоритет: ${task.priority.label}'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Выполнено'),
                  value: task.isDone,
                  onChanged: (_) =>
                      ref.read(tasksActionsProvider).toggleDone(task),
                ),
                if (task.buildingId != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Показать корпус на карте'),
                    onPressed: () => context.push(
                      '/map?building=${Uri.encodeComponent(task.buildingId!)}',
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push('/task/$taskId/edit'),
                  child: const Text('Редактировать'),
                ),
              ],
            ),
    );
  }
}
