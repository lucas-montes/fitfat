import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_models.dart';
import '../services/seance_foreground_service.dart';

final exerciseListProvider = Provider<List<ExerciseDefinition>>((ref) {
  return _seedExercises();
});

final activeSeanceProvider =
    NotifierProvider<ActiveSeanceNotifier, Seance?>(
  ActiveSeanceNotifier.new,
);

final seanceHistoryProvider =
    NotifierProvider<SeanceHistoryNotifier, List<Seance>>(
  SeanceHistoryNotifier.new,
);

class ActiveSeanceNotifier extends Notifier<Seance?> {
  @override
  Seance? build() => null;

  void startSeance() {
    state = Seance(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      exercises: [],
    );
    // Start notification/foreground task for the active seance
    unawaited(SeanceForegroundService.instance.start(state!.startedAt));
  }

  void addExercise(ExerciseDefinition exercise) {
    if (state == null) return;
    final newEntry = ExerciseEntry(
      id: const Uuid().v4(),
      exercise: exercise,
      sets: [],
      startedAt: DateTime.now(),
    );
    state = Seance(
      id: state!.id,
      startedAt: state!.startedAt,
      exercises: [...state!.exercises, newEntry],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    // Note: returns void for compatibility; callers can inspect state if needed.
  }

  void addSet(int exerciseIndex, int reps, double weight) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;
    final exercises = state!.exercises;
    final exercise = exercises[exerciseIndex];
    final updatedExercise = ExerciseEntry(
      id: exercise.id,
      exercise: exercise.exercise,
      sets: [...exercise.sets, ExerciseSet(reps: reps, weight: weight)],
      startedAt: exercise.startedAt,
      completedAt: exercise.completedAt,
    );
    state = Seance(
      id: state!.id,
      startedAt: state!.startedAt,
      exercises: [
        ...exercises.sublist(0, exerciseIndex),
        updatedExercise,
        ...exercises.sublist(exerciseIndex + 1),
      ],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
  }

  void completeSeance() {
    if (state == null) return;
    final completed = Seance(
      id: state!.id,
      startedAt: state!.startedAt,
      exercises: state!.exercises,
      completedAt: DateTime.now(),
      restBetweenSets: state!.restBetweenSets,
    );
    ref.read(seanceHistoryProvider.notifier).addSeance(completed);
    state = null;
    // Stop notifications/foreground tasks
    unawaited(SeanceForegroundService.instance.stop());
  }
}

class SeanceHistoryNotifier extends Notifier<List<Seance>> {
  @override
  List<Seance> build() => _seedSeances();

  void addSeance(Seance seance) {
    state = [...state, seance];
  }
}

final _uuid = Uuid();

List<ExerciseDefinition> _seedExercises() {
  return [
    ExerciseDefinition(id: _uuid.v4(), name: 'Bench Press', category: 'Chest'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Squats', category: 'Legs'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Deadlifts', category: 'Back'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Pull-ups', category: 'Back'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Dumbbell Rows', category: 'Back'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Shoulder Press', category: 'Shoulders'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Lat Pulldown', category: 'Back'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Leg Press', category: 'Legs'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Dumbbell Curls', category: 'Arms'),
    ExerciseDefinition(id: _uuid.v4(), name: 'Tricep Dips', category: 'Arms'),
  ];
}

List<Seance> _seedSeances() => [];
