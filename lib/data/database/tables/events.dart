import 'package:drift/drift.dart';
import 'buildings.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get buildingId => integer().references(Buildings, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}