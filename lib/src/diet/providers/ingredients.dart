import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food.dart';
import '../../database/providers.dart';
import '../../adapters/drift/ingredient_repository.dart';

final ingredientRepositoryProvider = Provider<DriftIngredientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftIngredientRepository(db);
});

class IngredientsController extends Notifier<List<Ingredient>> {
  late final DriftIngredientRepository _repo;
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
      state = items;
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
    await _repo.deleteIngredient(id);
    state = state.where((ingredient) => ingredient.id != id).toList();
  }

  Future<void> archiveIngredient(Ingredient ingredient) async {
    await _repo.archiveIngredient(ingredient.id);
    state = [
      for (final existing in state)
        if (existing.id == ingredient.id)
          Ingredient(
            id: existing.id,
            name: existing.name,
            caloriesPer100g: existing.caloriesPer100g,
            proteinPer100g: existing.proteinPer100g,
            carbsPer100g: existing.carbsPer100g,
            fatPer100g: existing.fatPer100g,
            creatorId: existing.creatorId,
            isArchived: true,
            sodiumPer100g: existing.sodiumPer100g,
            fiberPer100g: existing.fiberPer100g,
            sugarsPer100g: existing.sugarsPer100g,
            saturatedFatPer100g: existing.saturatedFatPer100g,
            cholesterolPer100g: existing.cholesterolPer100g,
            components: existing.components,
          )
        else
          existing,
    ];
  }

  Future<List<Ingredient>> getArchivedIngredients() async {
    final repo = ref.read(ingredientRepositoryProvider);
    return await repo.getArchivedIngredients();
  }
}

final ingredientsProvider =
    NotifierProvider<IngredientsController, List<Ingredient>>(
      IngredientsController.new,
    );
