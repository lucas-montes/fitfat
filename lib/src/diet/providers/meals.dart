import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  return ref.watch(mealRepositoryProvider).getAll();
});
