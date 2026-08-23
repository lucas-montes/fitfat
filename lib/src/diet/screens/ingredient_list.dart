import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../../settings/providers/settings.dart';
import '../../sync/sync_button.dart';
import '../../sync/sync_service.dart';
import '../../ui/haptics.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/ingredients.dart';
import 'ingredient_detail_screen.dart';
import 'ingredient_form.dart';

final class IngredientListScreen extends ConsumerWidget {
  const IngredientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ingredientListAppBar),
        actions: [
          SyncButton(
            tooltip: l10n.syncIngredientsTooltip,
            run: () {
              final s = ref.read(settingsProvider);
              return ref
                  .read(syncServiceProvider)
                  .syncIngredients(s.remoteSyncBaseUrl, s.remoteSyncApiKey);
            },
          ),
        ],
      ),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (ingredients) => ingredients.isEmpty
            ? EmptyState(
                icon: Icons.soup_kitchen_outlined,
                title: l10n.emptyIngredientsTitle,
                description: l10n.emptyIngredientsBody,
                ctaLabel: l10n.emptyIngredientsCta,
                onCtaPressed: () => _openForm(context, ref, null),
              )
            : ListView.builder(
                itemCount: ingredients.length,
                itemBuilder: (_, i) => _IngredientTile(
                  ingredient: ingredients[i],
                  l10n: l10n,
                  onTap: () => _openDetail(context, ref, ingredients[i]),
                  onDismissed: () =>
                      _archiveIngredient(context, ref, ingredients[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Opens the read-mostly detail screen; edits go through its appbar action.
  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientDetailScreen(ingredientId: ingredient.id),
      ),
    );
    if (context.mounted) ref.invalidate(ingredientListProvider);
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

  Future<void> _archiveIngredient(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(ingredientRepositoryProvider);
    await repo.archive(ingredient.id);
    ref.invalidate(ingredientListProvider);
    if (context.mounted) {
      showTopBanner(
        context,
        message: l10n.ingredientArchived(ingredient.name),
        actionLabel: l10n.commonUndo,
        onAction: () async {
          await repo.restore(ingredient.id);
          ref.invalidate(ingredientListProvider);
        },
      );
    }
  }
}

final class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _IngredientTile({
    required this.ingredient,
    required this.l10n,
    required this.onTap,
    required this.onDismissed,
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
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        title: Text(ingredient.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ingredientMacroRow(
                ingredient.caloriesPer100g.toStringAsFixed(0),
                ingredient.caloriesPer100g.toStringAsFixed(0),
                ingredient.proteinPer100g.toStringAsFixed(1),
                ingredient.carbsPer100g.toStringAsFixed(1),
                ingredient.fatPer100g.toStringAsFixed(1),
              ),
            ),
            if (_nutrientLine(l10n) case final line?) Text(line),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// Optional second subtitle line listing the set extra nutriments
  /// (sodium / fiber / sugar), or null when none are set.
  String? _nutrientLine(AppLocalizations l10n) {
    final parts = <String>[
      if (ingredient.sodiumPer100g != null)
        l10n.ingredientNutrientSodium(
          ingredient.sodiumPer100g!.toStringAsFixed(0),
        ),
      if (ingredient.fiberPer100g != null)
        l10n.ingredientNutrientFiber(
          ingredient.fiberPer100g!.toStringAsFixed(1),
        ),
      if (ingredient.sugarPer100g != null)
        l10n.ingredientNutrientSugar(
          ingredient.sugarPer100g!.toStringAsFixed(1),
        ),
    ];
    if (parts.isEmpty) return null;
    return parts.join('  ·  ');
  }
}
