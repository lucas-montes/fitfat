import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../../ui/tokens.dart';
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

  /// Foods the user has ticked, which is **not** the same thing as having an
  /// amount.
  ///
  /// These were conflated, and the conflation was the bug: `enabled` on the amount
  /// field was derived from `amount > 0`, so backspacing `100` to `00` parsed to
  /// zero and disabled the very field being typed into. That dropped its focus,
  /// closed the keyboard, and read as the sheet closing — while also removing the
  /// food from the meal. Selection now lives here and never moves because of
  /// what the user is typing.
  late final Set<String> _selected = {
    for (final e in widget.initialAmounts.entries)
      if (e.value > 0) e.key,
  };

  /// Parsed amount per selected food id. A ticked food with no valid amount is
  /// simply absent here. `_done` refuses to close while that is the case, so the
  /// result is always safe to use.
  ///
  /// Seeded from the incoming selection, so reopening the sheet for an existing
  /// meal restores both the tick state and the amounts.
  late final Map<String, double> _amounts = {
    for (final e in widget.initialAmounts.entries)
      if (e.value > 0) e.key: e.value,
  };

  /// The food blocking the Done button, or null. Inline rather than a banner: this is an
  /// error the user has to act on, and a banner would auto-dismiss before they
  /// had read which food was at fault.
  String? _missingAmountFor;

  /// Per-row amount fields. Kept in a map because rows rebuild on every
  /// keystroke in the amount field itself, and a `TextFormField` rebuilt from a
  /// changing `initialValue` would drop the caret mid-edit.
  final Map<String, TextEditingController> _amountCtrls = {};

  /// Food id -> display name, so the missing-amount error can name the food
  /// without another lookup.
  late final Map<String, String> _names = {
    for (final e in widget.foods) e.food.id: e.food.name,
  };

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

  TextEditingController _controllerFor(
    String id,
    double amount,
  ) => _amountCtrls.putIfAbsent(
    id,
    // Empty by default: ticking a box must not invent a portion. Only a food
    // that already had one gets its text back, so reopening the sheet for an
    // existing meal is unchanged.
    () => TextEditingController(
      text: amount > 0
          ? (amount == amount.roundToDouble()
                ? amount.toStringAsFixed(0)
                : amount.toString())
          : '',
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

  /// Records what the user typed, leaving the text itself alone.
  ///
  /// The controller keeps `00` or `80.` verbatim so the caret survives and the
  /// user can finish typing — normalising it here used to fight them mid-edit.
  /// Only a positive parse counts as an amount; anything else just means "not
  /// filled in yet", which leaves the food ticked.
  void _onAmountChanged(String id, String raw) {
    final parsed = double.tryParse(raw.trim());
    setState(() {
      if (parsed != null && parsed > 0) {
        _amounts[id] = parsed;
        _missingAmountFor = null;
      } else {
        _amounts.remove(id);
      }
    });
  }

  void _toggle(String id, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(id);
        // No default portion — the field starts empty on purpose.
        _amounts.remove(id);
      } else {
        _selected.remove(id);
        _amounts.remove(id);
        _amountCtrls.remove(id)?.dispose();
      }
      _missingAmountFor = null;
    });
  }

  /// Ticked foods with no usable amount, in list order.
  List<String> _missingAmounts() {
    final names = <String>[];
    for (final id in _selected) {
      if ((_amounts[id] ?? 0) <= 0) names.add(id);
    }
    names.sort();
    return names;
  }

  /// Confirms the selection, or blocks and names the first food with no amount.
  void _done() {
    final missing = _missingAmounts();
    if (missing.isNotEmpty) {
      setState(() => _missingAmountFor = _nameOf(missing.first));
      return;
    }
    Navigator.of(context).pop(Map.of(_amounts));
  }

  /// The blocking message, or null when nothing is wrong.
  String? _errorText(AppLocalizations l10n) => _missingAmountFor == null
      ? null
      : l10n.foodPickerNeedsAmount(_missingAmountFor!);

  /// The display name for a food id, falling back to the id so the error always
  /// identifies *something*.
  String _nameOf(String id) {
    final name = _names[id];
    return (name == null || name.isEmpty) ? id : name;
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
            onDone: _done,
            error: _errorText(l10n),
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
          onDone: _done,
          error: _errorText(l10n),
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
    final isSelected = _selected.contains(food.id);
    final per100g = entry.nutrition!.per100g;
    final portion = per100g.calories * amount / 100;
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: isSelected,
        onChanged: (v) => _toggle(food.id, v == true),
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
          // Never derived from the parsed amount: that made the field disable
          // itself the moment the user cleared it, which dropped the keyboard
          // and looked like the sheet closing.
          enabled: true,
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
          onChanged: (v) => _onAmountChanged(food.id, v),
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

  /// Blocking error shown under the header. Rendered inline rather than as a
  /// banner so it stays until the user fixes it — the sheet cannot close until
  /// they do.
  final String? error;

  const _SheetShell({
    required this.scrollController,
    required this.title,
    required this.searchField,
    required this.onDone,
    required this.children,
    this.error,
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
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: FitFatTokens.spaceS),
                Expanded(
                  child: Text(
                    error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
