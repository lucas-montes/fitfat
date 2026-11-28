import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/startup_gate.dart';
import '../../database/database_provider.dart';
import '../../diet/repositories/meal_repository.dart';
import '../../diet/services/food_nutrition.dart';
import '../../exercise/repositories/workout_repository.dart';
import '../../models/task.dart';
import '../../models/workout.dart';
import '../../planner/repositories/task_repository.dart';

/// Today's macro totals in grams, read-only composition data for the hero card.
typedef TodayMacros = ({
  double protein,
  double carbs,
  double fat,
  double fiber,
});

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

final dashboardRefreshProvider =
    NotifierProvider<DashboardRefreshNotifier, int>(
      DashboardRefreshNotifier.new,
    );

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

final _taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider));
});

/// Today's logged nutrition, straight from the `meal_foods` snapshots in a
/// single aggregate query.
///
/// Shared by [todayCaloriesProvider] and [todayMacrosProvider] so the two
/// hero-card numbers cost one query between them instead of each walking the
/// entire meal history (which is what they used to do, twice).
final todayNutritionProvider = FutureProvider<Nutrition>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) {
    return (
      calories: 0.0,
      protein: 0.0,
      carbs: 0.0,
      fat: 0.0,
      sodium: 0.0,
      fiber: 0.0,
      sugar: 0.0,
    );
  }
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  return ref
      .watch(_mealRepositoryProvider)
      .totalsBetween(todayStart, todayStart.add(const Duration(days: 1)));
});

// ---------------------------------------------------------------------------
// Today's total calories
// ---------------------------------------------------------------------------

final todayCaloriesProvider = FutureProvider<double>((ref) async {
  final nutrition = await ref.watch(todayNutritionProvider.future);
  return nutrition.calories;
});

// ---------------------------------------------------------------------------
// Today's macros (P/C/F/fiber grams) — composition data for the hero card
// ---------------------------------------------------------------------------

final todayMacrosProvider = FutureProvider<TodayMacros>((ref) async {
  final nutrition = await ref.watch(todayNutritionProvider.future);
  return (
    protein: nutrition.protein,
    carbs: nutrition.carbs,
    fat: nutrition.fat,
    fiber: nutrition.fiber,
  );
});

// ---------------------------------------------------------------------------
// Latest completed workout
// ---------------------------------------------------------------------------

final latestWorkoutProvider = FutureProvider<Workout?>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) return null;
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  // getAll() is newest first (day, then time of day).
  final completed = workouts.where((w) => w.isCompleted);
  return completed.isEmpty ? null : completed.first;
});

// ---------------------------------------------------------------------------
// Weekly workout stats (current calendar week, completed workouts)
// ---------------------------------------------------------------------------

typedef WeeklyWorkoutStats = ({
  double totalVolumeKg,
  int totalMinutes,
  int daysTrained,
  int workouts,
});

/// Monday 00:00 local of the week containing [now].
///
/// A calendar week, not a rolling seven days: the two differ on every day
/// except the seventh, and a rolling window silently attributes last
/// weekend's training to this week — which reads as "3/7 days" on a week
/// where nothing was done.
DateTime startOfCalendarWeek(DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).subtract(Duration(days: now.weekday - DateTime.monday));

// Days trained renders as `x/7` (`dashboardDaysTrainedValue`). The denominator
// is the whole week even on a Monday: the tile reads as progress toward a
// weekly target, and `1/1` would report full marks on day one.
final weeklyWorkoutStatsProvider = FutureProvider<WeeklyWorkoutStats>((
  ref,
) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) {
    return (totalVolumeKg: 0.0, totalMinutes: 0, daysTrained: 0, workouts: 0);
  }
  final weekStart = startOfCalendarWeek(DateTime.now());

  // Bulk aggregate — no per-workout `workoutDetailProvider` resolution
  // (perf T03).
  final stats = await ref
      .watch(_workoutRepositoryProvider)
      .getVolumeAndMinutesBetween(
        weekStart,
        weekStart.add(const Duration(days: 7)),
      );
  return (
    totalVolumeKg: stats.volumeKg,
    totalMinutes: stats.minutes,
    daysTrained: stats.daysTrained,
    workouts: stats.workouts,
  );
});

// ---------------------------------------------------------------------------
// Upcoming timed tasks (pending, today or later, with a start time)
// ---------------------------------------------------------------------------

final upcomingTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) return const [];
  final today = DateTime.now();
  return ref.watch(_taskRepositoryProvider).getUpcoming(today);
});

// ---------------------------------------------------------------------------
// Today's tasks (any status except cancelled), for the dashboard tasks card
// ---------------------------------------------------------------------------

final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) return const [];
  final tasks = await ref
      .watch(_taskRepositoryProvider)
      .getByDay(DateTime.now());
  return [
    for (final t in tasks)
      if (t.taskStatus != TaskStatus.cancelled) t,
  ]..sort((a, b) {
    // Open tasks first, then by start time (untimed last).
    if (a.done != b.done) return a.done ? 1 : -1;
    return (a.startTimeMinutes ?? 24 * 60).compareTo(
      b.startTimeMinutes ?? 24 * 60,
    );
  });
});

// ---------------------------------------------------------------------------
// Days of the current calendar week with a workout (0 = Monday)
// ---------------------------------------------------------------------------

final weekTrainingDaysProvider = FutureProvider<Set<int>>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) return const {};
  final weekStart = startOfCalendarWeek(DateTime.now());
  final weekEnd = weekStart.add(const Duration(days: 7));
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  return {
    for (final w in workouts)
      if (!w.isPending &&
          !w.date.isBefore(weekStart) &&
          w.date.isBefore(weekEnd))
        w.date.weekday - DateTime.monday,
  };
});

// ---------------------------------------------------------------------------
// Next pending workout (planned, not started, today or later)
// ---------------------------------------------------------------------------

/// The soonest workout that is planned but not started, dated today or
/// later. Older pending ones are stale plans and are left out.
final nextPendingWorkoutProvider = FutureProvider<Workout?>((ref) async {
  ref.watch(dashboardRefreshProvider);
  if (!ref.watch(startupGateProvider)) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final workouts = await ref.watch(_workoutRepositoryProvider).getAll();
  final pending = [
    for (final w in workouts)
      if (w.isPending && !w.date.isBefore(today)) w,
  ]..sort((a, b) => a.sortTime.compareTo(b.sortTime));
  return pending.firstOrNull;
});
