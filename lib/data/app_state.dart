import 'package:flutter/material.dart';

import 'models.dart';
import 'snapshot.dart';
import 'storage_contract.dart';

// All changes are saved synchronously as one browser-local snapshot.
class AppState extends ChangeNotifier {
  AppState({SnapshotStorage? storage}) : storage = storage ?? MemoryStorage() {
    try {
      final raw = this.storage.read();
      if (raw == null) {
        _persist();
      } else {
        isReturning = true;
        try {
          final data = decodeSnapshot(raw);
          schedules.addAll(data.schedules);
          tasks.addAll(data.tasks);
          if (data.skippedInvalid) {
            recoveryMessage =
                'Some entries couldn’t be restored. Your valid data is here.';
          }
        } on FormatException {
          recoveryMessage = 'Saved data couldn’t be opened. Adding an item starts a new planner.';
        }
      }
    } catch (_) {
      storageWarning = 'Storage is blocked. Allow browser storage, then edit an item to save.';
    }
    for (final id in [
      ...schedules.map((s) => s.id),
      ...tasks.map((t) => t.id),
    ]) {
      if (id >= _nextId) _nextId = id + 1;
    }
  }
  final SnapshotStorage storage;
  final schedules = <Schedule>[];
  final tasks = <StudentTask>[];
  bool isReturning = false;
  String? recoveryMessage;
  String? storageWarning;
  int _nextId = 10;
  int newId() => _nextId++;
  void _persist() {
    try {
      storage.write(encodeSnapshot(schedules, tasks));
      storageWarning = null;
      recoveryMessage = null;
    } catch (_) {
      storageWarning = 'Could not save. Keep this tab open. Check browser storage, then edit an item to retry.';
    }
  }

  void _changed() {
    _persist();
    notifyListeners();
  }

  void clearPlanner() {
    schedules.clear();
    tasks.clear();
    _changed();
  }

  void deleteSchedule(int id) {
    schedules.removeWhere((s) => s.id == id);
    tasks.removeWhere((t) => t.scheduleId == id);
    _changed();
  }

  void deleteTask(int id) {
    tasks.removeWhere((t) => t.id == id);
    _changed();
  }

  Schedule schedule(int id) => schedules.firstWhere((s) => s.id == id);
  List<StudentTask> sortedTasks({int? scheduleId}) {
    final result = tasks
        .where((t) => scheduleId == null || t.scheduleId == scheduleId)
        .toList();
    result.sort((a, b) => compareTasks(a, b, DateTime.now()));
    return result;
  }

  void saveSchedule(Schedule value) {
    if (value.subject.trim().isEmpty ||
        value.subject.length > 100 ||
        value.weekday < 1 ||
        value.weekday > 7 ||
        minutes(value.end) <= minutes(value.start)) {
      throw ArgumentError(
        'A schedule needs a subject, weekday, and end time after its start.',
      );
    }
    final index = schedules.indexWhere((s) => s.id == value.id);
    if (index < 0) {
      schedules.add(value);
    } else {
      schedules[index] = value;
    }
    _changed();
  }

  void saveTask(StudentTask value) {
    if (!schedules.any((s) => s.id == value.scheduleId) ||
        value.title.trim().isEmpty ||
        value.title.length > 120) {
      throw ArgumentError('A task needs a title and a valid schedule.');
    }
    final index = tasks.indexWhere((t) => t.id == value.id);
    if (index < 0) {
      tasks.add(value);
    } else {
      tasks[index] = value;
    }
    _changed();
  }

  void toggleTask(StudentTask task) {
    task.completed = !task.completed;
    _changed();
  }

  void saveNotes(int id, String notes) {
    schedule(id).notes = notes;
    _changed();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
