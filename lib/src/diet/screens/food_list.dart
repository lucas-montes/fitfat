import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../../ui/haptics.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/foods.dart';
import 'food_form.dart';

/// Lists the foods a user created — the recipes — with their **live** per-100g
/// profile.
///
/// Derived 1:1 foods are excluded: one exists per ingredient, they are the
/// ingredient's own loggable wrapper rather than something the user composed,
/// and they are managed from the ingredient screen.
final class FoodListScreen extends ConsumerWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final foodsAsync = ref.watch(foodCombinationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.foodListAppBar)),
      body: foodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (resolved) => resolved.isEmpty
            ? EmptyState(
                icon: Icons.restaurant_menu_outlined,
                title: l10n.emptyFoodsTitle,
                description: l10n.emptyFoodsBody,
                ctaLabel: l10n.emptyFoodsCta,
                onCtaPressed: () => _openForm(context, ref, null),
              )
            : ListView.builder(
                itemCount: resolved.length,
                itemBuilder: (_, i) {
                  final entry = resolved[i];
                  return _FoodTile(
                    food: entry.food,
                    nutrition: entry.nutrition,
                    l10n: l10n,
                    onTap: () => _openForm(context, ref, entry.food),
                    onDismissed: () => _archive(context, ref, entry.food),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Food? existing,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FoodFormScreen(food: existing)),
    );
    if (saved == true) invalidateFoods(ref);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref, Food food) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(foodRepositoryProvider);
    await repo.archive(food.id);
    invalidateFoods(ref);
    if (context.mounted) {
      showTopBanner(
        context,
        message: l10n.foodArchived(food.name),
        actionLabel: l10n.commonUndo,
        onAction: () async {
          await repo.restore(food.id);
          invalidateFoods(ref);
        },
      );
    }
  }
}

final class _FoodTile extends StatelessWidget {
  final Food food;
  final FoodNutrition? nutrition;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _FoodTile({
    required this.food,
    required this.nutrition,
    required this.l10n,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final per100g = nutrition?.per100g;
    final parts = food.components.length;
    return Dismissible(
      key: ValueKey(food.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        title: Text(food.name, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (per100g != null)
              Text(
                l10n.ingredientMacroRow(
                  per100g.calories.toStringAsFixed(0),
                  per100g.calories.toStringAsFixed(0),
                  per100g.protein.toStringAsFixed(1),
                  per100g.carbs.toStringAsFixed(1),
                  per100g.fat.toStringAsFixed(1),
                ),
              )
            else
              Text(
                l10n.foodListUnresolved,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Text(
              l10n.foodListPartCount(parts),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
