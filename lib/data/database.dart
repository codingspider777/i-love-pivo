import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// ВАЖНО: Эта строка связывает ваш код со сгенерированным файлом!
part 'database.g.dart';

// 1. Таблица Задач (Tasks)
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueTime => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // Связь со зданием (может быть пустой)
  TextColumn get buildingId => text().nullable()(); 
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
@DriftDatabase(tables: [Tasks, Buildings, Events])
class AppDatabase extends _$AppDatabase {
  // Конструктор, который создает файл базы данных на телефоне
  AppDatabase() : super(driftDatabase(name: 'salamanca_db'));

  @override
  int get schemaVersion => 1;
}