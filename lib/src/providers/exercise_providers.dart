import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart'
    hide Seance, ExerciseEntry, ExerciseSet, Exercise;
import '../models/exercise_models.dart';
import '../models/seance_models.dart';
import '../services/logger.dart';
import '../services/seance_foreground_service.dart';
import 'database_providers.dart';

final _log = logger('exercise_providers');

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
    } catch (_) {}
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
    Future.microtask(() => restoreFromPrefs());
    return null;
  }

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
    } catch (e, stack) {
      _log.warning('Could not load exercise from DB', e, stack);
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
      exercises: template.exercises
          .map(
            (e) => ExerciseEntry(
              id: const Uuid().v4(),
              exercise: ExerciseDefinition(id: e.id, name: e.name),
              sets: e.plannedSets
                  .map(
                    (ps) =>
                        ExerciseSet(reps: ps.reps, weight: ps.weightKg ?? 0),
                  )
                  .toList(),
              startedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
    unawaited(
      SeanceForegroundService.instance.start(
        state!.startedAt,
        seanceName: template.name,
      ),
    );
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
    if (state!.exercises.any(
      (e) => e.exercise.name.toLowerCase() == exercise.name.toLowerCase(),
    ))
      return;
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [
        ...state!.exercises,
        ExerciseEntry(
          id: const Uuid().v4(),
          exercise: exercise,
          sets: [],
          startedAt: DateTime.now(),
        ),
      ],
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
    final now = DateTime.now();
    final updatedSets = exercise.sets
        .map(
          (s) => s.isCompleted
              ? s
              : ExerciseSet(reps: s.reps, weight: s.weight, completedAt: now),
        )
        .followedBy([ExerciseSet(reps: reps, weight: weight, completedAt: now)])
        .toList();
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [
        ...exercises.sublist(0, exerciseIndex),
        ExerciseEntry(
          id: exercise.id,
          exercise: exercise.exercise,
          sets: updatedSets,
          startedAt: exercise.startedAt,
          completedAt: exercise.completedAt,
        ),
        ...exercises.sublist(exerciseIndex + 1),
      ],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
    unawaited(SeanceForegroundService.instance.lastSetCompleted());
  }

  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;
    final exercise = state!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final updatedSets = [
      for (int i = 0; i < exercise.sets.length; i++)
        if (i == setIndex)
          ExerciseSet(
            reps: set.reps,
            weight: set.weight,
            completedAt: set.isCompleted ? null : DateTime.now(),
          )
        else
          exercise.sets[i],
    ];
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [
        ...state!.exercises.sublist(0, exerciseIndex),
        ExerciseEntry(
          id: exercise.id,
          exercise: exercise.exercise,
          sets: updatedSets,
          startedAt: exercise.startedAt,
          completedAt: exercise.completedAt,
        ),
        ...state!.exercises.sublist(exerciseIndex + 1),
      ],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
  }

  void updateSet(int exerciseIndex, int setIndex, int reps, double weight) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;
    final exercise = state!.exercises[exerciseIndex];
    final updatedSets = [
      for (int i = 0; i < exercise.sets.length; i++)
        if (i == setIndex)
          ExerciseSet(reps: reps, weight: weight)
        else
          exercise.sets[i],
    ];
    state = Seance(
      id: state!.id,
      name: state!.name,
      startedAt: state!.startedAt,
      exercises: [
        ...state!.exercises.sublist(0, exerciseIndex),
        ExerciseEntry(
          id: exercise.id,
          exercise: exercise.exercise,
          sets: updatedSets,
          startedAt: exercise.startedAt,
          completedAt: exercise.completedAt,
        ),
        ...state!.exercises.sublist(exerciseIndex + 1),
      ],
      completedAt: state!.completedAt,
      restBetweenSets: state!.restBetweenSets,
    );
    unawaited(_persist());
  }

  void completeSeance() {
    if (state == null) return;
    final now = DateTime.now();
    final defaultName =
        'Seance - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final completed = Seance(
      id: state!.id,
      name: state!.name ?? defaultName,
      startedAt: state!.startedAt,
      exercises: state!.exercises,
      completedAt: now,
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
  List<Seance> build() {
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final seanceRows = await (db.select(
        db.seances,
      )..where((t) => t.completedAt.isNotNull())).get();
      final result = <Seance>[];
      for (final sr in seanceRows) {
        final entryRows = await (db.select(
          db.exerciseEntries,
        )..where((t) => t.seanceId.equals(sr.id))).get();
        final exercises = <ExerciseEntry>[];
        for (final er in entryRows) {
          // Look up the exercise name from the exercises table
          final exRow = await (db.select(
            db.exercises,
          )..where((t) => t.id.equals(er.exerciseId))).getSingleOrNull();
          final setRows = await (db.select(
            db.exerciseSets,
          )..where((t) => t.entryId.equals(er.id))).get();
          exercises.add(
            ExerciseEntry(
              id: er.id,
              exercise: ExerciseDefinition(
                id: er.exerciseId,
                name: exRow?.name ?? '',
              ),
              sets: setRows
                  .map((s) => ExerciseSet(reps: s.reps, weight: s.weight))
                  .toList(),
              startedAt: er.startedAt,
              completedAt: er.completedAt,
            ),
          );
        }
        result.add(
          Seance(
            id: sr.id,
            name: sr.name,
            startedAt: sr.startedAt,
            exercises: exercises,
            completedAt: sr.completedAt,
          ),
        );
      }
      if (result.isNotEmpty) state = result;
    } catch (e, stack) {
      _log.severe('Failed to load seance history', e, stack);
    }
  }

  Future<void> _saveToDb(Seance seance) async {
    try {
      final db = ref.read(databaseProvider);
      // Save the seance
      await db
          .into(db.seances)
          .insert(
            SeancesCompanion(
              id: Value(seance.id),
              name: Value(seance.name),
              startedAt: Value(seance.startedAt),
              completedAt: Value(seance.completedAt),
              restBetweenSetsMillis: Value(
                seance.restBetweenSets.inMilliseconds,
              ),
            ),
            mode: InsertMode.insertOrReplace,
          );
      // Save each exercise entry + sets
      for (final entry in seance.exercises) {
        final existing = await (db.select(
          db.exercises,
        )..where((t) => t.name.equals(entry.exercise.name))).get();
        final exerciseId = existing.isNotEmpty
            ? existing.first.id
            : const Uuid().v4();
        if (existing.isEmpty) {
          await db
              .into(db.exercises)
              .insert(
                ExercisesCompanion.insert(
                  id: exerciseId,
                  name: entry.exercise.name,
                  category: entry.exercise.category,
                ),
              );
        }
        await db
            .into(db.exerciseEntries)
            .insert(
              ExerciseEntriesCompanion(
                id: Value(entry.id),
                seanceId: Value(seance.id),
                exerciseId: Value(exerciseId),
                startedAt: Value(entry.startedAt),
                completedAt: Value(entry.completedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
        for (final set in entry.sets) {
          await db
              .into(db.exerciseSets)
              .insert(
                ExerciseSetsCompanion.insert(
                  id: const Uuid().v4(),
                  entryId: entry.id,
                  reps: set.reps,
                  weight: set.weight,
                ),
              );
        }
      }
    } catch (e, stack) {
      _log.severe('Failed to save seance', e, stack);
    }
  }

  void addSeance(Seance seance) {
    state = [...state, seance];
    unawaited(_saveToDb(seance));
  }
}
