import '../../models/exercise.dart';
import '../repositories/workout_repository.dart';

/// Estimated energy spent in one workout, from each exercise's MET.
final class WorkoutEnergy {
  /// Gross kcal (MET × kg × hours), resting cost included. That is what
  /// fitness trackers show; anything adding it to a daily total must subtract
  /// the 1 MET already counted by the BMR.
  final double kcal;

  /// Exercises with logged work that the estimate leaves out: no MET yet, or
  /// strength work in a workout that wasn't timed.
  final List<String> notCounted;

  const WorkoutEnergy({required this.kcal, required this.notCounted});
}

/// Estimates a workout's energy cost.
///
/// Cardio sets carry their own duration. Strength sets don't, so the rest of
/// the workout's elapsed time (rests included, which is how the Compendium
/// rates resistance training) is split across the strength exercises by
/// completed-set count. A workout logged after the fact has no elapsed time,
/// so only its cardio counts.
///
/// Returns null without a body weight or when nothing could be counted.
WorkoutEnergy? estimateWorkoutEnergy({
  required WorkoutWithDetails detail,
  required Exercise? Function(String exerciseId) exerciseById,
  required double? weightKg,
}) {
  if (weightKg == null || weightKg <= 0) return null;

  var kcal = 0.0;
  final notCounted = <String>[];
  var cardioMinutes = 0;
  final strength = <(ExerciseBlock, double?, int)>[];

  for (final block in detail.exercises) {
    final done = block.sets.where((s) => s.isCompleted).toList();
    if (done.isEmpty) continue;
    final exercise = exerciseById(block.exercise.exerciseId);
    final met = exercise?.met;
    final minutes = done.fold<int>(
      0,
      (sum, s) => sum + s.effectiveDurationMinutes,
    );
    final isCardio = exercise?.isCardio ?? minutes > 0;
    if (isCardio) {
      // Its time is spoken for whether or not it can be rated.
      cardioMinutes += minutes;
      if (met == null || minutes == 0) {
        notCounted.add(block.exercise.exerciseName);
      } else {
        kcal += met * weightKg * minutes / 60;
      }
    } else {
      strength.add((block, met, done.length));
    }
  }

  final strengthMinutes =
      detail.workout.duration.inSeconds / 60 - cardioMinutes;
  final strengthSets = strength.fold<int>(0, (sum, e) => sum + e.$3);
  for (final (block, met, sets) in strength) {
    if (met == null || strengthMinutes <= 0) {
      notCounted.add(block.exercise.exerciseName);
      continue;
    }
    kcal += met * weightKg * (strengthMinutes * sets / strengthSets) / 60;
  }

  if (kcal <= 0) return null;
  return WorkoutEnergy(kcal: kcal, notCounted: notCounted);
}
