import 'fixtures/seeded_state.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/data/snapshot.dart';
import 'package:iskedyul/data/storage_contract.dart';

class UnavailableStorage extends MemoryStorage {
  bool failRead = false;
  bool failWrite = false;
  @override
  String? read() {
    if (failRead) throw StateError('Storage blocked');
    return super.read();
  }

  @override
  void write(String value) {
    if (failWrite) throw StateError('Quota exceeded');
    super.write(value);
  }
}

void main() {
  test('fresh planner starts empty and stays empty after refresh', () {
    final storage = MemoryStorage();
    final fresh = AppState(storage: storage);
    expect(fresh.schedules, isEmpty);
    expect(fresh.tasks, isEmpty);
    expect(fresh.isReturning, isFalse);
    final restored = AppState(storage: storage);
    expect(restored.schedules, isEmpty);
    expect(restored.tasks, isEmpty);
    expect(restored.isReturning, isTrue);
  });
  test('clearing a populated planner persists an empty snapshot', () {
    final storage = MemoryStorage();
    final state = seededState(storage: storage);
    state.clearPlanner();
    final restored = AppState(storage: storage);
    expect(restored.schedules, isEmpty);
    expect(restored.tasks, isEmpty);
  });
  test('refresh restores schedule and task edits, dates, priority, completion and notes', () {
    final storage = MemoryStorage();
    final state = AppState(storage: storage);
    final scheduleId = state.newId();
    state.saveSchedule(
      Schedule(
        id: scheduleId,
        subject: 'Project lab',
        weekday: 2,
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 15, minute: 30),
      ),
    );
    final taskId = state.newId();
    state.saveTask(
      StudentTask(
        id: taskId,
        title: 'Draft report',
        scheduleId: scheduleId,
        due: DateTime(2027, 2, 3),
        priority: Priority.low,
      ),
    );
    state.saveTask(
      StudentTask(
        id: taskId,
        title: 'Final report',
        scheduleId: scheduleId,
        due: DateTime(2027, 2, 4),
        priority: Priority.high,
      ),
    );
    state.saveSchedule(
      Schedule(
        id: scheduleId,
        subject: 'Project workshop',
        weekday: 3,
        start: const TimeOfDay(hour: 15, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 0),
      ),
    );
    state.saveNotes(scheduleId, 'Bring notebook\nReview the rubric.');
    state.toggleTask(state.tasks.last);
    final restored = AppState(storage: storage);
    expect(restored.schedule(scheduleId).subject, 'Project workshop');
    expect(restored.schedule(scheduleId).weekday, 3);
    expect(restored.schedule(scheduleId).start.hour, 15);
    expect(restored.schedule(scheduleId).end.hour, 16);
    expect(
      restored.schedule(scheduleId).notes,
      'Bring notebook\nReview the rubric.',
    );
    expect(restored.tasks.last.title, 'Final report');
    expect(restored.tasks.last.due, DateTime(2027, 2, 4));
    expect(restored.tasks.last.priority, Priority.high);
    expect(restored.tasks.last.completed, isTrue);
    restored.toggleTask(restored.tasks.last);
    expect(AppState(storage: storage).tasks.last.completed, isFalse);
    expect(restored.newId(), greaterThan(taskId));
  });
  test(
    'linked deletion removes only selected schedule, its tasks and notes',
    () {
      final storage = MemoryStorage();
      final state = seededState(storage: storage);
      state.deleteSchedule(1);
      final restored = AppState(storage: storage);
      expect(restored.schedules.map((s) => s.id), [2, 3]);
      expect(restored.tasks.any((t) => t.scheduleId == 1), isFalse);
      expect(restored.tasks.map((t) => t.id), [2, 3]);
      restored.deleteTask(2);
      expect(AppState(storage: storage).tasks.map((t) => t.id), [3]);
      expect(AppState(storage: storage).schedules.length, 2);
    },
  );
  test('intentionally empty snapshot stays empty across repeated reloads', () {
    final storage = MemoryStorage();
    final state = seededState(storage: storage);
    for (final schedule in state.schedules.toList()) {
      state.deleteSchedule(schedule.id);
    }
    for (var i = 0; i < 3; i++) {
      final restored = AppState(storage: storage);
      expect(restored.schedules, isEmpty);
      expect(restored.tasks, isEmpty);
    }
  });
  test('malformed JSON and unsupported snapshots start empty without overwriting saved data', () {
    for (final raw in [
      'not json',
      'null',
      '[]',
      '{"version":2,"schedules":[],"tasks":[]}',
    ]) {
      final storage = MemoryStorage()..value = raw;
      final state = AppState(storage: storage);
      expect(state.schedules, isEmpty);
      expect(state.tasks, isEmpty);
      expect(state.recoveryMessage, isNotNull);
      expect(storage.value, raw);
    }
  });
  test('invalid rows, duplicate IDs, bad dates and orphan tasks are skipped, valid data recovered', () {
    final source = seededState();
    final json = jsonDecode(
      encodeSnapshot(source.schedules, source.tasks),
    ) as Map<String, dynamic>;
    final schedules = json['schedules'] as List;
    schedules.add(schedules.first); // duplicate
    schedules.add({'id': 30, 'subject': '', 'weekday': 8});
    schedules.add(null);
    final tasks = json['tasks'] as List;
    tasks.add({...tasks.first as Map, 'id': 30, 'scheduleId': 999});
    tasks.add({...tasks.first as Map, 'id': 31, 'due': '2026-02-31'});
    tasks.add({...tasks.first as Map, 'id': 32, 'completed': 'true'});
    tasks.add({...tasks.first as Map, 'id': 33, 'priority': 'urgent'});
    final storage = MemoryStorage()..value = jsonEncode(json);
    final state = AppState(storage: storage);
    expect(state.schedules.length, 3);
    expect(state.tasks.length, 4);
    expect(state.recoveryMessage, contains('restored'));
  });
  test('unavailable storage and write failures are visible, changes survive in memory and retry succeeds', () {
    final blocked = UnavailableStorage()..failRead = true;
    expect(AppState(storage: blocked).storageWarning, isNotNull);
    final storage = UnavailableStorage();
    final state = seededState(storage: storage);
    storage.failWrite = true;
    state.saveNotes(1, 'Unsaved note');
    expect(state.schedule(1).notes, 'Unsaved note');
    expect(state.storageWarning, contains('Could not save'));
    expect(AppState(storage: storage).schedule(1).notes, isNot('Unsaved note'));
    storage.failWrite = false;
    state.saveNotes(1, 'Saved note');
    expect(state.storageWarning, isNull);
    expect(AppState(storage: storage).schedule(1).notes, 'Saved note');
  });
  test(
    'urgency sorting survives reload and completed tasks sort separately',
    () {
      final today = dateOnly(DateTime.now());
      final source = seededState();
      StudentTask task(
        int id,
        int offset,
        Priority priority, {
        bool completed = false,
      }) => StudentTask(
        id: id,
        title: 'Task $id',
        scheduleId: 1,
        due: today.add(Duration(days: offset)),
        priority: priority,
        completed: completed,
      );
      final tasks = [
        task(10, 1, Priority.high),
        task(11, -2, Priority.low),
        task(12, -1, Priority.medium),
        task(13, 0, Priority.high),
        task(14, -3, Priority.high, completed: true),
      ];
      final storage = MemoryStorage()
        ..value = encodeSnapshot(source.schedules, tasks);
      final restored = AppState(storage: storage);
      expect(restored.sortedTasks().map((t) => t.id), [12, 11, 13, 10, 14]);
      restored.toggleTask(restored.tasks.firstWhere((t) => t.id == 14));
      expect(AppState(storage: storage).sortedTasks().first.id, 14);
    },
  );
  test(
    'required fields, links and time range are validated at state boundary',
    () {
      final state = AppState();
      expect(
        () => state.saveSchedule(
          Schedule(
            id: 20,
            subject: ' ',
            weekday: 1,
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 10, minute: 0),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => state.saveSchedule(
          Schedule(
            id: 20,
            subject: 'Test',
            weekday: 1,
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 9, minute: 0),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => state.saveTask(
          StudentTask(
            id: 20,
            title: 'Test',
            scheduleId: 999,
            due: DateTime.now(),
            priority: Priority.high,
          ),
        ),
        throwsArgumentError,
      );
    },
  );
}
