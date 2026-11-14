import 'package:flutter/material.dart';
import 'package:salamanca/data/database.dart';

/// Набор иконок для категорий. В БД хранится ключ, а не codePoint —
/// иначе tree-shaking иконок в release-сборке не сработает.
const Map<String, IconData> kCategoryIcons = {
  'school': Icons.school,
  'person': Icons.person,
  'work': Icons.work,
  'home': Icons.home,
  'fitness': Icons.fitness_center,
  'book': Icons.menu_book,
  'code': Icons.code,
  'cart': Icons.shopping_cart,
  'flight': Icons.flight,
  'heart': Icons.favorite,
  'music': Icons.music_note,
  'group': Icons.groups,
  'science': Icons.science,
  'star': Icons.star,
};

@immutable
class TaskCategory {
  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.iconKey,
  });

  final int id;
  final String name;
  final Color color;
  final String iconKey;

  IconData get icon => kCategoryIcons[iconKey] ?? Icons.label_outline;

  factory TaskCategory.fromRow(CategoryRow r) => TaskCategory(
        id: r.id,
        name: r.name,
        color: Color(r.colorValue),
        iconKey: r.iconKey,
      );

  /// Показываются, пока поток из БД ещё не отдал данные.
  static const defaults = [
    TaskCategory(
        id: 1, name: 'Учёба', color: Color(0xFF4F46E5), iconKey: 'school'),
    TaskCategory(
        id: 2, name: 'Личное', color: Color(0xFF14B8A6), iconKey: 'person'),
    TaskCategory(
        id: 3, name: 'Работа', color: Color(0xFFF59E0B), iconKey: 'work'),
  ];
}

TaskCategory categoryOf(List<TaskCategory> list, int id) => list.firstWhere(
      (c) => c.id == id,
      orElse: () =>
          list.isNotEmpty ? list.first : TaskCategory.defaults.first,
    );
