import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/food.dart';
import '../../models/ingredient.dart';
import '../../ui/format.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/confirm_delete.dart';
import '../../ui/widgets/form_scaffold.dart';
import '../../ui/widgets/macro_bar.dart';
import '../../ui/widgets/top_banner.dart';
import '../providers/foods.dart';
import '../providers/ingredients.dart';
import '../repositories/food_repository.dart';
import '../services/food_nutrition.dart';

/// Creates or edits a recipe as a table: one row per ingredient (raw grams,
/// kcal, protein, carbs, fat), an inline row to add one, the raw total, the
/// cooked weight (weighed after cooking) and the per-100 g row it produces.
///
/// The food stores no nutrition: every number is resolved live with the same
/// pure function the repository and the meal snapshot use.
final class FoodFormScreen extends ConsumerStatefulWidget {
  final Food? food;

  /// An existing recipe to start a **new** one from (a new batch of the same
  /// dish): name and composition are prefilled and saving inserts a separate
  /// food. Ignored when [food] is set.
  final Food? template;

  const FoodFormScreen({super.key, this.food, this.template});

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

final class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _cookedCtrl = TextEditingController();

  /// Ingredient id → amount in the batch (raw grams), in insertion order.
  final Map<String, double> _amounts = {};

  /// Ingredient id → its row, so an archived part still renders.
  final Map<String, Ingredient> _parts = {};
  final Map<String, TextEditingController> _amountCtrls = {};

  String _filter = '';
  bool _saving = false;

  /// Whether the user has typed their own cooked weight; until then it
  /// follows the raw total.
  bool _cookedEdited = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = (widget.food ?? widget.template)?.name ?? '';
    unawaited(_load());
  }

  Future<void> _load() async {
    final food = widget.food ?? widget.template;
    if (food == null) return;
    final components = await ref
        .read(foodRepositoryProvider)
        .getComponents(food.id);
    // The list provider hides archived rows; fetch those directly so they are
    // not dropped on save.
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
        _amountCtrls[c.ingredientId] = TextEditingController(
          text: _formatAmount(c.amount),
        );
      }
      // A stored weight is authoritative; a new batch from a template never
      // inherits it (it is a different cook).
      final stored = _isEditing ? food.cookedWeight : null;
      _cookedEdited = stored != null;
      _cookedCtrl.text = _formatAmount(stored ?? _batchTotal);
    });
  }

  String _formatAmount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : formatDecimal(v);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    _cookedCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _parsedCooked {
    final parsed = double.tryParse(
      _cookedCtrl.text.trim().replaceAll(',', '.'),
    );
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _followRawTotal() {
    if (_cookedEdited) return;
    _cookedCtrl.text = _batchTotal > 0 ? _formatAmount(_batchTotal) : '';
  }

  FoodNutrition? get _preview => _amounts.isEmpty
      ? null
      : resolveFoodPer100g([
          for (final e in _amounts.entries)
            (
              caloriesPer100g: _parts[e.key]!.caloriesPer100g,
              proteinPer100g: _parts[e.key]!.proteinPer100g,
              carbsPer100g: _parts[e.key]!.carbsPer100g,
              fatPer100g: _parts[e.key]!.fatPer100g,
              sodiumPer100g: _parts[e.key]!.sodiumPer100g,
              fiberPer100g: _parts[e.key]!.fiberPer100g,
              sugarPer100g: _parts[e.key]!.sugarPer100g,
              amount: e.value,
            ),
        ], cookedWeight: _parsedCooked);

  double get _batchTotal => _amounts.values.fold(0.0, (a, b) => a + b);

  void _addPart(Ingredient i) {
    setState(() {
      _parts[i.id] = i;
      _amounts[i.id] = 100;
      _amountCtrls[i.id] = TextEditingController(text: '100');
      _followRawTotal();
      _searchCtrl.clear();
      _filter = '';
    });
  }

  void _removePart(String id) => setState(() {
    _amounts.remove(id);
    _parts.remove(id);
    _amountCtrls.remove(id)?.dispose();
    _followRawTotal();
  });

  Future<void> _duplicate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FoodFormScreen(template: widget.food)),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final food = widget.food!;
    final repo = ref.read(foodRepositoryProvider);
    final done = await confirmDelete(
      context,
      itemName: food.name,
      delete: () async {
        await repo.archive(food.id);
        invalidateFoods(ref);
      },
      undo: () async {
        await repo.restore(food.id);
        invalidateFoods(ref);
      },
      confirmLabel: l10n.commonDelete,
    );
    if (done && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final all = ref.watch(ingredientListProvider).value ?? const <Ingredient>[];
    final query = _filter.trim().toLowerCase();
    final candidates = query.isEmpty
        ? const <Ingredient>[]
        : [
            for (final i in all)
              if (!_amounts.containsKey(i.id) &&
                  i.name.toLowerCase().contains(query))
                i,
          ];

    // Raw totals over the parts.
    var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0;
    for (final e in _amounts.entries) {
      final i = _parts[e.key]!;
      kcal += i.caloriesPer100g * e.value / 100;
      p += i.proteinPer100g * e.value / 100;
      c += i.carbsPer100g * e.value / 100;
      f += i.fatPer100g * e.value / 100;
    }
    final per100 = _preview?.per100g;
    final success = theme.extension<FitFatColors>()?.success ?? scheme.primary;

    String n(double v) => nf.format(v.round());

    return FormScaffold(
      title: _isEditing ? l10n.foodFormEditTitle : l10n.foodFormNewTitle,
      formKey: _formKey,
      saving: _saving,
      onSave: _save,
      actions: [
        if (_isEditing)
          PopupMenuButton<VoidCallback>(
            onSelected: (fn) => fn(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _duplicate,
                child: Text(l10n.foodFormDuplicate),
              ),
            ],
          ),
      ],
      delete: _isEditing
          ? FormDeleteAction(
              label: l10n.recipeDelete,
              consequence: l10n.recipeDeleteConsequence,
              onDelete: _delete,
            )
          : null,
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
        const SizedBox(height: FitFatTokens.spaceM),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceM,
              FitFatTokens.spaceS,
              FitFatTokens.spaceM,
              FitFatTokens.spaceS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableRow(
                  header: true,
                  name: Text(l10n.recipeColIngredient.toUpperCase()),
                  grams: const Text('G'),
                  cells: const ['KCAL', 'P', 'C', 'F'],
                ),
                for (final id in _amounts.keys.toList())
                  Dismissible(
                    key: ValueKey('part-$id'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(
                        right: FitFatTokens.spaceM,
                      ),
                      color: scheme.errorContainer,
                      child: Icon(Icons.delete_outline, color: scheme.error),
                    ),
                    onDismissed: (_) => _removePart(id),
                    child: _TableRow(
                      divider: true,
                      name: Text(
                        _parts[id]!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      grams: TextField(
                        key: ValueKey('grams-$id'),
                        controller: _amountCtrls[id],
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                        ),
                        onChanged: (v) => setState(() {
                          _amounts[id] =
                              double.tryParse(v.replaceAll(',', '.')) ?? 0;
                          _followRawTotal();
                        }),
                      ),
                      cells: [
                        for (final per in [
                          _parts[id]!.caloriesPer100g,
                          _parts[id]!.proteinPer100g,
                          _parts[id]!.carbsPer100g,
                          _parts[id]!.fatPer100g,
                        ])
                          n(per * _amounts[id]! / 100),
                      ],
                    ),
                  ),
                _TableRow(
                  divider: true,
                  name: TextField(
                    key: const ValueKey('foodFormSearch'),
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      hintText: l10n.recipeTypeIngredient,
                      prefixIcon: const Icon(Icons.add, size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 24),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  span: true,
                ),
                _TableRow(
                  divider: true,
                  strong: true,
                  name: Text(l10n.recipeRaw),
                  grams: Text(n(_batchTotal), textAlign: TextAlign.right),
                  cells: [n(kcal), n(p), n(c), n(f)],
                ),
                _TableRow(
                  divider: true,
                  name: Text(l10n.recipeCookedWeight),
                  grams: TextFormField(
                    key: const ValueKey('foodFormCookedWeight'),
                    controller: _cookedCtrl,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );
                      return parsed == null || parsed <= 0
                          ? l10n.foodFormCookedWeightRequired
                          : null;
                    },
                    onChanged: (_) => setState(() => _cookedEdited = true),
                  ),
                  cells: [
                    if (_parsedCooked != null && _batchTotal > 0)
                      l10n.recipeYield(
                        (_parsedCooked! / _batchTotal * 100).round(),
                      ),
                  ],
                  cellsSpan: true,
                ),
                DefaultTextStyle.merge(
                  style: TextStyle(color: success, fontWeight: FontWeight.w600),
                  child: _TableRow(
                    divider: true,
                    name: Text(l10n.recipePer100),
                    cells: per100 == null
                        ? const ['–', '–', '–', '–']
                        : [
                            n(per100.calories),
                            n(per100.protein),
                            n(per100.carbs),
                            n(per100.fat),
                          ],
                  ),
                ),
                if (per100 != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: FitFatTokens.spaceXs,
                      bottom: FitFatTokens.spaceXs,
                    ),
                    child: MacroBar(MacroValues.of(per100)),
                  ),
              ],
            ),
          ),
        ),
        if (query.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: FitFatTokens.spaceS),
            child: candidates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(FitFatTokens.spaceM),
                    child: Text(
                      l10n.foodFormNoMatches,
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (final i in candidates.take(8))
                        ListTile(
                          key: ValueKey('candidate-${i.id}'),
                          dense: true,
                          title: Text(i.name),
                          subtitle: i.brand == null ? null : Text(i.brand!),
                          trailing: Text(
                            '${i.caloriesPer100g.round()} kcal/100 g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _addPart(i),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_amounts.isEmpty) {
      showTopBanner(context, message: l10n.foodFormNeedsParts);
      return;
    }
    // Amounts are the denominator: a zero or negative one makes the batch
    // unresolvable, so refuse rather than store a zero-calorie food.
    if (_amounts.values.any((v) => v <= 0)) {
      showTopBanner(context, message: l10n.foodFormAmountPositive);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(foodRepositoryProvider);
      final cookedWeight = _parsedCooked!;
      final food =
          widget.food?.copyWith(cookedWeight: cookedWeight) ??
          newFood(name: _nameCtrl.text.trim(), cookedWeight: cookedWeight);
      final components = [
        for (final e in _amounts.entries)
          FoodIngredient(
            foodId: food.id,
            ingredientId: e.key,
            ingredientName: _parts[e.key]!.name,
            amount: e.value,
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

/// One table row: name (flexible), grams (field or text) and four number
/// cells (kcal, P, C, F).
final class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.name,
    this.grams,
    this.cells = const [],
    this.header = false,
    this.strong = false,
    this.divider = false,
    this.span = false,
    this.cellsSpan = false,
  });

  final Widget name;
  final Widget? grams;
  final List<String> cells;
  final bool header;
  final bool strong;
  final bool divider;

  /// [name] takes the whole row.
  final bool span;

  /// The single cell takes the space of all four.
  final bool cellsSpan;

  static const _gramsW = 72.0;
  static const _kcalW = 44.0;
  static const _macroW = 30.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = header
        ? theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          )
        : theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: strong ? FontWeight.w700 : null,
          );
    final style = base?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget cell(String text, double w) => SizedBox(
      width: w,
      child: Text(text, textAlign: TextAlign.right, maxLines: 1),
    );
    return Container(
      decoration: BoxDecoration(
        border: divider
            ? Border(
                top: BorderSide(
                  color: strong ? scheme.onSurface : scheme.outlineVariant,
                  width: strong ? 1.2 : 1,
                ),
              )
            : null,
      ),
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: DefaultTextStyle.merge(
        style: style,
        child: Row(
          spacing: 6,
          children: [
            Expanded(child: name),
            if (!span) ...[
              SizedBox(width: _gramsW, child: grams ?? const SizedBox()),
              if (cellsSpan)
                SizedBox(
                  width: _kcalW + _macroW * 3 + 18,
                  child: Text(
                    cells.isEmpty ? '' : cells.first,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else ...[
                cell(cells.isNotEmpty ? cells[0] : '', _kcalW),
                for (var i = 1; i < 4; i++)
                  cell(cells.length > i ? cells[i] : '', _macroW),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
