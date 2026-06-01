import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../../models/food.dart';
import '../../providers/ingredients.dart';
import '../../providers/meals.dart';
import '../ingredients/edit.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key, this.initialMeal});

  final MealEntry? initialMeal;

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _uuid = const Uuid();

  DateTime _eatenAt = DateTime.now();
  List<IngredientPortion> _items = [];

  @override
  void initState() {
    super.initState();
    final meal = widget.initialMeal;
    if (meal != null) {
      _nameController.text = meal.name ?? '';
      _eatenAt = meal.eatenAt;
      _items = List.of(meal.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableIngredients = ref.watch(ingredientsProvider);
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();
    final filteredIngredients = query.isEmpty
        ? <Ingredient>[]
        : availableIngredients
              .where(
                (ingredient) => ingredient.name.toLowerCase().contains(query),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMeal == null ? l10n.addMeal : l10n.editMeal),
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.icon(
                onPressed: _saveMeal,
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.mealNameOptional),
          ),
          const SizedBox(height: 12),
          _buildTimePicker(context, l10n),
          const SizedBox(height: 20),
          Text(
            l10n.selectedIngredients,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty) Text(l10n.noIngredientsSelected),
          for (final item in _items)
            Card(
              child: ListTile(
                title: Text(item.ingredient.name),
                subtitle: Text('${item.grams.toStringAsFixed(0)} g'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editItem(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeItem(item),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
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
            ..._buildResultsOrCustom(filteredIngredients, l10n)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.typeToSearchIngredient,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildTimePicker(BuildContext context, AppLocalizations l10n) {
    final formatted = DateFormat('MMM d, h:mm a').format(_eatenAt);

    return Row(
      children: [
        Expanded(child: Text(l10n.eatenAtLabel(formatted))),
        TextButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_eatenAt),
            );
            if (time == null) return;
            setState(() {
              _eatenAt = DateTime(
                _eatenAt.year,
                _eatenAt.month,
                _eatenAt.day,
                time.hour,
                time.minute,
              );
            });
          },
          child: Text(l10n.change),
        ),
      ],
    );
  }

  List<Widget> _buildResultsOrCustom(
    List<Ingredient> filtered,
    AppLocalizations l10n,
  ) {
    final widgets = <Widget>[];
    if (filtered.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(l10n.noIngredientsFound),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _addCustomIngredient,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.createNewIngredient),
              ),
            ],
          ),
        ),
      );
    } else {
      for (final ingredient in filtered) {
        widgets.add(
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
                onPressed: () => _promptAndAddIngredient(ingredient),
              ),
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TextButton.icon(
            onPressed: _addCustomIngredient,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.createNewIngredient),
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _promptAndAddIngredient(Ingredient ingredient) async {
    final grams = await _promptForGrams(context);
    if (grams == null) return;
    setState(() {
      _items = [
        ..._items,
        IngredientPortion(ingredient: ingredient, grams: grams),
      ];
    });
  }

  Future<void> _editItem(IngredientPortion item) async {
    final grams = await _promptForGrams(context, initialValue: item.grams);
    if (grams == null) return;
    setState(() {
      _items = [
        for (final existing in _items)
          if (existing == item)
            IngredientPortion(ingredient: item.ingredient, grams: grams)
          else
            existing,
      ];
    });
  }

  void _removeItem(IngredientPortion item) {
    setState(() {
      _items = _items.where((existing) => existing != item).toList();
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
          decoration: InputDecoration(hintText: l10n.gramsHintMeal),
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

    // Dispose the controller on the next frame to avoid disposing while the
    // dialog's TextField is still mounted (which can trigger
    // "_dependents.isEmpty" assertions).
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  Future<void> _addCustomIngredient() async {
    final ingredient = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const CustomIngredientScreen()),
    );
    if (!mounted) return;
    if (ingredient == null) return;

    final grams = await _promptForGrams(context);
    if (!mounted) return;
    if (grams == null) return;

    await ref.read(ingredientsProvider.notifier).addIngredient(ingredient);

    setState(() {
      _items = [
        ..._items,
        IngredientPortion(ingredient: ingredient, grams: grams),
      ];
    });
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    final meal = MealEntry(
      id: widget.initialMeal?.id ?? _uuid.v7(),
      name: name.isEmpty ? null : name,
      eatenAt: _eatenAt,
      items: _items,
    );

    final controller = ref.read(mealsProvider.notifier);
    if (widget.initialMeal == null) {
      try {
        await controller.addMeal(meal);
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToSave(e.toString()))),
          );
        }
        return;
      }
    } else {
      try {
        await controller.updateMeal(widget.initialMeal!.id, meal);
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToUpdate(e.toString()))),
          );
        }
        return;
      }
    }

    if (mounted) Navigator.of(context).pop();
  }
}
