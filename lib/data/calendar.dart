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
