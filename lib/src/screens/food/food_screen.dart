import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/food_models.dart';
import '../../providers/food_providers.dart';
import 'add_meal_screen.dart';
import 'widgets/food_entry_card.dart';

class MealsTab extends ConsumerWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealLogProvider);

    return meals.isEmpty
        ? const Center(child: Text('No meals yet'))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return FoodEntryCard(
                title: meal.name?.trim().isEmpty ?? true ? 'Meal' : meal.name!,
                onTap: () => _openEditMeal(context, meal),
                onDelete: () => _deleteMeal(ref, meal.id),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('MMM d, h:mm a').format(meal.eatenAt)),
                    const SizedBox(height: 8),
                    _MacroRow(macros: meal.totalMacros),
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: meals.length,
          );
  }

  void _openEditMeal(BuildContext context, MealEntry meal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddMealScreen(initialMeal: meal)),
    );
  }

  void _deleteMeal(WidgetRef ref, String id) {
    _confirmAndDelete(ref, id);
  }

  Future<void> _confirmAndDelete(WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal?'),
        content: const Text('This will remove the meal from your log.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    ref.read(mealLogProvider.notifier).removeMeal(id);
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
