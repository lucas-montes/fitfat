import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../diet/repositories/meal_repository.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/repositories/workout_repository.dart';
import '../../models/planner_item.dart';
import '../../models/workout.dart';
import '../../planner/repositories/planner_repository.dart';

/// Today's macro totals in grams, read-only composition data for the hero card.
typedef TodayMacros = ({double protein, double carbs, double fat});

// ---------------------------------------------------------------------------
// Dashboard refresh signal
// ---------------------------------------------------------------------------
// The dashboard lives inside a `StatefulShellRoute.indexedStack`, so its widget
// is kept alive and never rebuilds when the user switches tabs. Its data
// providers are `FutureProvider`s that cache their result, so mutations made on
// other tabs (planner, diet, workouts) would otherwise never be reflected.
// Any code that changes data shown on the dashboard calls `invalidateDashboard`
// (which bumps this counter); every dashboard data provider watches it and
// therefore recomputes.

final class DashboardRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dashboardRefreshProvider = NotifierProvider<
  DashboardRefreshNotifier,
  int
>(DashboardRefreshNotifier.new);

/// Forces every dashboard data provider to recompute on its next read. Call
/// this after any mutation that affects dashboard content (planner tasks,
/// meals, workouts, body metrics, ...).
void invalidateDashboard(WidgetRef ref) =>
    ref.read(dashboardRefreshProvider.notifier).bump();

// ---------------------------------------------------------------------------
// Repository providers (local to dashboard domain)
// ---------------------------------------------------------------------------

final _mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

final _workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

final _plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Today's total calories
// ---------------------------------------------------------------------------

final todayCaloriesProvider = FutureProvider<double>((ref) async {
  ref.watch(dashboardRefreshProvider);
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
// Today's macros (P/C/F grams) — composition data for the hero card
// ---------------------------------------------------------------------------

final todayMacrosProvider = FutureProvider<TodayMacros>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final meals = await ref.watch(_mealRepositoryProvider).getAll();
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final todayMeals = meals.where(
    (m) => m.eatenAt.isAfter(todayStart) && m.eatenAt.isBefore(todayEnd),
  );

  var protein = 0.0;
  var carbs = 0.0;
  var fat = 0.0;
  for (final meal in todayMeals) {
    for (final item in meal.items) {
      protein += item.protein;
      carbs += item.carbs;
      fat += item.fat;
    }
  }
  return (protein: protein, carbs: carbs, fat: fat);
});

// ---------------------------------------------------------------------------
// Latest completed workout
// ---------------------------------------------------------------------------

final latestWorkoutProvider = FutureProvider<Workout?>((ref) async {
  ref.watch(dashboardRefreshProvider);
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  final completed = workouts.where((w) => w.isCompleted).toList();
  if (completed.isEmpty) return null;
  // Workouts are already ordered by date desc, so first is latest
  return completed.first;
});

// ---------------------------------------------------------------------------
// Weekly workout volume + minutes (last 7 days, completed workouts)
// ---------------------------------------------------------------------------

typedef WeeklyWorkoutStats = ({double totalVolumeKg, int totalMinutes});

final weeklyWorkoutStatsProvider = FutureProvider<WeeklyWorkoutStats>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day - 6);

  var volumeKg = 0.0;
  var minutes = 0;
  for (final workout in workouts) {
    if (!workout.isCompleted) continue;
    final day = DateTime(
      workout.completedAt!.year,
      workout.completedAt!.month,
      workout.completedAt!.day,
    );
    if (day.isBefore(weekStart)) continue;

    final detail = await ref.watch(workoutDetailProvider(workout.id).future);
    if (detail == null) continue;
    for (final block in detail.exercises) {
      for (final set in block.sets) {
        volumeKg += set.totalVolume;
      }
    }
    minutes += workout.duration.inMinutes;
  }
  return (totalVolumeKg: volumeKg, totalMinutes: minutes);
});

// ---------------------------------------------------------------------------
// Upcoming timed tasks (pending, today or later, with a start time)
// ---------------------------------------------------------------------------

final upcomingTimedTasksProvider = FutureProvider<List<PlannerItem>>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  final today = DateTime.now();
  return ref
      .watch(_plannerRepositoryProvider)
      .getUpcomingWithStartTime(today);
});
