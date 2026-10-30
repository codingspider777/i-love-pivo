import 'package:drift/drift.dart';
import '../database.dart'; // Импорт твоей базы данных

// Привязываем DAO к таблице Tasks
part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db); // Конструктор, обязательный для Drift

  // --- CREATE ---
  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  // --- READ (все задачи) ---
  Future<List<Task>> getAllTasks() {
    return select(tasks).get();
  }

  // --- READ (одна задача по ID) ---
  Future<Task?> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // --- UPDATE ---
  Future<bool> updateTask(Task task) {
    return update(tasks).replace(task);
  }

  // --- DELETE ---
  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // --- READ (реактивный поток для UI) ---
  // Это позволит экрану автоматически обновляться при изменении данных
  Stream<List<Task>> watchAllTasks() {
    return select(tasks).watch();
  }
}