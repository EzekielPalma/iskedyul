import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/calendar.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/main.dart';
import 'package:iskedyul/screens/screens.dart';
import 'package:iskedyul/screens/weekly_calendar.dart';

Schedule lesson(int id, String name, int day, int start, int end) => Schedule(
  id: id,
  subject: name,
  weekday: day,
  start: TimeOfDay(hour: start, minute: 0),
  end: TimeOfDay(hour: end, minute: 0),
);
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Next class refreshes from upcoming to in progress to the following class',
    (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      var now = DateTime(2026, 10, 19, 8, 59);
      final state = AppState();
      state.saveSchedule(lesson(1, 'First class', 1, 9, 10));
      state.saveSchedule(lesson(2, 'Later class', 1, 11, 12));
      state.saveTask(
        StudentTask(
          id: 3,
          title: 'Today deadline',
          scheduleId: 1,
          due: DateTime(2026, 10, 19),
          priority: Priority.high,
        ),
      );
      state.saveTask(
        StudentTask(
          id: 4,
          title: 'Tomorrow deadline',
          scheduleId: 1,
          due: DateTime(2026, 10, 20),
          priority: Priority.low,
        ),
      );
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(home: DashboardScreen(clock: () => now)),
        ),
      );
      expect(find.text('Next class'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Today deadline'), findsOneWidget);
      expect(find.text('Tomorrow deadline'), findsNothing);
      now = DateTime(2026, 10, 19, 9, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('In progress'), findsOneWidget);
      now = DateTime(2026, 10, 19, 10);
      await tester.pump(const Duration(minutes: 1));
      expect(
        find.descendant(
          of: find.byType(NextClassCard),
          matching: find.text('Later class'),
        ),
        findsOneWidget,
      );
      expect(find.text('In progress'), findsNothing);
      now = DateTime(2026, 10, 19, 11, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('In progress'), findsOneWidget);
    },
  );
  test('week dates cross month, year, and leap-day boundaries', () {
    expect(mondayOf(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
    expect(
      calendarWeekRange(DateTime(2026, 12, 28)),
      'Dec 28, 2026 – Jan 3, 2027',
    );
    expect(shiftDay(DateTime(2026, 12, 28), 7), DateTime(2027, 1, 4));
    expect(shiftDay(DateTime(2028, 2, 28), 1), DateTime(2028, 2, 29));
    expect(shiftDay(DateTime(2028, 2, 28), 2), DateTime(2028, 3, 1));
  });
  test('next class includes in-progress classes, excludes ended ones and repeats weekly', () {
    final now = DateTime(2026, 10, 19, 10);
    final ended = lesson(1, 'Earlier', 1, 8, 9);
    final current = lesson(2, 'Current', 1, 9, 11);
    final later = lesson(3, 'Later', 1, 12, 13);
    final tomorrow = lesson(4, 'Tomorrow', 2, 8, 9);
    expect(nextClass([ended, current, later, tomorrow], now)!.schedule.id, 2);
    expect(nextClass([ended, later, tomorrow], now)!.schedule.id, 3);
    expect(nextClass([ended], now)!.date, DateTime(2026, 10, 26));
    expect(
      nextClass([current], DateTime(2026, 10, 19, 11))!.date,
      DateTime(2026, 10, 26),
    );
    expect(nextClass([], now), isNull);
  });
  testWidgets(
    'calendar selects days, changes weeks, keeps repeating classes and dated deadlines',
    (tester) async {
      final monday = DateTime(2026, 12, 28);
      final schedules = [
        lesson(1, 'Monday lab', 1, 9, 10),
        lesson(2, 'Tuesday class', 2, 13, 14),
      ];
      final tasks = [
        StudentTask(
          id: 1,
          title: 'Monday deadline',
          scheduleId: 1,
          due: monday,
          priority: Priority.high,
        ),
      ];
      DateTime? selectedScheduleDate;
      Schedule? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyCalendar(
                today: monday,
                schedules: schedules,
                tasks: tasks,
                scheduleCard: (s) => Text(s.subject),
                taskCard: (t) => Text(t.title),
                onAddSchedule: (_) {},
                onSelectionChanged: (_, date) => selectedScheduleDate = date,
                onOpenSchedule: (s) => opened = s,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Monday lab'), findsNWidgets(2));
      expect(find.text('Monday deadline'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('calendar-day-1')));
      expect(find.text('Tuesday class'), findsNWidgets(2));
      expect(find.text('Monday deadline'), findsNothing);
      expect(selectedScheduleDate, DateTime(2026, 12, 29));
      await tap(tester, find.byTooltip('Next week'));
      expect(find.text('Tuesday class'), findsNWidgets(2));
      expect(find.text('Tuesday · Jan 5'), findsOneWidget);
      await tap(tester, find.byTooltip('Previous week'));
      expect(find.text('Tuesday · Dec 29'), findsOneWidget);
      await tap(tester, find.byTooltip('Go to today'));
      expect(find.text('Monday deadline'), findsOneWidget);
      expect(opened, isNull);
    },
  );
  testWidgets('desktop timetable shows classes as tappable events', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Schedule? opened;
    final monday = DateTime(2026, 10, 19);
    final schedule = lesson(1, 'Programming lab', 1, 9, 11);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeeklyCalendar(
              today: monday,
              schedules: [schedule],
              tasks: const [],
              scheduleCard: (s) => Text('Agenda: ${s.subject}'),
              taskCard: (t) => Text(t.title),
              onAddSchedule: (_) {},
              onOpenSchedule: (s) => opened = s,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('weekly-timetable')), findsOneWidget);
    await tap(tester, find.text('Programming lab'));
    expect(opened, same(schedule));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'calendar Add class prefills weekday and Add task prefills due date',
    (tester) async {
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      final state = AppState();
      state.saveSchedule(lesson(1, 'Existing class', 1, 9, 10));
      await tester.pumpWidget(ISkedyulApp(state: state));
      await tap(tester, find.text('Get started'));
      await tap(tester, find.text('Calendar').last);
      await tap(tester, find.byKey(const ValueKey('calendar-day-2')));
      await tap(tester, find.byType(FloatingActionButton));
      await tap(tester, find.text('Add class'));
      final weekday = tester.widget<DropdownButtonFormField<int>>(
        find.byType(DropdownButtonFormField<int>),
      );
      expect(weekday.initialValue, 3);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Wednesday review',
      );
      await tap(tester, find.text('Save class'));
      expect(state.schedules.last.weekday, 3);
      // A separate fresh route verifies the task's contextual date.
      final date = DateTime(2027, 1, 6);
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(
            home: TaskFormScreen(initialDue: date, scheduleId: 1),
          ),
        ),
      );
      expect(find.text('Due date: 1/6/2027'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Calendar task');
      await tap(tester, find.text('Save task'));
      expect(state.tasks.last.due, date);
      expect(state.tasks.last.scheduleId, 1);
    },
  );
}
