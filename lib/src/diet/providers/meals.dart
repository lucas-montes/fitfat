import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/startup_gate.dart';
import '../../database/database_provider.dart';
import '../../models/meal_entry.dart';
import '../repositories/meal_repository.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Meal list provider
// ---------------------------------------------------------------------------

final mealListProvider = FutureProvider<List<MealEntry>>((ref) async {
  if (!ref.watch(startupGateProvider)) return const [];
  return ref.watch(mealRepositoryProvider).getAll();
});
