import 'package:drift/drift.dart';
import '../database.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // --- CREATE ---
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  // --- READ ---
  Future<List<TaskRow>> getAllTasks() => select(tasks).get();

  Future<TaskRow?> getTaskById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  // --- UPDATE ---
  Future<bool> updateTask(TaskRow task) => update(tasks).replace(task);

  Future<int> updateTaskById(int id, TasksCompanion data) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(data);

  Future<int> setCompleted(int id, bool value) =>
      updateTaskById(id, TasksCompanion(isCompleted: Value(value)));

  // --- DELETE ---
  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // --- READ (реактивный поток для UI) ---
  Stream<List<TaskRow>> watchAllTasks() => select(tasks).watch();
}
