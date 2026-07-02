import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/meal_entry.dart';
import '../../models/meal_ingredient.dart';
import '../providers/meals.dart';
import 'ingredient_list.dart';
import 'meal_form.dart' show MealFormScreen;

final class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Manage Ingredients',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IngredientListScreen()),
            ),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meals) => meals.isEmpty
            ? const Center(child: Text('No meals yet. Tap + to add one.'))
            : _buildMealList(context, ref, meals),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMealList(
    BuildContext context,
    WidgetRef ref,
    List<MealEntry> meals,
  ) {
    // Group meals by date (day only)
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in meals) {
      final day = DateTime(
        meal.eatenAt.year,
        meal.eatenAt.month,
        meal.eatenAt.day,
      );
      final list = grouped.putIfAbsent(day, () => []);
      list.add(meal);
    }

    // Sort dates descending
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (_, i) {
        final date = sortedDates[i];
        final dayMeals = grouped[date]!;
        return _DayGroup(
          date: date,
          meals: dayMeals,
          onTap: (meal) => _openForm(context, ref, meal),
          onDelete: (meal) => _deleteMeal(ref, meal),
        );
      },
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    MealEntry? existing,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MealFormScreen(meal: existing)),
    );
    if (saved == true) ref.invalidate(mealListProvider);
  }

  Future<void> _deleteMeal(WidgetRef ref, MealEntry meal) async {
    await ref.read(mealRepositoryProvider).delete(meal.id);
    ref.invalidate(mealListProvider);
  }
}

final class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<MealEntry> meals;
  final void Function(MealEntry) onTap;
  final void Function(MealEntry) onDelete;

  const _DayGroup({
    required this.date,
    required this.meals,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';

    // Calculate daily totals
    final totalCalories = meals.fold(
      0.0,
      (double sum, m) => sum + m.totalCalories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(dateStr, style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '${totalCalories.toStringAsFixed(0)} kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        for (final meal in meals)
          _MealTile(
            meal: meal,
            onTap: () => onTap(meal),
            onDelete: () => onDelete(meal),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

final class _MealTile extends StatelessWidget {
  final MealEntry meal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealTile({
    required this.meal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete meal?'),
          content: Text('Remove "${meal.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ).then((r) => r ?? false),
      onDismissed: (_) => onDelete(),
      child: ExpansionTile(
        title: Text(meal.name),
        subtitle: Text(
          '${meal.items.length} ingredient${meal.items.length == 1 ? '' : 's'}  ·  '
          '${meal.totalCalories.toStringAsFixed(0)} kcal',
        ),
        leading: const Icon(Icons.restaurant),
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onTap),
        children: meal.items
            .map((item) => _IngredientItemTile(item: item))
            .toList(),
      ),
    );
  }
}

final class _IngredientItemTile extends StatelessWidget {
  final MealIngredient item;
  const _IngredientItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.ingredientName),
      subtitle: Text(
        '${item.grams.toStringAsFixed(0)}g  ·  '
        '${item.calories.toStringAsFixed(0)} kcal  ·  '
        'P ${item.protein.toStringAsFixed(1)}g  ·  '
        'C ${item.carbs.toStringAsFixed(1)}g  ·  '
        'F ${item.fat.toStringAsFixed(1)}g',
      ),
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
    );
  }
}
