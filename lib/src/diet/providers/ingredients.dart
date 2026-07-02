import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/ingredient.dart';
import '../repositories/ingredient_repository.dart';

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
