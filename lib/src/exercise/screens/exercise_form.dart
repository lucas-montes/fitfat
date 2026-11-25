import 'package:material_ui/material_ui.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../providers/exercises.dart';
import '../repositories/exercise_repository.dart';

final class ExerciseFormScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;

  /// Optional prefill for a brand-new exercise (used by the workout form's
  /// "create" row so the typed search query becomes the exercise name).
  final String? initialName;
  const ExerciseFormScreen({super.key, this.exercise, this.initialName});

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

final class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _metCtrl;
  late String _exerciseType;
  bool _saving = false;

  bool get _isEditing => widget.exercise != null;

  /// Catalogue exercises carry a curated MET from the server, and a local edit
  /// would be overwritten by the next pull, so only the user's own exercises
  /// (which have no body part) can be rated here.
  bool get _canRate => widget.exercise?.bodyPart == null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(
      text: ex?.name ?? widget.initialName ?? '',
    );
    _exerciseType = ex?.exerciseType ?? 'weightlifting';
    _metCtrl = TextEditingController(text: _formatMet(ex?.met));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _metCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.exerciseFormEditTitle : l10n.exerciseFormNewTitle,
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
                labelText: l10n.exerciseFormNameLabel,
                hintText: l10n.exerciseFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.exerciseFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _exerciseType,
              decoration: InputDecoration(
                labelText: l10n.exerciseFormTypeLabel,
              ),
              items: [
                DropdownMenuItem(
                  value: 'weightlifting',
                  child: Text(l10n.exerciseTypeWeightlifting),
                ),
                DropdownMenuItem(
                  value: 'cardio',
                  child: Text(l10n.exerciseTypeCardio),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _exerciseType = v);
              },
            ),
            if (_canRate) ...[
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('exercise-met'),
                controller: _metCtrl,
                decoration: InputDecoration(
                  labelText: l10n.exerciseFormMetLabel,
                  helperText: l10n.exerciseFormMetHelper,
                  helperMaxLines: 3,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v ?? '').trim().isNotEmpty && parseMet(v!) == null
                    ? l10n.exerciseFormMetInvalid
                    : null,
              ),
              if (_exerciseType == 'cardio') ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final preset in _metPresets(l10n))
                      ActionChip(
                        label: Text('${preset.$1} · ${_formatMet(preset.$2)}'),
                        onPressed: () => setState(
                          () => _metCtrl.text = _formatMet(preset.$2),
                        ),
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? l10n.exerciseFormSaving : l10n.exerciseFormSave,
              ),
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
      final repo = ref.read(exerciseRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final met = parseMet(_metCtrl.text);

      if (_isEditing) {
        await repo.update(
          widget.exercise!.copyWith(
            name: name,
            exerciseType: _exerciseType,
            met: _canRate ? met : widget.exercise!.met,
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final created = newExercise(
          name: name,
          exerciseType: _exerciseType,
        ).copyWith(met: met);
        await repo.insert(created);
        if (mounted) Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _formatMet(double? met) {
  if (met == null) return '';
  return met == met.roundToDouble()
      ? met.toStringAsFixed(0)
      : met.toStringAsFixed(1);
}

/// Common activities that aren't in the catalogue, with their Compendium of
/// Physical Activities values, so a custom exercise can be rated in a tap.
List<(String, double)> _metPresets(AppLocalizations l10n) => [
  (l10n.metPresetSkating, 7.0), // Skating, roller (15590)
  (l10n.metPresetCycling, 7.5), // Bicycling, general (01015)
  (l10n.metPresetSwimming, 6.0), // Swimming, leisurely, general (18310)
  (l10n.metPresetHiking, 6.0), // Hiking, cross country (17080)
  (l10n.metPresetFootball, 7.0), // Soccer, casual, general (15610)
];

/// Parses a MET typed by the user: a decimal point or comma, 1–25 (resting
/// is 1; the Compendium tops out near 23). Empty or out of range is null.
double? parseMet(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value < 1 || value > 25) return null;
  return value;
}
