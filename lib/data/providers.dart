import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/data/daos/tasks_dao.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/repositories/task_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tasksDaoProvider =
    Provider<TasksDao>((ref) => ref.watch(databaseProvider).tasksDao);

final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(tasksDaoProvider)));
