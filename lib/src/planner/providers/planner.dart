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
