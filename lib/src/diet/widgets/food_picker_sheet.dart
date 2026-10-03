import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../repositories/food_repository.dart';

/// Picks the foods logged in a meal, with an amount for each.
///
/// Replaces an inline list on the meal form. That list rendered every food —
/// every single ingredient's own 1:1 food plus every recipe — as one
/// non-virtualized `Column`, re-filtered on every keystroke, so typing rebuilt
/// hundreds of rows per character. This sheet debounces the query and
/// virtualizes the list, and separates recipes from single ingredients so the
/// recipes you actually compose are not buried.
///
/// Returns the chosen amounts keyed by food id, or `null` if dismissed.
/// Foods whose composition does not resolve are excluded: logging one would
/// record a zero-calorie meal, which `MealRepository` refuses anyway.
Future<Map<String, double>?> showFoodPickerSheet(
  BuildContext context, {
  required List<ResolvedFood> foods,
  required Map<String, double> initialAmounts,
}) {
  return showModalBottomSheet<Map<String, double>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) =>
        _FoodPickerSheet(foods: foods, initialAmounts: initialAmounts),
  );
}

final class _FoodPickerSheet extends StatefulWidget {
  final List<ResolvedFood> foods;
  final Map<String, double> initialAmounts;

  const _FoodPickerSheet({required this.foods, required this.initialAmounts});

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

final class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final _searchCtrl = TextEditingController();

  /// Amount per food id. A value > 0 means selected, matching `MealRepository`.
  late final Map<String, double> _amounts = {
    for (final e in widget.initialAmounts.entries)
      if (e.value > 0) e.key: e.value,
  };

  /// Per-row amount fields. Kept in a map because rows rebuild on every
  /// keystroke in the amount field itself, and a `TextFormField` rebuilt from a
  /// changing `initialValue` would drop the caret mid-edit.
  final Map<String, TextEditingController> _amountCtrls = {};

  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String id, double amount) =>
      _amountCtrls.putIfAbsent(
        id,
        () => TextEditingController(
          text: amount == amount.roundToDouble()
              ? amount.toStringAsFixed(0)
              : amount.toString(),
        ),
      );

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    // Same debounce as the exercise select sheet: long enough to skip
    // intermediate keystrokes, short enough to feel immediate.
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = v);
    });
  }

  void _setAmount(String id, double amount) {
    setState(() {
      if (amount > 0) {
        _amounts[id] = amount;
      } else {
        _amounts.remove(id);
      }
    });
    final c = _amountCtrls[id];
    if (c != null && amount > 0) {
      final text = amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toString();
      if (c.text != text) c.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();

    final resolvable = [
      for (final entry in widget.foods)
        if (entry.nutrition != null) entry,
    ];

    bool matches(Food food) =>
        query.isEmpty || food.name.toLowerCase().contains(query);

    // Recipes first, then the single-ingredient foods. Derived foods all mirror
    // an ingredient 1:1 and are excluded from the recipes screen, so this is
    // also the only place they surface — without them a plain ingredient could
    // not be logged at all.
    final recipes = [
      for (final e in resolvable)
        if (!e.food.isDerived && matches(e.food)) e,
    ];
    final singles = [
      for (final e in resolvable)
        if (e.food.isDerived && matches(e.food)) e,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        if (resolvable.isEmpty) {
          return _SheetShell(
            scrollController: scrollController,
            title: l10n.foodPickerTitle,
            searchField: null,
            onDone: () => Navigator.of(context).pop(_amounts),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.foodPickerNoFoods,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          );
        }

        final rows = <Widget>[];
        if (recipes.isNotEmpty) {
          rows.add(_SectionHeader(l10n.foodPickerSectionRecipes));
          for (final e in recipes) {
            rows.add(
              _row(e, _controllerFor(e.food.id, _amounts[e.food.id] ?? 0)),
            );
          }
        }
        if (singles.isNotEmpty) {
          if (recipes.isNotEmpty) rows.add(const SizedBox(height: 8));
          rows.add(_SectionHeader(l10n.foodPickerSectionIngredients));
          for (final e in singles) {
            rows.add(
              _row(e, _controllerFor(e.food.id, _amounts[e.food.id] ?? 0)),
            );
          }
        }
        if (rows.isEmpty) {
          rows.add(
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.foodPickerEmpty,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        return _SheetShell(
          scrollController: scrollController,
          title: l10n.foodPickerTitle,
          searchField: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.foodPickerSearchHint,
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          onDone: () => Navigator.of(context).pop(_amounts),
          // The section headers are already in `rows`, so a plain sliver list of
          // the rows keeps them sticky-free but virtualized — the whole point of
          // this sheet.
          children: rows,
        );
      },
    );
  }

  Widget _row(ResolvedFood entry, TextEditingController controller) {
    final l10n = AppLocalizations.of(context)!;
    final food = entry.food;
    final amount = _amounts[food.id] ?? 0;
    final isSelected = amount > 0;
    final per100g = entry.nutrition!.per100g;
    final portion = per100g.calories * amount / 100;
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: isSelected,
        onChanged: (v) => _setAmount(food.id, v == true ? 100 : 0),
      ),
      title: Text(
        food.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        isSelected
            ? l10n.mealFormFoodCalories(
                portion.toStringAsFixed(0),
                per100g.calories.toStringAsFixed(0),
              )
            : l10n.mealFormFoodCalories(
                '0',
                per100g.calories.toStringAsFixed(0),
              ),
        style: theme.textTheme.bodySmall,
      ),
      trailing: SizedBox(
        width: 84,
        child: TextField(
          controller: controller,
          enabled: isSelected,
          textAlign: TextAlign.end,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            suffixText: 'g',
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            _setAmount(food.id, parsed ?? 0);
          },
        ),
      ),
    );
  }
}

/// Chrome shared by the empty and populated states: a title bar, an optional
/// search field, the virtualized body, and a done button.
final class _SheetShell extends StatelessWidget {
  final ScrollController scrollController;
  final String title;
  final Widget? searchField;
  final VoidCallback onDone;
  final List<Widget> children;

  const _SheetShell({
    required this.scrollController,
    required this.title,
    required this.searchField,
    required this.onDone,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              TextButton(onPressed: onDone, child: Text(l10n.foodPickerDone)),
            ],
          ),
        ),
        if (searchField != null) searchField!,
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: children.length,
            itemBuilder: (_, i) => children[i],
          ),
        ),
      ],
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
