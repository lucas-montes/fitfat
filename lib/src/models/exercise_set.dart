/// Plain domain model for a single set within a workout exercise.
final class ExerciseSet {
  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? actualReps;
  final double? actualWeightKg;
  final int? durationMinutes;
  final double? distanceMeters;
  final String? notes;

  const ExerciseSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.actualReps,
    this.actualWeightKg,
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
