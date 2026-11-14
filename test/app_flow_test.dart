import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/providers.dart';
import 'package:salamanca/main.dart';

void main() {
  testWidgets('Create task, open details, edit and complete', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(overrides:[databaseProvider.overrideWithValue(db)],child:const MyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Новая задача'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first,'Сдать курсовую');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сдать курсовую'));
    await tester.pumpAndSettle();
    expect(find.text('Задача'),findsOneWidget);
    await tester.tap(find.byTooltip('Редактировать'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(1),'Взять распечатку');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Взять распечатку'),findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final rows = await db.tasksDao.getAllTasks();
    expect(rows.single.isCompleted,isTrue);
    expect(rows.single.description,'Взять распечатку');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds:100));
  });
}
