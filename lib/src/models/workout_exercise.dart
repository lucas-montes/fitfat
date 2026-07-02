/// Plain domain model linking an exercise to a workout.
final class WorkoutExercise {
  final String id;
  final String workoutId;
  final String exerciseId;
  final String exerciseName;
  final int sortOrder;

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.sortOrder,
  });
}
