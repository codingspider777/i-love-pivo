import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/core/services/notification_service.dart';
import 'package:salamanca/data/models/task.dart';

void main() {
  final now = DateTime(2026, 11, 13, 12);
  Task task(int id, int hour, {bool done = false, bool timed = true}) => Task(
    id: id,
    title: 'Задача $id',
    date: DateTime(2026, 11, 13),
    time: timed ? TimeOfDay(hour: hour, minute: 0) : null,
    isDone: done,
  );
  test(
    'Reminders omit completed, untimed and elapsed tasks, and sort deadlines',
    () {
      expect(
        reminderTasks(
          [
            task(1, 14),
            task(2, 13),
            task(3, 12),
            task(4, 15, done: true),
            task(5, 16, timed: false),
          ],
          15,
          now,
        ).map((t) => t.id),
        [2, 1],
      );
    },
  );
  test('Reminder window respects the chosen offset and iOS request limit', () {
    expect(reminderTasks([task(1, 13)], 60, now), isEmpty);
    expect(
      reminderTasks(List.generate(80, (i) => task(i, 14)), 0, now).length,
      60,
    );
  });
}
