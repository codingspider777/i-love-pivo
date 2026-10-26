import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';

/// Временное хранилище задач в памяти.
/// Когда будет готова БД (Drift), заменить реализацию на репозиторий.
class TasksNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() => [];

  void addTask(Task task) => state = [...state, task];

  void updateTask(Task task) =>
      state = [for (final t in state) t.id == task.id ? task : t];

  void removeTask(String id) =>
      state = state.where((t) => t.id != id).toList();

  void toggleDone(String id) => state = [
    for (final t in state)
      t.id == id ? t.copyWith(isDone: !t.isDone) : t,
  ];
}

final tasksProvider =
NotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

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
