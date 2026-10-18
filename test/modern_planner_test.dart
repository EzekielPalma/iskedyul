import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/calendar.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/screens/day_timeline.dart';
import 'package:iskedyul/screens/screens.dart';
import 'package:iskedyul/screens/weekly_calendar.dart';

Schedule lesson(int id, int start, int end) => Schedule(
  id: id,
  subject: 'Class $id',
  weekday: 1,
  start: TimeOfDay(hour: start ~/ 60, minute: start % 60),
  end: TimeOfDay(hour: end ~/ 60, minute: end % 60),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget calendar({
  CalendarMode mode = CalendarMode.week,
  DateTime? date,
  List<Schedule> schedules = const [],
  List<StudentTask> tasks = const [],
  void Function(DateTime, TimeOfDay)? onSlot,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: WeeklyCalendar(
        today: DateTime(2026, 10, 19, 9),
        initialDate: date,
        initialMode: mode,
        schedules: schedules,
        tasks: tasks,
        scheduleCard: (s) => Text('Agenda ${s.subject}'),
        taskCard: (t) => Text(t.title),
        onAddSchedule: (_) {},
        onOpenSchedule: (_) {},
        onAddTimeSlot: onSlot,
      ),
    ),
  ),
);

void main() {
  test('month arithmetic clamps dates and lays out Monday-first cells', () {
    expect(shiftMonth(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
    expect(shiftMonth(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    expect(shiftMonth(DateTime(2027, 1, 12), -1), DateTime(2026, 12, 12));
    final cells = monthDates(DateTime(2026, 11, 1));
    expect(cells.first, DateTime(2026, 10, 26));
    expect(cells.last, DateTime(2026, 12, 6));
    expect(cells.length, 42);
    expect(monthDates(DateTime(2027, 2)).length, 28);
  });
  test(
    'overlapping events use separate lanes and adjacent events use full width',
    () {
      final lanes = eventLanes([
        lesson(1, 540, 660),
        lesson(2, 570, 630),
        lesson(3, 660, 720),
      ]);
      expect(lanes.map((e) => e.lanes), [2, 2, 1]);
      expect(lanes.map((e) => e.lane), [0, 1, 0]);
      expect(eventLanes([]), isEmpty);
    },
  );
  testWidgets(
    'summary cards open daily classes and separate pending/completed filters',
    (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      final state = AppState();
      state.saveSchedule(lesson(1, 540, 600));
      for (final completed in [false, true]) {
        state.saveTask(
          StudentTask(
            id: completed ? 2 : 1,
            title: completed ? 'Finished report' : 'Write report',
            scheduleId: 1,
            due: DateTime(2026, 10, 19),
            priority: Priority.high,
            completed: completed,
          ),
        );
      }
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            home: DashboardScreen(clock: () => DateTime(2026, 10, 19)),
          ),
        ),
      );
      await tap(tester, find.byKey(const ValueKey('summary-done')));
      expect(find.text('Finished report'), findsOneWidget);
      expect(find.text('Write report'), findsNothing);
      await tap(tester, find.text('To do · 1'));
      expect(find.text('Finished report'), findsNothing);
      expect(find.text('Write report'), findsOneWidget);
      await tap(tester, find.text('Today').last);
      await tap(tester, find.byKey(const ValueKey('summary-todo')));
      expect(find.text('Write report'), findsOneWidget);
      await tap(tester, find.text('Today').last);
      await tap(tester, find.byKey(const ValueKey('summary-classes')));
      final segmented = tester.widget<SegmentedButton<CalendarMode>>(
        find.byType(SegmentedButton<CalendarMode>),
      );
      expect(segmented.selected, {CalendarMode.day});
      expect(find.text('Monday · Oct 19'), findsOneWidget);
    },
  );
  testWidgets(
    'month browsing changes months and a date opens its daily agenda',
    (tester) async {
      await tester.pumpWidget(
        calendar(
          mode: CalendarMode.month,
          date: DateTime(2026, 12, 31),
          schedules: [lesson(1, 540, 600)],
        ),
      );
      expect(find.text('December 2026'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      await tap(tester, find.byTooltip('Next month'));
      expect(find.text('January 2027'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('month-day-2027-1-4')));
      expect(find.byKey(const ValueKey('month-grid')), findsNothing);
      expect(find.byType(DayTimeline), findsOneWidget);
      expect(find.text('Monday · Jan 4'), findsOneWidget);
      await tap(tester, find.byTooltip('Next day'));
      expect(find.text('Tuesday · Jan 5'), findsOneWidget);
      await tap(tester, find.byTooltip('Go to today'));
      expect(find.text('Monday · Oct 19'), findsOneWidget);
    },
  );
  testWidgets(
    'calendar period opens date picker and can jump to another year',
    (tester) async {
      await tester.pumpWidget(calendar(mode: CalendarMode.month));
      await tap(tester, find.byKey(const ValueKey('calendar-period')));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tap(tester, find.text('October 2026').last);
      await tap(tester, find.text('2027').last);
      await tap(tester, find.text('OK'));
      expect(find.text('October 2027'), findsOneWidget);
    },
  );
  testWidgets(
    'events use exact start/duration and empty slots select half-hour times',
    (tester) async {
      final date = DateTime(2026, 10, 19);
      DateTime? chosenDate;
      TimeOfDay? chosenTime;
      await tester.pumpWidget(
        calendar(
          mode: CalendarMode.day,
          schedules: [lesson(1, 570, 660)],
          onSlot: (day, time) {
            chosenDate = day;
            chosenTime = time;
          },
        ),
      );
      final event = tester.widget<Positioned>(
        find.byKey(ValueKey('timeline-event-${date.toIso8601String()}-1')),
      );
      expect(event.top, 9.5 * 72);
      expect(event.height, 1.5 * 72);
      final grid = find.byKey(const ValueKey('timeline-grid'));
      await tester.ensureVisible(find.byType(DayTimeline));
      final position = tester.getTopLeft(grid);
      await tester.tapAt(position + const Offset(80, 8.5 * 72 + 3));
      await tester.pumpAndSettle();
      expect(chosenDate, date);
      expect(chosenTime, const TimeOfDay(hour: 8, minute: 30));
    },
  );
  testWidgets('empty timetable scrolls through all 24 hours', (tester) async {
    await tester.pumpWidget(calendar(mode: CalendarMode.day));
    final timeline = find.byType(DayTimeline);
    final view = find
        .descendant(of: timeline, matching: find.byType(SingleChildScrollView))
        .last;
    final controller = tester.widget<SingleChildScrollView>(view).controller!;
    await tester.ensureVisible(view);
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('12:00 AM').hitTestable(), findsOneWidget);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('12:00 AM').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'late slots stay reachable and the footer never creates phantom classes',
    (tester) async {
      TimeOfDay? chosen;
      await tester.pumpWidget(
        calendar(mode: CalendarMode.day, onSlot: (_, time) => chosen = time),
      );
      final view = find
          .descendant(
            of: find.byType(DayTimeline),
            matching: find.byType(SingleChildScrollView),
          )
          .last;
      await tester.ensureVisible(view);
      final controller = tester.widget<SingleChildScrollView>(view).controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(
        find.byKey(const ValueKey('timeline-grid')),
      );
      await tester.tapAt(top + const Offset(100, 23.5 * 72 + 4));
      await tester.pumpAndSettle();
      expect(chosen, const TimeOfDay(hour: 23, minute: 30));
      chosen = null;
      await tester.tapAt(top + const Offset(100, 24 * 72 + 50));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    },
  );
  testWidgets('late time-slot class saves valid contextual times', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(
          home: ScheduleFormScreen(
            initialWeekday: 5,
            initialStart: TimeOfDay(hour: 23, minute: 30),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Evening review');
    await tap(tester, find.text('Save class'));
    expect(state.schedules.single.weekday, 5);
    expect(minutes(state.schedules.single.start), 1410);
    expect(minutes(state.schedules.single.end), 1439);
  });
  testWidgets('navigation disables dates outside supported range', (
    tester,
  ) async {
    await tester.pumpWidget(
      calendar(mode: CalendarMode.day, date: DateTime(2100, 12, 31)),
    );
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNull);
  });
  for (final size in [
    const Size(320, 640),
    const Size(640, 320),
    const Size(1200, 800),
  ]) {
    testWidgets(
      'all calendar modes fit $size with short and overlapping classes',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          calendar(
            schedules: [
              lesson(1, 540, 541),
              lesson(2, 540, 600),
              lesson(3, 600, 720),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        await tap(tester, find.text('Month'));
        expect(tester.takeException(), isNull);
        await tap(tester, find.text('Day'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
