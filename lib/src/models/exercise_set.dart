/// Plain domain model for a single set within a workout exercise.
final class ExerciseSet {
  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final int? reps;
  final double? weightKg;

  /// Planned rest between sets in seconds (schema v5). Required at the form
  /// level for every set; null only for legacy rows.
  final int? restSeconds;
  final int? actualReps;
  final double? actualWeightKg;

  /// Actual rest taken between sets in seconds (schema v5). Null until a rest
  /// period for this set is started and finished/cancelled.
  final int? actualRestSeconds;

  /// Time the set's actuals were saved (schema v7), stamped whenever set
  /// actuals are recorded; null for planned-only sets.
  final DateTime? completedAt;

  /// Planned cardio duration/distance (schema v5). Kept as planned values;
  /// logged cardio actuals are stored in [actualDurationMinutes] /
  /// [actualDistanceMeters] so planned vs done stay distinguishable.
  final int? durationMinutes;
  final double? distanceMeters;

  /// Logged cardio duration/distance (schema v16). Null until the set's
  /// actuals are saved. A cardio set with these set is completed.
  final int? actualDurationMinutes;
  final double? actualDistanceMeters;
  final String? notes;

  const ExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.restSeconds,
    this.actualReps,
    this.actualWeightKg,
    this.actualRestSeconds,
    this.completedAt,
    this.durationMinutes,
    this.distanceMeters,
    this.actualDurationMinutes,
    this.actualDistanceMeters,
    this.notes,
  });

  /// Actual values only. A set without logged actuals contributes 0, never its
  /// planned values — unlogged sets count as "not done at all".
  int get effectiveReps => actualReps ?? 0;
  double get effectiveWeightKg => actualWeightKg ?? 0;
  int get effectiveDurationMinutes => actualDurationMinutes ?? 0;
  double get effectiveDistanceMeters => actualDistanceMeters ?? 0;

  double get totalVolume => effectiveReps * effectiveWeightKg;

  bool get isCompleted =>
      actualReps != null ||
      actualDurationMinutes != null ||
      actualDistanceMeters != null;

  int? get repsDelta =>
      (actualReps != null && reps != null) ? actualReps! - reps! : null;
  double? get weightDelta => (actualWeightKg != null && weightKg != null)
      ? actualWeightKg! - weightKg!
      : null;
}
