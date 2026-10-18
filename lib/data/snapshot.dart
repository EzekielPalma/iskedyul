import 'dart:convert';

import 'package:flutter/material.dart';

import 'models.dart';

// One versioned snapshot keeps schedules and their linked tasks together.
String encodeSnapshot(
  List<Schedule> schedules,
  List<StudentTask> tasks,
) => jsonEncode({
  'version': 1,
  'schedules': schedules
      .map(
        (s) => {
          'id': s.id,
          'subject': s.subject,
          'weekday': s.weekday,
          'start': minutes(s.start),
          'end': minutes(s.end),
          'notes': s.notes,
        },
      )
      .toList(),
  'tasks': tasks
      .map(
        (t) => {
          'id': t.id,
          'title': t.title,
          'scheduleId': t.scheduleId,
          'due':
              '${t.due.year.toString().padLeft(4, '0')}-${t.due.month.toString().padLeft(2, '0')}-${t.due.day.toString().padLeft(2, '0')}',
          'priority': t.priority.name,
          'completed': t.completed,
        },
      )
      .toList(),
});

class RestoredData {
  final schedules = <Schedule>[];
  final tasks = <StudentTask>[];
  bool skippedInvalid = false;
}

int validInt(dynamic value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Invalid number');
  }
  return value;
}

String validText(dynamic value, int max, {bool empty = false}) {
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty)) {
    throw const FormatException('Invalid text');
  }
  return value;
}

RestoredData decodeSnapshot(String raw) {
  final data = jsonDecode(raw);
  if (data is! Map ||
      data['version'] != 1 ||
      data['schedules'] is! List ||
      data['tasks'] is! List) {
    throw const FormatException('Invalid snapshot');
  }
  final result = RestoredData();
  for (final row in data['schedules']) {
    try {
      if (row is! Map) throw const FormatException();
      final id = validInt(row['id'], 1, 9007199254740990);
      if (result.schedules.any((s) => s.id == id)) {
        throw const FormatException();
      }
      final start = validInt(row['start'], 0, 1439);
      final end = validInt(row['end'], start + 1, 1439);
      result.schedules.add(
        Schedule(
          id: id,
          subject: validText(row['subject'], 100),
          weekday: validInt(row['weekday'], 1, 7),
          start: TimeOfDay(hour: start ~/ 60, minute: start % 60),
          end: TimeOfDay(hour: end ~/ 60, minute: end % 60),
          notes: validText(row['notes'], 2000, empty: true),
        ),
      );
    } on FormatException {
      result.skippedInvalid = true;
    }
  }
  for (final row in data['tasks']) {
    try {
      if (row is! Map) throw const FormatException();
      final id = validInt(row['id'], 1, 9007199254740990);
      final scheduleId = validInt(row['scheduleId'], 1, 9007199254740990);
      if (result.tasks.any((t) => t.id == id) ||
          !result.schedules.any((s) => s.id == scheduleId)) {
        throw const FormatException();
      }
      final date = validText(row['due'], 10);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        throw const FormatException();
      }
      final due = DateTime.tryParse(date);
      if (due == null ||
          due.year < 2000 ||
          due.year > 2100 ||
          due.toIso8601String().substring(0, 10) != date ||
          row['completed'] is! bool) {
        throw const FormatException();
      }
      final priority = Priority.values
          .where((p) => p.name == row['priority'])
          .firstOrNull;
      if (priority == null) throw const FormatException();
      result.tasks.add(
        StudentTask(
          id: id,
          title: validText(row['title'], 120),
          scheduleId: scheduleId,
          due: due,
          priority: priority,
          completed: row['completed'],
        ),
      );
    } on FormatException {
      result.skippedInvalid = true;
    }
  }
  return result;
}
