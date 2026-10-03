import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_food.dart';
import '../../ui/date_formats.dart';
import '../providers/meals.dart';
import '../providers/foods.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../ui/widgets/top_banner.dart';

final class MealFormScreen extends ConsumerStatefulWidget {
  final MealEntry? meal;
  const MealFormScreen({super.key, this.meal});

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

final class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _searchCtrl;
  late DateTime _eatenAt;
  late TimeOfDay _eatenTime;
  bool _saving = false;

  /// Current name filter for the food picker (empty = show all).
  String _filter = '';

  /// Maps food id → grams eaten. A value > 0 means selected.
  late Map<String, double> _amounts;

  /// Live per-100g profile per selected food id, captured when the picker
  /// renders so `_buildItem` can hand the repository a real profile to
  /// snapshot instead of a zeroed placeholder.
  final Map<String, FoodNutrition?> _profiles = {};

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameCtrl = TextEditingController(text: meal?.name ?? '');
    _searchCtrl = TextEditingController();
    _eatenAt = meal?.eatenAt ?? DateTime.now();
    _eatenTime = TimeOfDay.fromDateTime(_eatenAt);
    _amounts = {};
    if (meal != null) {
      for (final item in meal.items) {
        _amounts[item.foodId] = item.amount;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Totals for what is currently selected, from the same pure resolution the
  /// repository uses — so the preview cannot disagree with what gets stored.
  Nutrition get _previewTotals {
    var calories = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    var sodium = 0.0, fiber = 0.0, sugar = 0.0;
    var sawSodium = false, sawFiber = false, sawSugar = false;
    for (final entry in _amounts.entries) {
      if (entry.value <= 0) continue;
      final per100g = _profiles[entry.key]?.per100g;
      // A food whose composition does not resolve contributes nothing here; the
      // save is refused later with a clearer message than a silent zero.
      if (per100g == null) continue;
      final f = entry.value / 100;
      calories += per100g.calories * f;
      protein += per100g.protein * f;
      carbs += per100g.carbs * f;
      fat += per100g.fat * f;
      if (per100g.sodium != null) {
        sawSodium = true;
        sodium += per100g.sodium! * f;
      }
      if (per100g.fiber != null) {
        sawFiber = true;
        fiber += per100g.fiber! * f;
      }
      if (per100g.sugar != null) {
        sawSugar = true;
        sugar += per100g.sugar! * f;
      }
    }
    return (
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sodium: sawSodium ? sodium : null,
      fiber: sawFiber ? fiber : null,
      sugar: sawSugar ? sugar : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final foodsAsync = ref.watch(foodListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.mealFormEditTitle : l10n.mealFormNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.mealFormNameLabel,
                hintText: l10n.mealFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.mealFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Date & time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.mealFormDateTime),
              subtitle: Text(
                '${DateFormats.formatDate(context, _eatenAt)}  '
                '${DateFormats.formatTime(context, _eatenTime)}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),

            // Food selection
            Text(
              l10n.mealFormFoods,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            foodsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text(l10n.errorLoadingResource(l10n.mealFormFoods, '$e')),
              data: (resolved) {
                // Remember each food's live profile for the snapshot, including
                // ones already selected, so editing an existing meal keeps the
                // stored macros in step with the current recipe.
                for (final entry in resolved) {
                  _profiles[entry.food.id] = entry.nutrition;
                }
                final foods =
                    [
                      for (final entry in resolved)
                        if (entry.nutrition != null) entry.food,
                    ]..sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                if (foods.isEmpty) {
                  return Text(l10n.mealFormNoFoods);
                }
                final query = _filter.trim().toLowerCase();
                final visible = query.isEmpty
                    ? foods
                    : foods
                          .where((f) => f.name.toLowerCase().contains(query))
                          .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.commonSearch,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 8),
                    ...visible.map(
                      (food) => _FoodRow(
                        food: food,
                        amount: _amounts[food.id] ?? 0,
                        nutrition: _profiles[food.id],
                        l10n: l10n,
                        onChanged: (g) => setState(() {
                          if (g > 0) {
                            _amounts[food.id] = g;
                          } else {
                            _amounts.remove(food.id);
                          }
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            _TotalsCard(totals: _previewTotals, l10n: l10n),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.mealFormSaving : l10n.mealFormSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    // Pick date
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    // Pick time
    final time = await showTimePicker(
      context: context,
      initialTime: _eatenTime,
    );
    if (time == null || !mounted) return;

    setState(() {
      _eatenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _eatenTime = time;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final selected = _amounts.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      showTopBanner(context, message: l10n.mealFormAddFood);
      return;
    }

    // A food with an unresolvable composition would snapshot as zeros, so refuse
    // the whole log rather than record a meal that silently under-reports.
    final unresolved = selected
        .where((e) => _profiles[e.key]?.per100g == null)
        .map((e) => e.key)
        .toList();
    if (unresolved.isNotEmpty) {
      showTopBanner(context, message: l10n.mealFormFoodUnresolved);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final mealId = _isEditing ? widget.meal!.id : const Uuid().v7();

      final items = selected
          .map(
            (e) => _buildItem(
              e.key,
              e.value,
              nutrition: _profiles[e.key]!,
              mealId: mealId,
            ),
          )
          .toList();

      final meal = MealEntry(
        id: mealId,
        name: name,
        eatenAt: _eatenAt,
        createdAt: _isEditing ? widget.meal!.createdAt : DateTime.now(),
        items: items,
      );
      if (_isEditing) {
        await repo.update(meal);
      } else {
        await repo.insert(meal);
      }
      invalidateDashboard(ref);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  MealFood _buildItem(
    String foodId,
    double amount, {
    required FoodNutrition nutrition,
    required String mealId,
  }) {
    return MealFood(
      id: const Uuid().v7(),
      mealId: mealId,
      foodId: foodId,
      foodName: '', // filled in after save via getAll
      amount: amount,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      // The live profile is all the repository needs; it scales this to
      // [amount] and writes the snapshot itself.
      nutrition: nutrition,
    );
  }
}

final class _FoodRow extends StatelessWidget {
  final Food food;
  final double amount;
  final FoodNutrition? nutrition;
  final AppLocalizations l10n;
  final void Function(double) onChanged;

  const _FoodRow({
    required this.food,
    required this.amount,
    required this.nutrition,
    required this.l10n,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = amount > 0;
    final per100g = nutrition?.per100g;
    if (per100g == null) return const SizedBox.shrink();
    final portionCalories = per100g.calories * amount / 100;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) => onChanged(v == true ? 100 : 0),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    Text(
                      l10n.mealFormFoodCalories(
                        portionCalories.toStringAsFixed(0),
                        per100g.calories.toStringAsFixed(0),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: isSelected ? amount.toStringAsFixed(0) : '',
                decoration: InputDecoration(
                  labelText: l10n.mealFormGramsLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: isSelected,
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  onChanged(parsed ?? 0);
                },
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

final class _TotalsCard extends StatelessWidget {
  final Nutrition totals;
  final AppLocalizations l10n;

  const _TotalsCard({required this.totals, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mealFormTotals, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              l10n.ingredientMacroRow(
                totals.calories.toStringAsFixed(0),
                totals.calories.toStringAsFixed(0),
                totals.protein.toStringAsFixed(1),
                totals.carbs.toStringAsFixed(1),
                totals.fat.toStringAsFixed(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
