import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/main.dart';
import 'package:iskedyul/data/storage_contract.dart';
import 'package:iskedyul/screens/screens.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<AppState> start(WidgetTester tester) async {
  final state = AppState();
  await tester.pumpWidget(ISkedyulApp(state: state));
  await tapText(tester, 'Get Started');
  return state;
}

void main() {
  test('tasks sort overdue before priority, pending before completed', () {
    final today = DateTime(2026, 10, 18);
    StudentTask task(
      int id,
      int offset,
      Priority priority, {
      bool done = false,
    }) => StudentTask(
      id: id,
      title: 'Task $id',
      scheduleId: 1,
      due: today.add(Duration(days: offset)),
      priority: priority,
      completed: done,
    );
    final tasks = [
      task(1, 0, Priority.high),
      task(2, -1, Priority.low),
      task(3, 0, Priority.high, done: true),
      task(4, 3, Priority.low),
      task(5, 1, Priority.low),
    ];
    tasks.sort((a, b) => compareTasks(a, b, today));
    expect(tasks.map((t) => t.id), [2, 1, 5, 4, 3]);
  });
  testWidgets('returning visits open Today without onboarding', (tester) async {
    final storage = MemoryStorage();
    final original = AppState(storage: storage);
    original.saveNotes(1, 'Keep this note.');
    final restored = AppState(storage: storage);
    await tester.pumpWidget(ISkedyulApp(state: restored));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(restored.schedule(1).notes, 'Keep this note.');
  });
  testWidgets('welcome, dashboard, details, notes and completion', (
    tester,
  ) async {
    final state = await start(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    await tester.ensureVisible(find.byType(ScheduleCard).first);
    await tester.tap(find.byType(ScheduleCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Schedule Details'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    final task = state.tasks.first;
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(task.completed, isTrue);
    await tapText(tester, 'Edit notes');
    await tester.enterText(
      find.byType(TextField),
      'Bring the project notebook.',
    );
    await tapText(tester, 'Save notes');
    expect(state.schedule(1).notes, 'Bring the project notebook.');
  });
  testWidgets('schedule required field, create, confirmation and edit', (
    tester,
  ) async {
    final state = await start(tester);
    await tapText(tester, 'Add Schedule');
    await tapText(tester, 'Save Schedule');
    expect(find.text('Enter a subject or activity.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Study group');
    await tapText(tester, 'Save Schedule');
    expect(find.text('Schedule saved.'), findsOneWidget);
    expect(state.schedules.length, 4);
    await tapText(tester, 'View Schedule');
    expect(find.text('Study group'), findsOneWidget);
    await tapText(tester, 'Edit Schedule');
    await tester.enterText(find.byType(TextFormField).first, 'Solo study');
    await tapText(tester, 'Save Schedule');
    expect(state.schedules.last.subject, 'Solo study');
    expect(state.schedules.length, 4);
    await tapText(tester, 'Back to Today');
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
  testWidgets('schedule rejects end before start', (tester) async {
    final state = AppState();
    state.schedules.add(
      Schedule(
        id: 20,
        subject: 'Invalid time demo',
        weekday: 1,
        start: const TimeOfDay(hour: 12, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ),
    );
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          home: ScheduleFormScreen(schedule: state.schedule(20)),
        ),
      ),
    );
    await tapText(tester, 'Save Schedule');
    expect(find.text('End time must follow start time.'), findsOneWidget);
    expect(find.text('Schedule saved.'), findsNothing);
  });
  testWidgets('task validation, link, create, edit and completion retained', (
    tester,
  ) async {
    final state = await start(tester);
    await tapText(tester, 'Add Task');
    await tapText(tester, 'Save Task');
    expect(find.text('Enter a task title.'), findsOneWidget);
    expect(find.text('Choose a linked schedule.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Read chapter five',
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(
      find.textContaining('Mobile Application Development ·').last,
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Save Task');
    expect(find.text('Task saved.'), findsOneWidget);
    expect(state.tasks.last.scheduleId, 1);
    await tapText(tester, 'View Schedule');
    await tapText(tester, 'Read chapter five');
    await tester.enterText(
      find.byType(TextFormField).first,
      'Read chapter six',
    );
    await tapText(tester, 'Save Task');
    expect(state.tasks.last.title, 'Read chapter six');
    expect(state.tasks.length, 5);
  });
  testWidgets('cancel leaves schedule state unchanged', (tester) async {
    final state = await start(tester);
    await tapText(tester, 'Add Schedule');
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved class');
    await tapText(tester, 'Cancel');
    expect(state.schedules.length, 3);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
  testWidgets(
    'schedule deletion requires confirmation, cancels safely and cascades',
    (tester) async {
      final state = await start(tester);
      await tester.ensureVisible(find.byType(ScheduleCard).first);
      await tester.tap(find.byType(ScheduleCard).first);
      await tester.pumpAndSettle();
      await tapText(tester, 'Delete Schedule');
      expect(find.textContaining('linked task(s) and notes'), findsOneWidget);
      await tapText(tester, 'Cancel');
      expect(state.schedules.length, 3);
      await tapText(tester, 'Delete Schedule');
      await tapText(tester, 'Delete');
      expect(state.schedules.length, 2);
      expect(state.tasks.any((t) => t.scheduleId == 1), isFalse);
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );
  testWidgets(
    'task deletion requires confirmation and completed tasks have a separate section',
    (tester) async {
      final state = await start(tester);
      await tapText(tester, 'Tasks');
      expect(find.text('Completed · 1'), findsOneWidget);
      await tapText(tester, 'Read the project brief');
      await tapText(tester, 'Delete Task');
      await tapText(tester, 'Cancel');
      expect(state.tasks.length, 4);
      await tapText(tester, 'Delete Task');
      await tapText(tester, 'Delete');
      expect(state.tasks.length, 3);
      await tapText(tester, 'Tasks');
      expect(find.text('No completed tasks yet.'), findsOneWidget);
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(640, 320),
    const Size(1200, 800),
  ]) {
    testWidgets('screens fit $size without overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await start(tester);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Week');
      expect(find.text('Your weekly schedule'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Tasks');
      expect(find.text('To do · 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Today');
      await tapText(tester, 'Add Task');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Cancel');
      await tapText(tester, 'Add Schedule');
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Landscape study',
      );
      await tapText(tester, 'Save Schedule');
      expect(tester.takeException(), isNull);
      await tapText(tester, 'View Schedule');
      expect(tester.takeException(), isNull);
    });
  }
}
