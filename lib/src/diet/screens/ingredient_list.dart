import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ingredient.dart';
import '../providers/ingredients.dart';
import 'ingredient_form.dart';

final class IngredientListScreen extends ConsumerWidget {
  const IngredientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ingredients')),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ingredients) => ingredients.isEmpty
            ? const Center(child: Text('No ingredients yet. Tap + to add one.'))
            : ListView.builder(
                itemCount: ingredients.length,
                itemBuilder: (_, i) => _IngredientTile(
                  ingredient: ingredients[i],
                  onTap: () => _openForm(context, ref, ingredients[i]),
                  onDelete: () => _deleteIngredient(ref, ingredients[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Ingredient? existing,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => IngredientFormScreen(ingredient: existing),
      ),
    );
    if (saved == true) ref.invalidate(ingredientListProvider);
  }

  Future<void> _deleteIngredient(WidgetRef ref, Ingredient ingredient) async {
    await ref.read(ingredientRepositoryProvider).delete(ingredient.id);
    ref.invalidate(ingredientListProvider);
  }
}

final class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IngredientTile({
    required this.ingredient,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(ingredient.id),
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
          title: const Text('Delete ingredient?'),
          content: Text('Remove "${ingredient.name}"?'),
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
      child: ListTile(
        title: Text(ingredient.name),
        subtitle: Text(
          '${ingredient.caloriesPer100g.toStringAsFixed(0)} kcal/100g  ·  '
          'P ${ingredient.proteinPer100g.toStringAsFixed(1)}g  ·  '
          'C ${ingredient.carbsPer100g.toStringAsFixed(1)}g  ·  '
          'F ${ingredient.fatPer100g.toStringAsFixed(1)}g',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
