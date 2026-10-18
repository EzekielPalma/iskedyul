import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/calendar.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/main.dart';
import 'package:iskedyul/screens/day_timeline.dart';
import 'package:iskedyul/screens/screens.dart';
import 'package:iskedyul/screens/timetable_screen.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<AppState> start(WidgetTester tester) async {
  addTearDown(() => tester.pumpWidget(const SizedBox()));
  final state = AppState();
  state.calendarDate = DateTime(2026, 10, 19);
  await tester.pumpWidget(ISkedyulApp(state: state));
  await tap(tester, find.text('Get started'));
  return state;
}

Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

ScrollController gridController(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(
      find
          .descendant(
            of: find.byType(DayTimeline),
            matching: find.byType(SingleChildScrollView),
          )
          .last,
    )
    .controller!;

void main() {
  test('AM/PM labels cover midnight, noon, late night and next midnight', () {
    expect(time12(0), '12:00 AM');
    expect(time12(720), '12:00 PM');
    expect(time12(1439), '11:59 PM');
    expect(time12(1440), '12:00 AM');
  });
  testWidgets(
    'creation selection and saves replace their browser history entries',
    (tester) async {
      final messages = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        (call) async {
          messages.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.navigation,
          null,
        ),
      );
      await start(tester);
      await tap(tester, find.byType(FloatingActionButton));
      await tap(tester, find.text('Add class'));
      var update = messages.lastWhere(
        (m) => m.method == 'routeInformationUpdated',
      );
      expect((update.arguments as Map)['replace'], isTrue);
      await tester.enterText(find.byType(TextFormField).first, 'Project lab');
      await tap(tester, find.text('Save class'));
      update = messages.lastWhere((m) => m.method == 'routeInformationUpdated');
      expect((update.arguments as Map)['replace'], isTrue);
    },
  );
  testWidgets('welcome has concise copy and no old tagline', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(ISkedyulApp(state: AppState()));
    expect(find.textContaining('Klase,'), findsNothing);
    expect(find.text('Your week,\norganized.'), findsOneWidget);
  });
  testWidgets(
    'floating creation menu closes with Back and explains unavailable tasks',
    (tester) async {
      await start(tester);
      expect(find.text('Add class'), findsNothing);
      await tap(tester, find.byType(FloatingActionButton));
      expect(find.text('Add class'), findsOneWidget);
      expect(find.text('Add a class first.'), findsOneWidget);
      final taskOption = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Add task'),
      );
      expect(taskOption.enabled, isFalse);
      await back(tester);
      expect(find.byType(AddMenu), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );
  testWidgets(
    'Back dismisses a time picker then a form without saving its draft',
    (tester) async {
      final state = await start(tester);
      await tap(tester, find.byType(FloatingActionButton));
      await tap(tester, find.text('Add class'));
      await tester.enterText(find.byType(TextFormField).first, 'Unsaved class');
      await tap(tester, find.text('Start time: 9:00 AM'));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await back(tester);
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.text('Unsaved class'), findsOneWidget);
      await back(tester);
      expect(find.byType(ScheduleFormScreen), findsNothing);
      expect(state.schedules, isEmpty);
    },
  );
  testWidgets('Back dismisses date picker and deletion confirmation safely', (
    tester,
  ) async {
    final state = await start(tester);
    state.saveSchedule(
      Schedule(
        id: 1,
        subject: 'Project lab',
        weekday: 1,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 10, minute: 0),
      ),
    );
    await tap(tester, find.text('Calendar').last);
    await tap(tester, find.byKey(const ValueKey('calendar-period')));
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await back(tester);
    expect(find.byType(DatePickerDialog), findsNothing);
    final context = tester.element(find.byType(DashboardScreen));
    GoRouter.of(context).push<void>('/class/1');
    await tester.pumpAndSettle();
    await tap(tester, find.text('Delete class'));
    expect(find.text('Delete class?'), findsOneWidget);
    await back(tester);
    expect(find.text('Delete class?'), findsNothing);
    expect(state.schedules.length, 1);
    expect(find.text('Class details'), findsOneWidget);
  });
  for (final size in [
    const Size(320, 640),
    const Size(640, 320),
    const Size(1200, 800),
  ]) {
    testWidgets(
      'expanded week fits $size, scrolls horizontally and keeps its time position',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = await start(tester);
        await tap(tester, find.text('Calendar').last);
        expect(find.text('Oct 19 – Oct 25, 2026'), findsOneWidget);
        await tap(tester, find.byTooltip('Expand timetable'));
        expect(find.byType(TimetableScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        final horizontal = tester.widget<SingleChildScrollView>(
          find
              .descendant(
                of: find.byType(DayTimeline),
                matching: find.byType(SingleChildScrollView),
              )
              .at(1),
        );
        expect(horizontal.scrollDirection, Axis.horizontal);
        gridController(tester).jumpTo(720);
        await tester.pumpAndSettle();
        expect(state.timelineOffset.value, 720);
        await back(tester);
        expect(find.byType(TimetableScreen), findsNothing);
        expect(gridController(tester).offset, closeTo(720, .1));
        expect(find.text('Oct 19 – Oct 25, 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
