import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/planner_entry.dart';
import '../repositories/links_repository.dart';
import '../repositories/task_repository.dart';
import '../../experiments/providers/experiments_repository.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider));
});

final linksRepositoryProvider = Provider<LinksRepository>((ref) {
  return LinksRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Timeline entry providers (tasks ∪ experiments, schema v27)
// ---------------------------------------------------------------------------

/// Every planner entry (task or experiment) scheduled on [day] — powers the
/// Day view. Recurring series are materialized first so generated occurrences
/// exist before reading.
final dayEntriesProvider = FutureProvider.family<List<PlannerEntry>, DateTime>((
  ref,
  day,
) async {
  final tasks = ref.watch(taskRepositoryProvider);
  final experiments = ref.watch(experimentRepositoryProvider);
  await tasks.materializeForDay(day);
  final dayTasks = await tasks.getByDay(day);
  final dayExperiments = await experiments.getByDay(day);
  return [
    for (final task in dayTasks) TaskEntry(task),
    for (final experiment in dayExperiments) ExperimentEntry(experiment),
  ];
});

/// Every planner entry whose span falls within the month containing
/// [monthAnchor] — powers the calendar month markers.
final monthEntriesProvider =
    FutureProvider.family<List<PlannerEntry>, DateTime>((ref, monthAnchor) {
      final start = DateTime(monthAnchor.year, monthAnchor.month, 1);
      final end = DateTime(monthAnchor.year, monthAnchor.month + 1, 0);
      return entriesInRange(ref, start, end);
    });

/// Every planner entry within an inclusive (start, end) day range — powers
/// the week overview. Keyed by a record so each week caches independently.
final rangeEntriesProvider =
    FutureProvider.family<List<PlannerEntry>, (DateTime, DateTime)>((
      ref,
      range,
    ) {
      final (start, end) = range;
      return entriesInRange(
        ref,
        DateTime(start.year, start.month, start.day),
        DateTime(end.year, end.month, end.day),
      );
    });

Future<List<PlannerEntry>> entriesInRange(
  Ref ref,
  DateTime start,
  DateTime end,
) async {
  final rangeTasks = await ref
      .watch(taskRepositoryProvider)
      .getByRange(start, end);
  final rangeExperiments = await ref
      .watch(experimentRepositoryProvider)
      .getByRange(start, end);
  return [
    for (final task in rangeTasks) TaskEntry(task),
    for (final experiment in rangeExperiments) ExperimentEntry(experiment),
  ];
}
