import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/router/app_router.dart';
import 'package:salamanca/core/theme/app_theme.dart';
import 'package:salamanca/features/widget/widget_service.dart';
import 'core/services/notification_service.dart';

// Провайдеры базы/DAO/репозитория живут в data/providers.dart.

// Провайдер для сервиса уведомлений
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  await WidgetBackground.init(); // ночное обновление Android-виджета
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Любое изменение задач/категорий перерисовывает виджет на рабочем столе.
    ref.watch(widgetSyncProvider);

    return MaterialApp.router(
      title: 'Salamanca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // следует за темой телефона
      routerConfig: _router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
