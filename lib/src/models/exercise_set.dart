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

  /// Time the set's actuals were saved (schema v7). Stamped whenever set
  /// actuals are recorded; null for planned-only sets.
  final DateTime? completedAt;
  final int? durationMinutes;
  final double? distanceMeters;
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
    this.notes,
  });

  int get effectiveReps => actualReps ?? reps ?? 0;
  double get effectiveWeightKg => actualWeightKg ?? weightKg ?? 0;
  int get effectiveDurationMinutes =>
      actualDurationMinutes ?? durationMinutes ?? 0;

  int? get actualDurationMinutes {
    // For weightlifting sets, duration is not logged via actuals.
    // For cardio, the actual duration is stored in actualReps as minutes.
    // This simplifies the model: cardio uses actualReps for duration.
    return null;
  }

  double get totalVolume => effectiveReps * effectiveWeightKg;

  bool get isCompleted => actualReps != null || actualDurationMinutes != null;

  int? get repsDelta =>
      (actualReps != null && reps != null) ? actualReps! - reps! : null;
  double? get weightDelta => (actualWeightKg != null && weightKg != null)
      ? actualWeightKg! - weightKg!
      : null;
}
