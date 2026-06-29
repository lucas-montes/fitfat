import 'dart:async';
import 'dart:io' show Platform;

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

      // Load translations for the device locale (language part only, e.g. "fr")
      final locale = Platform.localeName.split('_').first;
      final translations = await db.getTranslations(locale);
      final translationMap = {for (final t in translations) t.exerciseId: t};

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
              localizedName: translationMap[exercise.id]?.name,
              localizedDescription: translationMap[exercise.id]?.description,
            ),
          )
          .toList();
    } catch (e, stack) {
      _log.warning('Failed to load exercises from database', e, stack);
    }
  }
}
