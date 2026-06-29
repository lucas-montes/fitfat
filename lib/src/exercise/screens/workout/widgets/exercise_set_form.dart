import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';

/// Compact inline add-set form for a given exercise.
///
/// Layout is a single horizontal row:
///   `[Reps] [Weight] [Add Set]` for weightlifting
///   `[Duration] [Add Set]` for cardio
///
/// Notes field is below, hidden by default — tap "Add notes" to reveal.
///
/// The form is empty by default. The user can tap an existing set tile to
/// copy its values into these fields via the parent's controllers.
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Input row: fields + inline Add button ──
            Row(
              children: [
                if (isWeight) ...[
                  Expanded(
                    child: TextField(
                      controller: widget.repsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.reps,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: widget.weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.weightKg,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: TextField(
                      controller: widget.durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (min)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: widget.onAddSet,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Collapsible notes field ──
            if (_notesExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: widget.notesController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: l10n.quickLogNotes,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              )
            else
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
          ],
        ),
      ),
    );
  }
}
