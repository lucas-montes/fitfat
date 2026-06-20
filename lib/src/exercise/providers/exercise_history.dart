import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adapters/drift/workout_repository.dart';
import '../../models/workout.dart';
import '../services/workout_services.dart';
import 'workout_history.dart';

/// Structured history data for a single exercise.
class ExerciseHistoryData {
  const ExerciseHistoryData({
    required this.sessionsCount,
    required this.totalVolume,
    required this.sessions,
  });

  static const empty = ExerciseHistoryData(
    sessionsCount: 0,
    totalVolume: 0,
    sessions: [],
  );

  final int sessionsCount;
  final double totalVolume;
  final List<ExerciseHistorySession> sessions;
}

/// A single workout session that included the exercise.
class ExerciseHistorySession {
  const ExerciseHistorySession({
    required this.workoutId,
    required this.workoutName,
    required this.date,
    required this.sets,
  });

  final String workoutId;
  final String workoutName;
  final DateTime date;
  final List<WeightSet> sets;
}

/// Loads completed WeightSets for a specific exercise across all workouts.
/// Watches workoutHistoryProvider so data refreshes when new workouts complete.
final exerciseHistoryProvider =
    FutureProvider.family<ExerciseHistoryData, String>((ref, exerciseId) async {
      final repo = ref.read(workoutRepositoryProvider);
      final history = ref.watch(workoutHistoryProvider).asData?.value ?? [];

      // Quick lookup: workout ID -> workout
      final workoutMap = <String, Workout>{};
      for (final w in history) {
        workoutMap[w.id] = w;
      }

      // Load all completed weight sets for this exercise
      final sets = await repo.getCompletedWeightSetsByExercise(exerciseId);
      if (sets.isEmpty) return ExerciseHistoryData.empty;

      // Group by workout
      final grouped = <String, List<WeightSet>>{};
      for (final set in sets) {
        grouped.putIfAbsent(set.workoutId, () => []).add(set);
      }

      // Build sessions
      final progression = ProgressionService();
      var totalVolume = 0.0;
      final sessions = <ExerciseHistorySession>[];

      for (final entry in grouped.entries) {
        final workout = workoutMap[entry.key];
        final date =
            entry.value.first.completedAt ??
            workout?.completedAt ??
            workout?.startedAt ??
            DateTime.now();
        sessions.add(
          ExerciseHistorySession(
            workoutId: entry.key,
            workoutName: workout?.name ?? 'Workout',
            date: date,
            sets: entry.value,
          ),
        );
        totalVolume += progression.totalVolumeFromWeightSets(entry.value);
      }

      // Sort by date descending (most recent first)
      sessions.sort((a, b) => b.date.compareTo(a.date));

      return ExerciseHistoryData(
        sessionsCount: sessions.length,
        totalVolume: totalVolume,
        sessions: sessions,
      );
    });
