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
  const PageFrame({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
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
    padding: const EdgeInsets.only(top: 28, bottom: 12),
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
      const SizedBox(height: 36),
      const Align(
        alignment: Alignment.centerLeft,
        child: Icon(Icons.calendar_month_outlined, size: 64),
      ),
      const Section('A little order for your student week.'),
      const Text(tagline, style: TextStyle(fontSize: 20, height: 1.5)),
      const SizedBox(height: 24),
      const Text(
        'See your classes, keep tasks linked to each subject, and collect quick notes in one calm space.',
        style: TextStyle(fontSize: 16, height: 1.6),
      ),
      const Section('Made for your everyday routine'),
      const Text(
        '01  Plan your weekly classes\n\n02  Know what needs your attention\n\n03  Keep your notes close to your schedule',
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: () => dashboard(context),
        child: const Text('Get Started'),
      ),
      const SizedBox(height: 16),
      const Text(
        'Saved on this browser · No account needed.\nYour schedules, tasks, and notes stay on this device.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final today = DateTime.now();
    final todays =
        state.schedules.where((s) => s.weekday == today.weekday).toList()
          ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start)));
    final urgent = state
        .sortedTasks()
        .where(
          (t) =>
              !t.completed &&
              (overdue(t, today) ||
                  t.priority == Priority.high ||
                  !dateOnly(t.due).isAfter(dateOnly(today))),
        )
        .toList();
    return PageFrame(
      title: 'iSkedyul',
      children: [
        const Text(
          'YOUR STUDENT WEEK',
          style: TextStyle(letterSpacing: 2, fontSize: 12),
        ),
        const Section('One week. A clearer head.'),
        const Text(tagline),
        const SizedBox(height: 16),
        const Text(
          'Saved on this browser · Keep using the same browser and site.',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => open(context, const ScheduleFormScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Add Schedule'),
            ),
            OutlinedButton.icon(
              onPressed: state.schedules.isEmpty
                  ? null
                  : () => open(context, const TaskFormScreen()),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add Task'),
            ),
          ],
        ),
        Section('Today · ${weekdays[today.weekday - 1]}'),
        if (todays.isEmpty)
          const Text('No classes today. Make room for a little rest.'),
        ...todays.map((s) => ScheduleCard(schedule: s)),
        Section('Urgent tasks · ${urgent.length}'),
        const Text(
          'Pending overdue first, then priority and nearest due date.',
        ),
        const SizedBox(height: 8),
        if (urgent.isEmpty) const Text('All clear! No urgent tasks right now.'),
        ...urgent.map((t) => TaskCard(task: t)),
        const Section('Other pending tasks'),
        if (!state.tasks.any((t) => !t.completed && !urgent.contains(t)))
          const Text(
            'No other pending tasks. Add a task from a class when you need one.',
          ),
        ...state
            .sortedTasks()
            .where((t) => !t.completed && !urgent.contains(t))
            .map((t) => TaskCard(task: t)),
        const Section('Completed tasks'),
        if (!state.tasks.any((t) => t.completed))
          const Text(
            'No completed tasks yet. Check off a task when it is done.',
          ),
        ...state
            .sortedTasks()
            .where((t) => t.completed)
            .map((t) => TaskCard(task: t)),
        const Section('Your weekly schedule'),
        if (state.schedules.isEmpty)
          const Text(
            'Your week is a blank page. Add a schedule first, then link tasks to it.',
          ),
        const Text('Repeats each week · Select a class for tasks and notes.'),
        for (var day = 1; day <= 7; day++) ...[
          Section(weekdays[day - 1]),
          if (!state.schedules.any((s) => s.weekday == day))
            const Text('No classes planned.'),
          ...(state.schedules.where((s) => s.weekday == day).toList()
                ..sort((a, b) => minutes(a.start).compareTo(minutes(b.start))))
              .map((s) => ScheduleCard(schedule: s)),
        ],
      ],
    );
  }
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
            const Icon(Icons.menu_book_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${clock(schedule.start)} – ${clock(schedule.end)}'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final StudentTask task;
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final status = task.completed
        ? 'Completed'
        : overdue(task, DateTime.now())
        ? 'Overdue'
        : 'Pending';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.completed,
              semanticLabel: 'Complete ${task.title}',
              onChanged: (_) => state.toggleTask(task),
            ),
            Expanded(
              child: InkWell(
                onTap: () => open(context, TaskFormScreen(task: task)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(state.schedule(task.scheduleId).subject),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            '${task.priority == Priority.high
                                ? '‼'
                                : task.priority == Priority.medium
                                ? '!'
                                : '↓'} ${task.priority.name.toUpperCase()}',
                          ),
                          Text('$status · ${shortDate(task.due)}'),
                          const Text('Edit ↗'),
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
            child: const Text('Back to Dashboard'),
          ),
        ],
      );
    }
    final schedule = state.schedule(id);
    final tasks = state.sortedTasks(scheduleId: id);
    return PageFrame(
      title: 'Schedule Details',
      children: [
        Section(schedule.subject),
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
        Section('Pending tasks · ${tasks.where((t) => !t.completed).length}'),
        if (!tasks.any((t) => !t.completed))
          const Text('No linked tasks yet. Add your first one.'),
        ...tasks.where((t) => !t.completed).map((t) => TaskCard(task: t)),
        Section('Completed tasks · ${tasks.where((t) => t.completed).length}'),
        if (!tasks.any((t) => t.completed))
          const Text('No completed tasks yet.'),
        ...tasks.where((t) => t.completed).map((t) => TaskCard(task: t)),
        const Section('Quick notes'),
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
              'Delete “${schedule.subject}”? This permanently removes its ${tasks.length} linked task(s) and notes from this browser. This cannot be undone.',
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
          child: const Text('Back to Dashboard'),
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
      const Text('A weekly class or activity. Keep the details simple.'),
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
                  ? 'End time must be after start time (same day).'
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
                      message: 'Schedule saved successfully.',
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
        const Text('One task, one class. Give it a clear next step.'),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Past dates are allowed and marked overdue.'),
              ),
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
                        message: 'Task saved successfully.',
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
        AppScope.of(context).storageWarning == null
            ? message
            : 'Updated in this session.',
      ),
      Text(
        AppScope.of(context).storageWarning == null
            ? 'Saved on this browser. Your changes will be here after refresh.'
            : 'Browser saving failed. Keep this page open to retain these changes.',
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
        child: const Text('Back to Dashboard'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => TaskFormScreen(scheduleId: scheduleId),
          ),
        ),
        child: const Text('Add another task'),
      ),
    ],
  );
}
