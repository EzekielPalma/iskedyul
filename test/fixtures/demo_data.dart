import 'package:flutter/material.dart';

import 'package:iskedyul/data/models.dart';

List<Schedule> demoSchedules(DateTime today) => [
  Schedule(
    id: 1,
    subject: 'Mobile Application Development',
    weekday: today.weekday,
    start: const TimeOfDay(hour: 9, minute: 0),
    end: const TimeOfDay(hour: 10, minute: 30),
    notes: 'Lab 204. Bring the wireframes for our student app.',
  ),
  Schedule(
    id: 2,
    subject: 'Data Structures',
    weekday: today.weekday,
    start: const TimeOfDay(hour: 13, minute: 0),
    end: const TimeOfDay(hour: 14, minute: 30),
    notes: 'Review stacks and queues before the next quiz.',
  ),
  Schedule(
    id: 3,
    subject: 'Database Management',
    weekday: today.weekday == 5 ? 2 : 5,
    start: const TimeOfDay(hour: 10, minute: 0),
    end: const TimeOfDay(hour: 12, minute: 0),
    notes: 'Prepare the ER diagram for the library system.',
  ),
];
List<StudentTask> demoTasks(DateTime today) => [
  StudentTask(
    id: 1,
    title: 'Finish app wireframes',
    scheduleId: 1,
    due: today.subtract(const Duration(days: 1)),
    priority: Priority.medium,
  ),
  StudentTask(
    id: 2,
    title: 'Practice linked lists',
    scheduleId: 2,
    due: today,
    priority: Priority.high,
  ),
  StudentTask(
    id: 3,
    title: 'Draft the ER diagram',
    scheduleId: 3,
    due: today.add(const Duration(days: 3)),
    priority: Priority.low,
  ),
  StudentTask(
    id: 4,
    title: 'Read the project brief',
    scheduleId: 1,
    due: today,
    priority: Priority.low,
    completed: true,
  ),
];
