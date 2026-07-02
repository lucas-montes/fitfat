import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../providers/ingredients.dart';
import 'ingredient_form.dart';

final class IngredientListScreen extends ConsumerWidget {
  const IngredientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingredientListAppBar)),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (ingredients) => ingredients.isEmpty
            ? Center(child: Text(l10n.ingredientListEmpty))
            : ListView.builder(
                itemCount: ingredients.length,
                itemBuilder: (_, i) => _IngredientTile(
                  ingredient: ingredients[i],
                  l10n: l10n,
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
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IngredientTile({
    required this.ingredient,
    required this.l10n,
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
          title: Text(l10n.ingredientListDeleteTitle),
          content: Text(l10n.ingredientListDeleteConfirm(ingredient.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      ).then((r) => r ?? false),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(ingredient.name),
        subtitle: Text(
          l10n.ingredientMacroRow(
            ingredient.caloriesPer100g.toStringAsFixed(0),
            ingredient.caloriesPer100g.toStringAsFixed(0),
            ingredient.proteinPer100g.toStringAsFixed(1),
            ingredient.carbsPer100g.toStringAsFixed(1),
            ingredient.fatPer100g.toStringAsFixed(1),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
