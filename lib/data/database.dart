import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:salamanca/data/daos/tasks_dao.dart';

part 'database.g.dart';

@DataClassName('TaskRow')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueTime => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get buildingId => text().nullable()();
  // индекс TaskPriority: 0 low, 1 medium, 2 high
  IntColumn get priority => integer().withDefault(const Constant(1))();
  // false => задача без времени, в dueTime важна только дата
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  // v3: категория (1 = Учёба, 2 = Личное, 3 = Работа по умолчанию)
  IntColumn get categoryId => integer().withDefault(const Constant(1))();
}

class Buildings extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get buildingId => text().nullable()();
}

/// v3: настраиваемые категории задач.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
}

/// v3: простое key-value хранилище настроек (цвета приоритетов и т.п.).
class AppSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}

@DriftDatabase(
  tables: [Tasks, Buildings, Events, Categories, AppSettings],
  daos: [TasksDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'salamanca_db'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.priority);
        await m.addColumn(tasks, tasks.hasTime);
      }
      if (from < 3) {
        await m.createTable(categories);
        await m.createTable(appSettings);
        await m.addColumn(tasks, tasks.categoryId);
        await _seedCategories();
      }
    },
  );

  Future<void> _seedCategories() async {
    await batch((b) => b.insertAll(categories, [
      CategoriesCompanion.insert(
          name: 'Учёба', colorValue: 0xFF4F46E5, iconKey: 'school'),
      CategoriesCompanion.insert(
          name: 'Личное', colorValue: 0xFF14B8A6, iconKey: 'person'),
      CategoriesCompanion.insert(
          name: 'Работа', colorValue: 0xFFF59E0B, iconKey: 'work'),
    ]));
  }

  // --- Категории ---
  Stream<List<CategoryRow>> watchCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.id)])).watch();

  Future<List<CategoryRow>> getCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.id)])).get();

  Future<void> updateCategory(int id,
      {String? name, int? colorValue, String? iconKey}) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(
          name: name == null ? const Value.absent() : Value(name),
          colorValue:
          colorValue == null ? const Value.absent() : Value(colorValue),
          iconKey: iconKey == null ? const Value.absent() : Value(iconKey),
        ),
      );

  // --- Настройки ---
  Stream<Map<String, String>> watchSettings() =>
      select(appSettings).watch().map(
              (rows) => {for (final r in rows) r.settingKey: r.settingValue});

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(settingKey: key, settingValue: value));

  Future<void> deleteSetting(String key) =>
      (delete(appSettings)..where((s) => s.settingKey.equals(key))).go();
}
