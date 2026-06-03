import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../adapters/drift/seance.dart';
import '../../models/exercise.dart';
import '../../models/seance.dart';
import '../../database/providers.dart';
import '../../services/logger.dart';
import '../../services/seance_foreground_service.dart';
import 'seances/history.dart';

final _log = logger('exercise_seance');
const _activeSeanceKey = 'active_seance_json';

final activeSeanceProvider = NotifierProvider<ActiveSeanceNotifier, Seance?>(
  ActiveSeanceNotifier.new,
);

final seanceRepositoryProvider = Provider<DriftSeanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftSeanceRepository(db);
});

final templateListProvider =
    NotifierProvider<TemplateListNotifier, List<SeanceTemplate>>(
      TemplateListNotifier.new,
    );

final activeSeancePlanProvider =
    NotifierProvider<ActiveSeancePlanNotifier, Map<String, ExerciseTemplate>>(
      ActiveSeancePlanNotifier.new,
    );

class ActiveSeanceNotifier extends Notifier<Seance?> {
  @override
  Seance? build() {
    Future.microtask(restoreFromPrefs);
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
      _log.warning('Could not restore active seance', e, stack);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await prefs.remove(_activeSeanceKey);
      return;
    }
    await prefs.setString(
      _activeSeanceKey,
      const JsonEncoder().convert(state!.toJson()),
    );
  }

  void startSeanceFromTemplate(SeanceTemplate template) {
    state = Seance(
      id: const Uuid().v4(),
      name: template.name,
      startedAt: DateTime.now(),
      exercises: template.exercises
          .map(
            (exerciseTemplate) => ExerciseEntry(
              id: const Uuid().v4(),
              exercise: ExerciseDefinition(
                id: exerciseTemplate.id,
                name: exerciseTemplate.name,
              ),
              sets: exerciseTemplate.plannedSets
                  .map(
                    (plannedSet) => ExerciseSet(
                      reps: plannedSet.reps,
                      weight: plannedSet.weightKg ?? 0,
                    ),
                  )
                  .toList(),
              startedAt: DateTime.now(),
            ),
          )
          .toList(),
      restBetweenSets: const Duration(seconds: 90),
      isGuided: true,
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
    final now = DateTime.now();
    final defaultName =
        'Workout - ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    state = Seance(
      id: const Uuid().v4(),
      name: defaultName,
      startedAt: now,
      exercises: [],
    );
    unawaited(SeanceForegroundService.instance.start(state!.startedAt));
    unawaited(_persist());
  }

  void addExercise(ExerciseDefinition exercise) {
    if (state == null) return;
    if (state!.exercises.any(
      (entry) =>
          entry.exercise.name.toLowerCase() == exercise.name.toLowerCase(),
    )) {
      return;
    }
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
    unawaited(
      SeanceForegroundService.instance.updateExerciseName(exercise.name),
    );
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
    final exercise = state!.exercises[exerciseIndex];
    final now = DateTime.now();
    final updatedSets = [
      ...exercise.sets,
      ExerciseSet(reps: reps, weight: weight, completedAt: now),
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
    unawaited(SeanceForegroundService.instance.lastSetCompleted());
  }

  void toggleSetCompleted(int exerciseIndex, int setIndex) {
    if (state == null || exerciseIndex >= state!.exercises.length) return;
    final exercise = state!.exercises[exerciseIndex];
    final set = exercise.sets[setIndex];
    final updatedSets = [
      for (var i = 0; i < exercise.sets.length; i++)
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
    final currentSet = exercise.sets[setIndex];
    final updatedSets = [
      for (var i = 0; i < exercise.sets.length; i++)
        if (i == setIndex)
          ExerciseSet(
            reps: reps,
            weight: weight,
            completedAt: currentSet.completedAt,
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

  void completeSeance() {
    if (state == null) return;
    if (state!.exercises.isEmpty) {
      state = null;
      unawaited(SeanceForegroundService.instance.stop());
      unawaited(_persist());
      return;
    }
    final now = DateTime.now();
    final completed = Seance(
      id: state!.id,
      name: state!.name,
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

class TemplateListNotifier extends Notifier<List<SeanceTemplate>> {
  late final DriftSeanceRepository _repo;

  @override
  List<SeanceTemplate> build() {
    _repo = ref.read(seanceRepositoryProvider);
    // NOTE: this actually works, the async task is scheduled and the state updated once it loads the data
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    state = await _repo.listTemplates();
  }

  Future<void> loadTemplates() async {
    state = await _repo.listTemplates();
  }

  Future<void> createTemplate(SeanceTemplate template) async {
    final created = await _repo.createTemplate(template);
    state = [...state, created];
  }

  Future<void> updateTemplate(SeanceTemplate template) async {
    final updated = await _repo.updateTemplate(template);
    state = state
        .map((current) => current.id == updated.id ? updated : current)
        .toList();
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.deleteTemplate(id);
    state = state.where((template) => template.id != id).toList();
  }

  Future<SeanceTemplate> cloneTemplate(
    String id, {
    DateTime? scheduledFor,
  }) async {
    final cloned = await _repo.cloneTemplate(id, scheduledFor: scheduledFor);
    state = [...state, cloned];
    return cloned;
  }
}

class ActiveSeancePlanNotifier extends Notifier<Map<String, ExerciseTemplate>> {
  @override
  Map<String, ExerciseTemplate> build() => {};

  void setPlanForEntry(String entryId, ExerciseTemplate plan) {
    state = {...state, entryId: plan};
  }

  void clear() {
    state = {};
  }

  void populateFromTemplate(SeanceTemplate template) {
    final seance = ref.read(activeSeanceProvider);
    if (seance == null) return;
    final map = <String, ExerciseTemplate>{};
    for (
      var i = 0;
      i < template.exercises.length && i < seance.exercises.length;
      i++
    ) {
      map[seance.exercises[i].id] = template.exercises[i];
    }
    state = map;
  }
}
