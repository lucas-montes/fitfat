import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_ingredient.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/meals.dart';
import 'ingredient_list.dart';
import 'meal_form.dart' show MealFormScreen;

final class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mealsAsync = ref.watch(mealListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mealListAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: l10n.mealListManageBtn,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IngredientListScreen()),
            ),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (meals) => meals.isEmpty
            ? EmptyState(
                icon: Icons.restaurant_outlined,
                title: l10n.emptyMealsTitle,
                description: l10n.emptyMealsBody,
                ctaLabel: l10n.emptyMealsCta,
                onCtaPressed: () => _openForm(context, ref, null),
              )
            : _buildMealList(context, ref, meals, l10n),
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
    AppLocalizations l10n,
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
          l10n: l10n,
          onTap: (meal) => _openForm(context, ref, meal),
          onDelete: (meal) => _deleteMeal(context, ref, meal),
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

  Future<void> _deleteMeal(
    BuildContext context,
    WidgetRef ref,
    MealEntry meal,
  ) async {
    unawaited(Haptics.mediumImpact());
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    await ref.read(mealRepositoryProvider).delete(meal.id);
    ref.invalidate(mealListProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.mealDeleted(meal.name)),
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () async {
              await ref.read(mealRepositoryProvider).restore(meal);
              ref.invalidate(mealListProvider);
            },
          ),
        ),
      );
  }
}

final class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<MealEntry> meals;
  final AppLocalizations l10n;
  final void Function(MealEntry) onTap;
  final void Function(MealEntry) onDelete;

  const _DayGroup({
    required this.date,
    required this.meals,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormats.formatDate(context, date);

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
                l10n.mealListCaloriesValue(totalCalories.toStringAsFixed(0)),
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
            l10n: l10n,
            onTap: () => onTap(meal),
            onDelete: () => onDelete(meal),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

/// One meal row: tapping the tile expands/collapses the ingredient breakdown;
/// long-pressing opens the meal edit form; swiping (end-to-start) deletes with
/// undo. The trailing is an animated chevron as the expansion affordance
/// (active-workout-flow T02 — the edit affordance moved to long-press).
final class _MealTile extends StatefulWidget {
  final MealEntry meal;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MealTile({
    required this.meal,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_MealTile> createState() => _MealTileState();
}

final class _MealTileState extends State<_MealTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final l10n = widget.l10n;

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        // ExpansionTile has no onLongPress in Flutter 3.38.3; the outer
        // long-press recognizer only wins after the hold deadline, so quick
        // taps still expand/collapse while a hold opens the edit form.
        onLongPress: widget.onTap,
        child: ExpansionTile(
          title: Text(meal.name),
          subtitle: Text(
            '${l10n.mealListIngredientCount(meal.items.length)}  ·  '
            '${l10n.mealListCaloriesValue(meal.totalCalories.toStringAsFixed(0))}',
          ),
          leading: const Icon(Icons.restaurant),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: FitFatTokens.motionNormal,
            curve: Curves.easeOut,
            child: const Icon(Icons.expand_more),
          ),
          onExpansionChanged: (expanded) =>
              setState(() => _expanded = expanded),
          children: meal.items
              .map((item) => _IngredientItemTile(item: item, l10n: l10n))
              .toList(),
        ),
      ),
    );
  }
}

final class _IngredientItemTile extends StatelessWidget {
  final MealIngredient item;
  final AppLocalizations l10n;
  const _IngredientItemTile({required this.item, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.ingredientName),
      subtitle: Text(
        l10n.mealListMacroFormat(
          item.grams.toStringAsFixed(0),
          item.calories.toStringAsFixed(0),
          item.protein.toStringAsFixed(1),
          item.carbs.toStringAsFixed(1),
          item.fat.toStringAsFixed(1),
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
    );
  }
}
