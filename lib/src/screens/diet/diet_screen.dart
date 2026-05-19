import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_models.dart';
import '../../providers/food_providers.dart';
import '../food/add_meal_screen.dart';
import '../food/custom_ingredient_screen.dart';
import '../food/widgets/food_entry_card.dart';

class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meals'),
            Tab(text: 'Ingredients'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MealsTab(),
          _IngredientsTab(),
        ],
      ),
    );
  }
}

class MealsTab extends ConsumerWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealLogProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        // Add button at the top
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Meal'),
              onPressed: () => _openAddMeal(context),
            ),
          );
        }

        final mealIndex = index - 1;
        if (mealIndex >= meals.length) return null;

        final meal = meals[mealIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FoodEntryCard(
            title: meal.name?.trim().isEmpty ?? true ? 'Meal' : meal.name!,
            onTap: () {},  // TODO: Implement edit meal
            onDelete: () {},  // TODO: Implement delete meal
            body: Text(
              '${meal.totalMacros.calories.toStringAsFixed(0)} kcal · ${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
            ),
          ),
        );
      },
      itemCount: meals.length + 1,
    );
  }

  void _openAddMeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
  }
}

class _IngredientsTab extends ConsumerWidget {
  const _IngredientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(ingredientListProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        // Add button at the top
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
              onPressed: () => _openAddIngredient(context, ref),
            ),
          );
        }

        final ingredientIndex = index - 1;
        if (ingredientIndex >= ingredients.length) return null;

        final ingredient = ingredients[ingredientIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FoodEntryCard(
            title: ingredient.name,
            onTap: () => _editIngredient(context, ref, ingredient),
            onDelete: () => _deleteIngredient(ref, ingredient.id),
            body: Text(
              '${ingredient.caloriesPer100g.toStringAsFixed(0)} kcal · '
              'P ${ingredient.proteinPer100g.toStringAsFixed(1)}g · '
              'C ${ingredient.carbsPer100g.toStringAsFixed(1)}g · '
              'F ${ingredient.fatPer100g.toStringAsFixed(1)}g',
            ),
          ),
        );
      },
      itemCount: ingredients.length + 1,
    );
  }

  void _openAddIngredient(BuildContext context, WidgetRef ref) async {
    final ingredient = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const CustomIngredientScreen()),
    );
    if (ingredient == null) return;
    ref.read(ingredientListProvider.notifier).addIngredient(ingredient);
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
