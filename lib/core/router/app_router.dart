import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/features/calendar/day_screen.dart';
import 'package:salamanca/features/calendar/month_screen.dart';
import 'package:salamanca/features/tasks/task_editor_screen.dart';
import 'package:salamanca/features/map/map_screen.dart';

/// Маршруты:
///   /                 — месяц
///   /day/2026-10-25   — задачи дня
///   /task/new?date=…  — создание задачи
///   /task/:id         — редактирование задачи
///
/// [extraRoutes] позволяет подключать экраны, которые живут вне этого файла
/// (например, прототип карты из main.dart).
GoRouter createAppRouter({List<RouteBase> extraRoutes = const []}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MonthScreen(),
      ),
      GoRoute(
        path: '/day/:date',
        builder: (context, state) {
          final date = dateFromParam(state.pathParameters['date']) ??
              dateOnly(DateTime.now());
          return DayScreen(date: date);
        },
      ),
      // '/task/new' должен идти раньше '/task/:id'.
      GoRoute(
        path: '/task/new',
        builder: (context, state) => TaskEditorScreen(
          initialDate: dateFromParam(state.uri.queryParameters['date']),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) =>
            TaskEditorScreen(taskId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => MapScreen(
          focusBuildingId: state.uri.queryParameters['building'],
        ),
      ),  
      ...extraRoutes,
    ],
  );
}