import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/food.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../services/logger.dart';
import '../providers/ingredients.dart';
import '../providers/meals.dart';
import '../providers/diet_preferences.dart';
import 'meals/edit.dart';
import 'ingredients/edit.dart';
import 'widgets/food_entry_card.dart';

final _log = logger('diet_meals_tab');

// Widget that is used by the router to display the diet screen, which contains tabs for meals and ingredients
class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.mealsTab),
              Tab(text: l10n.ingredientsTab),
            ],
          ),
        ),
        body: const TabBarView(children: [MealsTab(), _IngredientsTab()]),
      ),
    );
  }
}

class MealsTab extends ConsumerStatefulWidget {
  const MealsTab({super.key});

  @override
  ConsumerState<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends ConsumerState<MealsTab> {
  final DateFormat _dayFormat = DateFormat('EEE, MMM d');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealsProvider.notifier).loadMonth(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealsProvider);
    final meals = state.meals;
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(dietPreferencesProvider);
    final groupedMeals = _groupMealsByDay(meals);
    _log.info('MealsTab build: meals=${meals.length} status=${state.status}');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addMeal),
              onPressed: () => _openAddMeal(context),
            ),
          );
        }

        final groupIndex = index - 1;
        if (groupIndex >= groupedMeals.length) return null;

        final group = groupedMeals[groupIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDayGroupCard(context, group, prefs),
        );
      },
      itemCount: groupedMeals.length + 1,
    );
  }

  List<_MealsDayGroup> _groupMealsByDay(List<MealEntry> meals) {
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in meals) {
      final dayKey = DateTime(
        meal.eatenAt.year,
        meal.eatenAt.month,
        meal.eatenAt.day,
      );
      grouped.putIfAbsent(dayKey, () => <MealEntry>[]).add(meal);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return entries
        .map((entry) => _MealsDayGroup(day: entry.key, meals: entry.value))
        .toList();
  }

  Widget _buildDayGroupCard(
    BuildContext context,
    _MealsDayGroup group,
    DietPreferences prefs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dailyTotals = group.meals.fold(
      MacroNutrients.zero,
      (sum, meal) => sum + meal.totalMacros,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayFormat.format(group.day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.formatTotal(
                _formatMacrosWithPrefs(dailyTotals, prefs, l10n),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
            for (final meal in group.meals) _buildMealRow(context, meal, prefs),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(
    BuildContext context,
    MealEntry meal,
    DietPreferences prefs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final title = (meal.name?.trim().isEmpty ?? true) ? l10n.meal : meal.name!;
    final macros = meal.totalMacros;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        '${_timeFormat.format(meal.eatenAt)} · ${_formatMacrosWithPrefs(macros, prefs, l10n)} · ${l10n.items(meal.items.length)}',
      ),
      onTap: () => _editMeal(context, meal),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.deleteMealTooltip,
        onPressed: () => _deleteMeal(meal.id),
      ),
    );
  }

  String _formatMacrosWithPrefs(
    MacroNutrients macros,
    DietPreferences prefs,
    AppLocalizations l10n,
  ) {
    final parts = <String>[];

    if (prefs.isCaloriesVisible) {
      parts.add('${macros.calories.toStringAsFixed(0)} ${l10n.kcalAbbrev}');
    }
    if (prefs.isProteinVisible) {
      parts.add('${l10n.proteinAbbrev} ${macros.protein.toStringAsFixed(1)}g');
    }
    if (prefs.isCarbsVisible) {
      parts.add('${l10n.carbsAbbrev} ${macros.carbs.toStringAsFixed(1)}g');
    }
    if (prefs.isFatVisible) {
      parts.add('${l10n.fatAbbrev} ${macros.fat.toStringAsFixed(1)}g');
    }

    return parts.join(' · ');
  }

  void _openAddMeal(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddMealScreen()));
  }

  void _editMeal(BuildContext context, MealEntry meal) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddMealScreen(initialMeal: meal)));
  }

  void _deleteMeal(String id) async {
    final l10n = AppLocalizations.of(ref.context)!;
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMealTitle),
        content: Text(l10n.deleteMealContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mealsProvider.notifier).deleteMeal(id);
  }
}

class _MealsDayGroup {
  const _MealsDayGroup({required this.day, required this.meals});

  final DateTime day;
  final List<MealEntry> meals;
}

class _IngredientsTab extends ConsumerStatefulWidget {
  const _IngredientsTab();

  @override
  ConsumerState<_IngredientsTab> createState() => _IngredientsTabState();
}

class _IngredientsTabState extends ConsumerState<_IngredientsTab> {
  final _searchController = TextEditingController();
  final bool _sortAscending = true;
  bool _showArchived = false;
  double? _filterMinCalories;
  double? _filterMaxCalories;
  double? _filterMinProtein;
  double? _filterMaxProtein;
  double? _filterMinCarbs;
  double? _filterMaxCarbs;
  double? _filterMinFat;
  double? _filterMaxFat;
  double? _filterMinSodium;
  double? _filterMaxSodium;
  double? _filterMinFiber;
  double? _filterMaxFiber;

  // Holds slider state for the filter sheet (initialized on open)
  RangeValues _calRange = const RangeValues(0, 900);
  RangeValues _proRange = const RangeValues(0, 100);
  RangeValues _carbsRange = const RangeValues(0, 100);
  RangeValues _fatRange = const RangeValues(0, 100);
  RangeValues _sodiumRange = const RangeValues(0, 5000);
  RangeValues _fiberRange = const RangeValues(0, 50);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.watch(dietPreferencesProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filtered =
        ingredients.where((e) {
          if (_showArchived != e.isArchived) return false;
          if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
            return false;
          }
          if (_filterMinCalories != null &&
              e.caloriesPer100g < _filterMinCalories!) {
            return false;
          }
          if (_filterMaxCalories != null &&
              e.caloriesPer100g > _filterMaxCalories!) {
            return false;
          }
          if (_filterMinProtein != null &&
              e.proteinPer100g < _filterMinProtein!) {
            return false;
          }
          if (_filterMaxProtein != null &&
              e.proteinPer100g > _filterMaxProtein!) {
            return false;
          }
          if (_filterMinCarbs != null && e.carbsPer100g < _filterMinCarbs!) {
            return false;
          }
          if (_filterMaxCarbs != null && e.carbsPer100g > _filterMaxCarbs!) {
            return false;
          }
          if (_filterMinFat != null && e.fatPer100g < _filterMinFat!) {
            return false;
          }
          if (_filterMaxFat != null && e.fatPer100g > _filterMaxFat!) {
            return false;
          }
          if (_filterMinSodium != null &&
              (e.sodiumPer100g ?? 0) < _filterMinSodium!) {
            return false;
          }
          if (_filterMaxSodium != null &&
              (e.sodiumPer100g ?? 0) > _filterMaxSodium!) {
            return false;
          }
          if (_filterMinFiber != null &&
              (e.fiberPer100g ?? 0) < _filterMinFiber!) {
            return false;
          }
          if (_filterMaxFiber != null &&
              (e.fiberPer100g ?? 0) > _filterMaxFiber!) {
            return false;
          }
          return true;
        }).toList()..sort(
          (a, b) => _sortAscending
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );

    final hasActiveFilters =
        _filterMinCalories != null ||
        _filterMaxCalories != null ||
        _filterMinProtein != null ||
        _filterMaxProtein != null ||
        _filterMinCarbs != null ||
        _filterMaxCarbs != null ||
        _filterMinFat != null ||
        _filterMaxFat != null ||
        _filterMinSodium != null ||
        _filterMaxSodium != null ||
        _filterMinFiber != null ||
        _filterMaxFiber != null;

    return Column(
      children: [
        // ── Compact header bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchIngredients,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  hasActiveFilters
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  size: 20,
                ),
                onPressed: () => _openFilterSheet(context, l10n),
                tooltip: 'Filters',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                onPressed: () => _openAddIngredient(context, ref),
                tooltip: l10n.addIngredient,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noIngredientsFound,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.noIngredientsFoundSubtext,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ingredient = filtered[index];
                    final macroChips = <Widget>[];
                    if (prefs.isCaloriesVisible) {
                      macroChips.add(
                        _MacroChip(
                          label:
                              '${ingredient.caloriesPer100g.toStringAsFixed(0)} ${l10n.kcalAbbrev}',
                        ),
                      );
                    }
                    if (prefs.isProteinVisible) {
                      macroChips.add(
                        _MacroChip(
                          label:
                              '${l10n.proteinAbbrev} ${ingredient.proteinPer100g.toStringAsFixed(1)}g',
                        ),
                      );
                    }
                    if (prefs.isCarbsVisible) {
                      macroChips.add(
                        _MacroChip(
                          label:
                              '${l10n.carbsAbbrev} ${ingredient.carbsPer100g.toStringAsFixed(1)}g',
                        ),
                      );
                    }
                    if (prefs.isFatVisible) {
                      macroChips.add(
                        _MacroChip(
                          label:
                              '${l10n.fatAbbrev} ${ingredient.fatPer100g.toStringAsFixed(1)}g',
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FoodEntryCard(
                        title: ingredient.name,
                        onTap: () => _editIngredient(context, ref, ingredient),
                        onDelete: () => _deleteIngredient(ref, ingredient.id),
                        body: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: macroChips,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openFilterSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        // Local slider state
        var cal = _calRange;
        var pro = _proRange;
        var carbs = _carbsRange;
        var fat = _fatRange;
        var sod = _sodiumRange;
        var fib = _fiberRange;
        var showArchived = _showArchived;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Active'),
                        selected: !showArchived,
                        onSelected: (_) =>
                            setSheetState(() => showArchived = false),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(l10n.archivedIngredients),
                        selected: showArchived,
                        onSelected: (_) =>
                            setSheetState(() => showArchived = true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        _NutrientSlider(
                          label: 'Kcal',
                          range: cal,
                          min: 0,
                          max: 900,
                          divisions: 18,
                          onChanged: (v) => setSheetState(() => cal = v),
                        ),
                        _NutrientSlider(
                          label: 'Protein (g)',
                          range: pro,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (v) => setSheetState(() => pro = v),
                        ),
                        _NutrientSlider(
                          label: 'Carbs (g)',
                          range: carbs,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (v) => setSheetState(() => carbs = v),
                        ),
                        _NutrientSlider(
                          label: 'Fat (g)',
                          range: fat,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          onChanged: (v) => setSheetState(() => fat = v),
                        ),
                        _NutrientSlider(
                          label: 'Sodium (mg)',
                          range: sod,
                          min: 0,
                          max: 5000,
                          divisions: 50,
                          onChanged: (v) => setSheetState(() => sod = v),
                        ),
                        _NutrientSlider(
                          label: 'Fiber (g)',
                          range: fib,
                          min: 0,
                          max: 50,
                          divisions: 25,
                          onChanged: (v) => setSheetState(() => fib = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showArchived = false;
                            _filterMinCalories = null;
                            _filterMaxCalories = null;
                            _filterMinProtein = null;
                            _filterMaxProtein = null;
                            _filterMinCarbs = null;
                            _filterMaxCarbs = null;
                            _filterMinFat = null;
                            _filterMaxFat = null;
                            _filterMinSodium = null;
                            _filterMaxSodium = null;
                            _filterMinFiber = null;
                            _filterMaxFiber = null;
                            _calRange = const RangeValues(0, 900);
                            _proRange = const RangeValues(0, 100);
                            _carbsRange = const RangeValues(0, 100);
                            _fatRange = const RangeValues(0, 100);
                            _sodiumRange = const RangeValues(0, 5000);
                            _fiberRange = const RangeValues(0, 50);
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset'),
                      ),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _showArchived = showArchived;
                            _calRange = cal;
                            _proRange = pro;
                            _carbsRange = carbs;
                            _fatRange = fat;
                            _sodiumRange = sod;
                            _fiberRange = fib;
                            _filterMinCalories = cal.start > 0
                                ? cal.start
                                : null;
                            _filterMaxCalories = cal.end < 900 ? cal.end : null;
                            _filterMinProtein = pro.start > 0
                                ? pro.start
                                : null;
                            _filterMaxProtein = pro.end < 100 ? pro.end : null;
                            _filterMinCarbs = carbs.start > 0
                                ? carbs.start
                                : null;
                            _filterMaxCarbs = carbs.end < 100
                                ? carbs.end
                                : null;
                            _filterMinFat = fat.start > 0 ? fat.start : null;
                            _filterMaxFat = fat.end < 100 ? fat.end : null;
                            _filterMinSodium = sod.start > 0 ? sod.start : null;
                            _filterMaxSodium = sod.end < 5000 ? sod.end : null;
                            _filterMinFiber = fib.start > 0 ? fib.start : null;
                            _filterMaxFiber = fib.end < 50 ? fib.end : null;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddIngredient(BuildContext context, WidgetRef ref) async {
    final ingredient = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const CustomIngredientScreen()),
    );
    if (ingredient == null) return;
    ref.read(ingredientsProvider.notifier).addIngredient(ingredient);
  }

  Future<void> _editIngredient(
    BuildContext context,
    WidgetRef ref,
    Ingredient ingredient,
  ) async {
    final updated = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(
        builder: (_) => CustomIngredientScreen(initialIngredient: ingredient),
      ),
    );
    if (updated == null) return;
    ref.read(ingredientsProvider.notifier).updateIngredient(updated);
  }

  void _deleteIngredient(WidgetRef ref, String id) {
    _confirmAndDelete(ref, id);
  }

  Future<void> _confirmAndDelete(WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(ref.context)!;
    final confirmed = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteIngredientTitle),
        content: Text(l10n.deleteIngredientContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(ingredientsProvider.notifier).removeIngredient(id);
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _NutrientSlider extends StatelessWidget {
  const _NutrientSlider({
    required this.label,
    required this.range,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final RangeValues range;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${range.start.toStringAsFixed(1)} – ${range.end.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          RangeSlider(
            values: range,
            min: min,
            max: max,
            divisions: divisions,
            labels: RangeLabels(
              range.start.toStringAsFixed(1),
              range.end.toStringAsFixed(1),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
