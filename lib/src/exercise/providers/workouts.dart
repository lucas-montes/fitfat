import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/startup_gate.dart';
import '../../database/database_provider.dart';
import '../../models/workout.dart';
import '../repositories/workout_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Workout list provider
// ---------------------------------------------------------------------------

final workoutListProvider = FutureProvider<List<Workout>>((ref) async {
  if (!ref.watch(startupGateProvider)) return const [];
  return ref.watch(workoutRepositoryProvider).getAll();
});

// ---------------------------------------------------------------------------
// Active workout provider
// ---------------------------------------------------------------------------

/// The workout currently in progress (started, not completed), or null.
///
/// Derives from [workoutListProvider], which every screen already invalidates
/// on mutation (start / complete / delete / undo in workout_detail and the
/// lists), so the global floating bar (T08) and the dashboard resume chip
/// (T09) stay in sync without a dedicated query or stream.
final activeWorkoutProvider = Provider<Workout?>((ref) {
  if (!ref.watch(startupGateProvider)) return null;
  final workouts = ref.watch(workoutListProvider).value;
  if (workouts == null) return null;
  for (final workout in workouts) {
    if (workout.isActive) return workout;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Workout detail provider (family by id)
// ---------------------------------------------------------------------------

final workoutDetailProvider =
    FutureProvider.family<WorkoutWithDetails?, String>((ref, id) async {
      return ref.watch(workoutRepositoryProvider).getWithDetails(id);
    }, name: 'workoutDetailProvider');

// ---------------------------------------------------------------------------
// Exercise history provider (family by exercise id)
// ---------------------------------------------------------------------------

final exerciseHistoryProvider =
    FutureProvider.family<List<ExerciseHistoryEntry>, String>((ref, id) async {
      return ref.watch(workoutRepositoryProvider).getExerciseHistory(id);
    }, name: 'exerciseHistoryProvider');
