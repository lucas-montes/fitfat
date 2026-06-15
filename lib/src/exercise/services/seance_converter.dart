import '../../models/exercise.dart';
import '../../models/workout.dart';

/// Converts a legacy [Seance] (old model) into the new [Workout] domain model.
///
/// Cardio-type exercises produce a [WorkoutEntry] with an empty [WeightSet]
/// list and a placeholder [CardioDetail] with 0 duration (the user can
/// update the duration later via the new UI).
///
/// Freeform old exercises with no sets produce a [WorkoutEntry] with an
/// empty sets list (no [CardioDetail]).
Workout convertSeanceToWorkout(Seance seance) {
  final entries = <WorkoutEntry>[];
  for (var i = 0; i < seance.exercises.length; i++) {
    final entry = seance.exercises[i];
    entries.add(_convertExerciseEntry(entry, i));
  }

  return Workout(
    id: seance.id,
    name: seance.name,
    startTime: seance.startedAt,
    endTime: seance.completedAt,
    entries: entries,
    isGuided: seance.isGuided,
    source: 'manual',
  );
}

/// Converts a list of seances in batch, preserving sort order (most recent first
/// is caller's responsibility).
List<Workout> convertSeancesToWorkouts(List<Seance> seances) {
  return seances.map(convertSeanceToWorkout).toList();
}

WorkoutEntry _convertExerciseEntry(ExerciseEntry entry, int sortOrder) {
  final exercise = entry.exercise;
  final isCardio = exercise.type == 'cardio';

  final sets = <WeightSet>[];
  for (final set in entry.sets) {
    // Filter to completed sets only, matching existing save behavior
    if (set.isCompleted) {
      sets.add(
        WeightSet(
          reps: set.reps,
          weightKg: set.weight,
          completedAt: set.completedAt,
        ),
      );
    }
  }

  return WorkoutEntry(
    id: entry.id,
    exercise: exercise,
    sets: sets,
    cardioDetail: isCardio ? const CardioDetail(durationMinutes: 0) : null,
    sortOrder: sortOrder,
  );
}
