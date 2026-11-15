import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:salamanca/data/database.dart';

enum TaskPriority {
  low('Низкий'),
  medium('Средний'),
  high('Высокий');

  const TaskPriority(this.label);
  final String label;
}

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.time,
    this.priority = TaskPriority.medium,
    this.isDone = false,
    this.buildingId,
    this.categoryId = 1,
  });

  /// 0 — ещё не сохранена в БД.
  final int id;
  final String title;
  final String description;

  /// Дата дедлайна (только дата, без времени).
  final DateTime date;

  /// Время дедлайна (необязательно).
  final TimeOfDay? time;
  final TaskPriority priority;
  final bool isDone;

  /// Для связки «задача ↔ карта».
  final String? buildingId;

  /// Категория (см. таблицу categories).
  final int categoryId;

  DateTime get dueTime => DateTime(
      date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);

  factory Task.fromRow(TaskRow r) {
    final due = r.dueTime;
    return Task(
      id: r.id,
      title: r.title,
      description: r.description ?? '',
      date: DateTime(due.year, due.month, due.day),
      time: r.hasTime ? TimeOfDay(hour: due.hour, minute: due.minute) : null,
      priority: TaskPriority.values[r.priority.clamp(0, 2)],
      isDone: r.isCompleted,
      buildingId: r.buildingId,
      categoryId: r.categoryId,
    );
  }

  TasksCompanion toCompanion() => TasksCompanion(
    title: Value(title),
    description: Value(description.isEmpty ? null : description),
    dueTime: Value(dueTime),
    isCompleted: Value(isDone),
    buildingId: Value(buildingId),
    priority: Value(priority.index),
    hasTime: Value(time != null),
    categoryId: Value(categoryId),
  );

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    bool clearTime = false,
    TaskPriority? priority,
    bool? isDone,
    String? buildingId,
    int? categoryId,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      buildingId: buildingId ?? this.buildingId,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
