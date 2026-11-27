import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../models/food.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_food.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/confirm_delete.dart';
import '../../ui/widgets/form_scaffold.dart';
import '../../ui/widgets/macro_bar.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/calories.dart';
import '../providers/foods.dart';
import '../providers/ingredients.dart';
import '../providers/meals.dart';
import '../repositories/food_repository.dart' show ResolvedFood;
import 'barcode_scan_sheet.dart';

/// Creates or edits a meal: the date and time (the title; tap to change),
/// live totals pinned on top, the foods with their grams, and a search field
/// at the end of the list that adds foods as you type. Meals have no name.
final class MealFormScreen extends ConsumerStatefulWidget {
  final MealEntry? meal;
  const MealFormScreen({super.key, this.meal});

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

final class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  late DateTime _eatenAt;
  bool _saving = false;
  String _query = '';

  /// Food id → grams, in the order the foods were added.
  final Map<String, double> _amounts = {};
  final Map<String, TextEditingController> _gramCtrls = {};

  /// Names of the foods already in the meal, so the first frame has them.
  final Map<String, String> _names = {};

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _eatenAt = meal?.eatenAt ?? DateTime.now();
    for (final item in meal?.items ?? const <MealFood>[]) {
      _put(item.foodId, item.amount);
      _names[item.foodId] = item.foodName;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    for (final c in _gramCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmtGrams(double g) =>
      g == g.roundToDouble() ? g.toStringAsFixed(0) : g.toStringAsFixed(1);

  void _put(String foodId, double grams) {
    _amounts[foodId] = grams;
    _gramCtrls.putIfAbsent(
      foodId,
      () => TextEditingController(text: _fmtGrams(grams)),
    );
  }

  void _remove(String foodId) => setState(() {
    _amounts.remove(foodId);
    _gramCtrls.remove(foodId)?.dispose();
  });

  void _add(String foodId, double grams) {
    setState(() {
      if (!_amounts.containsKey(foodId)) _put(foodId, grams);
      _searchCtrl.clear();
      _query = '';
    });
  }

  /// The grams last logged for each food, from the meal history.
  Map<String, double> _lastAmounts(List<MealEntry> meals) {
    final out = <String, double>{};
    final latest = <String, DateTime>{};
    for (final m in meals) {
      if (m.id == widget.meal?.id) continue;
      for (final i in m.items) {
        final seen = latest[i.foodId];
        if (seen == null || m.eatenAt.isAfter(seen)) {
          latest[i.foodId] = m.eatenAt;
          out[i.foodId] = i.amount;
        }
      }
    }
    return out;
  }

  ({double kcal, double grams, MacroValues macros}) _totals(
    Map<String, FoodNutrition?> profiles,
  ) {
    var kcal = 0.0, grams = 0.0;
    var macros = MacroValues.zero;
    for (final e in _amounts.entries) {
      final p = profiles[e.key]?.per100g;
      grams += e.value;
      if (p == null) continue;
      kcal += p.calories * e.value / 100;
      macros = macros + MacroValues.of(p).scale(e.value / 100);
    }
    return (kcal: kcal, grams: grams, macros: macros);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eatenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eatenAt),
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
    });
  }

  Future<void> _scan(Map<String, double> last) async {
    final l10n = AppLocalizations.of(context)!;
    final code = await showBarcodeScanSheet(context);
    if (code == null || !mounted) return;
    final ingredients = await ref.read(ingredientListProvider.future);
    if (!mounted) return;
    final match = ingredients.where((i) => i.barcode == code).firstOrNull;
    if (match == null) {
      showTopBanner(context, message: l10n.mealEditBarcodeUnknown(code));
      return;
    }
    final id = derivedFoodId(match.id);
    _names[id] = match.name;
    _add(id, last[id] ?? 100);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal!;
    final repo = ref.read(mealRepositoryProvider);
    final deleted = await confirmDelete(
      context,
      itemName: l10n.mealEditItemName,
      delete: () => repo.delete(meal.id),
      undo: () async {
        await repo.restore(meal);
        ref.invalidate(mealListProvider);
        invalidateDashboard(ref);
      },
    );
    if (!deleted || !mounted) return;
    invalidateDashboard(ref);
    Navigator.of(context).pop(true);
  }

  Future<void> _save(Map<String, FoodNutrition?> profiles) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = _amounts.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      showTopBanner(context, message: l10n.mealFormAddFood);
      return;
    }
    // A food that does not resolve would snapshot as zeros: refuse the log.
    if (selected.any((e) => profiles[e.key] == null)) {
      showTopBanner(context, message: l10n.mealFormFoodUnresolved);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final mealId = widget.meal?.id ?? const Uuid().v7();
      final meal = MealEntry(
        id: mealId,
        name: widget.meal?.name ?? '',
        eatenAt: _eatenAt,
        createdAt: widget.meal?.createdAt ?? DateTime.now(),
        items: [
          for (final e in selected)
            MealFood(
              id: const Uuid().v7(),
              mealId: mealId,
              foodId: e.key,
              foodName: '',
              amount: e.value,
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              // The repository scales the live profile and stores it.
              nutrition: profiles[e.key],
            ),
        ],
      );
      if (_isEditing) {
        await repo.update(meal);
      } else {
        await repo.insert(meal);
      }
      invalidateDashboard(ref);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nf = NumberFormat.decimalPattern(locale);

    final foods = ref.watch(foodListProvider).value ?? const <ResolvedFood>[];
    final profiles = {for (final f in foods) f.food.id: f.nutrition};
    for (final f in foods) {
      _names[f.food.id] = f.food.name;
    }
    final meals = ref.watch(mealListProvider).value ?? const <MealEntry>[];
    final last = _lastAmounts(meals);
    final target = ref.watch(calorieTargetProvider).value;
    final t = _totals(profiles);

    // Everything else eaten that day, plus this meal as it stands.
    final day = DateTime(_eatenAt.year, _eatenAt.month, _eatenAt.day);
    final dayOthers = meals
        .where(
          (m) =>
              m.id != widget.meal?.id &&
              DateTime(m.eatenAt.year, m.eatenAt.month, m.eatenAt.day) == day,
        )
        .fold(0.0, (a, m) => a + m.totalCalories);
    final dayTotal = dayOthers + t.kcal;

    final pinned = Container(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceM,
        FitFatTokens.spaceL,
        FitFatTokens.spaceM,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
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
              Text(
                nf.format(t.kcal.round()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text('kcal', style: theme.textTheme.bodyMedium),
              Expanded(
                child: Text(
                  '${nf.format(t.grams.round())} g · '
                  '${target == null ? l10n.mealEditDay(nf.format(dayTotal.round())) : l10n.mealEditDayOf(nf.format(dayTotal.round()), nf.format(target.round()))}',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          MacroBar(t.macros),
        ],
      ),
    );

    final q = _query.trim().toLowerCase();
    final suggestions = <ResolvedFood>[
      if (q.isNotEmpty)
        ...foods.where(
          (f) =>
              !_amounts.containsKey(f.food.id) &&
              f.food.name.toLowerCase().contains(q),
        )
      else if (_amounts.isEmpty)
        // Nothing typed yet on an empty meal: the foods logged most recently.
        ...() {
          final recent = <String>[];
          final byTime = [...meals]
            ..sort((a, b) => b.eatenAt.compareTo(a.eatenAt));
          for (final m in byTime) {
            for (final i in m.items) {
              if (!recent.contains(i.foodId)) recent.add(i.foodId);
            }
          }
          final byId = {for (final f in foods) f.food.id: f};
          return [for (final id in recent.take(6)) ?byId[id]];
        }(),
    ];
    // Recently logged foods first, then alphabetical.
    if (q.isNotEmpty) {
      suggestions.sort((a, b) {
        final la = last.containsKey(a.food.id) ? 0 : 1;
        final lb = last.containsKey(b.food.id) ? 0 : 1;
        return la != lb ? la - lb : a.food.name.compareTo(b.food.name);
      });
    }

    final dateLabel =
        '${DateFormat.MMMd(locale).format(_eatenAt)} · '
        '${DateFormats.formatTime(context, TimeOfDay.fromDateTime(_eatenAt))}';

    return FormScaffold(
      title: dateLabel,
      titleWidget: InkWell(
        key: const ValueKey('mealEditDate'),
        onTap: _pickDateTime,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FitFatTokens.spaceXs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
      canSave: _amounts.isNotEmpty,
      saving: _saving,
      onSave: () => _save(profiles),
      pinned: pinned,
      delete: _isEditing
          ? FormDeleteAction(label: l10n.mealEditDelete, onDelete: _delete)
          : null,
      children: [
        if (_amounts.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: FitFatTokens.spaceS),
            child: Column(
              children: [
                for (final id in _amounts.keys.toList())
                  Dismissible(
                    key: ValueKey('food-$id'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(
                        right: FitFatTokens.spaceL,
                      ),
                      color: scheme.errorContainer,
                      child: Icon(Icons.delete_outline, color: scheme.error),
                    ),
                    onDismissed: (_) => _remove(id),
                    child: _FoodRow(
                      name: _names[id] ?? id,
                      isRecipe: !isDerivedFoodId(id),
                      kcal:
                          (profiles[id]?.per100g.calories ?? 0) *
                          (_amounts[id] ?? 0) /
                          100,
                      unresolved: foods.isNotEmpty && profiles[id] == null,
                      controller: _gramCtrls[id]!,
                      onChanged: (v) => setState(
                        () => _amounts[id] =
                            double.tryParse(v.replaceAll(',', '.')) ?? 0,
                      ),
                      onRemove: () => _remove(id),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: FitFatTokens.spaceM),
        TextField(
          key: const ValueKey('mealEditSearch'),
          controller: _searchCtrl,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: l10n.mealEditSearch,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: l10n.mealEditScan,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scan(last),
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (q.isNotEmpty && suggestions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceM),
            child: Text(
              l10n.mealEditNoMatch,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (suggestions.isNotEmpty) ...[
          if (q.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FitFatTokens.spaceXs,
                FitFatTokens.spaceM,
                0,
                FitFatTokens.spaceXs,
              ),
              child: Text(
                l10n.mealEditRecent.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.only(top: FitFatTokens.spaceXs),
            child: Column(
              children: [
                for (final f in suggestions.take(8))
                  ListTile(
                    key: ValueKey('suggest-${f.food.id}'),
                    dense: true,
                    title: Text(f.food.name),
                    subtitle: Text(
                      [
                        if (!f.food.isDerived) l10n.mealEditRecipe,
                        if (last[f.food.id] case final g?)
                          l10n.mealEditLast(_fmtGrams(g)),
                      ].join(' · '),
                    ),
                    trailing: f.nutrition == null
                        ? null
                        : Text(
                            l10n.mealEditPer100(
                              f.nutrition!.per100g.calories.round(),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                    onTap: () => _add(f.food.id, last[f.food.id] ?? 100),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One food in the meal: icon, name, its kcal at this amount, and the grams.
final class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.name,
    required this.isRecipe,
    required this.kcal,
    required this.unresolved,
    required this.controller,
    required this.onChanged,
    required this.onRemove,
  });

  final String name;
  final bool isRecipe;
  final double kcal;
  final bool unresolved;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceM,
        FitFatTokens.spaceS,
        FitFatTokens.spaceXs,
        FitFatTokens.spaceS,
      ),
      child: Row(
        spacing: FitFatTokens.spaceM,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(FitFatTokens.radiusS),
            ),
            child: Icon(
              isRecipe ? Icons.menu_book_outlined : Icons.eco_outlined,
              size: 18,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  unresolved ? l10n.foodListUnresolved : '${kcal.round()} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: unresolved ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                isDense: true,
                suffixText: 'g',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: FitFatTokens.spaceS,
                  vertical: FitFatTokens.spaceS,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            tooltip: l10n.foodFormRemovePart,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
