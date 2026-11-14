import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salamanca/features/settings/settings.dart';
import 'package:salamanca/main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(title: Text('Внешний вид')),
            RadioGroup<ThemeMode>(
              groupValue: settings.theme,
              onChanged: (value) {
                if (value != null) settings.update(themeMode: value);
              },
              child: const Column(
                children: [
                  RadioListTile(
                    value: ThemeMode.system,
                    title: Text('Как на устройстве'),
                  ),
                  RadioListTile(
                    value: ThemeMode.light,
                    title: Text('Светлая тема'),
                  ),
                  RadioListTile(
                    value: ThemeMode.dark,
                    title: Text('Тёмная тема'),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Разрешить уведомления на устройстве'),
              leading: const Icon(Icons.notifications_outlined),
              onTap: () async {
                await ref
                    .read(notificationServiceProvider)
                    .requestPermissions();
              },
            ),
            const Divider(),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Доступ к геопозиции'),
                subtitle: const Text('Только при использовании приложения'),
                onTap: () async {
                  String message;
                  try {
                    final status = await const MethodChannel('daydock/location')
                        .invokeMethod<String>('requestPermission');
                    message = status == 'authorized'
                        ? 'Доступ разрешён'
                        : status == 'disabled'
                        ? 'Службы геолокации выключены на iPhone'
                        : 'Разрешение можно изменить в настройках iPhone → DayDock';
                  } on PlatformException {
                    message = 'Не удалось запросить доступ к геопозиции';
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(message)));
                  }
                },
              ),
            const ListTile(
              title: Text('Напоминания о задачах'),
              subtitle: Text(
                'Для задач с указанным временем. Разрешение iOS запрашивается отдельно.',
              ),
            ),
            SwitchListTile(
              title: const Text('Уведомления'),
              value: settings.notifications,
              onChanged: (v) async {
                if (v) {
                  await ref
                      .read(notificationServiceProvider)
                      .requestPermissions();
                }
                await settings.update(enabled: v);
              },
            ),
            SwitchListTile(
              title: const Text('Звук'),
              value: settings.sound,
              onChanged: settings.notifications
                  ? (v) => settings.update(playSound: v)
                  : null,
            ),
            ListTile(
              title: const Text('Напомнить заранее'),
              trailing: DropdownButton<int>(
                value: settings.reminderMinutes,
                items: [0, 5, 15, 30, 60]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v == 0 ? 'В момент задачи' : 'За $v мин'),
                      ),
                    )
                    .toList(),
                onChanged: settings.notifications
                    ? (v) {
                        if (v != null) settings.update(minutes: v);
                      }
                    : null,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Если уведомления запрещены, разрешите их в настройках iPhone → Уведомления → DayDock.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
