import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/quick_add/quick_add_parser.dart';

void main() {
  // 13 ноября 2026 — пятница.
  final now = DateTime(2026, 11, 13, 9, 0);
  final cats = TaskCategory.defaults;

  test('завтра + время', () {
    final p = QuickAddParser.parse('Завтра в 10:00 сдать лабу', now: now);
    expect(p.title, 'Сдать лабу');
    expect(p.date, DateTime(2026, 11, 14));
    expect(p.time, const TimeOfDay(hour: 10, minute: 0));
  });

  test('день недели', () {
    final p = QuickAddParser.parse('в понедельник купить хлеб', now: now);
    expect(p.title, 'Купить хлеб');
    expect(p.date, DateTime(2026, 11, 16));
  });

  test('через N дней и приоритет', () {
    final p = QuickAddParser.parse('Позвонить через 3 дня !высокий', now: now);
    expect(p.title, 'Позвонить');
    expect(p.date, DateTime(2026, 11, 16));
    expect(p.priority, TaskPriority.high);
  });

  test('дата, время и категория', () {
    final p = QuickAddParser.parse('Сдать отчёт 25.11 в 18:30 #работа',
        now: now, categories: cats);
    expect(p.title, 'Сдать отчёт');
    expect(p.date, DateTime(2026, 11, 25));
    expect(p.time, const TimeOfDay(hour: 18, minute: 30));
    expect(p.categoryId, 3);
  });

  test('без распознанного — только заголовок', () {
    final p = QuickAddParser.parse('Прочитать книгу', now: now);
    expect(p.title, 'Прочитать книгу');
    expect(p.date, isNull);
    expect(p.time, isNull);
  });
}
