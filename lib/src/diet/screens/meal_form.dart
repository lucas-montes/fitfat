import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/ingredient.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_ingredient.dart';
import '../providers/ingredients.dart';
import '../providers/meals.dart';
import '../repositories/meal_repository.dart';

final class MealFormScreen extends ConsumerStatefulWidget {
  final MealEntry? meal;
  const MealFormScreen({super.key, this.meal});

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

final class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late DateTime _eatenAt;
  late TimeOfDay _eatenTime;
  bool _saving = false;

  /// Maps ingredient id → gram amount. A value > 0 means selected.
  late Map<String, double> _grams;

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameCtrl = TextEditingController(text: meal?.name ?? '');
    _eatenAt = meal?.eatenAt ?? DateTime.now();
    _eatenTime = TimeOfDay.fromDateTime(_eatenAt);
    _grams = {};
    if (meal != null) {
      for (final item in meal.items) {
        _grams[item.ingredientId] = item.grams;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Meal' : 'New Meal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                hintText: 'e.g. Breakfast',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Date & time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & Time'),
              subtitle: Text(
                '${_eatenAt.day.toString().padLeft(2, '0')}.'
                '${_eatenAt.month.toString().padLeft(2, '0')}.'
                '${_eatenAt.year}  '
                '${_eatenTime.hour.toString().padLeft(2, '0')}:'
                '${_eatenTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),

            // Ingredient selection
            Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            ingredientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading ingredients: $e'),
              data: (ingredients) => ingredients.isEmpty
                  ? const Text('No ingredients available. Add some first.')
                  : Column(
                      children: ingredients
                          .map(
                            (ing) => _IngredientRow(
                              ingredient: ing,
                              grams: _grams[ing.id] ?? 0,
                              onChanged: (g) => setState(() {
                                if (g > 0) {
                                  _grams[ing.id] = g;
                                } else {
                                  _grams.remove(ing.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
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

    final selected = _grams.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient with grams')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final name = _nameCtrl.text.trim();

      if (_isEditing) {
        // Rebuild items from scratch
        final items = selected
            .map((e) => _buildItem(widget.meal!.id, e.key, e.value))
            .toList();
        await repo.update(
          MealEntry(
            id: widget.meal!.id,
            name: name,
            eatenAt: _eatenAt,
            createdAt: widget.meal!.createdAt,
            items: items,
          ),
        );
      } else {
        final items = selected
            .map(
              (e) => _buildItem(
                '', // mealId will be assigned by newMeal
                e.key,
                e.value,
              ),
            )
            .toList();
        await repo.insert(newMeal(name: name, eatenAt: _eatenAt, items: items));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  MealIngredient _buildItem(String mealId, String ingredientId, double grams) {
    // Look up ingredient name/macros from the list
    // We cache it here; a cleaner approach would pass ingredient data through
    return MealIngredient(
      id: const Uuid().v7(),
      mealId: mealId,
      ingredientId: ingredientId,
      ingredientName: '', // filled in after save via getAll
      grams: grams,
      caloriesPer100g: 0,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
    );
  }
}

final class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;
  final double grams;
  final void Function(double) onChanged;

  const _IngredientRow({
    required this.ingredient,
    required this.grams,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = grams > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (v) => onChanged(v == true ? 100 : 0),
            ),
            // Name
            Expanded(
              child: Text(
                ingredient.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            // Grams input
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: isSelected ? grams.toStringAsFixed(0) : '',
                decoration: const InputDecoration(
                  labelText: 'g',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
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
