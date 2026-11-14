import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salamanca/data/daos/tasks_dao.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/repositories/task_repository.dart';

// Фейковый DAO (чтобы не трогать настоящую БД)
class MockTasksDao extends Mock implements TasksDao {}

void main() {
  setUpAll(() {
    registerFallbackValue(TasksCompanion.insert(
      title: 'fallback',
      dueTime: DateTime(2000),
    ));
  });

  late TaskRepository repository;
  late MockTasksDao mockDao;

  setUp(() {
    mockDao = MockTasksDao();
    repository = TaskRepository(mockDao);
  });

  group('TaskRepository Tests', () {
    test('getAllTasks должен возвращать список задач', () async {
      final fakeTasks = [
        TaskRow(
          id: 1,
          categoryId: 1,
          title: 'Тестовая задача',
          dueTime: DateTime.now(),
          isCompleted: false,
          priority: 1,
          hasTime: false,
        ),
      ];

      when(() => mockDao.getAllTasks()).thenAnswer((_) async => fakeTasks);

      final result = await repository.getAllTasks();

      expect(result.length, 1);
      expect(result.first.title, 'Тестовая задача');
      verify(() => mockDao.getAllTasks()).called(1);
    });

    test('addTask должен передавать задачу в DAO', () async {
      final newTask = TasksCompanion.insert(
        title: 'Новая задача',
        dueTime: DateTime.now(),
      );

      when(() => mockDao.insertTask(any())).thenAnswer((_) async => 42);

      final resultId = await repository.addTask(newTask);

      expect(resultId, 42);
      verify(() => mockDao.insertTask(newTask)).called(1);
    });

    test('deleteTask должен возвращать количество удаленных строк', () async {
      when(() => mockDao.deleteTask(1)).thenAnswer((_) async => 1);

      final deletedCount = await repository.deleteTask(1);

      expect(deletedCount, 1);
      verify(() => mockDao.deleteTask(1)).called(1);
    });
  });
}
