import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../../models/food.dart';
import '../../providers/ingredients.dart';

class CustomIngredientScreen extends ConsumerStatefulWidget {
  const CustomIngredientScreen({super.key, this.initialIngredient});

  final Ingredient? initialIngredient;

  @override
  ConsumerState<CustomIngredientScreen> createState() =>
      _CustomIngredientScreenState();
}

class _CustomIngredientScreenState
    extends ConsumerState<CustomIngredientScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _fiberController = TextEditingController();
  final _uuid = const Uuid();

  bool _buildFromIngredients = true;
  List<IngredientPortion> _components = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIngredient;
    if (initial == null) return;
    _nameController.text = initial.name;
    _buildFromIngredients = initial.isComposite;
    if (_buildFromIngredients) {
      _components = List.from(initial.components);
    } else {
      _caloriesController.text = initial.caloriesPer100g.toString();
      _proteinController.text = initial.proteinPer100g.toString();
      _carbsController.text = initial.carbsPer100g.toString();
      _fatController.text = initial.fatPer100g.toString();
      if (initial.sodiumPer100g != null) {
        _sodiumController.text = initial.sodiumPer100g.toString();
      }
      if (initial.fiberPer100g != null) {
        _fiberController.text = initial.fiberPer100g.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sodiumController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientsProvider);
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();
    final per100g = _buildFromIngredients
        ? _computePer100g(_components)
        : _parseManualMacros();
    final filteredIngredients = query.isEmpty
        ? <Ingredient>[]
        : ingredients
              .where(
                (ingredient) => ingredient.name.toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialIngredient == null
              ? l10n.addIngredient
              : l10n.editIngredient,
        ),
        actions: [
          if (widget.initialIngredient != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.icon(
                onPressed: () async {
                  final ingredient = widget.initialIngredient;
                  if (ingredient == null) return;
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.archiveIngredientTitle),
                      content: Text(l10n.archiveIngredientContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.archive),
                        ),
                      ],
                    ),
                  );
                  if (result == true && context.mounted) {
                    await ref
                        .read(ingredientsProvider.notifier)
                        .archiveIngredient(ingredient);
                    Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.ingredientArchived)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.archive),
                label: Text(l10n.archive),
              ),
            ),
          if (_canSave(per100g))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.icon(
                onPressed: () => _save(per100g),
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Macro preview at top
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.formatPer100g(
                per100g.calories,
                per100g.protein,
                per100g.carbs,
                per100g.fat,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.ingredientName),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _buildFromIngredients,
            onChanged: (value) => setState(() => _buildFromIngredients = value),
            title: Text(l10n.buildFromIngredients),
          ),
          const SizedBox(height: 12),
          if (_buildFromIngredients) ...[
            Text(
              l10n.components,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_components.isEmpty) Text(l10n.noComponentsAdded),
            for (final component in _components)
              Card(
                child: ListTile(
                  title: Text(component.ingredient.name),
                  subtitle: Text('${component.grams.toStringAsFixed(0)} g'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editComponent(component),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeComponent(component),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.addComponents,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchIngredients,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _searchController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (query.isNotEmpty)
              ..._buildComponentResults(filteredIngredients, l10n)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.typeToSearchIngredient,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ] else ...[
            _buildManualField(_caloriesController, l10n.caloriesPer100g),
            _buildManualField(_proteinController, l10n.proteinPer100g),
            _buildManualField(_carbsController, l10n.carbsPer100g),
            _buildManualField(_fatController, l10n.fatPer100g),
            _buildManualField(_sodiumController, l10n.sodiumPer100g),
            _buildManualField(_fiberController, l10n.fiberPer100g),
          ],
        ],
      ),
      floatingActionButton: null,
    );
  }

  List<Widget> _buildComponentResults(
    List<Ingredient> ingredients,
    AppLocalizations l10n,
  ) {
    return [
      for (final ingredient in ingredients)
        Card(
          child: ListTile(
            title: Text(ingredient.name),
            subtitle: Text(
              '${ingredient.caloriesPer100g.toStringAsFixed(0)} ${l10n.kcalAbbrev} · '
              '${l10n.proteinAbbrev} ${ingredient.proteinPer100g.toStringAsFixed(1)}g · '
              '${l10n.carbsAbbrev} ${ingredient.carbsPer100g.toStringAsFixed(1)}g · '
              '${l10n.fatAbbrev} ${ingredient.fatPer100g.toStringAsFixed(1)}g',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addComponent(ingredient),
            ),
          ),
        ),
    ];
  }

  Widget _buildManualField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  MacroNutrients _computePer100g(List<IngredientPortion> components) {
    if (components.isEmpty) {
      return MacroNutrients.zero;
    }
    final totals = components.fold(
      MacroNutrients.zero,
      (sum, portion) => sum + portion.macros,
    );
    final totalGrams = components.fold(
      0.0,
      (sum, portion) => sum + portion.grams,
    );
    if (totalGrams == 0) return MacroNutrients.zero;
    return totals.scale(100.0 / totalGrams);
  }

  MacroNutrients _parseManualMacros() {
    double parse(TextEditingController controller) {
      return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
    }

    return MacroNutrients(
      calories: parse(_caloriesController),
      protein: parse(_proteinController),
      carbs: parse(_carbsController),
      fat: parse(_fatController),
    );
  }

  bool _canSave(MacroNutrients per100g) {
    if (_nameController.text.trim().isEmpty) return false;
    if (_buildFromIngredients) {
      return _components.isNotEmpty;
    }
    return per100g.calories > 0 ||
        per100g.protein > 0 ||
        per100g.carbs > 0 ||
        per100g.fat > 0;
  }

  Future<void> _addComponent(Ingredient ingredient) async {
    final grams = await _promptForGrams(context);
    if (grams == null) return;
    setState(() {
      _components = [
        ..._components,
        IngredientPortion(ingredient: ingredient, grams: grams),
      ];
    });
  }

  Future<void> _editComponent(IngredientPortion component) async {
    final grams = await _promptForGrams(context, initialValue: component.grams);
    if (grams == null) return;
    setState(() {
      _components = [
        for (final existing in _components)
          if (existing == component)
            IngredientPortion(ingredient: component.ingredient, grams: grams)
          else
            existing,
      ];
    });
  }

  void _removeComponent(IngredientPortion component) {
    setState(() {
      _components = _components
          .where((existing) => existing != component)
          .toList();
    });
  }

  Future<double?> _promptForGrams(
    BuildContext context, {
    double? initialValue,
  }) async {
    final controller = TextEditingController(
      text: initialValue?.toStringAsFixed(0) ?? '',
    );

    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.amountInGrams),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: l10n.gramsHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (value == null || value <= 0) return;
              Navigator.of(context).pop(value);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );

    // Dispose after the dialog is fully torn down to avoid disposing the
    // controller while the dialog's TextField is still attached.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  void _save(MacroNutrients per100g) {
    final name = _nameController.text.trim();

    Ingredient ingredient;
    if (_buildFromIngredients) {
      ingredient = Ingredient.fromComponents(
        id: widget.initialIngredient?.id ?? _uuid.v7(),
        name: name,
        components: _components,
      );
    } else {
      double? parseOptional(TextEditingController c) {
        final v = double.tryParse(c.text.replaceAll(',', '.'));
        return v != null && v > 0 ? v : null;
      }

      ingredient = Ingredient(
        id: widget.initialIngredient?.id ?? _uuid.v7(),
        name: name,
        caloriesPer100g: per100g.calories,
        proteinPer100g: per100g.protein,
        carbsPer100g: per100g.carbs,
        fatPer100g: per100g.fat,
        sodiumPer100g: parseOptional(_sodiumController),
        fiberPer100g: parseOptional(_fiberController),
      );
    }

    Navigator.of(context).pop(ingredient);
  }
}
