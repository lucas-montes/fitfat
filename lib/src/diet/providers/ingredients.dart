import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/ingredient.dart';

import '../../models/ingredient_picture.dart';
import '../../models/ingredient_price.dart';
import '../../models/store.dart';
import '../repositories/ingredient_repository.dart';
import 'foods.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  return IngredientRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// Ingredient list provider
// ---------------------------------------------------------------------------

final ingredientListProvider = FutureProvider<List<Ingredient>>((ref) async {
  return ref.watch(ingredientRepositoryProvider).getAll();
});

/// Resolves a single ingredient by id; `null` when it doesn't exist (the
/// detail screen's not-found state).
final ingredientByIdProvider = FutureProvider.autoDispose
    .family<Ingredient?, String>((ref, id) async {
      return ref.watch(ingredientRepositoryProvider).getById(id);
    });

// ---------------------------------------------------------------------------
// Stores / pictures / prices providers (v20)
// ---------------------------------------------------------------------------

final storesProvider = FutureProvider<List<Store>>((ref) async {
  return ref.watch(ingredientRepositoryProvider).getStores();
});

final ingredientPicturesProvider = FutureProvider.autoDispose
    .family<List<IngredientPicture>, String>((ref, ingredientId) async {
      return ref.watch(ingredientRepositoryProvider).getPictures(ingredientId);
    });

/// Full price history per ingredient (newest first), each entry paired with
/// its store.
final ingredientPricesProvider = FutureProvider.autoDispose
    .family<List<(IngredientPrice, Store)>, String>((ref, ingredientId) async {
      return ref.watch(ingredientRepositoryProvider).getPrices(ingredientId);
    });

/// Invalidates the ingredient surface after an edit.
///
/// Also invalidates the foods list: foods resolve their nutrition **live** from
/// ingredient rows, so a macro or name change has to reach the foods list and
/// the meal picker too.
void invalidateIngredients(WidgetRef ref) {
  ref.invalidate(ingredientListProvider);
  ref.invalidate(foodListProvider);
  ref.invalidate(foodCombinationProvider);
}
