import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_models.dart';
import '../models/seance_models.dart';
import '../services/seance_foreground_service.dart';
import 'database_providers.dart';

const _activeSeanceKey = 'active_seance_json';

final exerciseListProvider =
    NotifierProvider<ExerciseListNotifier, List<ExerciseDefinition>>(
      ExerciseListNotifier.new,
    );

class ExerciseListNotifier extends Notifier<List<ExerciseDefinition>> {
  @override
  List<ExerciseDefinition> build() {
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final rows = await db.getAllExercises();
      if (rows.isEmpty) return;
      state = rows
          .map(
            (e) => ExerciseDefinition(
              id: e.id,
              name: e.name,
              category: e.category,
            ),
          )
          .toList();
    } catch (_) {
      // DB not available (tests, first launch, etc.)
    }
  }
}

final activeSeanceProvider = NotifierProvider<ActiveSeanceNotifier, Seance?>(
  ActiveSeanceNotifier.new,
);

final seanceHistoryProvider =
    NotifierProvider<SeanceHistoryNotifier, List<Seance>>(
      SeanceHistoryNotifier.new,
    );

class ActiveSeanceNotifier extends Notifier<Seance?> {
  @override
  Seance? build() {
    // Kick off async restore from SharedPreferences on provider init
    Future.microtask(() => restoreFromPrefs());
    return null;
  }

  /// Call on app boot to restore active seance from SharedPreferences.
  Future<void> restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_activeSeanceKey);
    if (json == null) return;
    try {
      state = Seance.fromJson(
        Map<String, dynamic>.from(const JsonDecoder().convert(json) as Map),
      );
      if (state != null && state!.isActive) {
        unawaited(SeanceForegroundService.instance.start(state!.startedAt));
      }
    } catch (_) {
      await prefs.remove(_activeSeanceKey);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await prefs.remove(_activeSeanceKey);
    } else {
      await prefs.setString(
        _activeSeanceKey,
        const JsonEncoder().convert(state!.toJson()),
      );
    }
  }

  void startSeanceFromTemplate(SeanceTemplate template) {
    state = Seance(
      id: const Uuid().v4(),
      name: template.name,
      startedAt: DateTime.now(),
      exercises: template.exercises.map((e) {
        return ExerciseEntry(
          id: const Uuid().v4(),
          exercise: ExerciseDefinition(id: e.id, name: e.name),
          sets: e.plannedSets
              .map((ps) => ExerciseSet(reps: ps.reps, weight: ps.weightKg ?? 0))
              .toList(),
          startedAt: DateTime.now(),
        );
      }).toList(),
    );
    unawaited(SeanceForegroundService.instance.start(state!.startedAt));
    unawaited(_persist());
  }

  void startSeance() {
    state = Seance(
      id: const Uuid().v4(),
      startedAt: DateTime.now(),
      exercises: [],
    );
    unawaited(SeanceForegroundService.instance.start(state!.startedAt));
    unawaited(_persist());
  }

  void addExercise(ExerciseDefinition exercise) {
    if (state == null) return;
    final alreadyAdded = state!.exercises.any(
      (e) => e.exercise.name.toLowerCase() == exercise.name.toLowerCase(),
    );
    if (alreadyAdded) return;
    final newEntry = ExerciseEntry(
      id: const Uuid().v4(),
      exercise: exercise,
      sets: [],
      startedAt: DateTime.now(),
    );
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [...state!.exercises, newEntry],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
  }

  void removeExercise(int index) {
    if (state == null || index >= state!.exercises.length) return;
    final exercises = List<ExerciseEntry>.from(state!.exercises)
      ..removeAt(index);
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: exercises,
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
  }

  void addSet(int exerciseIndex, int reps, double weight) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;
    final exercises = state!.exercises;
    final exercise = exercises[exerciseIndex];
    final updatedExercise = ExerciseEntry(
      id: exercise.id,
      exercise: exercise.exercise,
      sets: [
        ...exercise.sets,
        ExerciseSet(reps: reps, weight: weight),
      ],
      startedAt: exercise.startedAt,
      completedAt: exercise.completedAt,
    );
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [
        ...exercises.sublist(0, exerciseIndex),
        updatedExercise,
        ...exercises.sublist(exerciseIndex + 1),
      ],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
  }

  void completeSeance() {
    if (state == null) return;
    final completed = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: state!.exercises,
      completedAt: DateTime.now(),
      restBetweenSets: state!.restBetweenSets,
    );
    ref.read(seanceHistoryProvider.notifier).addSeance(completed);
    state = null;
    unawaited(SeanceForegroundService.instance.stop());
    unawaited(_persist());
  }

  void cancelSeance() {
    if (state == null) return;
    state = null;
    unawaited(SeanceForegroundService.instance.stop());
    unawaited(_persist());
  }
}

class SeanceHistoryNotifier extends Notifier<List<Seance>> {
  @override
  List<Seance> build() => _seedSeances();

  void addSeance(Seance seance) {
    state = [...state, seance];
  }
}

List<Seance> _seedSeances() => [];
