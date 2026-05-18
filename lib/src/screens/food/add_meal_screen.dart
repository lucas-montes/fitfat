import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/food_models.dart';
import '../../providers/food_providers.dart';
import 'custom_ingredient_screen.dart';

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
    final ingredients = ref.watch(ingredientListProvider);
    final filteredIngredients = ingredients.where((ingredient) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return ingredient.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMeal == null ? 'Add Meal' : 'Edit Meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Meal name (optional)',
            ),
          ),
          const SizedBox(height: 12),
          _buildTimePicker(context),
          const SizedBox(height: 20),
          Text(
            'Selected ingredients',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Text('No ingredients selected yet'),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _addCustomIngredient,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Custom ingredient'),
              ),
            ],
          ),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search ingredients',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          for (final ingredient in filteredIngredients)
            Card(
              child: ListTile(
                title: Text(ingredient.name),
                subtitle: Text(
                  '${ingredient.caloriesPer100g.toStringAsFixed(0)} kcal · '
                  'P ${ingredient.proteinPer100g.toStringAsFixed(1)}g · '
                  'C ${ingredient.carbsPer100g.toStringAsFixed(1)}g · '
                  'F ${ingredient.fatPer100g.toStringAsFixed(1)}g',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _promptAndAddIngredient(ingredient),
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _items.isEmpty ? null : _saveMeal,
            child: Text(widget.initialMeal == null ? 'Save meal' : 'Update meal'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    final formatted = DateFormat('MMM d, h:mm a').format(_eatenAt);

    return Row(
      children: [
        Expanded(child: Text('Eaten at: $formatted')),
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
          child: const Text('Change'),
        ),
      ],
    );
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

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Amount in grams'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g. 120'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value == null || value <= 0) return;
              Navigator.of(context).pop(value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _addCustomIngredient() async {
    final ingredient = await Navigator.of(context).push<Ingredient>(
      MaterialPageRoute(builder: (_) => const CustomIngredientScreen()),
    );
    if (!mounted) return;
    if (ingredient == null) return;

    ref.read(ingredientListProvider.notifier).addIngredient(ingredient);

    final grams = await _promptForGrams(context);
    if (!mounted) return;
    if (grams == null) return;
    setState(() {
      _items = [
        ..._items,
        IngredientPortion(ingredient: ingredient, grams: grams),
      ];
    });
  }

  void _saveMeal() {
    final name = _nameController.text.trim();
    final meal = MealEntry(
      id: widget.initialMeal?.id ?? _uuid.v4(),
      name: name.isEmpty ? null : name,
      eatenAt: _eatenAt,
      items: _items,
    );

    final notifier = ref.read(mealLogProvider.notifier);
    if (widget.initialMeal == null) {
      notifier.addMeal(meal);
    } else {
      notifier.updateMeal(meal);
    }

    Navigator.of(context).pop();
  }
}
