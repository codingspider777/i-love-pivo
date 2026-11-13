import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/router/app_router.dart';
import 'package:salamanca/core/theme/app_theme.dart';
import 'package:salamanca/features/settings/settings.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';

import 'core/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  final service = NotificationService();
  // The planner remains usable if the OS notification service is unavailable.
  try {
    await service.init();
  } catch (error) {
    debugPrint('Notifications: $error');
  }
  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWithValue(settings),
        notificationServiceProvider.overrideWithValue(service),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router = createAppRouter();
  late final AppSettings _settings;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings = ref.read(settingsProvider)..addListener(_refreshReminders);
  }

  void _refreshReminders() {
    final tasks = ref.read(tasksStreamProvider).value;
    if (tasks == null) return;
    ref
        .read(notificationServiceProvider)
        .synchronize(
          tasks,
          enabled: _settings.notifications,
          sound: _settings.sound,
          minutes: _settings.reminderMinutes,
        )
        .catchError((Object error) {
          debugPrint('Reminders: $error');
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_refreshReminders);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tasksStreamProvider, (_, next) {
      if (next.hasValue) _refreshReminders();
    });
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp.router(
        title: 'DayDock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _settings.theme,
        routerConfig: _router,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
