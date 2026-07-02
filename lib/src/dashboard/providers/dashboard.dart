import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../diet/repositories/meal_repository.dart';
import '../../exercise/repositories/workout_repository.dart';
import '../../models/workout.dart';

// ---------------------------------------------------------------------------
// Repository providers (local to dashboard domain)
// ---------------------------------------------------------------------------

final _mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

final _workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Today's total calories
// ---------------------------------------------------------------------------

final todayCaloriesProvider = FutureProvider<double>((ref) async {
  final meals = await ref.watch(_mealRepositoryProvider).getAll();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final todayMeals = meals.where(
    (m) => m.eatenAt.isAfter(todayStart) && m.eatenAt.isBefore(todayEnd),
  );

  return todayMeals.fold<double>(0.0, (sum, m) => sum + m.totalCalories);
});

// ---------------------------------------------------------------------------
// Latest completed workout
// ---------------------------------------------------------------------------

final latestWorkoutProvider = FutureProvider<Workout?>((ref) async {
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  final completed = workouts.where((w) => w.isCompleted).toList();
  if (completed.isEmpty) return null;
  // Workouts are already ordered by date desc, so first is latest
  return completed.first;
});
