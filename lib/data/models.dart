import 'package:flutter/material.dart';

const weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

enum Priority { high, medium, low }

class Schedule {
  Schedule({
    required this.id,
    required this.subject,
    required this.weekday,
    required this.start,
    required this.end,
    this.notes = '',
  });
  final int id;
  String subject;
  int weekday;
  TimeOfDay start;
  TimeOfDay end;
  String notes;
}

class StudentTask {
  StudentTask({
    required this.id,
    required this.title,
    required this.scheduleId,
    required this.due,
    required this.priority,
    this.completed = false,
  });
  final int id;
  String title;
  int scheduleId;
  DateTime due;
  Priority priority;
  bool completed;
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
String shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
int minutes(TimeOfDay time) => time.hour * 60 + time.minute;
String clock(TimeOfDay time) =>
    '${(time.hour % 12 == 0 ? 12 : time.hour % 12)}:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
bool overdue(StudentTask task, DateTime today) =>
    !task.completed && dateOnly(task.due).isBefore(dateOnly(today));

// Overdue pending tasks first, then priority, then due date; completed last.
int compareTasks(StudentTask a, StudentTask b, DateTime today) {
  if (a.completed != b.completed) return a.completed ? 1 : -1;
  if (overdue(a, today) != overdue(b, today)) return overdue(a, today) ? -1 : 1;
  final priority = a.priority.index.compareTo(b.priority.index);
  if (priority != 0) return priority;
  final due = a.due.compareTo(b.due);
  return due != 0 ? due : a.id.compareTo(b.id);
}
