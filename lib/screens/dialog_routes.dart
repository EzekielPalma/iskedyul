import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';

// Dialog pages get browser history entries so phone Back closes only the dialog.
class PlannerDialogPage<T> extends Page<T> {
  const PlannerDialogPage({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Route<T> createRoute(BuildContext context) =>
      DialogRoute<T>(context: context, settings: this, builder: builder);
}

Future<T?> plannerDialog<T>(
  BuildContext context,
  Uri location,
  WidgetBuilder builder,
) {
  final router = GoRouter.maybeOf(context);
  return router != null
      ? router.push<T>(location.toString())
      : showDialog<T>(context: context, builder: builder);
}

Future<DateTime?> pickPlannerDate(
  BuildContext context,
  DateTime initial, {
  String? help,
}) => plannerDialog<DateTime>(
  context,
  Uri(
    path: '/pick-date',
    queryParameters: {
      'date': initial.toIso8601String().split('T').first,
      'help': ?help,
    },
  ),
  (_) => DatePickerDialog(
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100, 12, 31),
    helpText: help,
  ),
);
Future<TimeOfDay?> pickPlannerTime(BuildContext context, TimeOfDay initial) =>
    plannerDialog<TimeOfDay>(
      context,
      Uri(path: '/pick-time', queryParameters: {'time': '${minutes(initial)}'}),
      (_) => TimePickerDialog(initialTime: initial),
    );
Widget deleteDialog(BuildContext context, String title, String message) =>
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
