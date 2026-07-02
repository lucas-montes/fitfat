import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return ref.watch(workoutRepositoryProvider).getAll();
});

// ---------------------------------------------------------------------------
// Workout detail provider (family by id)
// ---------------------------------------------------------------------------

final workoutDetailProvider =
    FutureProvider.family<WorkoutWithDetails?, String>((ref, id) async {
      return ref.watch(workoutRepositoryProvider).getWithDetails(id);
    }, name: 'workoutDetailProvider');
