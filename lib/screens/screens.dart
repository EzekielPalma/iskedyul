import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';

const tagline = 'Klase, gawain, at notes—ayos sa isang lugar.';
void open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
void dashboard(BuildContext context) => Navigator.of(context)
    .pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
      (_) => false,
    );

Future<bool> confirmDelete(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.children,
    this.navigation,
    this.scrollController,
  });
  final String title;
  final List<Widget> children;
  final Widget? navigation;
  final ScrollController? scrollController;
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
                    Icons.calendar_view_week_rounded,
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
    body: SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: title == 'iSkedyul' ? 820 : 640,
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
              'A LITTLE SPACE FOR YOUR WEEK',
              style: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 10,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Less scattered.\nMore settled.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              tagline,
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
                height: 1.6,
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
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                          style: TextStyle(
                            color: i == 2 ? Colors.black : Colors.white,
                            fontSize: 11,
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
          FeatureLabel(Icons.calendar_today_outlined, 'Classes'),
          FeatureLabel(Icons.check_circle_outline, 'Tasks'),
          FeatureLabel(Icons.notes_rounded, 'Notes'),
        ],
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: () => dashboard(context),
        child: const Text('Get Started'),
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
  const EmptyCard(
    this.message, {
    super.key,
    this.icon = Icons.check_circle_outline,
  });
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
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int tab = 0;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void select(int value) {
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() => tab = value);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = DateTime.now();
    final todays =
        state.schedules.where((s) => s.weekday == today.weekday).toList()
          ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
    final pending = state.sortedTasks().where((t) => !t.completed).toList();
    final done = state.sortedTasks().where((t) => t.completed).toList();
    final urgent = pending
        .where(
          (t) =>
              overdue(t, today) ||
              t.priority == Priority.high ||
              !dateOnly(t.due).isAfter(dateOnly(today)),
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
      scrollController: scroll,
      navigation: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week_rounded),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
        ],
      ),
      children: [
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
        Text(
          [
            'Your day, in order.',
            'Your weekly rhythm.',
            'A little progress.',
          ][tab],
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 22),
        if (tab == 0) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                _stat('${todays.length}', 'Classes today'),
                _stat('${pending.length}', 'To do'),
                _stat('${done.length}', 'Done'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => open(context, const ScheduleFormScreen()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Schedule'),
            ),
            OutlinedButton.icon(
              onPressed: state.schedules.isEmpty
                  ? null
                  : () => open(context, const TaskFormScreen()),
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('Add Task'),
            ),
          ],
        ),
        if (tab == 0) ...[
          const Section('On your schedule'),
          if (todays.isEmpty)
            const EmptyCard('No classes today.', icon: Icons.wb_sunny_outlined),
          ...todays.map((s) => ScheduleCard(schedule: s)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Section('Needs attention')),
              TextButton(
                onPressed: () => select(2),
                child: const Text('View all'),
              ),
            ],
          ),
          if (urgent.isEmpty) const EmptyCard('You’re all caught up.'),
          ...urgent.take(3).map((t) => TaskCard(task: t)),
          if (urgent.length > 3)
            TextButton(
              onPressed: () => select(2),
              child: Text('View ${urgent.length - 3} more'),
            ),
        ],
        if (tab == 1) ...[
          const Section('Your weekly schedule'),
          if (state.schedules.isEmpty)
            const EmptyCard(
              'No classes yet. Add your first schedule.',
              icon: Icons.calendar_today_outlined,
            ),
          for (var day = 1; day <= 7; day++) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Row(
                children: [
                  Text(
                    weekdays[day - 1],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (day == today.weekday) ...[
                    const SizedBox(width: 8),
                    const StatusPill('Today', dark: true),
                  ],
                  const Spacer(),
                  if (!state.schedules.any((s) => s.weekday == day))
                    const Text(
                      'Free',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                    ),
                ],
              ),
            ),
            ...(state.schedules.where((s) => s.weekday == day).toList()..sort(
                  (a, b) => minutes(a.start).compareTo(minutes(b.start)),
                ))
                .map((s) => ScheduleCard(schedule: s)),
            if (!state.schedules.any((s) => s.weekday == day))
              const Divider(color: Color(0xFFE6E6E6)),
          ],
        ],
        if (tab == 2) ...[
          Section('To do · ${pending.length}'),
          if (pending.isEmpty)
            const EmptyCard('Nothing to do. Enjoy the breather.'),
          ...pending.map((t) => TaskCard(task: t)),
          Section('Completed · ${done.length}'),
          if (done.isEmpty) const EmptyCard('No completed tasks yet.'),
          ...done.map((t) => TaskCard(task: t)),
        ],
      ],
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11),
        ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.dark = false});
  final String label;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: dark ? Colors.white : const Color(0xFF555555),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
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
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Color(0xFF888888),
            ),
          ],
        ),
      ),
    ),
  );
}

String dueLabel(DateTime due) {
  final days = dateOnly(due).difference(dateOnly(DateTime.now())).inDays;
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
                            Icons.edit_outlined,
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
                            '${task.priority == Priority.high
                                ? '↑'
                                : task.priority == Priority.low
                                ? '↓'
                                : '–'} ${priority[0].toUpperCase()}${priority.substring(1)}',
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
        title: 'Schedule unavailable',
        children: [
          const Text('This schedule was deleted.'),
          TextButton(
            onPressed: () => dashboard(context),
            child: const Text('Back to Today'),
          ),
        ],
      );
    }
    final schedule = state.schedule(id);
    final tasks = state.sortedTasks(scheduleId: id);
    return PageFrame(
      title: 'Schedule Details',
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
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Schedule'),
            ),
            FilledButton.icon(
              onPressed: () => open(context, TaskFormScreen(scheduleId: id)),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
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
              final value = await showDialog<String>(
                context: context,
                builder: (_) => NotesDialog(notes: schedule.notes),
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
              'Delete schedule?',
              'Delete “${schedule.subject}” and its ${tasks.length} linked task(s) and notes? This can’t be undone.',
            );
            if (!context.mounted || !confirmed) return;
            state.deleteSchedule(id);
            dashboard(context);
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Schedule'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => dashboard(context),
          child: const Text('Back to Today'),
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
  const ScheduleFormScreen({super.key, this.schedule});
  final Schedule? schedule;
  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final form = GlobalKey<FormState>();
  late final subject = TextEditingController(
    text: widget.schedule?.subject ?? '',
  );
  late int day = widget.schedule?.weekday ?? DateTime.now().weekday;
  late TimeOfDay start =
      widget.schedule?.start ?? const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay end =
      widget.schedule?.end ?? const TimeOfDay(hour: 10, minute: 0);
  @override
  void dispose() {
    subject.dispose();
    super.dispose();
  }

  Future<void> pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
    );
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
    title: widget.schedule == null ? 'Add Schedule' : 'Edit Schedule',
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => ConfirmationScreen(
                      message: 'Schedule saved.',
                      scheduleId: id,
                    ),
                  ),
                );
              },
              child: const Text('Save Schedule'),
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
  const TaskFormScreen({super.key, this.task, this.scheduleId});
  final StudentTask? task;
  final int? scheduleId;
  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title ?? '');
  int? scheduleId;
  late DateTime due = dateOnly(widget.task?.due ?? DateTime.now());
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
      title: widget.task == null ? 'Add Task' : 'Edit Task',
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
                decoration: const InputDecoration(labelText: 'Linked schedule'),
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
                validator: (v) =>
                    v == null ? 'Choose a linked schedule.' : null,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: due,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100, 12, 31),
                  );
                  if (picked != null && mounted) setState(() => due = picked);
                },
                icon: const Icon(Icons.event_outlined),
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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ConfirmationScreen(
                        message: 'Task saved.',
                        scheduleId: scheduleId!,
                      ),
                    ),
                  );
                },
                child: const Text('Save Task'),
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
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Task'),
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
      const Icon(Icons.check_circle_outline, size: 72),
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
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ScheduleDetailsScreen(id: scheduleId),
          ),
        ),
        child: const Text('View Schedule'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => dashboard(context),
        child: const Text('Back to Today'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TaskFormScreen(scheduleId: scheduleId),
          ),
        ),
        child: const Text('Add Task'),
      ),
    ],
  );
}
