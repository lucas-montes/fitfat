import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/providers/health_connect_steps.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/experiment.dart';
import '../../models/planner_item.dart';
import '../../planner/providers/planner.dart';

/// All experiments ordered newest-first. Since v24 experiments are planner
/// items (kind='experiment'), so these providers read through
/// [PlannerRepository].
final experimentListProvider = FutureProvider<List<Experiment>>((ref) {
  return ref.watch(plannerRepositoryProvider).getExperiments();
});

/// A single experiment by id, or `null` when it does not exist.
final experimentByIdProvider = FutureProvider.family<Experiment?, String>((
  ref,
  id,
) {
  return ref.watch(plannerRepositoryProvider).getExperimentById(id);
});

/// Check-ins for an experiment ordered chronologically (chart-ready).
final experimentCheckinsProvider =
    FutureProvider.family<List<ExperimentCheckin>, String>((ref, experimentId) {
      return ref.watch(plannerRepositoryProvider).getCheckins(experimentId);
    });

/// Planner tasks linked to an experiment via their `experimentId`.
final experimentLinkedTasksProvider =
    FutureProvider.family<List<PlannerItem>, String>((ref, experimentId) {
      return ref.watch(plannerRepositoryProvider).getLinkedTasks(experimentId);
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
