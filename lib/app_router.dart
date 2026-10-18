import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/app_state.dart';
import 'data/calendar.dart';
import 'data/models.dart';
import 'screens/screens.dart';
import 'screens/timetable_screen.dart';
import 'screens/dialog_routes.dart';

// Hash URLs work on GitHub Pages and the local Windows server without rewrites.
GoRouter createAppRouter(AppState app) {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  DateTime? date(GoRouterState route) {
    final parsed = DateTime.tryParse(route.uri.queryParameters['date'] ?? '');
    return parsed != null && supportedDate(parsed) ? dateOnly(parsed) : null;
  }

  int? number(GoRouterState route, String name) =>
      int.tryParse(route.uri.queryParameters[name] ?? '');
  Schedule? schedule(GoRouterState route) {
    final id = int.tryParse(route.pathParameters['id'] ?? '');
    return app.schedules.where((s) => s.id == id).firstOrNull;
  }

  StudentTask? task(GoRouterState route) {
    final id = int.tryParse(route.pathParameters['id'] ?? '');
    return app.tasks.where((t) => t.id == id).firstOrNull;
  }

  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, route) {
          if (!app.isReturning && route.uri.queryParameters['tab'] == null) {
            return const WelcomeScreen();
          }
          return DashboardScreen(
            initialDone: route.uri.queryParameters['done'] == '1',
            initialTab: switch (route.uri.queryParameters['tab']) {
              'calendar' => 1,
              'tasks' => 2,
              _ => 0,
            },
            initialMode: CalendarMode.values
                .where((m) => m.name == route.uri.queryParameters['view'])
                .firstOrNull,
            initialDate: date(route),
          );
        },
        routes: [
          GoRoute(
            path: 'pick-date',
            pageBuilder: (context, route) => PlannerDialogPage<DateTime>(
              key: route.pageKey,
              builder: (_) => DatePickerDialog(
                initialDate: date(route) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100, 12, 31),
                helpText: route.uri.queryParameters['help'],
              ),
            ),
          ),
          GoRoute(
            path: 'pick-time',
            pageBuilder: (context, route) {
              final minute = (number(route, 'time') ?? 540).clamp(0, 1439);
              return PlannerDialogPage<TimeOfDay>(
                key: route.pageKey,
                builder: (_) => TimePickerDialog(
                  initialTime: TimeOfDay(
                    hour: minute ~/ 60,
                    minute: minute % 60,
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: 'confirm-delete',
            pageBuilder: (context, route) => PlannerDialogPage<bool>(
              key: route.pageKey,
              builder: (context) => deleteDialog(
                context,
                route.uri.queryParameters['title'] ?? 'Delete?',
                route.uri.queryParameters['message'] ??
                    'This cannot be undone.',
              ),
            ),
          ),
          GoRoute(
            path: 'class/:id/notes',
            pageBuilder: (context, route) => PlannerDialogPage<String>(
              key: route.pageKey,
              builder: (_) => schedule(route) == null
                  ? const AlertDialog(
                      content: Text('This class is no longer available.'),
                    )
                  : NotesDialog(notes: schedule(route)!.notes),
            ),
          ),
          GoRoute(
            path: 'class/new',
            builder: (context, route) {
              final minute = number(route, 'time');
              return ScheduleFormScreen(
                initialWeekday:
                    [1, 2, 3, 4, 5, 6, 7].contains(number(route, 'weekday'))
                    ? number(route, 'weekday')
                    : null,
                initialStart: minute != null && minute >= 0 && minute <= 1410
                    ? TimeOfDay(hour: minute ~/ 60, minute: minute % 60)
                    : null,
              );
            },
          ),
          GoRoute(
            path: 'class/:id/edit',
            builder: (context, route) => schedule(route) == null
                ? const MissingEntryScreen()
                : ScheduleFormScreen(schedule: schedule(route)),
          ),
          GoRoute(
            path: 'class/:id',
            builder: (context, route) => ScheduleDetailsScreen(
              id: int.tryParse(route.pathParameters['id']!) ?? -1,
            ),
          ),
          GoRoute(
            path: 'task/new',
            builder: (context, route) => TaskFormScreen(
              scheduleId:
                  app.schedules.any((s) => s.id == number(route, 'class'))
                  ? number(route, 'class')
                  : null,
              initialDue: date(route),
            ),
          ),
          GoRoute(
            path: 'task/:id/edit',
            builder: (context, route) => task(route) == null
                ? const MissingEntryScreen()
                : TaskFormScreen(task: task(route)),
          ),
          GoRoute(
            path: 'saved/:id',
            builder: (context, route) => ConfirmationScreen(
              message: route.uri.queryParameters['kind'] == 'task'
                  ? 'Task saved.'
                  : 'Class saved.',
              scheduleId: int.tryParse(route.pathParameters['id']!) ?? -1,
            ),
          ),
          GoRoute(
            path: 'add',
            pageBuilder: (context, route) =>
                AddMenuPage(key: route.pageKey, date: date(route)),
          ),
          GoRoute(
            path: 'timetable',
            builder: (context, route) => TimetableScreen(
              date: date(route) ?? DateTime.now(),
              mode: route.uri.queryParameters['view'] == 'week'
                  ? CalendarMode.week
                  : CalendarMode.day,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, route) => const MissingEntryScreen(),
  );
}

class MissingEntryScreen extends StatelessWidget {
  const MissingEntryScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Unavailable',
    children: [
      const EmptyCard('This entry is no longer available.'),
      TextButton(
        onPressed: () => dashboard(context),
        child: const Text('Back to today'),
      ),
    ],
  );
}
