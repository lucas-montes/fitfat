import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/macro_bar.dart';
import '../providers/foods.dart';
import '../providers/ingredients.dart';
import '../repositories/food_repository.dart' show ResolvedFood;
import 'food_form.dart';

enum RecipeSort { newest, name, kcal }

/// Sorts recipes: newest first (default), by name, or by kcal per 100 g
/// (highest first; unresolved last).
List<ResolvedFood> sortRecipes(List<ResolvedFood> list, RecipeSort sort) {
  final out = [...list];
  switch (sort) {
    case RecipeSort.newest:
      out.sort((a, b) => b.food.createdAt.compareTo(a.food.createdAt));
    case RecipeSort.name:
      out.sort(
        (a, b) =>
            a.food.name.toLowerCase().compareTo(b.food.name.toLowerCase()),
      );
    case RecipeSort.kcal:
      out.sort(
        (a, b) => (b.nutrition?.per100g.calories ?? -1).compareTo(
          a.nutrition?.per100g.calories ?? -1,
        ),
      );
  }
  return out;
}

/// The recipes (foods the user composed), as cards: kcal and macros per
/// 100 g, cooked weight and how much of the batch has been eaten. Tap a card
/// to see its ingredients; Edit opens the form.
final class FoodListScreen extends ConsumerStatefulWidget {
  const FoodListScreen({super.key});

  @override
  ConsumerState<FoodListScreen> createState() => _FoodListScreenState();
}

final class _FoodListScreenState extends ConsumerState<FoodListScreen> {
  RecipeSort _sort = RecipeSort.newest;
  bool _searching = false;
  String _query = '';
  final Set<String> _open = {};

  Future<void> _openForm(ResolvedFood? entry) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FoodFormScreen(food: entry?.food)),
    );
    if (saved == true) invalidateFoods(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all =
        ref.watch(foodCombinationProvider).value ?? const <ResolvedFood>[];
    final eaten = ref.watch(foodEatenGramsProvider).value ?? const {};
    final ingredients = {
      for (final i in ref.watch(ingredientListProvider).value ?? <Ingredient>[])
        i.id: i,
    };
    final q = _query.trim().toLowerCase();
    final recipes = sortRecipes([
      for (final r in all)
        if (q.isEmpty || r.food.name.toLowerCase().contains(q)) r,
    ], _sort);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.recipeSearch,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.foodListAppBar),
        actions: [
          IconButton(
            tooltip: l10n.commonSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
        ],
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.restaurant_menu_outlined,
              title: l10n.emptyFoodsTitle,
              description: l10n.emptyFoodsBody,
              ctaLabel: l10n.emptyFoodsCta,
              onCtaPressed: () => _openForm(null),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FitFatTokens.kContentMaxWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    FitFatTokens.spaceL,
                    FitFatTokens.spaceXs,
                    FitFatTokens.spaceL,
                    88,
                  ),
                  children: [
                    Wrap(
                      spacing: FitFatTokens.spaceS,
                      children: [
                        for (final (s, label) in [
                          (RecipeSort.newest, l10n.recipeSortNewest),
                          (RecipeSort.name, l10n.recipeSortName),
                          (RecipeSort.kcal, l10n.recipeSortKcal),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _sort == s,
                            onSelected: (_) => setState(() => _sort = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: FitFatTokens.spaceS),
                    for (final r in recipes) ...[
                      RecipeCard(
                        key: ValueKey(r.food.id),
                        recipe: r,
                        eatenGrams: eaten[r.food.id] ?? 0,
                        ingredients: ingredients,
                        open: _open.contains(r.food.id),
                        onToggle: () => setState(() {
                          if (!_open.remove(r.food.id)) _open.add(r.food.id);
                        }),
                        onEdit: () => _openForm(r),
                      ),
                      const SizedBox(height: FitFatTokens.spaceS),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.dietAddRecipe,
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Name and kcal / 100 g; date · ingredients · cooked weight; the macro bar
/// (per 100 g); the eaten bar. Opened: each ingredient with grams and kcal.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.eatenGrams,
    required this.ingredients,
    required this.open,
    required this.onToggle,
    required this.onEdit,
  });

  final ResolvedFood recipe;
  final double eatenGrams;
  final Map<String, Ingredient> ingredients;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);
    const tabular = [FontFeature.tabularFigures()];
    final food = recipe.food;
    final per100 = recipe.nutrition?.per100g;
    final cooked =
        food.cookedWeight ??
        food.components.fold<double>(0, (a, c) => a + c.amount);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: tabular,
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FitFatTokens.spaceL,
            FitFatTokens.spaceM,
            FitFatTokens.spaceM,
            FitFatTokens.spaceM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FitFatTokens.spaceS,
            children: [
              Row(
                spacing: FitFatTokens.spaceS,
                children: [
                  Expanded(
                    child: Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (per100 != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${per100.calories.round()} kcal',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFeatures: tabular,
                            ),
                          ),
                          TextSpan(text: ' /100 g', style: muted),
                        ],
                      ),
                    ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: FitFatTokens.motionFast,
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                [
                  (food.createdAt.year == DateTime.now().year
                          ? DateFormat.MMMEd(locale)
                          : DateFormat.yMMMd(locale))
                      .format(food.createdAt),
                  l10n.foodListPartCount(food.components.length),
                  l10n.recipeCooked(nf.format(cooked.round())),
                ].join(' · '),
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (per100 == null)
                Text(
                  l10n.foodListUnresolved,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                )
              else
                MacroBar(MacroValues.of(per100)),
              EatenBar(eaten: eatenGrams, total: cooked),
              if (open) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FitFatTokens.spaceM,
                    vertical: FitFatTokens.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
                  ),
                  child: Column(
                    children: [
                      for (final c in food.components)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: FitFatTokens.spaceXs + 1,
                          ),
                          child: Row(
                            spacing: FitFatTokens.spaceS,
                            children: [
                              Expanded(
                                child: Text(
                                  c.ingredientName.isEmpty
                                      ? l10n.recipeMissingIngredient
                                      : c.ingredientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${nf.format(c.amount.round())} g',
                                style: muted,
                              ),
                              SizedBox(
                                width: 76,
                                child: Text(
                                  switch (ingredients[c.ingredientId]) {
                                    final i? =>
                                      '${nf.format((i.caloriesPer100g * c.amount / 100).round())} kcal',
                                    null => '',
                                  },
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFeatures: tabular,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.recipeEdit),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Grams eaten (green) against what is left of the batch, numbers inside.
class EatenBar extends StatelessWidget {
  const EatenBar({super.key, required this.eaten, required this.total});

  final double eaten;
  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;
    final style = theme.textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = (total - eaten).clamp(0.0, double.infinity);
    final eatenPart = total <= 0 ? 0.0 : (eaten / total).clamp(0.0, 1.0);
    Widget seg(String text, Color color, Color fg, Alignment align) =>
        Container(
          color: color,
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, style: style?.copyWith(color: fg)),
          ),
        );
    final eatenSeg = seg(
      eaten >= total && total > 0
          ? l10n.recipeAllEaten
          : l10n.recipeEaten(nf.format(eaten.round())),
      Color.lerp(scheme.surface, success, 0.5)!,
      scheme.onSurface,
      Alignment.centerLeft,
    );
    final leftSeg = seg(
      eaten <= 0
          ? l10n.recipeNoneEaten(nf.format(total.round()))
          : l10n.recipeLeft(nf.format(left.round())),
      scheme.surfaceContainerHighest,
      scheme.onSurfaceVariant,
      eaten <= 0 ? Alignment.centerLeft : Alignment.centerRight,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 18,
        child: LayoutBuilder(
          builder: (context, box) {
            if (eatenPart <= 0) return leftSeg;
            if (eatenPart >= 1) return eatenSeg;
            const minW = 92.0;
            final w = (box.maxWidth * eatenPart).clamp(
              minW,
              box.maxWidth - minW,
            );
            return Row(
              spacing: 2,
              children: [
                SizedBox(width: w - 1, child: eatenSeg),
                Expanded(child: leftSeg),
              ],
            );
          },
        ),
      ),
    );
  }
}
