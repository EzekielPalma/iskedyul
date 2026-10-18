import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../data/calendar.dart';
import 'weekly_calendar.dart';
import 'dialog_routes.dart';

String? screenLocation(Widget screen) => switch (screen) {
  ScheduleDetailsScreen(:final id) => '/class/$id',
  ScheduleFormScreen(
    :final schedule,
    :final initialWeekday,
    :final initialStart,
  ) =>
    schedule != null
        ? '/class/${schedule.id}/edit'
        : Uri(
            path: '/class/new',
            queryParameters: {
              if (initialWeekday != null) 'weekday': '$initialWeekday',
              if (initialStart != null) 'time': '${minutes(initialStart)}',
            },
          ).toString(),
  TaskFormScreen(:final task, :final scheduleId, :final initialDue) =>
    task != null
        ? '/task/${task.id}/edit'
        : Uri(
            path: '/task/new',
            queryParameters: {
              if (scheduleId != null) 'class': '$scheduleId',
              if (initialDue != null)
                'date': initialDue.toIso8601String().split('T').first,
            },
          ).toString(),
  ConfirmationScreen(:final scheduleId, :final message) =>
    '/saved/$scheduleId?kind=${message.startsWith('Task') ? 'task' : 'class'}',
  _ => null,
};
void open(BuildContext context, Widget screen) {
  final router = GoRouter.maybeOf(context);
  final location = screenLocation(screen);
  if (router != null && location != null) {
    router.push<void>(location);
  } else {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

void replaceScreen(BuildContext context, Widget screen) {
  final router = GoRouter.maybeOf(context);
  final location = screenLocation(screen);
  if (router != null && location != null) {
    // Replace browser history too, so Back skips the dismissed creation menu
    // and a saved form never returns as an unsaved draft.
    Router.neglect(context, () => router.replace<void>(location));
  } else {
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

void dashboard(BuildContext context) {
  AppScope.of(context).isReturning = true;
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    Router.neglect(context, () => router.go('/?tab=today'));
  } else {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }
}

class CreateFab extends StatelessWidget {
  const CreateFab({super.key, this.date});
  final DateTime? date;
  @override
  Widget build(BuildContext context) => FloatingActionButton(
    tooltip: 'Add',
    heroTag: null,
    onPressed: () {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        router.push<void>(
          Uri(
            path: '/add',
            queryParameters: {
              if (date != null)
                'date': date!.toIso8601String().split('T').first,
            },
          ).toString(),
        );
      } else {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => AddMenu(date: date),
        );
      }
    },
    child: const Icon(Icons.add),
  );
}

class AddMenuPage extends Page<void> {
  const AddMenuPage({super.key, this.date});
  final DateTime? date;
  @override
  Route<void> createRoute(BuildContext context) => ModalBottomSheetRoute<void>(
    settings: this,
    isScrollControlled: false,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => AddMenu(date: date),
  );
}

class AddMenu extends StatelessWidget {
  const AddMenu({super.key, this.date});
  final DateTime? date;
  @override
  Widget build(BuildContext context) {
    final hasClasses = AppScope.of(context).schedules.isNotEmpty;
    void choose(Widget screen) {
      if (GoRouter.maybeOf(context) != null) {
        replaceScreen(context, screen);
      } else {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Add class'),
              onTap: () =>
                  choose(ScheduleFormScreen(initialWeekday: date?.weekday)),
            ),
            ListTile(
              enabled: hasClasses,
              leading: const Icon(Icons.task_alt),
              title: const Text('Add task'),
              subtitle: hasClasses ? null : const Text('Add a class first.'),
              onTap: hasClasses
                  ? () => choose(TaskFormScreen(initialDue: date))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(
  BuildContext context,
  String title,
  String message,
) async =>
    await plannerDialog<bool>(
      context,
      Uri(
        path: '/confirm-delete',
        queryParameters: {'title': title, 'message': message},
      ),
      (context) => deleteDialog(context, title, message),
    ) ??
    false;

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.children,
    this.navigation,
    this.floatingActionButton,
    this.scrollController,
    this.maxWidth = 820,
  });
  final String title;
  final List<Widget> children;
  final Widget? navigation;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: title == 'iSkedyul'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'iSkedyul',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            )
          : Text(title),
    ),
    bottomNavigationBar: navigation,
    floatingActionButton: floatingActionButton,
    body: SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        floatingActionButton == null ? 36 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: title == 'iSkedyul' ? maxWidth : 640,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (AppScope.of(context).storageWarning case final warning?) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(warning),
                  ),
                ),
              ],
              if (AppScope.of(context).recoveryMessage case final message?) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(message),
                  ),
                ),
              ],
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class Section extends StatelessWidget {
  const Section(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'iSkedyul',
    children: [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME',
              style: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 10,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Your week,\norganized.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: List.generate(
                7,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: i == 2 ? Colors.white : const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdays[i].substring(0, 3),
                          style: TextStyle(
                            color: i == 2 ? Colors.black : Colors.white,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Icon(
                          i == 2 ? Icons.check : Icons.remove,
                          size: 15,
                          color: i == 2
                              ? Colors.black
                              : const Color(0xFF777777),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          FeatureLabel(Icons.calendar_today, 'Classes'),
          FeatureLabel(Icons.task_alt, 'Tasks'),
          FeatureLabel(Icons.notes, 'Notes'),
        ],
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: () => dashboard(context),
        child: const Text('Get started'),
      ),
      const SizedBox(height: 14),
      const Text(
        'No account. Just your week.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
      ),
    ],
  );
}

class FeatureLabel extends StatelessWidget {
  const FeatureLabel(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key, this.icon = Icons.task_alt});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF888888), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF666666), height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.clock,
    this.initialTab = 0,
    this.initialMode,
    this.initialDate,
    this.initialDone = false,
  });
  final DateTime Function()? clock;
  final int initialTab;
  final CalendarMode? initialMode;
  final DateTime? initialDate;
  final bool initialDone;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  late int tab = widget.initialTab;
  late bool showDone = widget.initialDone;
  CalendarMode calendarMode = CalendarMode.week;
  DateTime? calendarSelection;
  late final Timer clockTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  bool restoredView = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!restoredView) {
      final state = AppScope.of(context);
      calendarMode = widget.initialMode ?? state.calendarMode;
      calendarSelection = widget.initialDate ?? state.calendarDate;
      restoredView = true;
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    tab = widget.initialTab;
    showDone = widget.initialDone;
    calendarMode = widget.initialMode ?? calendarMode;
    calendarSelection = widget.initialDate ?? calendarSelection;
  }

  String rootLocation() => Uri(
    path: '/',
    queryParameters: {
      'tab': ['today', 'calendar', 'tasks'][tab],
      if (showDone) 'done': '1',
      'view': calendarMode.name,
      if (calendarSelection != null)
        'date': calendarSelection!.toIso8601String().split('T').first,
    },
  ).toString();
  void updateUrl() {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      Router.neglect(context, () => router.go(rootLocation()));
    }
  }

  final scroll = ScrollController();
  @override
  void dispose() {
    clockTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    scroll.dispose();
    super.dispose();
  }

  void select(int value) {
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() => tab = value);
    GoRouter.maybeOf(context)?.go(rootLocation());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = widget.clock?.call() ?? DateTime.now();
    final todays =
        state.schedules.where((s) => s.weekday == today.weekday).toList()
          ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
    final upcoming = nextClass(state.schedules, today);
    final dueToday = state
        .sortedTasks()
        .where((t) => !t.completed && sameDay(t.due, today))
        .toList();
    final pending = state.sortedTasks().where((t) => !t.completed).toList();
    final done = state.sortedTasks().where((t) => t.completed).toList();
    final urgent = pending
        .where(
          (t) =>
              !sameDay(t.due, today) &&
              (overdue(t, today) ||
                  t.priority == Priority.high ||
                  !dateOnly(t.due).isAfter(dateOnly(today))),
        )
        .toList();
    const months = [
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
    return PageFrame(
      title: 'iSkedyul',
      maxWidth: tab == 1 ? 1120 : 820,
      scrollController: scroll,
      floatingActionButton: CreateFab(
        date: tab == 1 ? calendarSelection : null,
      ),
      navigation: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
        ],
      ),
      children: [
        if (tab != 1) ...[
          const SizedBox(height: 12),
          Text(
            '${weekdays[today.weekday - 1].toUpperCase()}  /  ${months[today.month - 1].toUpperCase()} ${today.day}',
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.8,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          ['Today', 'Calendar', 'Tasks'][tab],
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 22),
        if (tab == 0) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SummaryCard(
                  key: const ValueKey('summary-classes'),
                  count: todays.length,
                  label: 'Classes today',
                  icon: Icons.today,
                  onTap: () {
                    calendarMode = CalendarMode.day;
                    calendarSelection = dateOnly(today);
                    select(1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryCard(
                  key: const ValueKey('summary-todo'),
                  count: pending.length,
                  label: 'To do',
                  icon: Icons.checklist,
                  onTap: () {
                    showDone = false;
                    select(2);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SummaryCard(
                  key: const ValueKey('summary-done'),
                  count: done.length,
                  label: 'Done',
                  icon: Icons.task_alt,
                  onTap: () {
                    showDone = true;
                    select(2);
                  },
                ),
              ),
            ],
          ),
          if (state.tasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${done.length} of ${state.tasks.length} tasks complete',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                Text(
                  '${(done.length / state.tasks.length * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: done.length / state.tasks.length,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: const Color(0xFFE3E3E3),
              color: Colors.black,
              semanticsLabel: 'Completed tasks',
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (tab == 0) ...[
          if (upcoming != null) ...[
            const SizedBox(height: 24),
            NextClassCard(occurrence: upcoming, now: today),
          ],
          const Section('Due today'),
          if (dueToday.isEmpty)
            const EmptyCard('No deadlines today.', icon: Icons.task_alt),
          ...dueToday.map((t) => TaskCard(task: t)),
          const Section('On your schedule'),
          if (todays.isEmpty)
            const EmptyCard('No classes today.', icon: Icons.event_available),
          ...todays.map((s) => ScheduleCard(schedule: s)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Section('Needs attention')),
              TextButton(
                onPressed: () {
                  showDone = false;
                  select(2);
                },
                child: const Text('View all'),
              ),
            ],
          ),
          if (urgent.isEmpty) const EmptyCard('You’re all caught up.'),
          ...urgent.take(3).map((t) => TaskCard(task: t)),
          if (urgent.length > 3)
            TextButton(
              onPressed: () {
                showDone = false;
                select(2);
              },
              child: Text('View ${urgent.length - 3} more'),
            ),
        ],
        if (tab == 1) ...[
          WeeklyCalendar(
            today: today,
            timelineOffset: state.timelineOffset,
            initialMode: calendarMode,
            initialDate: calendarSelection,
            onSelectionChanged: (mode, date) {
              if (calendarSelection == null ||
                  !sameDay(calendarSelection!, date)) {
                state.timelineOffset.value = null;
              }
              calendarMode = state.calendarMode = mode;
              calendarSelection = state.calendarDate = date;
              updateUrl();
            },
            onAddTimeSlot: (date, time) => open(
              context,
              ScheduleFormScreen(
                initialWeekday: date.weekday,
                initialStart: time,
              ),
            ),
            schedules: state.schedules,
            tasks: state.sortedTasks(),
            scheduleCard: (s) => ScheduleCard(schedule: s),
            taskCard: (t) => TaskCard(task: t),
            onOpenSchedule: (s) =>
                open(context, ScheduleDetailsScreen(id: s.id)),
            onAddSchedule: (date) =>
                open(context, ScheduleFormScreen(initialWeekday: date.weekday)),
          ),
          if (state.schedules.isNotEmpty || state.tasks.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await confirmDelete(
                    context,
                    'Clear planner?',
                    'Delete all classes, tasks, and notes? This can’t be undone.',
                  );
                  if (confirmed && context.mounted) state.clearPlanner();
                },
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear planner'),
              ),
            ),
        ],
        if (tab == 2) ...[
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            key: const ValueKey('task-filter'),
            segments: [
              ButtonSegment(
                value: false,
                label: Text('To do · ${pending.length}'),
              ),
              ButtonSegment(value: true, label: Text('Done · ${done.length}')),
            ],
            showSelectedIcon: false,
            selected: {showDone},
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(0, 48),
              selectedBackgroundColor: Colors.black,
              selectedForegroundColor: Colors.white,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onSelectionChanged: (value) {
              setState(() => showDone = value.single);
              updateUrl();
            },
          ),
          const SizedBox(height: 16),
          if (showDone && done.isEmpty)
            const EmptyCard('No completed tasks yet.'),
          if (!showDone && pending.isEmpty)
            const EmptyCard('You’re all caught up.'),
          ...(showDone ? done : pending).map((t) => TaskCard(task: t)),
        ],
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final int count;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count $label. Open $label.',
    button: true,
    excludeSemantics: true,
    onTap: onTap,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19, color: Colors.black54),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.black45,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(11) / 11 * 34,
                child: Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.dark = false, this.icon});
  final String label;
  final bool dark;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 12,
            color: dark ? Colors.white : const Color(0xFF555555),
          ),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: dark ? Colors.white : const Color(0xFF555555),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.schedule});
  final Schedule schedule;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => open(context, ScheduleDetailsScreen(id: schedule.id)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clock(schedule.start),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clock(schedule.end),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Container(width: 2, height: 40, color: const Color(0xFF222222)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    weekdays[schedule.weekday - 1],
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 12, color: Color(0xFF888888)),
          ],
        ),
      ),
    ),
  );
}

String dueLabel(DateTime due) {
  final now = DateTime.now();
  final days = DateTime.utc(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return shortDate(due);
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final StudentTask task;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isLate = overdue(task, DateTime.now());
    final priority = task.priority.name;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Checkbox(
                value: task.completed,
                semanticLabel: 'Complete ${task.title}',
                onChanged: (_) => state.toggleTask(task),
              ),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(context, TaskFormScreen(task: task)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                                color: task.completed
                                    ? const Color(0xFF777777)
                                    : Colors.black,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.edit,
                            size: 15,
                            color: Color(0xFF888888),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        state.schedule(task.scheduleId).subject,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777777),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            '${priority[0].toUpperCase()}${priority.substring(1)}',
                            icon: task.priority == Priority.high
                                ? Icons.priority_high
                                : task.priority == Priority.low
                                ? Icons.low_priority
                                : Icons.drag_handle,
                            dark:
                                task.priority == Priority.high &&
                                !task.completed,
                          ),
                          if (isLate) const StatusPill('Overdue', dark: true),
                          Text(
                            task.completed ? 'Done' : dueLabel(task.due),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleDetailsScreen extends StatelessWidget {
  const ScheduleDetailsScreen({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.schedules.any((s) => s.id == id)) {
      return PageFrame(
        title: 'Class unavailable',
        children: [
          const Text('This schedule was deleted.'),
          TextButton(
            onPressed: () => dashboard(context),
            child: const Text('Back to today'),
          ),
        ],
      );
    }
    final schedule = state.schedule(id);
    final tasks = state.sortedTasks(scheduleId: id);
    return PageFrame(
      title: 'Class details',
      children: [
        const SizedBox(height: 12),
        Text(
          schedule.subject,
          style: const TextStyle(
            fontSize: 26,
            height: 1.3,
            letterSpacing: -1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text('${weekdays[schedule.weekday - 1]} · Every week'),
        const SizedBox(height: 8),
        Text(
          '${clock(schedule.start)} – ${clock(schedule.end)}',
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  open(context, ScheduleFormScreen(schedule: schedule)),
              icon: const Icon(Icons.edit),
              label: const Text('Edit class'),
            ),
            FilledButton.icon(
              onPressed: () => open(context, TaskFormScreen(scheduleId: id)),
              icon: const Icon(Icons.add),
              label: const Text('Add task'),
            ),
          ],
        ),
        Section('To do · ${tasks.where((t) => !t.completed).length}'),
        if (!tasks.any((t) => !t.completed)) const Text('No pending tasks.'),
        ...tasks.where((t) => !t.completed).map((t) => TaskCard(task: t)),
        Section('Completed · ${tasks.where((t) => t.completed).length}'),
        if (!tasks.any((t) => t.completed))
          const Text('No completed tasks yet.'),
        ...tasks.where((t) => t.completed).map((t) => TaskCard(task: t)),
        const Section('Notes'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              schedule.notes.isEmpty ? 'No notes yet.' : schedule.notes,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final value = await plannerDialog<String>(
                context,
                Uri(path: '/class/$id/notes'),
                (_) => NotesDialog(notes: schedule.notes),
              );
              if (value != null) state.saveNotes(id, value);
            },
            icon: const Icon(Icons.notes),
            label: const Text('Edit notes'),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final confirmed = await confirmDelete(
              context,
              'Delete class?',
              'Delete “${schedule.subject}” and its ${tasks.length} linked task(s) and notes? This can’t be undone.',
            );
            if (!context.mounted || !confirmed) return;
            state.deleteSchedule(id);
            dashboard(context);
          },
          icon: const Icon(Icons.delete),
          label: const Text('Delete class'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => dashboard(context),
          child: const Text('Back to today'),
        ),
      ],
    );
  }
}

class NotesDialog extends StatefulWidget {
  const NotesDialog({super.key, required this.notes});
  final String notes;
  @override
  State<NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<NotesDialog> {
  late final controller = TextEditingController(text: widget.notes);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit notes'),
    content: SingleChildScrollView(
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        maxLength: 2000,
        decoration: const InputDecoration(labelText: 'Plain-text notes'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text('Save notes'),
      ),
    ],
  );
}

class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({
    super.key,
    this.schedule,
    this.initialWeekday,
    this.initialStart,
  });
  final Schedule? schedule;
  final int? initialWeekday;
  final TimeOfDay? initialStart;
  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final form = GlobalKey<FormState>();
  late final subject = TextEditingController(
    text: widget.schedule?.subject ?? '',
  );
  late int day =
      widget.schedule?.weekday ??
      widget.initialWeekday ??
      DateTime.now().weekday;
  late TimeOfDay start =
      widget.schedule?.start ??
      widget.initialStart ??
      const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay end =
      widget.schedule?.end ??
      TimeOfDay(
        hour: ((minutes(start) + 60).clamp(0, 1439)) ~/ 60,
        minute: ((minutes(start) + 60).clamp(0, 1439)) % 60,
      );
  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final time = await pickPlannerTime(context, isStart ? start : end);
    if (time != null && mounted) {
      setState(() {
        if (isStart) {
          start = time;
        } else {
          end = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: widget.schedule == null ? 'Add class' : 'Edit class',
    children: [
      const Text('Repeats weekly.'),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: subject,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Subject / activity',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a subject or activity.'
                  : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: day,
              decoration: const InputDecoration(labelText: 'Weekday'),
              items: [
                for (var i = 1; i <= 7; i++)
                  DropdownMenuItem(value: i, child: Text(weekdays[i - 1])),
              ],
              onChanged: (v) => setState(() => day = v!),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => pickTime(true),
              icon: const Icon(Icons.schedule),
              label: Text('Start time: ${clock(start)}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => pickTime(false),
              icon: const Icon(Icons.schedule),
              label: Text('End time: ${clock(end)}'),
            ),
            FormField<void>(
              validator: (_) => minutes(end) <= minutes(start)
                  ? 'End time must follow start time.'
                  : null,
              builder: (field) => field.hasError
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                final state = AppScope.of(context);
                final id = widget.schedule?.id ?? state.newId();
                state.saveSchedule(
                  Schedule(
                    id: id,
                    subject: subject.text.trim(),
                    weekday: day,
                    start: start,
                    end: end,
                    notes: widget.schedule?.notes ?? '',
                  ),
                );
                replaceScreen(
                  context,
                  ConfirmationScreen(message: 'Class saved.', scheduleId: id),
                );
              },
              child: const Text('Save class'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ],
  );
}

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    this.task,
    this.scheduleId,
    this.initialDue,
  });
  final StudentTask? task;
  final int? scheduleId;
  final DateTime? initialDue;
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title ?? '');
  int? scheduleId;
  late DateTime due = dateOnly(
    widget.task?.due ?? widget.initialDue ?? DateTime.now(),
  );
  late Priority priority = widget.task?.priority ?? Priority.medium;
  @override
  void initState() {
    super.initState();
    scheduleId = widget.task?.scheduleId ?? widget.scheduleId;
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return PageFrame(
      title: widget.task == null ? 'Add task' : 'Edit task',
      children: [
        const Text('What needs doing?'),
        const SizedBox(height: 24),
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Task title'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a task title.'
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: scheduleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Linked class'),
                items: state.schedules
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.subject} · ${weekdays[s.weekday - 1]}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => scheduleId = v),
                validator: (v) => v == null ? 'Choose a linked class.' : null,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickPlannerDate(context, due);
                  if (picked != null && mounted) setState(() => due = picked);
                },
                icon: const Icon(Icons.event),
                label: Text('Due date: ${shortDate(due)}'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Priority>(
                initialValue: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: Priority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => priority = v!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (!form.currentState!.validate()) return;
                  state.saveTask(
                    StudentTask(
                      id: widget.task?.id ?? state.newId(),
                      title: title.text.trim(),
                      scheduleId: scheduleId!,
                      due: due,
                      priority: priority,
                      completed: widget.task?.completed ?? false,
                    ),
                  );
                  replaceScreen(
                    context,
                    ConfirmationScreen(
                      message: 'Task saved.',
                      scheduleId: scheduleId!,
                    ),
                  );
                },
                child: const Text('Save task'),
              ),
              if (widget.task != null)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await confirmDelete(
                      context,
                      'Delete task?',
                      'Delete “${widget.task!.title}”? This cannot be undone.',
                    );
                    if (!context.mounted || !confirmed) return;
                    state.deleteTask(widget.task!.id);
                    dashboard(context);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete task'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.message,
    required this.scheduleId,
  });
  final String message;
  final int scheduleId;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Saved',
    children: [
      const SizedBox(height: 32),
      const Icon(Icons.task_alt, size: 72),
      Section(
        AppScope.of(context).storageWarning == null ? message : 'Updated.',
      ),
      Text(
        AppScope.of(context).storageWarning == null
            ? 'You’re all set.'
            : 'Not saved. Keep this tab open.',
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () =>
            replaceScreen(context, ScheduleDetailsScreen(id: scheduleId)),
        child: const Text('View class'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => dashboard(context),
        child: const Text('Back to today'),
      ),
      TextButton(
        onPressed: () =>
            replaceScreen(context, TaskFormScreen(scheduleId: scheduleId)),
        child: const Text('Add task'),
      ),
    ],
  );
}

class NextClassCard extends StatelessWidget {
  const NextClassCard({super.key, required this.occurrence, required this.now});
  final ClassOccurrence occurrence;
  final DateTime now;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF171717),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () =>
          open(context, ScheduleDetailsScreen(id: occurrence.schedule.id)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  occurrence.happeningAt(now) ? 'In progress' : 'Next class',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              occurrence.schedule.subject,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.35,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${sameDay(occurrence.date, now) ? 'Today' : '${weekdays[occurrence.date.weekday - 1]} · ${calendarDate(occurrence.date)}'} · ${clock(occurrence.schedule.start)} – ${clock(occurrence.schedule.end)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
