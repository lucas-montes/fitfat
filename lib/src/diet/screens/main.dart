import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/food_models.dart';
import '../providers/ingredients.dart';
import '../providers/meals.dart';
import 'meals/edit.dart';
import 'ingredients/edit.dart';
import 'widgets/food_entry_card.dart';

// Widget that is used by the router to display the diet screen, which contains tabs for meals and ingredients
// He's responsible to load the state
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

// This creates the display logic for the screen
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

  // This build the TapBar to go from Meals to Ingredients and display the list
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
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
        children: const [MealsTab(), _IngredientsTab()],
      ),
    );
  }
}

class MealsTab extends ConsumerStatefulWidget {
  const MealsTab({super.key});

  @override
  ConsumerState<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends ConsumerState<MealsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealsProvider.notifier).loadMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealsProvider);
    final meals = state.meals;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
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
        final title = (meal.name?.trim().isEmpty ?? true) ? 'Meal' : meal.name!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FoodEntryCard(
            title: title,
            onTap: () => _editMeal(context, meal),
            onDelete: () => _deleteMeal(meal.id),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddMealScreen()));
  }

  void _editMeal(BuildContext context, MealEntry meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddMealScreen(initialMeal: meal)));
  }

  void _deleteMeal(String id) async {
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: const Text('This will remove the meal from your log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mealsProvider.notifier).deleteMeal(id);
  }
}

class _IngredientsTab extends ConsumerWidget {
  const _IngredientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(ingredientsProvider);

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
    ref.read(ingredientsProvider.notifier).addIngredient(ingredient);
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
    ref.read(ingredientsProvider.notifier).updateIngredient(updated);
  }

  void _deleteIngredient(WidgetRef ref, String id) {
    _confirmAndDelete(ref, id);
  }

  Future<void> _confirmAndDelete(WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: const Text(
          'This will remove the ingredient and any portions from meals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(ingredientsProvider.notifier).removeIngredient(id);
  }
}
