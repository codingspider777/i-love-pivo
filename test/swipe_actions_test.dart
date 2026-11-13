import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/widgets/day_task_list.dart';
import 'package:salamanca/features/tasks/widgets/task_tile.dart';

class MockActions extends Mock implements TasksActions {}
void main() {
  testWidgets('Right swipe completes; left swipe deletes with undo', (tester) async {
    final day = DateTime(2026,11,14);
    final task = Task(id:7,title:'Подготовить отчёт',date:day);
    final actions = MockActions();
    when(()=>actions.toggleDone(task)).thenAnswer((_) async {});
    when(()=>actions.remove(7)).thenAnswer((_) async {});
    when(()=>actions.add(task)).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(overrides:[tasksStreamProvider.overrideWith((ref)=>Stream.value([task])),tasksActionsProvider.overrideWithValue(actions)],child:MaterialApp(home:Scaffold(body:DayTaskList(day:day)))));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TaskTile),const Offset(600,0));
    await tester.pumpAndSettle();
    verify(()=>actions.toggleDone(task)).called(1);
    expect(find.text(task.title),findsOneWidget);
    await tester.drag(find.byType(TaskTile),const Offset(-600,0));
    await tester.pumpAndSettle();
    verify(()=>actions.remove(7)).called(1);
    expect(find.text('Задача удалена'),findsOneWidget);
    await tester.tap(find.text('Отменить')); await tester.pumpAndSettle();
    verify(()=>actions.add(task)).called(1);
  });
}
