import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../../models/meal_entry.dart';
import '../../models/meal_ingredient.dart';
import '../../ui/date_formats.dart';
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
  late final TextEditingController _searchCtrl;
  late DateTime _eatenAt;
  late TimeOfDay _eatenTime;
  bool _saving = false;

  /// Current name filter for the ingredient picker (empty = show all).
  String _filter = '';

  /// Maps ingredient id → gram amount. A value > 0 means selected.
  late Map<String, double> _grams;

  bool get _isEditing => widget.meal != null;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameCtrl = TextEditingController(text: meal?.name ?? '');
    _searchCtrl = TextEditingController();
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
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ingredientsAsync = ref.watch(ingredientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.mealFormEditTitle : l10n.mealFormNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.mealFormNameLabel,
                hintText: l10n.mealFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.mealFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Date & time
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.mealFormDateTime),
              subtitle: Text(
                '${DateFormats.formatDate(context, _eatenAt)}  '
                '${DateFormats.formatTime(context, _eatenTime)}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),

            // Ingredient selection
            Text(
              l10n.mealFormIngredients,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            ingredientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                l10n.errorLoadingResource(l10n.mealFormIngredients, '$e'),
              ),
              data: (ingredients) {
                if (ingredients.isEmpty) {
                  return Text(l10n.mealFormNoIngredients);
                }
                final query = _filter.trim().toLowerCase();
                final visible = query.isEmpty
                    ? ingredients
                    : ingredients
                          .where(
                            (ing) => ing.name.toLowerCase().contains(query),
                          )
                          .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.commonSearch,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                    const SizedBox(height: 8),
                    ...visible.map(
                      (ing) => _IngredientRow(
                        ingredient: ing,
                        grams: _grams[ing.id] ?? 0,
                        l10n: l10n,
                        onChanged: (g) => setState(() {
                          if (g > 0) {
                            _grams[ing.id] = g;
                          } else {
                            _grams.remove(ing.id);
                          }
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.mealFormSaving : l10n.mealFormSave),
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
    final l10n = AppLocalizations.of(context)!;

    final selected = _grams.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.mealFormAddIngredient)));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final name = _nameCtrl.text.trim();

      if (_isEditing) {
        // Rebuild items from scratch, linked to the existing meal id.
        final items = selected
            .map((e) => _buildItem(e.key, e.value, mealId: widget.meal!.id))
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
        // New meal: newMeal() generates the meal id and stamps it onto
        // every item, so no placeholder mealId is needed here.
        final items = selected.map((e) => _buildItem(e.key, e.value)).toList();
        await repo.insert(newMeal(name: name, eatenAt: _eatenAt, items: items));
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.commonSaved)));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorWithMessage('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  MealIngredient _buildItem(
    String ingredientId,
    double grams, {
    String mealId = '',
  }) {
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
  final AppLocalizations l10n;
  final void Function(double) onChanged;

  const _IngredientRow({
    required this.ingredient,
    required this.grams,
    required this.l10n,
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
                decoration: InputDecoration(
                  labelText: l10n.mealFormGramsLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
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
