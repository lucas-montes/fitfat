import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/food_models.dart';
import '../../providers/food_providers.dart';
import 'add_meal_screen.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealLogProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: meals.isEmpty
          ? const Center(child: Text('No meals yet'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return _MealCard(
                  meal: meal,
                  onTap: () => _showMealDetails(context, ref, meal),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: meals.length,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMeal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddMeal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMealScreen()),
    );
  }

  void _showMealDetails(
    BuildContext context,
    WidgetRef ref,
    MealEntry meal,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _MealDetailSheet(
        meal: meal,
        onEdit: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddMealScreen(initialMeal: meal)),
          );
        },
        onDelete: () {
          ref.read(mealLogProvider.notifier).removeMeal(meal.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onTap});

  final MealEntry meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final macros = meal.totalMacros;
    final formattedTime = DateFormat('MMM d, h:mm a').format(meal.eatenAt);

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(meal.name?.trim().isEmpty ?? true ? 'Meal' : meal.name!),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedTime),
              const SizedBox(height: 6),
              _MacroRow(macros: macros),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.macros});

  final MacroNutrients macros;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _macroChip('Cal', macros.calories, 'kcal'),
        _macroChip('P', macros.protein, 'g'),
        _macroChip('C', macros.carbs, 'g'),
        _macroChip('F', macros.fat, 'g'),
      ],
    );
  }

  Widget _macroChip(String label, double value, String unit) {
    return Chip(
      label: Text('$label ${value.toStringAsFixed(1)}$unit'),
    );
  }
}

class _MealDetailSheet extends StatelessWidget {
  const _MealDetailSheet({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final macros = meal.totalMacros;
    final formattedTime = DateFormat('MMM d, h:mm a').format(meal.eatenAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.name?.trim().isEmpty ?? true ? 'Meal' : meal.name!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(formattedTime),
          const SizedBox(height: 12),
          _MacroRow(macros: macros),
          const SizedBox(height: 16),
          Text(
            'Ingredients',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...meal.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.ingredient.name),
              subtitle: Text('${item.grams.toStringAsFixed(0)} g'),
              trailing: Text(
                '${item.macros.calories.toStringAsFixed(0)} kcal',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
