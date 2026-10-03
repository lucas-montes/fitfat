import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/food.dart';
import '../repositories/food_repository.dart';
import 'ingredients.dart';

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Food list
// ---------------------------------------------------------------------------

/// Every active food with its **live** per-100g profile, name-ordered.
///
/// This is what the foods list and the meal picker render. Nutrition is resolved
/// on read — a recipe is never snapshotted here — so an ingredient edit shows up
/// immediately. (A *logged meal* is the opposite: it snapshots, so history is
/// stable. See `MealRepository`.)
final foodListProvider = FutureProvider<List<ResolvedFood>>((ref) async {
  return ref.watch(foodRepositoryProvider).getAllWithNutrition();
});

/// Only the foods a user created — the combinations. Derived 1:1 foods are
/// filtered out because they are the ingredient's own wrapper, not a recipe the
/// user authored, and there is one per ingredient.
final foodCombinationProvider = FutureProvider<List<ResolvedFood>>((ref) async {
  final all = await ref.watch(foodListProvider.future);
  return [
    for (final entry in all)
      if (!entry.food.isDerived) entry,
  ];
});

// ---------------------------------------------------------------------------
// Single food / composition
// ---------------------------------------------------------------------------

/// One food with its composition loaded; `null` when it does not exist.
final foodByIdProvider = FutureProvider.autoDispose
    .family<({Food food, FoodNutrition? nutrition})?, String>((ref, id) async {
      final repo = ref.watch(foodRepositoryProvider);
      final food = await repo.getById(id);
      if (food == null) return null;
      return (food: food, nutrition: await repo.resolveNutrition(id));
    });

/// The composition of a food, alphabetical by ingredient name.
final foodIngredientsProvider = FutureProvider.autoDispose
    .family<List<FoodIngredient>, String>((ref, foodId) async {
      return ref.watch(foodRepositoryProvider).getComponents(foodId);
    });

/// Invalidates the foods surface after a composition change.
///
/// Ingredients are invalidated too: a composition references them, so a renamed
/// or re-macros'd ingredient has to reach the resolved numbers on the foods list.
void invalidateFoods(WidgetRef ref) {
  ref.invalidate(foodListProvider);
  ref.invalidate(foodCombinationProvider);
  ref.invalidate(ingredientListProvider);
}
