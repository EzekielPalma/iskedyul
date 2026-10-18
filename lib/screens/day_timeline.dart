import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/calendar.dart';
import '../data/models.dart';

class DayTimeline extends StatefulWidget {
  const DayTimeline({
    super.key,
    required this.days,
    required this.schedules,
    required this.now,
    required this.onOpen,
    required this.onCreate,
    this.onExpand,
    this.expanded = false,
    this.position,
  });
  final List<DateTime> days;
  final List<Schedule> schedules;
  final DateTime now;
  final ValueChanged<Schedule> onOpen;
  final void Function(DateTime, TimeOfDay) onCreate;
  final VoidCallback? onExpand;
  final bool expanded;
  final ValueNotifier<double?>? position;
  @override
  State<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends State<DayTimeline> {
  static const hourHeight = 72.0;
  // Extra scroll space keeps the last time slot above the floating button.
  static const totalHeight = 24 * hourHeight + 100;
  static const gutter = 72.0;
  late final ScrollController grid;
  late final ScrollController labels;
  bool syncing = false;
  double get targetOffset =>
      (widget.days.any((d) => sameDay(d, widget.now))
          ? math.max(0, widget.now.hour - 1)
          : 8) *
      hourHeight;
  @override
  void initState() {
    super.initState();
    final offset = widget.position?.value ?? targetOffset;
    grid = ScrollController(initialScrollOffset: offset);
    labels = ScrollController(initialScrollOffset: offset);
    grid.addListener(scrolled);
    widget.position?.addListener(restorePosition);
  }

  void scrolled() {
    if (labels.hasClients) {
      labels.jumpTo(grid.offset.clamp(0, labels.position.maxScrollExtent));
    }
    if (!syncing &&
        widget.position != null &&
        widget.position!.value != grid.offset) {
      widget.position!.value = grid.offset;
    }
  }

  void restorePosition() {
    final offset = widget.position?.value;
    if (offset == null || !grid.hasClients || syncing) return;
    syncing = true;
    grid.jumpTo(offset.clamp(0, grid.position.maxScrollExtent));
    syncing = false;
  }

  void scrollToTime() {
    if (grid.hasClients) {
      grid.animateTo(
        targetOffset.clamp(0, grid.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant DayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      oldWidget.position?.removeListener(restorePosition);
      widget.position?.addListener(restorePosition);
    }
    if (!sameDay(oldWidget.days.first, widget.days.first) ||
        oldWidget.days.length != widget.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToTime();
      });
    }
  }

  @override
  void dispose() {
    widget.position?.removeListener(restorePosition);
    grid.removeListener(scrolled);
    grid.dispose();
    labels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Timetable',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          TextButton.icon(
            onPressed: scrollToTime,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(
              widget.days.any((d) => sameDay(d, widget.now)) ? 'Now' : '8 AM',
            ),
          ),
          if (widget.onExpand != null)
            IconButton(
              tooltip: 'Expand timetable',
              onPressed: widget.onExpand,
              icon: const Icon(Icons.fullscreen),
            ),
        ],
      ),
      if (!widget.expanded)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Tap a time to add a class.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      if (widget.expanded)
        Expanded(child: frame())
      else
        SizedBox(
          height:
              (MediaQuery.sizeOf(context).height * .55).clamp(320.0, 560.0) +
              48,
          child: frame(),
        ),
    ],
  );
  Widget frame() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDDDDDD)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: [
        SizedBox(
          width: gutter,
          child: Column(
            children: [
              const SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Time',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: labels,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: totalHeight,
                    child: Stack(
                      children: [
                        for (var hour = 0; hour <= 24; hour++)
                          Positioned(
                            top: hour * hourHeight + 2,
                            left: 5,
                            right: 3,
                            child: Text(
                              time12(hour * 60),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = widget.expanded
                  ? math.max(box.maxWidth, widget.days.length * 124.0)
                  : box.maxWidth;
              final column = width / widget.days.length;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final day in widget.days)
                            Expanded(
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: sameDay(day, widget.now)
                                      ? const Color(0xFFEAEAEA)
                                      : const Color(0xFFF7F7F7),
                                  border: const Border(
                                    left: BorderSide(color: Color(0xFFDDDDDD)),
                                  ),
                                ),
                                child: Text(
                                  '${weekdays[day.weekday - 1].substring(0, 3)} ${day.day}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: grid,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: grid,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (event) {
                                if (event.localPosition.dy >= 24 * hourHeight) {
                                  return;
                                }
                                final index = (event.localPosition.dx / column)
                                    .floor()
                                    .clamp(0, widget.days.length - 1);
                                final minute =
                                    ((event.localPosition.dy /
                                                hourHeight *
                                                60) ~/
                                            30 *
                                            30)
                                        .clamp(0, 1410);
                                if (supportedDate(widget.days[index])) {
                                  widget.onCreate(
                                    widget.days[index],
                                    TimeOfDay(
                                      hour: minute ~/ 60,
                                      minute: minute % 60,
                                    ),
                                  );
                                }
                              },
                              child: SizedBox(
                                key: const ValueKey('timeline-grid'),
                                width: width,
                                height: totalHeight,
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    for (var hour = 0; hour <= 24; hour++)
                                      Positioned(
                                        top: hour * hourHeight,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFFDDDDDD),
                                        ),
                                      ),
                                    for (var hour = 0; hour < 24; hour++)
                                      Positioned(
                                        top: (hour + .5) * hourHeight,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFFF0F0F0),
                                        ),
                                      ),
                                    for (
                                      var i = 0;
                                      i < widget.days.length;
                                      i++
                                    ) ...[
                                      Positioned(
                                        left: i * column,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 1,
                                          color: const Color(0xFFDDDDDD),
                                        ),
                                      ),
                                      for (final event in eventLanes(
                                        widget.schedules
                                            .where(
                                              (s) =>
                                                  s.weekday ==
                                                  widget.days[i].weekday,
                                            )
                                            .toList(),
                                      ))
                                        Positioned(
                                          key: ValueKey(
                                            'timeline-event-${widget.days[i].toIso8601String()}-${event.schedule.id}',
                                          ),
                                          top:
                                              minutes(event.schedule.start) /
                                              60 *
                                              hourHeight,
                                          left:
                                              i * column +
                                              event.lane *
                                                  (column / event.lanes) +
                                              3,
                                          width: math.max(
                                            1,
                                            column / event.lanes - 6,
                                          ),
                                          height: math.max(
                                            18,
                                            (minutes(event.schedule.end) -
                                                    minutes(
                                                      event.schedule.start,
                                                    )) /
                                                60 *
                                                hourHeight,
                                          ),
                                          child: _TimelineEvent(
                                            schedule: event.schedule,
                                            onOpen: widget.onOpen,
                                          ),
                                        ),
                                      if (sameDay(widget.days[i], widget.now))
                                        Positioned(
                                          top:
                                              (widget.now.hour +
                                                  widget.now.minute / 60) *
                                              hourHeight,
                                          left: i * column,
                                          width: column,
                                          child: IgnorePointer(
                                            child: Container(
                                              height: 2,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({required this.schedule, required this.onOpen});
  final Schedule schedule;
  final ValueChanged<Schedule> onOpen;
  @override
  Widget build(BuildContext context) {
    final time = '${clock(schedule.start)}–${clock(schedule.end)}';
    return Semantics(
      label: '${schedule.subject}, $time',
      button: true,
      excludeSemantics: true,
      onTap: () => onOpen(schedule),
      child: Tooltip(
        message: '${schedule.subject}\n$time',
        child: Material(
          color: const Color(0xFFEAEAEA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onOpen(schedule),
            child: LayoutBuilder(
              builder: (context, box) => Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        schedule.subject,
                        maxLines: box.maxHeight > 65 ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (box.maxHeight > 52) ...[
                      const SizedBox(height: 4),
                      Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
