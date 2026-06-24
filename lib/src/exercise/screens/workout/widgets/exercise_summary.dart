/// Aggregated data for one exercise in the workout summary.
///
/// Contains mutable counters populated by [WorkoutSummaryScreen] when
/// building the exercise list from raw set data.
class ExerciseSummary {
  final String exerciseName;
  final bool isWeight;
  int totalSets = 0;
  int completedSets = 0;
  double volume = 0;

  ExerciseSummary({required this.exerciseName, required this.isWeight});
}
