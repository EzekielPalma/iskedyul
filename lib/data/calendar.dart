import 'package:flutter/material.dart';

import 'models.dart';

const monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
// Calendar arithmetic keeps dates correct across daylight-saving changes.
DateTime shiftDay(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
DateTime mondayOf(DateTime date) => shiftDay(date, 1 - date.weekday);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
String calendarDate(DateTime date) =>
    '${monthNames[date.month - 1]} ${date.day}';

String calendarWeekRange(DateTime week) {
  final end = shiftDay(week, 6);
  if (week.year == end.year) {
    return '${calendarDate(week)} – ${calendarDate(end)}, ${end.year}';
  }
  return '${calendarDate(week)}, ${week.year} – ${calendarDate(end)}, ${end.year}';
}

class ClassOccurrence {
  const ClassOccurrence(this.schedule, this.date);
  final Schedule schedule;
  final DateTime date;
  DateTime get start => DateTime(
    date.year,
    date.month,
    date.day,
    schedule.start.hour,
    schedule.start.minute,
  );
  DateTime get end => DateTime(
    date.year,
    date.month,
    date.day,
    schedule.end.hour,
    schedule.end.minute,
  );
  bool happeningAt(DateTime now) => !now.isBefore(start) && now.isBefore(end);
}

// Weekly classes repeat. A class that has ended is next seen the following week.
ClassOccurrence? nextClass(Iterable<Schedule> schedules, DateTime now) {
  final occurrences = schedules.map((schedule) {
    var date = shiftDay(now, (schedule.weekday - now.weekday + 7) % 7);
    if (!ClassOccurrence(schedule, date).end.isAfter(now)) {
      date = shiftDay(date, 7);
    }
    return ClassOccurrence(schedule, date);
  }).toList()..sort((a, b) => a.start.compareTo(b.start));
  return occurrences.isEmpty ? null : occurrences.first;
}

enum CalendarMode { day, week, month }

const fullMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
String time12(int minute) =>
    clock(TimeOfDay(hour: (minute ~/ 60) % 24, minute: minute % 60));
DateTime shiftMonth(DateTime date, int offset) {
  final first = DateTime(date.year, date.month + offset);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(
    first.year,
    first.month,
    date.day > lastDay ? lastDay : date.day,
  );
}

List<DateTime> monthDates(DateTime date) {
  final first = DateTime(date.year, date.month);
  final start = mondayOf(first);
  final length = DateTime(date.year, date.month + 1, 0).day;
  final cells = ((first.weekday - 1 + length + 6) ~/ 7) * 7;
  return List.generate(cells, (i) => shiftDay(start, i));
}

bool supportedDate(DateTime date) => date.year >= 2000 && date.year <= 2100;

class EventLane {
  const EventLane(this.schedule, this.lane, this.lanes);
  final Schedule schedule;
  final int lane;
  final int lanes;
}

// Layout only: simultaneous cards get separate lanes so each stays selectable.
List<EventLane> eventLanes(List<Schedule> schedules) {
  final sorted = schedules.toList()
    ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
  final result = <EventLane>[];
  var group = <Schedule>[];
  var groupEnd = -1;
  void finishGroup() {
    final ends = <int>[];
    final assignments = <int>[];
    for (final schedule in group) {
      var lane = ends.indexWhere((end) => end <= minutes(schedule.start));
      if (lane < 0) {
        lane = ends.length;
        ends.add(0);
      }
      ends[lane] = minutes(schedule.end);
      assignments.add(lane);
    }
    for (var i = 0; i < group.length; i++) {
      result.add(EventLane(group[i], assignments[i], ends.length));
    }
  }

  for (final schedule in sorted) {
    if (group.isNotEmpty && minutes(schedule.start) >= groupEnd) {
      finishGroup();
      group = [];
      groupEnd = -1;
    }
    group.add(schedule);
    if (minutes(schedule.end) > groupEnd) groupEnd = minutes(schedule.end);
  }
  if (group.isNotEmpty) finishGroup();
  return result;
}
