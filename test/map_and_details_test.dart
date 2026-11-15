import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/map/map_screen.dart';
import 'package:salamanca/features/map/models/map_building.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/task_details_screen.dart';

void main() {
  test('Campus asset and SVG geometry load offline', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final buildings = await container.read(buildingsProvider.future);
    final shapes = await container.read(buildingShapesProvider.future);
    expect(buildings, isNotEmpty);
    expect(shapes, isNotEmpty);
    expect(buildings.map((b) => b.id).toSet().length, buildings.length);
  });
  testWidgets('Map renders offline and can reset its viewport', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(buildingsProvider.future);
      await container.read(buildingShapesProvider.future);
    });
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MaterialApp(home: MapScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Карта кампуса'), findsOneWidget);
    expect(find.byTooltip('Показать всю карту'), findsOneWidget);
    await tester.drag(find.byType(MapScreen), const Offset(40,20));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Показать всю карту'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Details show stored task information', (tester) async {
    final task = Task(
      id: 5,
      title: 'Лабораторная работа',
      description: 'Корпус 2, аудитория 105',
      date: DateTime(2026, 11, 14),
      time: const TimeOfDay(hour: 14, minute: 30),
      priority: TaskPriority.high,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value([task])),
        ],
        child: const MaterialApp(home: TaskDetailsScreen(taskId: '5')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(task.title), findsOneWidget);
    expect(find.text(task.description), findsOneWidget);
    expect(find.text('Приоритет: Высокий'), findsOneWidget);
    expect(find.byTooltip('Редактировать'), findsOneWidget);
  });
  testWidgets('Deleted or unknown task has a useful empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: TaskDetailsScreen(taskId: '999')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Задача не найдена'), findsOneWidget);
  });
}
