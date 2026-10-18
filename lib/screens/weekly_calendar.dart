import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/calendar.dart';
import '../data/models.dart';
import 'day_timeline.dart';
import 'timetable_screen.dart';
import 'dialog_routes.dart';

// Dated views of weekly classes; browsing never duplicates stored records.
class WeeklyCalendar extends StatefulWidget {
  const WeeklyCalendar({
    super.key,
    required this.schedules,
    required this.tasks,
    required this.scheduleCard,
    required this.taskCard,
    required this.onAddSchedule,
    required this.onOpenSchedule,
    this.today,
    this.initialMode = CalendarMode.week,
    this.initialDate,
    this.onSelectionChanged,
    this.onAddTimeSlot,
    this.timelineOffset,
  });
  final List<Schedule> schedules;
  final List<StudentTask> tasks;
  final Widget Function(Schedule) scheduleCard;
  final Widget Function(StudentTask) taskCard;
  final ValueChanged<DateTime> onAddSchedule;
  final ValueChanged<Schedule> onOpenSchedule;
  final DateTime? today;
  final ValueNotifier<double?>? timelineOffset;
  final CalendarMode initialMode;
  final DateTime? initialDate;
  final void Function(CalendarMode, DateTime)? onSelectionChanged;
  final void Function(DateTime, TimeOfDay)? onAddTimeSlot;
  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  final ownOffset = ValueNotifier<double?>(null);
  ValueNotifier<double?> get offsetMemory => widget.timelineOffset ?? ownOffset;
  @override
  void didUpdateWidget(covariant WeeklyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) mode = widget.initialMode;
    if (oldWidget.initialDate != widget.initialDate &&
        widget.initialDate != null) {
      selected = dateOnly(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    ownOffset.dispose();
    super.dispose();
  }

  void expand() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push<void>(
        Uri(
          path: '/timetable',
          queryParameters: {
            'date': selected.toIso8601String().split('T').first,
            'view': mode.name,
          },
        ).toString(),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TimetableScreen(date: selected, mode: mode),
        ),
      );
    }
  }

  late DateTime selected = dateOnly(widget.initialDate ?? today);
  late CalendarMode mode = widget.initialMode;
  DateTime get today => dateOnly(widget.today ?? DateTime.now());
  List<Schedule> classesOn(DateTime day) =>
      widget.schedules.where((s) => s.weekday == day.weekday).toList()
        ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
  List<StudentTask> tasksOn(DateTime day) =>
      widget.tasks.where((t) => sameDay(t.due, day)).toList()
        ..sort((a, b) => compareTasks(a, b, today));
  void choose(DateTime date, [CalendarMode? newMode]) {
    if (!supportedDate(date)) return;
    setState(() {
      selected = dateOnly(date);
      mode = newMode ?? mode;
    });
    widget.onSelectionChanged?.call(mode, selected);
  }

  DateTime offset(int amount) => mode == CalendarMode.month
      ? shiftMonth(selected, amount)
      : shiftDay(selected, amount * (mode == CalendarMode.week ? 7 : 1));

  Future<void> pickDate() async {
    final date = await pickPlannerDate(context, selected, help: 'Go to date');
    if (date != null && mounted) choose(date);
  }

  @override
  Widget build(BuildContext context) {
    final week = mondayOf(selected);
    final days = List.generate(7, (i) => shiftDay(week, i));
    final classes = classesOn(selected);
    final pending = tasksOn(selected).where((t) => !t.completed).toList();
    final done = tasksOn(selected).where((t) => t.completed).toList();
    final heading = switch (mode) {
      CalendarMode.day => '${calendarDate(selected)}, ${selected.year}',
      CalendarMode.week => calendarWeekRange(week),
      CalendarMode.month =>
        '${fullMonthNames[selected.month - 1]} ${selected.year}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<CalendarMode>(
                segments: const [
                  ButtonSegment(value: CalendarMode.day, label: Text('Day')),
                  ButtonSegment(value: CalendarMode.week, label: Text('Week')),
                  ButtonSegment(
                    value: CalendarMode.month,
                    label: Text('Month'),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  selectedBackgroundColor: Colors.black,
                  selectedForegroundColor: Colors.white,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onSelectionChanged: (value) => choose(selected, value.single),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Go to today',
              onPressed: () => choose(today),
              icon: const Icon(Icons.today, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous ${mode.name}',
              onPressed: supportedDate(offset(-1))
                  ? () => choose(offset(-1))
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton(
                key: const ValueKey('calendar-period'),
                onPressed: pickDate,
                child: Text(
                  heading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next ${mode.name}',
              onPressed: supportedDate(offset(1))
                  ? () => choose(offset(1))
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (mode == CalendarMode.week) _weekStrip(days),
        if (mode == CalendarMode.month) _monthGrid(),
        if (mode != CalendarMode.month) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => DayTimeline(
              key: const ValueKey('weekly-timetable'),
              position: offsetMemory,
              onExpand: expand,
              days: mode == CalendarMode.week && constraints.maxWidth >= 860
                  ? days
                  : [selected],
              schedules: widget.schedules,
              now: widget.today ?? DateTime.now(),
              onOpen: widget.onOpenSchedule,
              onCreate: (date, time) => widget.onAddTimeSlot != null
                  ? widget.onAddTimeSlot!(date, time)
                  : widget.onAddSchedule(date),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '${weekdays[selected.weekday - 1]} · ${calendarDate(selected)}',
          key: const ValueKey('selected-day-title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        if (widget.schedules.isEmpty)
          const _CalendarEmpty(
            'No classes yet. Add your first class.',
            Icons.calendar_today,
          )
        else if (classes.isEmpty)
          const _CalendarEmpty(
            'No classes on this day.',
            Icons.event_available,
          ),
        ...classes.map(widget.scheduleCard),
        const SizedBox(height: 24),
        Text(
          'Due this day · ${pending.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          const _CalendarEmpty('No pending deadlines.', Icons.task_alt),
        ...pending.map(widget.taskCard),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Completed · ${done.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          ...done.map(widget.taskCard),
        ],
      ],
    );
  }

  Widget _weekStrip(List<DateTime> days) => Row(
    children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Semantics(
              label: dayLabel(days[i]),
              button: true,
              selected: sameDay(selected, days[i]),
              excludeSemantics: true,
              onTap: supportedDate(days[i]) ? () => choose(days[i]) : null,
              child: InkWell(
                key: ValueKey('calendar-day-$i'),
                borderRadius: BorderRadius.circular(12),
                onTap: supportedDate(days[i]) ? () => choose(days[i]) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sameDay(selected, days[i])
                        ? Colors.black
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sameDay(today, days[i])
                          ? Colors.black
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekdays[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 10,
                          color: sameDay(selected, days[i])
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${days[i].day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: sameDay(selected, days[i])
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        classesOn(days[i]).isNotEmpty ||
                                tasksOn(days[i]).isNotEmpty
                            ? Icons.circle
                            : Icons.remove,
                        size: 5,
                        color: sameDay(selected, days[i])
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  String dayLabel(DateTime day) =>
      '${weekdays[day.weekday - 1]}, ${calendarDate(day)}, ${day.year}, ${classesOn(day).length} classes, ${tasksOn(day).where((t) => !t.completed).length} deadlines';

  Widget _monthGrid() => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return Column(
        children: [
          Row(
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      weekday.substring(0, 3),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          GridView.count(
            key: const ValueKey('month-grid'),
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio:
                (constraints.maxWidth / 7 - 3) /
                ((wide ? 106 : 72) *
                    MediaQuery.textScalerOf(context).scale(13) /
                    13),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final day in monthDates(selected))
                Builder(
                  builder: (context) {
                    final active = sameDay(day, selected);
                    final classes = classesOn(day);
                    final deadlines = tasksOn(day)
                        .where((t) => !t.completed)
                        .length;
                    final foreground = active
                        ? Colors.white
                        : day.month == selected.month
                        ? Colors.black
                        : Colors.black38;
                    return Semantics(
                      label: dayLabel(day),
                      button: true,
                      selected: active,
                      excludeSemantics: true,
                      onTap: supportedDate(day)
                          ? () => choose(day, CalendarMode.day)
                          : null,
                      child: Material(
                        color: active ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: sameDay(day, today)
                                ? Colors.black
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey(
                            'month-day-${day.year}-${day.month}-${day.day}',
                          ),
                          onTap: supportedDate(day)
                              ? () => choose(day, CalendarMode.day)
                              : null,
                          child: Padding(
                            padding: EdgeInsets.all(wide ? 10 : 4),
                            child: Column(
                              crossAxisAlignment: wide
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: foreground,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (classes.isNotEmpty)
                                  if (wide)
                                    Text(
                                      classes.first.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: foreground,
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 10,
                                          color: foreground,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${classes.length}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: foreground,
                                          ),
                                        ),
                                      ],
                                    ),
                                if (deadlines > 0)
                                  Text(
                                    '$deadlines due',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: foreground,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Weekly classes · Dated deadlines',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      );
    },
  );
}

class _CalendarEmpty extends StatelessWidget {
  const _CalendarEmpty(this.message, this.icon);
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
