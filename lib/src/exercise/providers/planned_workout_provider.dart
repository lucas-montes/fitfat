import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../adapters/drift/planned_workout_repository.dart';
import '../../adapters/drift/seance.dart';
import '../../models/workout.dart' as domain;
import '../../services/logger.dart';

final _log = logger('planned_workout');

final plannedWorkoutProvider =
    NotifierProvider<PlannedWorkoutNotifier, List<domain.PlannedWorkout>>(
      PlannedWorkoutNotifier.new,
    );

class PlannedWorkoutNotifier extends Notifier<List<domain.PlannedWorkout>> {
  @override
  List<domain.PlannedWorkout> build() {
    Future.microtask(_loadAll);
    return [];
  }

  DriftPlannedWorkoutRepository get _repo =>
      ref.read(plannedWorkoutRepositoryProvider);

  DriftSeanceRepository get _seanceRepo => ref.read(seanceRepositoryProvider);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadAll() async {
    try {
      state = await _repo.listAll();
    } catch (e, stack) {
      _log.severe('Failed to load planned workouts', e, stack);
    }
  }

  /// Load planned workouts for the week containing [date].
  Future<void> loadByWeek(DateTime date) async {
    try {
      state = await _repo.loadByWeek(date);
    } catch (e, stack) {
      _log.severe('Failed to load planned workouts for week', e, stack);
    }
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Create a planned workout manually.
  Future<domain.PlannedWorkout> createPlannedWorkout(
    domain.PlannedWorkout plan,
  ) async {
    try {
      final saved = await _repo.create(plan);
      await _loadAll();
      return saved;
    } catch (e, stack) {
      _log.severe('Failed to create planned workout', e, stack);
      rethrow;
    }
  }

  /// Create a planned workout from a template, copying all weights and sets.
  Future<domain.PlannedWorkout> createFromTemplate({
    required String templateId,
    required DateTime scheduledDate,
    String? name,
  }) async {
    try {
      // Load template
      final templates = await _seanceRepo.listTemplates();
      final template = templates.firstWhere(
        (t) => t.id == templateId,
        orElse: () => throw StateError('Template not found: $templateId'),
      );

      final resolvedName = name ?? template.name;
      final plannedEntries = <domain.PlannedEntry>[];
      var sortOrder = 0;

      for (final templateExercise in template.exercises) {
        // Look up exercise by name (expected to always exist)
        final exerciseDef = await _repo.findExerciseByName(
          templateExercise.name,
        );
        if (exerciseDef == null) {
          _log.warning(
            'Exercise not found for template: ${templateExercise.name}, skipping',
          );
          continue;
        }

        final isCardio = exerciseDef.type == 'cardio';

        for (final plannedSet in templateExercise.plannedSets) {
          domain.PlannedCardio? plannedCardio;
          if (isCardio) {
            // Map weightKg → duration minutes for cardio
            plannedCardio = domain.PlannedCardio(
              plannedDurationMinutes: plannedSet.weightKg?.toInt() ?? 0,
            );
          }

          plannedEntries.add(
            domain.PlannedEntry(
              id: const Uuid().v4(),
              exercise: exerciseDef,
              plannedReps: plannedSet.reps,
              plannedWeightKg: plannedSet.weightKg ?? 0.0,
              plannedRestSeconds: plannedSet.restSeconds,
              sortOrder: sortOrder++,
              note: null,
              effortTarget: null,
              plannedCardio: plannedCardio,
            ),
          );
        }
      }

      final plan = domain.PlannedWorkout(
        id: const Uuid().v4(),
        scheduledDate: scheduledDate,
        name: resolvedName,
        entries: plannedEntries,
        source: 'from_template',
        templateId: templateId,
      );

      final saved = await _repo.create(plan);
      await _loadAll();
      return saved;
    } catch (e, stack) {
      _log.severe('Failed to create planned workout from template', e, stack);
      rethrow;
    }
  }

  /// Update an existing planned workout.
  Future<void> updatePlannedWorkout(domain.PlannedWorkout plan) async {
    try {
      await _repo.update(plan);
      await _loadAll();
    } catch (e, stack) {
      _log.severe('Failed to update planned workout', e, stack);
      rethrow;
    }
  }

  /// Delete a planned workout.
  Future<void> deletePlannedWorkout(String id) async {
    try {
      await _repo.delete(id);
      await _loadAll();
    } catch (e, stack) {
      _log.severe('Failed to delete planned workout', e, stack);
      rethrow;
    }
  }

  /// Mark a planned workout as completed and link to the actual workout.
  Future<void> markCompleted(String id, String completedWorkoutId) async {
    try {
      await _repo.markCompleted(id, completedWorkoutId);
      await _loadAll();
    } catch (e, stack) {
      _log.severe('Failed to mark planned workout completed', e, stack);
      rethrow;
    }
  }
}
