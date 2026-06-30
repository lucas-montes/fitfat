/// Aggregated data for one exercise in the workout summary.
///
/// Contains mutable counters populated by [WorkoutSummaryScreen] when
/// building the exercise list from raw set data.
class ExerciseSummary {
  final String exerciseName;
  final bool isWeight;
  final String? exerciseId;
  int totalSets = 0;
  int completedSets = 0;
  double volume = 0;

  /// Sum of planned values (plannedReps × plannedWeightKg or
  /// plannedDurationMinutes) across ALL sets for this exercise. Used for
  /// planned-vs-actual comparison on scheduled workouts.
  double plannedVolume = 0;

  /// Sum of actual values across only COMPLETED sets for this exercise.
  /// Used for planned-vs-actual comparison on scheduled workouts.
  double actualVolume = 0;

  /// Sum of [WeightSet.effectiveReps] across all weight sets for this exercise.
  int totalReps = 0;

  /// Average rest time in seconds between consecutive completed sets of this
  /// exercise, derived from [completedAt] timestamps. Null when fewer than 2
  /// completed sets exist.
  double? avgRestSeconds;

  ExerciseSummary({
    required this.exerciseName,
    required this.isWeight,
    this.exerciseId,
  });
}
