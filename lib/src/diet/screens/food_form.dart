import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../../models/ingredient.dart';
import '../../ui/format.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/foods.dart';
import '../providers/ingredients.dart';
import '../repositories/food_repository.dart';
import '../services/food_nutrition.dart';

/// Creates or edits a food's **composition**: which ingredients go in it and
/// how much of each.
///
/// The food itself stores no nutrition — the preview below is resolved live
/// from the rows via the same pure function the repository and the meal snapshot
/// use, so what the user sees here is exactly what a meal will record. Amounts
/// are absolute amounts in the batch (the denominator is their sum), not
/// percentages.
final class FoodFormScreen extends ConsumerStatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

final class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  /// Ingredient id → amount in the batch.
  final Map<String, double> _amounts = {};

  /// Ingredient id → its own row, so a part that is archived (and therefore
  /// missing from the picker) still renders instead of vanishing on save.
  final Map<String, Ingredient> _parts = {};

  final Map<String, TextEditingController> _amountCtrls = {};
  final Map<String, ValueNotifier<String?>> _amountErrors = {};

  String _filter = '';
  bool _saving = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.food?.name ?? '';
    unawaited(_load());
  }

  Future<void> _load() async {
    final food = widget.food;
    if (food == null) return;
    final components = await ref
        .read(foodRepositoryProvider)
        .getComponents(food.id);
    // `ingredientListProvider` hides archived rows, so anything it does not
    // return is fetched directly — otherwise archiving a part and then editing
    // the recipe would silently drop it on save.
    final byId = <String, Ingredient>{
      for (final i in await ref.read(ingredientListProvider.future)) i.id: i,
    };
    final repo = ref.read(ingredientRepositoryProvider);
    for (final c in components) {
      if (byId.containsKey(c.ingredientId)) continue;
      final archived = await repo.getById(c.ingredientId);
      if (archived != null) byId[c.ingredientId] = archived;
    }
    if (!mounted) return;
    setState(() {
      for (final c in components) {
        final part = byId[c.ingredientId];
        if (part == null) continue;
        _parts[c.ingredientId] = part;
        _amounts[c.ingredientId] = c.amount;
      }
    });
    _syncControllers();
  }

  void _syncControllers() {
    for (final id in _amounts.keys) {
      _amountCtrls.putIfAbsent(
        id,
        () => TextEditingController(text: _formatAmount(_amounts[id]!)),
      );
      _amountErrors.putIfAbsent(id, () => ValueNotifier<String?>(null));
    }
    final live = _amounts.keys.toSet();
    for (final id in _amountCtrls.keys.toList()) {
      if (live.contains(id)) continue;
      _amountCtrls.remove(id)?.dispose();
      _amountErrors.remove(id)?.dispose();
    }
  }

  String _formatAmount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : formatDecimal(v);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    for (final e in _amountErrors.values) {
      e.dispose();
    }
    super.dispose();
  }

  /// Live per-100g profile of the current draft, or null when nothing is added
  /// yet. Uses the same resolution the repository snapshots from.
  FoodNutrition? get _preview => _amounts.isEmpty
      ? null
      : resolveFoodPer100g([
          for (final entry in _amounts.entries)
            (
              caloriesPer100g: _parts[entry.key]!.caloriesPer100g,
              proteinPer100g: _parts[entry.key]!.proteinPer100g,
              carbsPer100g: _parts[entry.key]!.carbsPer100g,
              fatPer100g: _parts[entry.key]!.fatPer100g,
              sodiumPer100g: _parts[entry.key]!.sodiumPer100g,
              fiberPer100g: _parts[entry.key]!.fiberPer100g,
              sugarPer100g: _parts[entry.key]!.sugarPer100g,
              amount: entry.value,
            ),
        ]);

  /// Total batch weight, which is the denominator of the per-100g figures.
  double get _batchTotal =>
      _amounts.values.fold(0.0, (sum, amount) => sum + amount);

  /// Ingredients not yet used in this recipe.
  List<Ingredient> _candidates(List<Ingredient> all) => [
    for (final i in all)
      if (!_amounts.containsKey(i.id)) i,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.foodFormEditTitle : l10n.foodFormNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.foodFormNameLabel,
                hintText: l10n.foodFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.foodFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            Text(l10n.foodFormComposition, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              l10n.foodFormCompositionHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            // Parts already in the recipe
            if (_amounts.isNotEmpty) ...[
              Card(
                child: Column(
                  children: [
                    for (final id in _amounts.keys.toList())
                      _PartRow(
                        ingredient: _parts[id]!,
                        amount: _amounts[id]!,
                        controller: _amountCtrls[id]!,
                        error: _amountErrors[id]!,
                        l10n: l10n,
                        onAmountChanged: (v) =>
                            setState(() => _amounts[id] = v),
                        onRemoved: () => setState(() {
                          _amounts.remove(id);
                          _parts.remove(id);
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PreviewCard(
                preview: _preview,
                batchTotal: _batchTotal,
                l10n: l10n,
              ),
              const SizedBox(height: 20),
            ],

            // Add a part
            Text(l10n.foodFormAddPart, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.ingredientListSearchHint,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            ingredientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (all) {
                final query = _filter.trim().toLowerCase();
                final candidates = _candidates(all).where(
                  (i) => query.isEmpty || i.name.toLowerCase().contains(query),
                );
                if (candidates.isEmpty) {
                  return Text(l10n.foodFormNoMoreParts);
                }
                return Column(
                  children: [
                    for (final i in candidates)
                      ListTile(
                        dense: true,
                        title: Text(i.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: l10n.foodFormAddPart,
                          onPressed: () => setState(() {
                            _parts[i.id] = i;
                            _amounts[i.id] = 100;
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.foodFormSaving : l10n.foodFormSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    if (_amounts.isEmpty) {
      showTopBanner(context, message: l10n.foodFormNeedsParts);
      return;
    }
    // A zero or negative amount would make the whole batch unresolvable, since
    // it is the denominator — so reject rather than store a food that logs as
    // zero calories.
    final bad = _amounts.entries.where((e) => e.value <= 0).toList();
    if (bad.isNotEmpty) {
      for (final e in bad) {
        _amountErrors[e.key]?.value = l10n.foodFormAmountPositive;
      }
      showTopBanner(context, message: l10n.foodFormAmountPositive);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(foodRepositoryProvider);
      final food = widget.food ?? newFood(name: _nameCtrl.text.trim());
      final components = [
        for (final entry in _amounts.entries)
          FoodIngredient(
            foodId: food.id,
            ingredientId: entry.key,
            ingredientName: _parts[entry.key]!.name,
            amount: entry.value,
          ),
      ];

      if (_isEditing) {
        await repo.update(
          food.copyWith(name: _nameCtrl.text.trim()),
          components,
        );
      } else {
        await repo.insert(food, components);
      }
      invalidateFoods(ref);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

final class _PartRow extends StatelessWidget {
  final Ingredient ingredient;
  final double amount;
  final TextEditingController controller;
  final ValueNotifier<String?> error;
  final AppLocalizations l10n;
  final void Function(double) onAmountChanged;
  final VoidCallback onRemoved;

  const _PartRow({
    required this.ingredient,
    required this.amount,
    required this.controller,
    required this.error,
    required this.l10n,
    required this.onAmountChanged,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 96,
            child: ValueListenableBuilder<String?>(
              valueListenable: error,
              builder: (context, err, _) => TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.foodFormAmountLabel,
                  isDense: true,
                  errorText: err,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  onAmountChanged(parsed ?? 0);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.foodFormRemovePart,
            onPressed: onRemoved,
          ),
        ],
      ),
    );
  }
}

/// Live composition math, so the user sees the consequence of the amounts
/// before anything is stored. Foods hold no nutrition — this is derived.
final class _PreviewCard extends StatelessWidget {
  final FoodNutrition? preview;
  final double batchTotal;
  final AppLocalizations l10n;

  const _PreviewCard({
    required this.preview,
    required this.batchTotal,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final per100g = preview?.per100g;
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.foodFormPreview, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            if (per100g == null)
              Text(l10n.foodFormPreviewEmpty)
            else ...[
              Text(
                l10n.ingredientMacroRow(
                  per100g.calories.toStringAsFixed(0),
                  per100g.calories.toStringAsFixed(0),
                  per100g.protein.toStringAsFixed(1),
                  per100g.carbs.toStringAsFixed(1),
                  per100g.fat.toStringAsFixed(1),
                ),
              ),
              const SizedBox(height: 4),
              Text(l10n.foodFormPer100g, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                l10n.foodFormBatchTotal(formatDecimal(batchTotal)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
