import '../daos/tasks_dao.dart';
import '../database.dart'; // Для типов Task и TasksCompanion

class TaskRepository {
  final TasksDao _tasksDao;

  // Внедряем зависимость через конструктор
  TaskRepository(this._tasksDao);

  // 1. Создать задачу
  Future<int> addTask(TasksCompanion task) {
    return _tasksDao.insertTask(task);
  }

  // 2. Получить все задачи (один раз)
  Future<List<Task>> getAllTasks() {
    return _tasksDao.getAllTasks();
  }

  // 3. Получить задачи в реальном времени (для UI)
  Stream<List<Task>> watchAllTasks() {
    return _tasksDao.watchAllTasks();
  }

  // 4. Обновить задачу
  Future<bool> updateTask(Task task) {
    return _tasksDao.updateTask(task);
  }

  // 5. Удалить задачу
  Future<int> deleteTask(int id) {
    return _tasksDao.deleteTask(id);
  }
  
  // 6. Получить одну задачу (например, для редактора)
  Future<Task?> getTaskById(int id) {
    return _tasksDao.getTaskById(id);
  }
}