import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_food.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/date_filter_chips.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/macro_bar.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/foods.dart';
import '../providers/meals.dart';
import 'food_list.dart';
import 'ingredient_list.dart';
import 'meal_form.dart' show MealFormScreen;

/// One calendar day of meals, earliest first.
typedef MealDay = ({DateTime day, List<MealEntry> meals});

/// Groups [meals] by day (newest day first, meals in time order), keeping
/// those inside [filter] and, with a [query], those with a matching food.
List<MealDay> groupMealDays(
  List<MealEntry> meals, {
  DateFilter filter = DateFilter.all,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  final byDay = <DateTime, List<MealEntry>>{};
  for (final m in meals) {
    if (!filter.contains(m.eatenAt)) continue;
    if (q.isNotEmpty &&
        !m.items.any((i) => i.foodName.toLowerCase().contains(q))) {
      continue;
    }
    final d = DateTime(m.eatenAt.year, m.eatenAt.month, m.eatenAt.day);
    (byDay[d] ??= []).add(m);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days)
      (
        day: d,
        meals: byDay[d]!..sort((a, b) => a.eatenAt.compareTo(b.eatenAt)),
      ),
  ];
}

MacroValues mealMacros(MealEntry m) =>
    m.items.fold(MacroValues.zero, (a, i) => a + itemMacros(i));

MacroValues itemMacros(MealFood i) => MacroValues(
  protein: i.protein,
  carbs: i.carbs,
  fat: i.fat,
  fiber: i.fiber,
  sodium: i.sodium,
);

/// The Food tab: every meal, one card per day (kcal, grams and macros in the
/// header), filtered by month or range. A meal row opens to list its foods;
/// ↻ logs the same foods again now.
final class MealListScreen extends ConsumerStatefulWidget {
  const MealListScreen({super.key});

  @override
  ConsumerState<MealListScreen> createState() => _MealListScreenState();
}

final class _MealListScreenState extends ConsumerState<MealListScreen> {
  DateFilter _filter = DateFilter.all;
  bool _searching = false;
  String _query = '';
  final Set<String> _open = {};

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _openForm(MealEntry? meal) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => MealFormScreen(meal: meal)));
    if (saved == true) ref.invalidate(mealListProvider);
  }

  /// Logs [meal]'s foods and grams again, now, resolved from the foods' live
  /// profiles (as any new log is), with Undo.
  Future<void> _logAgain(MealEntry meal) async {
    final l10n = AppLocalizations.of(context)!;
    final foods = await ref.read(foodListProvider.future);
    final profiles = {for (final f in foods) f.food.id: f.nutrition};
    if (!mounted) return;
    if (meal.items.any((i) => profiles[i.foodId] == null)) {
      showTopBanner(context, message: l10n.mealFormFoodUnresolved);
      return;
    }
    final id = const Uuid().v7();
    final now = DateTime.now();
    final copy = MealEntry(
      id: id,
      name: '',
      eatenAt: now,
      createdAt: now,
      items: [
        for (final i in meal.items)
          MealFood(
            id: const Uuid().v7(),
            mealId: id,
            foodId: i.foodId,
            foodName: i.foodName,
            amount: i.amount,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            nutrition: profiles[i.foodId],
          ),
      ],
    );
    final repo = ref.read(mealRepositoryProvider);
    await repo.insert(copy);
    ref.invalidate(mealListProvider);
    invalidateDashboard(ref);
    if (!mounted) return;
    final kcal = meal.items.fold(
      0.0,
      (a, i) => a + profiles[i.foodId]!.per100g.calories * i.amount / 100,
    );
    showTopBanner(
      context,
      message: l10n.foodHistoryLoggedAgain(kcal.round()),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        await repo.delete(id);
        ref.invalidate(mealListProvider);
        invalidateDashboard(ref);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meals = ref.watch(mealListProvider).value ?? const <MealEntry>[];
    final days = groupMealDays(meals, filter: _filter, query: _query);
    final months = <DateTime>{
      for (final m in meals) DateTime(m.eatenAt.year, m.eatenAt.month),
    }.toList()..sort((a, b) => b.compareTo(a));
    final earliest = meals.isEmpty
        ? DateTime.now()
        : meals.map((m) => m.eatenAt).reduce((a, b) => a.isBefore(b) ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.foodHistorySearch,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.mealListAppBar),
        actions: [
          IconButton(
            tooltip: l10n.commonSearch,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          if (!_searching) ...[
            IconButton(
              tooltip: l10n.foodListAppBar,
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () => _push(const FoodListScreen()),
            ),
            IconButton(
              tooltip: l10n.ingredientListAppBar,
              icon: const Icon(Icons.soup_kitchen_outlined),
              onPressed: () => _push(const IngredientListScreen()),
            ),
          ],
        ],
      ),
      body: meals.isEmpty
          ? EmptyState(
              icon: Icons.restaurant_outlined,
              title: l10n.emptyMealsTitle,
              description: l10n.emptyMealsBody,
              ctaLabel: l10n.emptyMealsCta,
              onCtaPressed: () => _openForm(null),
            )
          : Column(
              children: [
                const SizedBox(height: FitFatTokens.spaceXs),
                DateFilterChips(
                  months: months,
                  value: _filter,
                  earliest: earliest,
                  onChanged: (f) => setState(() => _filter = f),
                ),
                Expanded(
                  child: days.isEmpty
                      ? EmptyState(
                          icon: Icons.restaurant_outlined,
                          title: l10n.foodHistoryNoMatchTitle,
                          description: l10n.foodHistoryNoMatchBody,
                        )
                      : Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: FitFatTokens.kContentMaxWidth,
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                FitFatTokens.spaceL,
                                FitFatTokens.spaceM,
                                FitFatTokens.spaceL,
                                88,
                              ),
                              itemCount: days.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: FitFatTokens.spaceM),
                              itemBuilder: (_, i) => MealDayCard(
                                key: ValueKey(days[i].day),
                                day: days[i],
                                isOpen: _open.contains,
                                onToggle: (m) => setState(() {
                                  if (!_open.remove(m.id)) _open.add(m.id);
                                }),
                                onEdit: _openForm,
                                onLogAgain: _logAgain,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: l10n.dietAddMeal,
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _num(BuildContext context, num v) => NumberFormat.decimalPattern(
  Localizations.localeOf(context).toLanguageTag(),
).format(v.round());

/// A day: tinted header (date, kcal, grams, the five macros) and one row per
/// meal.
class MealDayCard extends StatelessWidget {
  const MealDayCard({
    super.key,
    required this.day,
    required this.isOpen,
    required this.onToggle,
    required this.onEdit,
    required this.onLogAgain,
  });

  final MealDay day;
  final bool Function(String mealId) isOpen;
  final ValueChanged<MealEntry> onToggle;
  final ValueChanged<MealEntry> onEdit;
  final ValueChanged<MealEntry> onLogAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final kcal = day.meals.fold(0.0, (a, m) => a + m.totalCalories);
    final grams = day.meals.fold(0.0, (a, m) => a + m.totalAmount);
    final macros = day.meals.fold(
      MacroValues.zero,
      (a, m) => a + mealMacros(m),
    );
    final v = macros.values;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              FitFatTokens.spaceM,
              FitFatTokens.spaceL,
              FitFatTokens.spaceM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FitFatTokens.spaceS,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat.MMMEd(locale).format(day.day),
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      _num(context, kcal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'kcal · ${_num(context, grams)} g',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                MacroColumns(
                  labels: macroLabels(l10n),
                  values: [
                    for (var i = 0; i < 5; i++) '${formatMacro(i, v[i])} g',
                  ],
                ),
              ],
            ),
          ),
          for (var i = 0; i < day.meals.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: FitFatTokens.spaceL,
                endIndent: FitFatTokens.spaceL,
                color: scheme.outlineVariant,
              ),
            MealRow(
              key: ValueKey(day.meals[i].id),
              meal: day.meals[i],
              open: isOpen(day.meals[i].id),
              onToggle: () => onToggle(day.meals[i]),
              onEdit: () => onEdit(day.meals[i]),
              onLogAgain: () => onLogAgain(day.meals[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// time · kcal · grams · N foods · ⌄ · ↻, then the macro bar. Opened, it
/// lists each food (name, grams, kcal, bar) and offers Edit.
class MealRow extends StatelessWidget {
  const MealRow({
    super.key,
    required this.meal,
    required this.open,
    required this.onToggle,
    required this.onEdit,
    required this.onLogAgain,
  });

  final MealEntry meal;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onLogAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const tabular = [FontFeature.tabularFigures()];
    final strong = theme.textTheme.titleSmall?.copyWith(fontFeatures: tabular);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: tabular,
    );
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFatTokens.spaceL,
          FitFatTokens.spaceS,
          FitFatTokens.spaceXs,
          FitFatTokens.spaceS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: FitFatTokens.spaceM,
              children: [
                Text(
                  DateFormats.formatTime(
                    context,
                    TimeOfDay.fromDateTime(meal.eatenAt),
                  ),
                  style: strong,
                ),
                Text(
                  '${_num(context, meal.totalCalories)} kcal',
                  style: strong,
                ),
                Expanded(
                  child: Text(
                    '${_num(context, meal.totalAmount)} g · '
                    '${l10n.foodHistoryFoods(meal.items.length)}',
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                IconButton(
                  tooltip: l10n.foodHistoryLogAgain,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.replay, color: scheme.primary, size: 20),
                  onPressed: onLogAgain,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: FitFatTokens.spaceM),
              child: MacroBar(mealMacros(meal)),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  FitFatTokens.spaceS,
                  FitFatTokens.spaceM,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    FitFatTokens.spaceM,
                    FitFatTokens.spaceXs,
                    FitFatTokens.spaceM,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in meal.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: FitFatTokens.spaceXs + 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: FitFatTokens.spaceXs,
                            children: [
                              Row(
                                spacing: FitFatTokens.spaceS,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.foodName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    '${_num(context, item.amount)} g',
                                    style: muted,
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      '${_num(context, item.calories)} kcal',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontFeatures: tabular),
                                    ),
                                  ),
                                ],
                              ),
                              MacroBar(itemMacros(item), height: 14),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(l10n.foodHistoryEditMeal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
