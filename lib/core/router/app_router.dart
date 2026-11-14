import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/features/calendar/day_screen.dart';
import 'package:salamanca/features/calendar/month_screen.dart';
import 'package:salamanca/features/calendar/week_screen.dart';
import 'package:salamanca/features/map/map_screen.dart';
import 'package:salamanca/features/settings/settings_screen.dart';
import 'package:salamanca/features/tasks/task_editor_screen.dart';

/// Мягкий переход: fade + лёгкий подъём.
CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

GoRouter createAppRouter({List<RouteBase> extraRoutes = const []}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(state, const MonthScreen()),
      ),
      GoRoute(
        path: '/week',
        pageBuilder: (context, state) => _page(
          state,
          WeekScreen(
              initialDate: dateFromParam(state.uri.queryParameters['date'])),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _page(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/day/:date',
        pageBuilder: (context, state) {
          final date = dateFromParam(state.pathParameters['date']) ??
              dateOnly(DateTime.now());
          return _page(state, DayScreen(date: date));
        },
      ),
      // '/task/new' должен идти раньше '/task/:id'.
      GoRoute(
        path: '/task/new',
        pageBuilder: (context, state) => _page(
          state,
          TaskEditorScreen(
            initialDate: dateFromParam(state.uri.queryParameters['date']),
          ),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        pageBuilder: (context, state) => _page(
            state, TaskEditorScreen(taskId: state.pathParameters['id'])),
      ),
      GoRoute(
        path: '/map',
        pageBuilder: (context, state) => _page(
          state,
          MapScreen(focusBuildingId: state.uri.queryParameters['building']),
        ),
      ),
      ...extraRoutes,
    ],
  );
}
