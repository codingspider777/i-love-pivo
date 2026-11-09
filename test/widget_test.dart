import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/providers.dart';
import 'package:salamanca/main.dart';

Future<void> pumpApp(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const MyApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('App should build without crashing', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
  });

  testWidgets('Editor shows validation error for empty title',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final saveButton = find.text('Сохранить');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Введите название задачи'), findsOneWidget);
  });
}
