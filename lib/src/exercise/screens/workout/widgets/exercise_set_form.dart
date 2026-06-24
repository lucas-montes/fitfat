import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';

/// Inline add-set form for a given exercise.
///
/// Shows:
/// - Reps + Weight fields for weightlifting exercises
/// - Duration field for cardio exercises
/// - Optional notes field (always shown)
/// - "Add Set" button at the bottom
///
/// The form is empty by default — no pre-populated values. The user can
/// tap an existing set tile to copy its values into these fields.
class ExerciseSetForm extends StatelessWidget {
  final ExerciseDefinition exercise;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final VoidCallback onAddSet;

  const ExerciseSetForm({
    super.key,
    required this.exercise,
    required this.repsController,
    required this.weightController,
    required this.durationController,
    required this.notesController,
    required this.onAddSet,
  });

  @override
  Widget build(BuildContext context) {
    final isWeight = exercise.type == ExerciseType.weightlifting;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addSet, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (isWeight) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAddSet,
                child: Text(l10n.addSet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
