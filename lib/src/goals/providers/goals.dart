import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../planner/providers/planner.dart' show linksRepositoryProvider;
import '../repositories/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(databaseProvider));
});

/// All goals, newest started first.
final goalListProvider = FutureProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).getGoals();
});

/// A single goal by id, or null when it does not exist.
final goalByIdProvider = FutureProvider.family<Goal?, String>((ref, id) {
  return ref.watch(goalRepositoryProvider).getGoalById(id);
});

/// Progress log for a goal, newest day first.
final goalProgressProvider = FutureProvider.family<List<GoalProgress>, String>((
  ref,
  goalId,
) {
  return ref.watch(goalRepositoryProvider).getProgressLog(goalId);
});

/// Latest recorded progress value per goal id, or null when nothing recorded.
final latestGoalProgressProvider = FutureProvider.family<double?, String>((
  ref,
  goalId,
) {
  return ref.watch(goalRepositoryProvider).getLatestProgressValue(goalId);
});

/// Tasks linked to a goal via the `task_goals` link table, ordered by day
/// then sort order. Each carries its optional relationship label.
final tasksByGoalProvider =
    FutureProvider.family<List<({Task item, String? label})>, String>((
      ref,
      goalId,
    ) {
      return ref.watch(linksRepositoryProvider).tasksForGoal(goalId);
    });
