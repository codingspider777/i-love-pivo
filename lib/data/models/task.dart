import 'package:flutter/material.dart';

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
  });

  final String id;
  final String title;
  final String description;

  /// Дата дедлайна (только дата, без времени).
  final DateTime date;

  /// Время дедлайна (необязательно).
  final TimeOfDay? time;
  final TaskPriority priority;
  final bool isDone;

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    bool clearTime = false,
    TaskPriority? priority,
    bool? isDone,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
    );
  }
}
