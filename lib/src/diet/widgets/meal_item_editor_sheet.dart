import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/ui/tokens.dart';
import 'package:flutter/material.dart';

/// What the caller wants done with a meal food.
///
/// The sheet is shared by the meal list and the meal form. The two differ in
/// what they key an edit by — the list by `meal_foods` row id, the form by
/// food id, since a food can only appear once in a meal — so it is
/// deliberately id-agnostic and hands back a decision rather than performing
/// it. The list applies that decision to the database straight away; the form
/// applies it to its unsaved draft, leaving the existing Save to persist.
sealed class MealItemEditResult {
  const MealItemEditResult();
}

class MealItemAmountChanged extends MealItemEditResult {
  final double grams;
  const MealItemAmountChanged(this.grams);
}

class MealItemRemoved extends MealItemEditResult {
  const MealItemRemoved();
}

/// Edits one food already logged in a meal: its amount, or its removal.
///
/// The common correction is a single portion — "that was 80 g, not 800 g" —
/// so this is one step from a food row rather than a trip through the form
/// and then the picker to express it.
Future<MealItemEditResult?> showMealItemEditorSheet(
  BuildContext context, {
  required String foodName,
  required double currentGrams,
  required String currentSummary,
}) {
  return showModalBottomSheet<MealItemEditResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Lift the sheet above the keyboard so the amount field is not covered.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _MealItemEditor(
        foodName: foodName,
        currentGrams: currentGrams,
        currentSummary: currentSummary,
      ),
    ),
  );
}

final class _MealItemEditor extends StatefulWidget {
  final String foodName;
  final double currentGrams;
  final String currentSummary;

  const _MealItemEditor({
    required this.foodName,
    required this.currentGrams,
    required this.currentSummary,
  });

  @override
  State<_MealItemEditor> createState() => _MealItemEditorState();
}

final class _MealItemEditorState extends State<_MealItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.currentGrams.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop(MealItemAmountChanged(double.parse(_amountCtrl.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.foodName,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: FitFatTokens.spaceXs),
              Text(
                widget.currentSummary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceL),
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.mealItemEditorAmountLabel,
                  suffixText: l10n.mealFormGramsLabel,
                ),
                // Same rule the picker and the form apply: a logged portion has
                // to be a positive weight, so zero is a mistake rather than a
                // way of expressing "remove it".
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return l10n.foodFormAmountPositive;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: FitFatTokens.spaceL),
              FilledButton(onPressed: _submit, child: Text(l10n.commonSave)),
              const SizedBox(height: FitFatTokens.spaceS),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const MealItemRemoved()),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.commonRemove),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
