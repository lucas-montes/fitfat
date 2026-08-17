import 'package:flutter/material.dart';
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
  late String _exerciseType;
  bool _saving = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(
      text: ex?.name ?? widget.initialName ?? '',
    );
    _exerciseType = ex?.exerciseType ?? 'weightlifting';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

      if (_isEditing) {
        await repo.update(
          widget.exercise!.copyWith(name: name, exerciseType: _exerciseType),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final created = newExercise(name: name, exerciseType: _exerciseType);
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
