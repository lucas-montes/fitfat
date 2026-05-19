import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_models.dart';
import '../../providers/food_providers.dart';
import '../food/add_meal_screen.dart';
import '../food/custom_ingredient_screen.dart';
import '../food/food_screen.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Diet'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Meals'),
                  Tab(text: 'Ingredients'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                MealsTab(),
                _IngredientsTab(),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                if (controller.index == 0) {
                  return FloatingActionButton(
                    onPressed: () => _openAddMeal(context),
                    child: const Icon(Icons.add),
                  );
                }
                if (controller.index == 1) {
                  return FloatingActionButton(
                    onPressed: () => _openAddIngredient(context, ref),
                    child: const Icon(Icons.add),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  void _openAddMeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
  }

  Future<void> _openAddIngredient(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ingredient = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const CustomIngredientScreen()),
    );
    if (ingredient == null) return;
    ref.read(ingredientListProvider.notifier).addIngredient(ingredient);
  }
}

class _IngredientsTab extends ConsumerWidget {
  const _IngredientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(ingredientListProvider);

    if (ingredients.isEmpty) {
      return const Center(child: Text('No ingredients yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return Card(
          child: ListTile(
            onTap: () => _editIngredient(context, ref, ingredient),
            title: Text(ingredient.name),
            subtitle: Text(
              '${ingredient.caloriesPer100g.toStringAsFixed(0)} kcal · '
              'P ${ingredient.proteinPer100g.toStringAsFixed(1)}g · '
              'C ${ingredient.carbsPer100g.toStringAsFixed(1)}g · '
              'F ${ingredient.fatPer100g.toStringAsFixed(1)}g',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteIngredient(ref, ingredient.id),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: ingredients.length,
    );
  }

  Future<void> _editIngredient(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    final updated = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(
        builder: (_) => CustomIngredientScreen(initialIngredient: ingredient),
      ),
    );
    if (updated == null) return;
    ref.read(ingredientListProvider.notifier).updateIngredient(updated);
  }

  void _deleteIngredient(WidgetRef ref, String id) {
    _confirmAndDelete(ref, id);
  }

  Future<void> _confirmAndDelete(WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: const Text('This will remove the ingredient and any portions from meals.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(ingredientListProvider.notifier).removeIngredient(id);
  }
}
