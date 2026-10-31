import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/router/app_router.dart';
import 'package:salamanca/core/theme/app_theme.dart';
import 'data/database.dart';
import 'data/daos/tasks_dao.dart';
import 'data/repositories/task_repository.dart';

// 1. Провайдер для базы данных
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// 2. Провайдер для DAO (берет базу из первого провайдера)
final tasksDaoProvider = Provider<TasksDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao;
});

// 3. Провайдер для Репозитория (берет DAO из второго провайдера)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dao = ref.watch(tasksDaoProvider);
  return TaskRepository(dao);
});

void main() {
  runApp(
    // ОБЯЗАТЕЛЬНО: Оборачиваем приложение в ProviderScope
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Создаем роутер один раз
  static final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Salamanca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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