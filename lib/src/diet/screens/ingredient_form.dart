import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
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
  late final TextEditingController _sodiumCtrl;
  late final TextEditingController _fiberCtrl;
  late final TextEditingController _sugarCtrl;
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
    _sodiumCtrl = TextEditingController(
      text: ing?.sodiumPer100g?.toStringAsFixed(1) ?? '',
    );
    _fiberCtrl = TextEditingController(
      text: ing?.fiberPer100g?.toStringAsFixed(1) ?? '',
    );
    _sugarCtrl = TextEditingController(
      text: ing?.sugarPer100g?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _sodiumCtrl.dispose();
    _fiberCtrl.dispose();
    _sugarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.ingredientFormEditTitle
              : l10n.ingredientFormNewTitle,
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
                labelText: l10n.ingredientFormNameLabel,
                hintText: l10n.ingredientFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.ingredientFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormCaloriesLabel,
                suffixText: l10n.ingredientFormCaloriesSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validatePositive(v, l10n.ingredientFormCaloriesLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _proteinCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormProteinLabel,
                suffixText: l10n.ingredientFormProteinSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateNonNegative(
                v,
                l10n.ingredientFormProteinLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _carbsCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormCarbsLabel,
                suffixText: l10n.ingredientFormCarbsSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validateNonNegative(v, l10n.ingredientFormCarbsLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fatCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormFatLabel,
                suffixText: l10n.ingredientFormFatSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) =>
                  _validateNonNegative(v, l10n.ingredientFormFatLabel, l10n),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sodiumCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormSodiumLabel,
                suffixText: l10n.ingredientFormSodiumSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormSodiumLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fiberCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormFiberLabel,
                suffixText: l10n.ingredientFormFiberSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormFiberLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sugarCtrl,
              decoration: InputDecoration(
                labelText: l10n.ingredientFormSugarLabel,
                suffixText: l10n.ingredientFormSugarSuffix,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]+')),
              ],
              validator: (v) => _validateOptionalNonNegative(
                v,
                l10n.ingredientFormSugarLabel,
                l10n,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
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
      final sodium = _parseOptional(_sodiumCtrl.text);
      final fiber = _parseOptional(_fiberCtrl.text);
      final sugar = _parseOptional(_sugarCtrl.text);

      final repo = ref.read(ingredientRepositoryProvider);

      if (_isEditing) {
        await repo.update(
          widget.ingredient!.copyWith(
            name: name,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            sodiumPer100g: sodium,
            fiberPer100g: fiber,
            sugarPer100g: sugar,
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
            sodiumPer100g: sodium,
            fiberPer100g: fiber,
            sugarPer100g: sugar,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validatePositive(String? v, String label, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.ingredientFormFieldRequired(label);
    final value = double.tryParse(v);
    if (value == null || value <= 0) {
      return l10n.ingredientFormFieldPositive(label);
    }
    return null;
  }

  String? _validateNonNegative(String? v, String label, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.ingredientFormFieldRequired(label);
    final value = double.tryParse(v);
    if (value == null || value < 0) {
      return l10n.ingredientFormFieldNonNegative(label);
    }
    return null;
  }

  /// Validates an optional numeric field: blank is allowed, non-blank must
  /// parse to a non-negative number.
  String? _validateOptionalNonNegative(
    String? v,
    String label,
    AppLocalizations l10n,
  ) {
    if (v == null || v.trim().isEmpty) return null;
    final value = double.tryParse(v);
    if (value == null || value < 0) {
      return l10n.ingredientFormFieldNonNegative(label);
    }
    return null;
  }

  /// Parses an optional numeric input; blank/whitespace maps to null.
  double? _parseOptional(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.parse(trimmed);
  }
}
