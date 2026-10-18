import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/calendar.dart';
import '../data/models.dart';
import 'day_timeline.dart';
import 'screens.dart';

// An in-app expanded view: browser chrome stays under the browser's control.
class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key, required this.date, required this.mode});
  final DateTime date;
  final CalendarMode mode;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final days = mode == CalendarMode.week
        ? List.generate(7, (i) => shiftDay(mondayOf(date), i))
        : [date];
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable')),
      floatingActionButton: CreateFab(date: date),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                mode == CalendarMode.week
                    ? calendarWeekRange(mondayOf(date))
                    : '${weekdays[date.weekday - 1]} · ${calendarDate(date)}, ${date.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: DayTimeline(
                  expanded: true,
                  position: state.timelineOffset,
                  days: days,
                  schedules: state.schedules,
                  now: DateTime.now(),
                  onOpen: (s) => open(context, ScheduleDetailsScreen(id: s.id)),
                  onCreate: (day, time) => open(
                    context,
                    ScheduleFormScreen(
                      initialWeekday: day.weekday,
                      initialStart: time,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
