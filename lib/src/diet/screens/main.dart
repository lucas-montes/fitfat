import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/food.dart';
import '../../l10n/app_localizations.dart';
import '../providers/ingredients.dart';
import '../providers/meals.dart';
import '../providers/diet_preferences.dart';
import 'meals/edit.dart';
import 'ingredients/edit.dart';
import 'widgets/food_entry_card.dart';

// Widget that is used by the router to display the diet screen, which contains tabs for meals and ingredients
class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.mealsTab),
              Tab(text: l10n.ingredientsTab),
            ],
          ),
        ),
        body: const TabBarView(children: [MealsTab(), _IngredientsTab()]),
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
  final DateFormat _dayFormat = DateFormat('EEE, MMM d');
  final DateFormat _timeFormat = DateFormat('h:mm a');

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
    final l10n = AppLocalizations.of(context);
    final groupedMeals = _groupMealsByDay(meals);
    // Debug: log UI-side meal count to ensure provider updates are seen
    try {
      print(
        '[UI] MealsTab build: meals=${meals.length} status=${state.status}',
      );
    } catch (_) {}

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

        final groupIndex = index - 1;
        if (groupIndex >= groupedMeals.length) return null;

        final group = groupedMeals[groupIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDayGroupCard(context, group),
        );
      },
      itemCount: groupedMeals.length + 1,
    );
  }

  List<_MealsDayGroup> _groupMealsByDay(List<MealEntry> meals) {
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in meals) {
      final dayKey = DateTime(
        meal.eatenAt.year,
        meal.eatenAt.month,
        meal.eatenAt.day,
      );
      grouped.putIfAbsent(dayKey, () => <MealEntry>[]).add(meal);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return entries
        .map((entry) => _MealsDayGroup(day: entry.key, meals: entry.value))
        .toList();
  }

  Widget _buildDayGroupCard(BuildContext context, _MealsDayGroup group) {
    final dailyTotals = group.meals.fold(
      MacroNutrients.zero,
      (sum, meal) => sum + meal.totalMacros,
    );

    final prefs = ref.read(dietPreferencesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayFormat.format(group.day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ${_formatMacrosWithPrefs(dailyTotals, prefs)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            for (final meal in group.meals) _buildMealRow(context, meal),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(BuildContext context, MealEntry meal) {
    final title = (meal.name?.trim().isEmpty ?? true) ? 'Meal' : meal.name!;
    final macros = meal.totalMacros;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        '${_timeFormat.format(meal.eatenAt)} · ${_formatMacros(macros)} · ${meal.items.length} item${meal.items.length == 1 ? '' : 's'}',
      ),
      onTap: () => _editMeal(context, meal),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete meal',
        onPressed: () => _deleteMeal(meal.id),
      ),
    );
  }

  String _formatMacros(MacroNutrients macros) {
    return '${macros.calories.toStringAsFixed(0)} kcal · '
        'P ${macros.protein.toStringAsFixed(1)}g · '
        'C ${macros.carbs.toStringAsFixed(1)}g · '
        'F ${macros.fat.toStringAsFixed(1)}g';
  }

  String _formatMacrosWithPrefs(MacroNutrients macros, DietPreferences prefs) {
    final result = StringBuffer();
    final visibleMacros = {
      'calories': prefs.isCaloriesVisible,
      'protein': prefs.isProteinVisible,
      'carbs': prefs.isCarbsVisible,
      'fat': prefs.isFatVisible,
    };

    if (visibleMacros['calories'] ?? true)
      result.write('${macros.calories.toStringAsFixed(0)} kcal · ');
    if (visibleMacros['protein'] ?? true)
      result.write('P ${macros.protein.toStringAsFixed(1)}g · ');
    if (visibleMacros['carbs'] ?? true)
      result.write('C ${macros.carbs.toStringAsFixed(1)}g · ');
    if (visibleMacros['fat'] ?? true)
      result.write('F ${macros.fat.toStringAsFixed(1)}g');

    return result.toString();
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

class _MealsDayGroup {
  const _MealsDayGroup({required this.day, required this.meals});

  final DateTime day;
  final List<MealEntry> meals;
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
