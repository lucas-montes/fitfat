import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/workout_list.dart';
import '../../../models/workout.dart';
import 'multi_select_exercise_sheet.dart';

/// Minimal screen to create a planned/scheduled workout.
///
/// The user provides:
/// - Workout name
/// - Scheduled date (via date picker)
/// - Exercise selection (via multi-select bottom sheet)
/// - Planned sets per exercise (reps/weight for weightlifting, duration for cardio)
///
/// On "Create", builds `WeightSet`/`CardioSet` objects and delegates to
/// [WorkoutListNotifier.create()].
class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  ConsumerState<CreateWorkoutScreen> createState() =>
      _CreateWorkoutScreenState();
}

/// Holds data for one planned set during creation.
class _SetFormData {
  final int reps;
  final double weightKg;
  final int durationMinutes;

  const _SetFormData.weight({this.reps = 10, this.weightKg = 20})
    : durationMinutes = 0;
  const _SetFormData.cardio({this.durationMinutes = 10})
    : reps = 0,
      weightKg = 0;
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  final _nameCtl = TextEditingController();
  DateTime? _scheduledDate;
  List<ExerciseDefinition> _selectedExercises = [];

  /// Per-exercise set data. Key = exercise ID.
  final Map<String, List<_SetFormData>> _setsByExercise = {};

  bool _creating = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  /// Open the multi-select exercise sheet.
  Future<void> _pickExercises() async {
    final exercises = await showModalBottomSheet<List<ExerciseDefinition>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiSelectExerciseSheet(
        initialSelection: _selectedExercises.map((e) => e.id).toSet(),
      ),
    );
    if (exercises != null && mounted) {
      setState(() {
        _selectedExercises = exercises;
        // Ensure each new exercise has at least one default set
        for (final ex in exercises) {
          _setsByExercise.putIfAbsent(ex.id, () {
            if (ex.type == ExerciseType.weightlifting) {
              return [const _SetFormData.weight()];
            } else {
              return [const _SetFormData.cardio()];
            }
          });
        }
        // Remove sets for exercises that were deselected
        final selectedIds = exercises.map((e) => e.id).toSet();
        _setsByExercise.removeWhere((id, _) => !selectedIds.contains(id));
      });
    }
  }

  /// Add another set row for a given exercise.
  void _addSet(String exerciseId, ExerciseType type) {
    setState(() {
      _setsByExercise[exerciseId]!.add(
        type == ExerciseType.weightlifting
            ? const _SetFormData.weight()
            : const _SetFormData.cardio(),
      );
    });
  }

  /// Remove a set row by index for a given exercise.
  void _removeSet(String exerciseId, int index) {
    setState(() {
      _setsByExercise[exerciseId]!.removeAt(index);
    });
  }

  /// Build [WeightSet] and [CardioSet] lists from form data, then create.
  Future<void> _create() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    final date = _scheduledDate;
    if (date == null) return;

    setState(() => _creating = true);

    final weightSets = <WeightSet>[];
    final cardioSets = <CardioSet>[];
    final now = DateTime.now();

    for (final exercise in _selectedExercises) {
      final sets = _setsByExercise[exercise.id] ?? [];
      for (int i = 0; i < sets.length; i++) {
        final s = sets[i];
        if (exercise.type == ExerciseType.weightlifting) {
          weightSets.add(
            WeightSet(
              id: 'ws_${now.millisecondsSinceEpoch}_${exercise.id}_$i',
              workoutId: '', // filled by repository
              exerciseId: exercise.id,
              sortOrder: i,
              plannedReps: s.reps,
              plannedWeightKg: s.weightKg,
            ),
          );
        } else {
          cardioSets.add(
            CardioSet(
              id: 'cs_${now.millisecondsSinceEpoch}_${exercise.id}_$i',
              workoutId: '', // filled by repository
              exerciseId: exercise.id,
              sortOrder: i,
              plannedDurationMinutes: s.durationMinutes,
            ),
          );
        }
      }
    }

    try {
      await ref
          .read(workoutListProvider.notifier)
          .create(name, weightSets, cardioSets, scheduledDate: date);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create workout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Schedule Workout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Workout name ──
          TextField(
            controller: _nameCtl,
            decoration: InputDecoration(
              labelText: l10n.workoutName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Scheduled date ──
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              _scheduledDate != null
                  ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                  : l10n.date,
            ),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _scheduledDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                setState(() => _scheduledDate = date);
              }
            },
          ),
          const SizedBox(height: 16),

          // ── Add Exercises button ──
          OutlinedButton.icon(
            onPressed: _pickExercises,
            icon: const Icon(Icons.add),
            label: Text(l10n.addExercise),
          ),
          const SizedBox(height: 16),

          // ── Selected exercises with set configuration ──
          if (_selectedExercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noExercisesAdded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._selectedExercises.map(
              (ex) => _buildExerciseCard(ex, l10n, theme),
            ),

          const SizedBox(height: 24),

          // ── Create button ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _creating ? null : _create,
              child: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.create),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    ExerciseDefinition exercise,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isWeightlifting = exercise.type == ExerciseType.weightlifting;
    final sets = _setsByExercise[exercise.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Icon(
                  isWeightlifting ? Icons.fitness_center : Icons.directions_run,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.localizedName ?? exercise.name,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Set rows
            ...sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(
                      '${l10n.set} ${index + 1}:',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    if (isWeightlifting) ...[
                      _CompactField(
                        initialValue: set.reps.toString(),
                        label: l10n.repsLower,
                        onChanged: (v) {
                          final reps = int.tryParse(v);
                          if (reps != null && reps > 0) {
                            _setsByExercise[exercise.id]![index] =
                                _SetFormData.weight(
                                  reps: reps,
                                  weightKg: set.weightKg,
                                );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _CompactField(
                        initialValue: set.weightKg.toString(),
                        label: l10n.weightKg,
                        onChanged: (v) {
                          final w = double.tryParse(v);
                          if (w != null && w >= 0) {
                            _setsByExercise[exercise.id]![index] =
                                _SetFormData.weight(
                                  reps: set.reps,
                                  weightKg: w,
                                );
                          }
                        },
                      ),
                    ] else ...[
                      _CompactField(
                        initialValue: set.durationMinutes.toString(),
                        label: 'min',
                        onChanged: (v) {
                          final dur = int.tryParse(v);
                          if (dur != null && dur > 0) {
                            _setsByExercise[exercise.id]![index] =
                                _SetFormData.cardio(durationMinutes: dur);
                          }
                        },
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: theme.colorScheme.error,
                      onPressed: sets.length > 1
                          ? () => _removeSet(exercise.id, index)
                          : null,
                    ),
                  ],
                ),
              );
            }),

            // Add Set button
            TextButton.icon(
              onPressed: () => _addSet(exercise.id, exercise.type),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.addSet),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact text field for entering small numeric values inline.
class _CompactField extends StatelessWidget {
  final String initialValue;
  final String label;
  final ValueChanged<String> onChanged;

  const _CompactField({
    required this.initialValue,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: TextEditingController(text: initialValue),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          border: const OutlineInputBorder(),
        ),
        style: const TextStyle(fontSize: 12),
        onChanged: onChanged,
      ),
    );
  }
}
