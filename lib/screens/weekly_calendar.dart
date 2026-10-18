import 'package:flutter/material.dart';

import '../data/calendar.dart';
import '../data/models.dart';

// This view derives dated occurrences from weekdays; it does not duplicate data.
class WeeklyCalendar extends StatefulWidget {
  const WeeklyCalendar({
    super.key,
    required this.schedules,
    required this.tasks,
    required this.scheduleCard,
    required this.taskCard,
    required this.onAddSchedule,
    required this.onAddTask,
    required this.onOpenSchedule,
    this.today,
  });
  final List<Schedule> schedules;
  final List<StudentTask> tasks;
  final Widget Function(Schedule) scheduleCard;
  final Widget Function(StudentTask) taskCard;
  final ValueChanged<DateTime> onAddSchedule;
  final ValueChanged<DateTime> onAddTask;
  final ValueChanged<Schedule> onOpenSchedule;
  final DateTime? today;
  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  late DateTime selected = dateOnly(widget.today ?? DateTime.now());
  late DateTime week = mondayOf(selected);
  DateTime get today => dateOnly(widget.today ?? DateTime.now());
  List<Schedule> classesOn(DateTime day) =>
      widget.schedules.where((s) => s.weekday == day.weekday).toList()
        ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
  List<StudentTask> tasksOn(DateTime day) =>
      widget.tasks.where((t) => sameDay(t.due, day)).toList()
        ..sort((a, b) => compareTasks(a, b, today));
  void changeWeek(int offset) => setState(() {
    week = shiftDay(week, offset * 7);
    selected = shiftDay(selected, offset * 7);
  });
  void goToday() => setState(() {
    selected = today;
    week = mondayOf(today);
  });
  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => shiftDay(week, i));
    final classes = classesOn(selected);
    final deadlines = tasksOn(selected);
    final pending = deadlines.where((t) => !t.completed).toList();
    final done = deadlines.where((t) => t.completed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                calendarWeekRange(week),
                key: const ValueKey('week-range'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Previous week',
              onPressed: () => changeWeek(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: () => changeWeek(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: goToday,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Today'),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    label:
                        '${weekdays[i]}, ${calendarDate(days[i])}, ${classesOn(days[i]).length} classes, ${tasksOn(days[i]).length} deadlines',
                    button: true,
                    selected: sameDay(selected, days[i]),
                    excludeSemantics: true,
                    onTap: () => setState(() => selected = days[i]),
                    child: InkWell(
                      key: ValueKey('calendar-day-$i'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => selected = days[i]),
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
                              weekdays[i].substring(0, 1),
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
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => widget.onAddSchedule(selected),
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
            ),
            OutlinedButton.icon(
              onPressed: widget.schedules.isEmpty
                  ? null
                  : () => widget.onAddTask(selected),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= 860 && widget.schedules.isNotEmpty
              ? _timetable(days)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        Text(
          '${weekdays[selected.weekday - 1]} · ${calendarDate(selected)}',
          key: const ValueKey('selected-day-title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        if (widget.schedules.isEmpty)
          const _CalendarEmpty(
            'No classes yet. Add your first schedule.',
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

  Widget _timetable(List<DateTime> days) {
    final hours = widget.schedules.map((s) => s.start.hour).toSet().toList()
      ..sort();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly timetable',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Table(
            key: const ValueKey('weekly-timetable'),
            columnWidths: const {0: FixedColumnWidth(66)},
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder.all(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Start', style: TextStyle(fontSize: 11)),
                  ),
                  for (final day in days)
                    InkWell(
                      onTap: () => setState(() => selected = day),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${weekdays[day.weekday - 1].substring(0, 3)} ${day.day}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              for (final hour in hours)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        clock(TimeOfDay(hour: hour, minute: 0)),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    for (final day in days)
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final schedule in classesOn(
                              day,
                            ).where((s) => s.start.hour == hour))
                              Card(
                                child: InkWell(
                                  onTap: () => widget.onOpenSchedule(schedule),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schedule.subject,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          '${clock(schedule.start)}\n${clock(schedule.end)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (!classesOn(day)
                                .any((s) => s.start.hour == hour))
                              const SizedBox(height: 46),
                          ],
                        ),
                      ),
                  ],
                ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('Due', style: TextStyle(fontSize: 10)),
                  ),
                  for (final day in days)
                    TextButton(
                      onPressed: () => setState(() => selected = day),
                      child: Text(
                        '${tasksOn(day).where((t) => !t.completed).length} tasks',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarEmpty extends StatelessWidget {
  const _CalendarEmpty(this.text, this.icon);
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    ),
  );
}
