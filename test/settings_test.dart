import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salamanca/features/settings/settings.dart';
import 'package:salamanca/features/settings/settings_screen.dart';

void main() {
  testWidgets('Theme and reminder controls update settings', (tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWithValue(settings)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.tap(find.text('Тёмная тема'));
    await tester.pumpAndSettle();
    expect(settings.theme, ThemeMode.dark);
    await tester.ensureVisible(find.text('Уведомления'));
    await tester.tap(find.text('Уведомления'));
    await tester.pumpAndSettle();
    expect(settings.notifications, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
  });
}
