import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:salamanca/data/daos/tasks_dao.dart';

// ВАЖНО: Эта строка связывает ваш код со сгенерированным файлом!
part 'database.g.dart';

// 1. Таблица Задач (Tasks)
// Класс данных назван TaskRow, чтобы не конфликтовать с моделью Task в UI.
@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueTime => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // Связь со зданием (может быть пустой)
  TextColumn get buildingId => text().nullable()();
  // индекс TaskPriority: 0 low, 1 medium, 2 high
  IntColumn get priority => integer().withDefault(const Constant(1))();
  // false => задача без времени, в dueTime важна только дата
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
}

// 2. Таблица Зданий (Buildings)
class Buildings extends Table {
  // Используем текстовый ID (например, 'main_building'), чтобы совпадало с SVG
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id}; // Указываем, что ID — это первичный ключ
}

// 3. Таблица Событий/Расписания (Events)
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get buildingId => text().nullable()();
}

// 4. Класс самой Базы Данных
@DriftDatabase(
  tables: [Tasks, Buildings, Events],
  daos: [TasksDao],
)
class AppDatabase extends _$AppDatabase {
  // Конструктор, который создает файл базы данных на телефоне
  AppDatabase() : super(driftDatabase(name: 'salamanca_db'));

  // Для тестов (in-memory база)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(tasks, tasks.priority);
            await m.addColumn(tasks, tasks.hasTime);
          }
        },
      );
}
