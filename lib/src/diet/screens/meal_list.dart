import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_food.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/meals.dart';
import '../widgets/meal_item_editor_sheet.dart';
import '../../dashboard/providers/dashboard.dart';
import '../providers/foods.dart';
import '../providers/ingredients.dart';
import 'food_form.dart';
import 'food_list.dart';
import 'ingredient_form.dart';
import 'ingredient_list.dart';
import 'meal_form.dart' show MealFormScreen;

/// The display name for a meal: its own name, or a generic label built from
/// when it was eaten.
///
/// A blank name is legitimate — most meals do not need naming — so the fallback
/// is a real label rather than an empty string, which would otherwise render as
/// a blank title line.
String _mealTitle(BuildContext context, MealEntry meal) {
  final name = meal.name.trim();
  if (name.isNotEmpty) return name;
  final l10n = AppLocalizations.of(context)!;
  return l10n.mealListUnnamedMeal(
    DateFormats.formatShortDate(context, meal.eatenAt),
    DateFormats.formatTime(context, TimeOfDay.fromDateTime(meal.eatenAt)),
  );
}

/// What the add sheet can open.
enum _AddChoice { meal, recipe, ingredient }

final class MealListScreen extends ConsumerStatefulWidget {
  const MealListScreen({super.key});

  @override
  ConsumerState<MealListScreen> createState() => _MealListScreenState();
}

final class _MealListScreenState extends ConsumerState<MealListScreen> {
  /// Meal ids swiped away but not yet reflected in the provider.
  ///
  /// Dismissible asserts if it is still in the tree once its dismiss animation
  /// finishes, and neither the database delete nor the provider rebuild can
  /// land in that same frame. Dropping the id from the rendered list
  /// synchronously is what satisfies the contract; the id is retired once the
  /// provider stops listing it.
  ///
  /// Held here rather than on the row because the row has no key and is
  /// positional inside its day group: after an undo its element would be reused
  /// with a stale "removed" flag and the restored meal would render invisible.
  final Set<String> _pendingRemoval = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mealsAsync = ref.watch(mealListProvider);

    // Retire ids the provider has caught up on. Guarded so a listener firing
    // before the first data never calls setState needlessly.
    ref.listen(mealListProvider, (previous, next) {
      final ids = next.asData?.value.map((meal) => meal.id).toSet();
      if (ids == null || _pendingRemoval.isEmpty) return;
      if (_pendingRemoval.any((id) => !ids.contains(id))) {
        setState(() => _pendingRemoval.removeWhere((id) => !ids.contains(id)));
      }
    });

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
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.foodListAppBar,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FoodListScreen())),
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
                onCtaPressed: () => _openForm(null),
              )
            : _buildMealList(meals, l10n),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.dashboardAddTitle,
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Offers the three things a meal can be built from.
  ///
  /// All three live on this tab, but only the meal form was reachable from here
  /// — creating a recipe or an ingredient meant walking to another screen first,
  /// even though you often need the ingredient before the recipe that uses it.
  /// A sheet rather than a speed-dial because the three are peers here: there is
  /// no sensible "primary" one to single out.
  Future<void> _showAddSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: Text(l10n.dietAddMeal),
              onTap: () => Navigator.of(sheetContext).pop(_AddChoice.meal),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.dietAddRecipe),
              onTap: () => Navigator.of(sheetContext).pop(_AddChoice.recipe),
            ),
            ListTile(
              leading: const Icon(Icons.soup_kitchen_outlined),
              title: Text(l10n.dietAddIngredient),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AddChoice.ingredient),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    // Each form's providers are invalidated on save, copied from how the
    // dashboard welcome card already wires them.
    switch (choice) {
      case _AddChoice.meal:
        await _openForm(null);
      case _AddChoice.recipe:
        final saved = await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const FoodFormScreen()));
        if (saved == true) invalidateFoods(ref);
      case _AddChoice.ingredient:
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const IngredientFormScreen()),
        );
        if (saved == true) ref.invalidate(ingredientListProvider);
    }
  }

  Widget _buildMealList(List<MealEntry> meals, AppLocalizations l10n) {
    // A swiped meal is hidden immediately, before the delete lands, so the
    // Dismissible leaves the tree in the frame its animation completes.
    final visible = _pendingRemoval.isEmpty
        ? meals
        : meals.where((meal) => !_pendingRemoval.contains(meal.id)).toList();

    // Group meals by date (day only)
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in visible) {
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
          key: ValueKey(date),
          date: date,
          meals: dayMeals,
          l10n: l10n,
          onTap: (meal) => _openForm(meal),
          onDelete: (meal) => _deleteMeal(context, meal),
          onEditItem: (meal, item) => _editMealItem(context, meal, item),
        );
      },
    );
  }

  Future<void> _openForm(MealEntry? existing) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MealFormScreen(meal: existing)),
    );
    if (saved == true) ref.invalidate(mealListProvider);
  }

  /// Edits one food inside a meal: its amount, or its removal.
  ///
  /// Amount changes go through `updateAmounts`, which rescales linearly and
  /// leaves the snapshot otherwise alone; a removal goes through `removeItem`,
  /// which touches one row. Neither re-resolves the meal's other foods, so
  /// fixing one row cannot rewrite what was eaten alongside it.
  Future<void> _editMealItem(
    BuildContext context,
    MealEntry meal,
    MealFood item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showMealItemEditorSheet(
      context,
      foodName: item.foodName,
      currentGrams: item.amount,
      currentSummary: l10n.mealListMacroFormat(
        item.amount.toStringAsFixed(0),
        item.calories.toStringAsFixed(0),
        item.protein.toStringAsFixed(1),
        item.carbs.toStringAsFixed(1),
        item.fat.toStringAsFixed(1),
      ),
    );
    // null = dismissed, keep everything as it was.
    if (result == null) return;

    final repo = ref.read(mealRepositoryProvider);
    switch (result) {
      case MealItemAmountChanged(:final grams):
        await repo.updateAmounts(meal.id, {item.id: grams});
      case MealItemRemoved():
        await repo.removeItem(meal.id, item.id);
    }
    ref.invalidate(mealListProvider);
    invalidateDashboard(ref);
  }

  /// Swipe-to-delete.
  ///
  /// The row is hidden synchronously, before the delete is awaited, because
  /// Dismissible has already finished its animation by the time this runs and
  /// must not still be in the tree on the next build.
  Future<void> _deleteMeal(BuildContext context, MealEntry meal) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    setState(() => _pendingRemoval.add(meal.id));
    try {
      await ref.read(mealRepositoryProvider).delete(meal.id);
    } catch (_) {
      // Nothing was deleted, so the row has to come back rather than vanish
      // silently while the meal still exists.
      if (mounted) setState(() => _pendingRemoval.remove(meal.id));
      return;
    }
    ref.invalidate(mealListProvider);
    invalidateDashboard(ref);
    if (!context.mounted) return;
    showTopBanner(
      context,
      message: l10n.mealDeleted(_mealTitle(context, meal)),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        await ref.read(mealRepositoryProvider).restore(meal);
        // Retire the id so the restored row is rendered again; the listener
        // only clears ids the provider no longer lists, and an undo brings this
        // one straight back.
        if (mounted) setState(() => _pendingRemoval.remove(meal.id));
        ref.invalidate(mealListProvider);
        invalidateDashboard(ref);
      },
    );
  }
}

final class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<MealEntry> meals;
  final AppLocalizations l10n;
  final void Function(MealEntry) onTap;
  final void Function(MealEntry) onDelete;

  /// Edits one food inside this group, with the meal it belongs to — the meal
  /// id is what the repository writes against.
  final void Function(MealEntry, MealFood) onEditItem;

  const _DayGroup({
    super.key,
    required this.date,
    required this.meals,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    // Every meal in this group may have been swiped away optimistically, in
    // which case the group itself must not linger as an empty header.
    if (meals.isEmpty) return const SizedBox.shrink();
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
            key: ValueKey(meal.id),
            meal: meal,
            l10n: l10n,
            onTap: () => onTap(meal),
            onDelete: () => onDelete(meal),
            onEditItem: (item) => onEditItem(meal, item),
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

  /// Edits one of this meal's foods.
  final void Function(MealFood) onEditItem;

  const _MealTile({
    super.key,
    required this.meal,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
    required this.onEditItem,
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
          title: Text(_mealTitle(context, meal)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.mealListFoodCount(meal.items.length)}  ·  '
                '${l10n.mealListCaloriesValue(meal.totalCalories.toStringAsFixed(0))}',
              ),
              // The first line is the scannable summary; this carries the rest of
              // the meal's totals, so a whole meal's weight and macros are
              // readable without expanding it.
              Text(
                l10n.mealListTotals(
                  meal.totalAmount.toStringAsFixed(0),
                  meal.totalProtein.toStringAsFixed(1),
                  meal.totalCarbs.toStringAsFixed(1),
                  meal.totalFat.toStringAsFixed(1),
                  meal.totalFiber.toStringAsFixed(1),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
          children: [
            for (final item in meal.items)
              _FoodItemTile(
                key: ValueKey(item.id),
                item: item,
                l10n: l10n,
                onTap: () => widget.onEditItem(item),
              ),
          ].toList(),
        ),
      ),
    );
  }
}

final class _FoodItemTile extends StatelessWidget {
  final MealFood item;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  const _FoodItemTile({
    super.key,
    required this.item,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(item.foodName),
      subtitle: Text(
        l10n.mealListMacroFormat(
          item.amount.toStringAsFixed(0),
          item.calories.toStringAsFixed(0),
          item.protein.toStringAsFixed(1),
          item.carbs.toStringAsFixed(1),
          item.fat.toStringAsFixed(1),
        ),
      ),
      onTap: onTap,
      // A trailing chevron, because a tappable row with no affordance is the
      // same undiscoverable surface that made these read as read-only in the
      // first place.
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      dense: true,
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
    );
  }
}
