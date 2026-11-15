import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/data/database.dart';
import 'package:salamanca/data/providers.dart';
import 'package:salamanca/features/settings/settings.dart';
import 'package:salamanca/features/settings/settings_screen.dart';

void main() {
  testWidgets('Theme and reminder controls update settings', (tester) async {
    // Высокий экран, чтобы ListView построил все пункты сразу.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = AppSettings();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWithValue(settings),
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Тёмная тема'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(settings.theme, ThemeMode.dark);

    await tester.scrollUntilVisible(
      find.text('Уведомления'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Уведомления'));
    await tester.pumpAndSettle();
    expect(settings.notifications, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    settings.dispose();
  });
}