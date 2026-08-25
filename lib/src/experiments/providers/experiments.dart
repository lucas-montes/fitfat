import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/providers/health_connect_steps.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/experiment.dart';
import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/task.dart';
import '../../planner/providers/planner.dart' show linksRepositoryProvider;
import 'experiments_repository.dart';

/// All experiments ordered newest-first.
final experimentListProvider = FutureProvider<List<Experiment>>((ref) {
  return ref.watch(experimentRepositoryProvider).getAll();
});

/// A single experiment by id, or `null` when it does not exist.
final experimentByIdProvider = FutureProvider.family<Experiment?, String>((
  ref,
  id,
) {
  return ref.watch(experimentRepositoryProvider).getById(id);
});

/// Check-ins for an experiment ordered chronologically (chart-ready).
final experimentCheckinsProvider =
    FutureProvider.family<List<ExperimentCheckin>, String>((ref, experimentId) {
      return ref.watch(experimentRepositoryProvider).getCheckins(experimentId);
    });

/// Tasks linked to an experiment via the `task_experiments` link table,
/// ordered by day then sort order. Each item carries its optional
/// relationship label.
final experimentLinkedTasksProvider =
    FutureProvider.family<List<({Task item, String? label})>, String>((
      ref,
      experimentId,
    ) {
      return ref
          .watch(linksRepositoryProvider)
          .tasksForExperiment(experimentId);
    });

/// Goals linked to an experiment via the `experiment_goals` link table.
final goalsByExperimentProvider =
    FutureProvider.family<List<({Goal item, String? label})>, String>((
      ref,
      experimentId,
    ) {
      return ref
          .watch(linksRepositoryProvider)
          .goalsForExperiment(experimentId);
    });

/// Notes attached to an experiment via the `experiment_notes` link table.
final notesByExperimentProvider =
    FutureProvider.family<List<({Note item, String? label})>, String>((
      ref,
      experimentId,
    ) {
      return ref
          .watch(linksRepositoryProvider)
          .notesForExperiment(experimentId);
    });

/// Completed-workout volume (kg) per day for workouts completed on or after
/// [from] — used to chart the workout category.
final workoutDailyVolumesProvider =
    FutureProvider.family<List<({DateTime day, double volumeKg})>, DateTime>((
      ref,
      from,
    ) {
      return ref.watch(workoutRepositoryProvider).getDailyVolumes(from);
    });

/// Daily step totals from [from] through today (best-effort; empty when
/// unavailable) — used to chart the steps category.
final stepsDailyProvider =
    FutureProvider.family<List<({DateTime day, int steps})>, DateTime>((
      ref,
      from,
    ) {
      return ref
          .watch(healthConnectStepsProvider)
          .getDailySteps(from, DateTime.now());
    });
