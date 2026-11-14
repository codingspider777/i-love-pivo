import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/data/providers.dart';

final categoriesStreamProvider = StreamProvider<List<TaskCategory>>((ref) {
  return ref
      .watch(databaseProvider)
      .watchCategories()
      .map((rows) => [for (final r in rows) TaskCategory.fromRow(r)]);
});

final categoriesProvider = Provider<List<TaskCategory>>((ref) {
  final list = ref.watch(categoriesStreamProvider).value;
  return (list == null || list.isEmpty) ? TaskCategory.defaults : list;
});

final settingsStreamProvider = StreamProvider<Map<String, String>>(
    (ref) => ref.watch(databaseProvider).watchSettings());

String _prioKey(TaskPriority p) => 'priority_color_${p.index}';

/// Только пользовательские цвета; для остальных используется цвет темы.
final priorityColorsProvider = Provider<Map<TaskPriority, Color>>((ref) {
  final s = ref.watch(settingsStreamProvider).value ?? const {};
  final result = <TaskPriority, Color>{};
  for (final p in TaskPriority.values) {
    final v = int.tryParse(s[_prioKey(p)] ?? '');
    if (v != null) result[p] = Color(v);
  }
  return result;
});

class SettingsActions {
  SettingsActions(this._db);
  final AppDatabase _db;

  Future<void> updateCategory(int id,
          {String? name, Color? color, String? iconKey}) =>
      _db.updateCategory(id,
          name: name, colorValue: color?.toARGB32(), iconKey: iconKey);

  Future<void> setPriorityColor(TaskPriority p, Color c) =>
      _db.setSetting(_prioKey(p), c.toARGB32().toString());

  Future<void> resetPriorityColor(TaskPriority p) =>
      _db.deleteSetting(_prioKey(p));
}

final settingsActionsProvider = Provider<SettingsActions>(
    (ref) => SettingsActions(ref.watch(databaseProvider)));
