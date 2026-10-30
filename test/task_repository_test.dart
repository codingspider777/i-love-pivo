import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salamanca/data/daos/tasks_dao.dart';
import 'package:salamanca/data/repositories/task_repository.dart';
import 'package:salamanca/data/database.dart';

// 1. Создаем фейковый DAO (чтобы не трогать настоящую БД)
class MockTasksDao extends Mock implements TasksDao {}

void main() {
  setUpAll(() {
    // Регистрируем заготовку для TasksCompanion
    registerFallbackValue(TasksCompanion.insert(
      title: 'fallback',
      dueTime: DateTime(2000),
    ));
  });

  
  // Объявляем переменные
  late TaskRepository repository;
  late MockTasksDao mockDao;

  // Эта функция выполняется ПЕРЕД каждым тестом
  setUp(() {
    mockDao = MockTasksDao();
    repository = TaskRepository(mockDao);
  });

  // Группируем тесты по названию
  group('TaskRepository Tests', () {

    test('getAllTasks должен возвращать список задач', () async {
      // Arrange (Подготовка): Говорим фейковому DAO, что он должен вернуть
      final fakeTasks = [
        Task(
          id: 1, 
          title: 'Тестовая задача', 
          dueTime: DateTime.now(), 
          isCompleted: false,
        ),
      ];
      
      // Настраиваем мок: "Когда вызовут getAllTasks, верни fakeTasks"
      when(() => mockDao.getAllTasks()).thenAnswer((_) async => fakeTasks);

      // Act (Действие): Вызываем метод нашего репозитория
      final result = await repository.getAllTasks();

      // Assert (Проверка): Убеждаемся, что результат правильный
      expect(result.length, 1);
      expect(result.first.title, 'Тестовая задача');
      
      // Проверяем, что метод в DAO действительно вызывался 1 раз
      verify(() => mockDao.getAllTasks()).called(1);
    });

    test('addTask должен передавать задачу в DAO', () async {
      // Arrange
      final newTask = TasksCompanion.insert(
        title: 'Новая задача',
        dueTime: DateTime.now(),
      );
      
      // Когда вызовут insertTask, верни 42 (ID новой задачи)
      when(() => mockDao.insertTask(any())).thenAnswer((_) async => 42);

      // Act
      final resultId = await repository.addTask(newTask);

      // Assert
      expect(resultId, 42);
      verify(() => mockDao.insertTask(newTask)).called(1);
    });

    test('deleteTask должен возвращать количество удаленных строк', () async {
      // Arrange
      when(() => mockDao.deleteTask(1)).thenAnswer((_) async => 1);

      // Act
      final deletedCount = await repository.deleteTask(1);

      // Assert
      expect(deletedCount, 1);
      verify(() => mockDao.deleteTask(1)).called(1);
    });
  });
}