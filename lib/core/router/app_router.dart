//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/features/calendar/day_screen.dart';
import 'package:salamanca/features/calendar/month_screen.dart';
import 'package:salamanca/features/tasks/task_editor_screen.dart';

// --- САМ РОУТЕР ---
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
      ...extraRoutes,
    ],
  );
}