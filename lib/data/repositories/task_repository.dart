import '../daos/tasks_dao.dart';
import '../database.dart';

class TaskRepository {
  final TasksDao _tasksDao;

  TaskRepository(this._tasksDao);

  Future<int> addTask(TasksCompanion task) => _tasksDao.insertTask(task);
  Future<List<TaskRow>> getAllTasks() => _tasksDao.getAllTasks();
  Stream<List<TaskRow>> watchAllTasks() => _tasksDao.watchAllTasks();
  Future<bool> updateTask(TaskRow task) => _tasksDao.updateTask(task);
  Future<int> updateTaskById(int id, TasksCompanion data) =>
      _tasksDao.updateTaskById(id, data);
  Future<int> setCompleted(int id, bool value) =>
      _tasksDao.setCompleted(id, value);
  Future<int> deleteTask(int id) => _tasksDao.deleteTask(id);
  Future<TaskRow?> getTaskById(int id) => _tasksDao.getTaskById(id);
}
