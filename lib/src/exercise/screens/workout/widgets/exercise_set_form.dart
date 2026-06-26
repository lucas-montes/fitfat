import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';

/// Inline add-set form for a given exercise.
///
/// Shows:
/// - Reps + Weight fields for weightlifting exercises
/// - Duration field for cardio exercises
/// - Optional notes field (collapsible — hidden by default, expand on tap)
/// - "Add Set" button at the bottom
///
/// The form is empty by default — no pre-populated values. The user can
/// tap an existing set tile to copy its values into these fields.
class ExerciseSetForm extends StatefulWidget {
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
  State<ExerciseSetForm> createState() => _ExerciseSetFormState();
}

class _ExerciseSetFormState extends State<ExerciseSetForm> {
  bool _notesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isWeight = widget.exercise.type == ExerciseType.weightlifting;
    final l10n = AppLocalizations.of(context)!;
    final notes = widget.notesController.text;
    final hasNotes = notes.isNotEmpty;

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
                      controller: widget.repsController,
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
                      controller: widget.weightController,
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
                controller: widget.durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),

            // ── Collapsible notes field ──
            if (_notesExpanded) ...[
              TextField(
                controller: widget.notesController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ] else
              InkWell(
                onTap: () => setState(() => _notesExpanded = true),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasNotes ? Icons.notes : Icons.note_add,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasNotes
                            ? 'Notes: ${notes.length > 20 ? '${notes.substring(0, 20)}…' : notes}'
                            : 'Add notes',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // ── Add Set button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onAddSet,
                child: Text(l10n.addSet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
