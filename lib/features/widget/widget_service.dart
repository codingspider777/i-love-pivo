import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/settings/providers/settings_providers.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/widget/widget_cards.dart';
import 'package:workmanager/workmanager.dart';

bool get _isAndroid => !kIsWeb && Platform.isAndroid;

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

WidgetSnapshot buildSnapshot(
    List<Task> tasks, List<TaskCategory> cats, DateTime now) {
  final today = tasksOnDay(tasks, now);
  final ordered = [
    ...today.where((t) => !t.isDone),
    ...today.where((t) => t.isDone),
  ];
  return WidgetSnapshot(
    date: now,
    open: today.where((t) => !t.isDone).length,
    total: today.length,
    items: [
      for (final t in ordered)
        WidgetItem(
          title: t.title,
          color: categoryOf(cats, t.categoryId).color,
          time: t.time == null ? null : _hhmm(t.time!),
          done: t.isDone,
        ),
    ],
  );
}

/// Рендерит Flutter-виджеты в PNG и просит Android обновить AppWidget.
class WidgetService {
  WidgetService._();

  static bool _running = false;
  static (List<Task>, List<TaskCategory>)? _pending;

  /// Вызов из UI: несколько быстрых изменений схлопываются в один рендер.
  static Future<void> sync(List<Task> tasks, List<TaskCategory> cats) async {
    if (!_isAndroid) return;
    _pending = (tasks, cats);
    if (_running) return;
    _running = true;
    try {
      while (_pending != null) {
        final p = _pending!;
        _pending = null;
        await _render(p.$1, p.$2);
      }
    } finally {
      _running = false;
    }
  }

  /// Вызов из фонового изолята WorkManager: открывает свою БД.
  static Future<void> refreshFromDb() async {
    if (!_isAndroid) return;
    final db = AppDatabase();
    try {
      final tasks = [
        for (final r in await db.tasksDao.getAllTasks()) Task.fromRow(r)
      ];
      final cats = [
        for (final r in await db.getCategories()) TaskCategory.fromRow(r)
      ];
      await _render(tasks, cats);
    } finally {
      await db.close();
    }
  }

  static Future<void> _render(List<Task> tasks, List<TaskCategory> cats) async {
    try {
      await initializeDateFormatting('ru');
      final snapshot = buildSnapshot(tasks, cats, DateTime.now());
      final dark =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
      for (final size in WidgetSize.values) {
        await HomeWidget.renderFlutterWidget(
          TasksWidgetCard(snapshot: snapshot, size: size, dark: dark),
          key: size.prefKey,
          logicalSize: size.logicalSize,
          pixelRatio: 2,
        );
        await HomeWidget.updateWidget(qualifiedAndroidName: size.androidProvider);
      }
    } catch (e, s) {
      debugPrint('Widget render failed: $e\n$s');
    }
  }
}

/// Подписка на изменения задач/категорий: любое изменение в приложении
/// обновляет виджет. Читается один раз в корне (MyApp).
final widgetSyncProvider = Provider<void>((ref) {
  void push() {
    final tasks = ref.read(tasksStreamProvider).value;
    if (tasks == null) return;
    final cats = ref.read(categoriesStreamProvider).value;
    WidgetService.sync(tasks, cats ?? TaskCategory.defaults);
  }

  ref.listen(tasksStreamProvider, (_, _) => push(), fireImmediately: true);
  ref.listen(categoriesStreamProvider, (_, _) => push());
});

// ---------------------------------------------------------------------------
// WorkManager: обновление виджета раз в сутки около 00:00.
// ---------------------------------------------------------------------------

const _kUniqueName = 'daydock.widget.midnight';
const _kTaskName = 'daydock.widget.refresh';

@pragma('vm:entry-point')
void widgetCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await WidgetService.refreshFromDb();
      return true;
    } catch (e) {
      debugPrint('Widget background refresh failed: $e');
      return false;
    }
  });
}

class WidgetBackground {
  WidgetBackground._();

  static Duration untilMidnight([DateTime? now]) {
    now ??= DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    return next.difference(now) + const Duration(seconds: 30);
  }

  /// Вызывать при старте приложения: каждый запуск пересчитывает «якорь»
  /// на ближайшую полночь, поэтому дрейф WorkManager не накапливается.
  static Future<void> init() async {
    if (!_isAndroid) return;
    try {
      await Workmanager().initialize(widgetCallbackDispatcher);
      await Workmanager().cancelByUniqueName(_kUniqueName);
      await Workmanager().registerPeriodicTask(
        _kUniqueName,
        _kTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: untilMidnight(),
      );
    } catch (e) {
      debugPrint('WorkManager init failed: $e');
    }
  }
}
