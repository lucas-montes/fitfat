import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/providers.dart';
import '../../models/workout.dart';
import '../../services/logger.dart';

final _log = logger('exercise_providers');

final exerciseListProvider =
    NotifierProvider<ExerciseListNotifier, List<ExerciseDefinition>>(
      ExerciseListNotifier.new,
    );

/// Manages the global exercise library.
/// State: All available exercises loaded from DB.
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
            (exercise) => ExerciseDefinition(
              id: exercise.id,
              name: exercise.name,
              type: ExerciseType.values.firstWhere(
                (e) => e.name == exercise.type,
                orElse: () => ExerciseType.weightlifting,
              ),
              met: exercise.met,
              description: exercise.description,
              imageUrl: exercise.imageUrl,
            ),
          )
          .toList();
    } catch (e, stack) {
      _log.warning('Failed to load exercises from database', e, stack);
    }
  }
}
