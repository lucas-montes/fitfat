import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food_models.dart';
import '../../database/providers.dart';
import '../../adapters/drift/ingredient_repository.dart';
import '../repositories/ingredients.dart';

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftIngredientRepository(db);
});

class IngredientsController extends Notifier<List<Ingredient>> {
  late final IngredientRepository _repo;
  bool _loaded = false;

  @override
  List<Ingredient> build() {
    _repo = ref.read(ingredientRepositoryProvider);
    if (!_loaded) {
      _loaded = true;
      unawaited(_loadInitialData());
    }
    return const [];
  }

  Future<void> _loadInitialData() async {
    try {
      final items = await _repo.getAll();
      if (ref.mounted) {
        state = items;
      }
    } catch (_) {}
  }

  Future<void> addIngredient(Ingredient ingredient) async {
    await _repo.insert(ingredient);
    state = [...state, ingredient];
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    await _repo.update(ingredient);
    state = [
      for (final existing in state)
        if (existing.id == ingredient.id) ingredient else existing,
    ];
  }

  Future<void> removeIngredient(String id) async {
    await _repo.delete(id);
    state = state.where((ingredient) => ingredient.id != id).toList();
  }
}

final ingredientsProvider =
    NotifierProvider<IngredientsController, List<Ingredient>>(
  IngredientsController.new,
);
