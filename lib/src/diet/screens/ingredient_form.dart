import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ingredient.dart';
import '../providers/ingredients.dart';
import '../repositories/ingredient_repository.dart';

final class IngredientFormScreen extends ConsumerStatefulWidget {
  final Ingredient? ingredient;
  const IngredientFormScreen({super.key, this.ingredient});

  @override
  ConsumerState<IngredientFormScreen> createState() =>
      _IngredientFormScreenState();
}

final class _IngredientFormScreenState
    extends ConsumerState<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _caloriesCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;
  bool _saving = false;

  bool get _isEditing => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _nameCtrl = TextEditingController(text: ing?.name ?? '');
    _caloriesCtrl = TextEditingController(
      text: ing?.caloriesPer100g.toStringAsFixed(1) ?? '',
    );
    _proteinCtrl = TextEditingController(
      text: ing?.proteinPer100g.toStringAsFixed(1) ?? '',
    );
    _carbsCtrl = TextEditingController(
      text: ing?.carbsPer100g.toStringAsFixed(1) ?? '',
    );
    _fatCtrl = TextEditingController(
      text: ing?.fatPer100g.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Ingredient' : 'New Ingredient'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Chicken Breast',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesCtrl,
              decoration: const InputDecoration(
                labelText: 'Calories (per 100g)',
                suffixText: 'kcal',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validatePositive(v, 'Calories'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinCtrl,
              decoration: const InputDecoration(
                labelText: 'Protein (per 100g)',
                suffixText: 'g',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateNonNegative(v, 'Protein'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carbsCtrl,
              decoration: const InputDecoration(
                labelText: 'Carbs (per 100g)',
                suffixText: 'g',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateNonNegative(v, 'Carbs'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fatCtrl,
              decoration: const InputDecoration(
                labelText: 'Fat (per 100g)',
                suffixText: 'g',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateNonNegative(v, 'Fat'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final calories = double.parse(_caloriesCtrl.text);
      final protein = double.parse(_proteinCtrl.text);
      final carbs = double.parse(_carbsCtrl.text);
      final fat = double.parse(_fatCtrl.text);

      final repo = ref.read(ingredientRepositoryProvider);

      if (_isEditing) {
        await repo.update(
          widget.ingredient!.copyWith(
            name: name,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
          ),
        );
      } else {
        await repo.insert(
          newIngredient(
            name: name,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
          ),
        );
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

  String? _validatePositive(String? v, String label) {
    if (v == null || v.isEmpty) return '$label is required';
    final value = double.tryParse(v);
    if (value == null || value <= 0) return '$label must be positive';
    return null;
  }

  String? _validateNonNegative(String? v, String label) {
    if (v == null || v.isEmpty) return '$label is required';
    final value = double.tryParse(v);
    if (value == null || value < 0) return '$label cannot be negative';
    return null;
  }
}
