import 'package:iskedyul/data/app_state.dart';
import 'package:iskedyul/data/models.dart';
import 'package:iskedyul/data/storage_contract.dart';

import 'demo_data.dart';

// Sample classes belong to test setup, never production initialization.
AppState seededState({SnapshotStorage? storage}) {
  final state = AppState(storage: storage);
  final today = dateOnly(DateTime.now());
  for (final schedule in demoSchedules(today)) {
    state.saveSchedule(schedule);
  }
  for (final task in demoTasks(today)) {
    state.saveTask(task);
  }
  return state;
}
