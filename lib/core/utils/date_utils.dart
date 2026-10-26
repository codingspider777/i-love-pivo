import 'package:intl/intl.dart';

/// Границы календаря и выбора даты.
final DateTime kFirstDay = DateTime(2020, 1, 1);
final DateTime kLastDay = DateTime(2100, 12, 31);

/// Обрезает время, оставляя только дату.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Дата -> строка для параметра маршрута (2026-10-25).
String dateToParam(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Строка из маршрута -> дата (или null, если строка некорректна).
DateTime? dateFromParam(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : dateOnly(parsed);
}

/// «25 октября, воскресенье»
String formatDayTitle(DateTime d, String locale) =>
    DateFormat('d MMMM, EEEE', locale).format(d);

/// «25 октября 2026»
String formatLongDate(DateTime d, String locale) =>
    DateFormat('d MMMM yyyy', locale).format(d);
