import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/planner_item.dart';
import '../repositories/planner_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Planner items provider (per day)
// ---------------------------------------------------------------------------

final plannerItemsProvider = FutureProvider.family<List<PlannerItem>, DateTime>(
  (ref, day) async {
    final repo = ref.watch(plannerRepositoryProvider);
    await repo.materializeForDay(day);
    return repo.getByDay(day);
  },
);

/// Every planner item (tasks and experiments) whose day falls within the
/// month containing [monthAnchor] — powers the calendar month markers.
final plannerMonthItemsProvider =
    FutureProvider.family<List<PlannerItem>, DateTime>((ref, monthAnchor) {
      final start = DateTime(monthAnchor.year, monthAnchor.month, 1);
      final end = DateTime(monthAnchor.year, monthAnchor.month + 1, 0);
      return ref.watch(plannerRepositoryProvider).getByRange(start, end);
    });

/// Every planner item within an inclusive (start, end) day range — powers
/// the week overview. Keyed by a record so each week caches independently.
final plannerRangeItemsProvider =
    FutureProvider.family<List<PlannerItem>, (DateTime, DateTime)>((
      ref,
      range,
    ) {
      final (start, end) = range;
      return ref
          .watch(plannerRepositoryProvider)
          .getByRange(
            DateTime(start.year, start.month, start.day),
            DateTime(end.year, end.month, end.day),
          );
    });
