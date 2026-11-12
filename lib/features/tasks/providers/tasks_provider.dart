import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/data/providers.dart';
import 'package:salamanca/data/repositories/task_repository.dart';

/// Реактивный поток задач из Drift.
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchAllTasks()
      .map((rows) => [for (final r in rows) Task.fromRow(r)]);
});

/// Синхронный список для UI (пока поток грузится, список пуст).
final tasksProvider = Provider<List<Task>>(
  (ref) => ref.watch(tasksStreamProvider).value ?? const [],
);

class TasksActions {
  TasksActions(this._repo);
  final TaskRepository _repo;

  Future<void> add(Task t) => _repo.addTask(t.toCompanion());
  Future<void> update(Task t) => _repo.updateTaskById(t.id, t.toCompanion());
  Future<void> remove(int id) => _repo.deleteTask(id);
  Future<void> toggleDone(Task t) => _repo.setCompleted(t.id, !t.isDone);
}

final tasksActionsProvider = Provider<TasksActions>(
  (ref) => TasksActions(ref.watch(taskRepositoryProvider)),
);

int _minutes(Task t) {
  final time = t.time;
  // Задачи без времени идут в конец дня.
  return time == null ? 24 * 60 : time.hour * 60 + time.minute;
}

/// Задачи конкретного дня: сначала по времени, затем по приоритету.
List<Task> tasksOnDay(List<Task> tasks, DateTime day) {
  final d = dateOnly(day);
  final result = tasks.where((t) => dateOnly(t.date) == d).toList();
  result.sort((a, b) {
    final byTime = _minutes(a).compareTo(_minutes(b));
    if (byTime != 0) return byTime;
    return b.priority.index.compareTo(a.priority.index);
  });
  return result;
}

/// Передавать день в виде dateOnly(...).
final tasksForDayProvider = Provider.family<List<Task>, DateTime>(
  (ref, day) => tasksOnDay(ref.watch(tasksProvider), day),
);
