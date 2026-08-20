import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/workout_exercise.dart';
import '../../ui/date_formats.dart';
import '../../ui/tokens.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../../dashboard/providers/dashboard.dart';
import '../repositories/workout_repository.dart';
import 'exercise_picker_sheet.dart';

/// A planned set entry used in the form before saving.
/// Null fields = unset; the form starts with an empty entry and each field
/// stores `null` until the user types a value.
final class _PlannedSetEntry {
  int? reps;
  double? weightKg;
  int? durationMinutes;
  int? restSeconds;
}

final class WorkoutFormScreen extends ConsumerStatefulWidget {
  /// When null the form creates a new workout; when set it edits that workout
  /// (only ever a pending, not-yet-started one).
  final WorkoutWithDetails? initial;
  const WorkoutFormScreen({super.key, this.initial});

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

final class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late DateTime _date;
  bool _saving = false;

  /// Selected exercise ids → planned set configs. Order is preserved (Dart
  /// Maps keep insertion order) and is user-reorderable via the drag handle.
  Map<String, List<_PlannedSetEntry>> _selected = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    final initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.workout.name;
      _date = initial.workout.date;
      for (final block in initial.exercises) {
        _selected[block.exercise.exerciseId] = [
          for (final set in block.sets)
            _PlannedSetEntry()
              ..reps = set.reps
              ..weightKg = set.weightKg
              ..durationMinutes = set.durationMinutes
              ..restSeconds = set.restSeconds,
        ];
      }
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial != null
              ? l10n.workoutFormEditTitle
              : l10n.workoutFormTitle,
        ),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? l10n.workoutFormSaving : l10n.workoutFormSave,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.workoutFormNameLabel,
                hintText: l10n.workoutFormNameHint,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.workoutFormNameRequired
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.workoutFormDate),
              subtitle: Text(DateFormats.formatDate(context, _date)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.workoutFormExercises,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _openExercisePicker,
              icon: const Icon(Icons.add),
              label: Text(l10n.workoutFormAddExercise),
            ),
            const SizedBox(height: 8),
            exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (exercises) {
                if (exercises.isEmpty && _selected.isEmpty) {
                  return Text(l10n.workoutFormNoExercises);
                }
                final byId = {for (final ex in exercises) ex.id: ex};
                final ordered = _selected.entries
                    .where((e) => byId[e.key] != null)
                    .toList();
                if (ordered.isEmpty) {
                  return Text(l10n.workoutFormNoExercises);
                }
                return ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: _reorderExercises,
                  children: [
                    for (var i = 0; i < ordered.length; i++)
                      _buildSelectedExerciseRow(
                        ordered[i].key,
                        byId[ordered[i].key]!,
                        ordered[i].value,
                        i,
                        l10n,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      final ids = _selected.keys.toList();
      if (oldIndex < newIndex) newIndex -= 1;
      final moved = ids.removeAt(oldIndex);
      ids.insert(newIndex, moved);
      _selected = {for (final id in ids) id: _selected[id]!};
    });
  }

  /// Reorders the planned sets within an exercise (drag the set chip handle).
  void _reorderSets(String exerciseId, int oldIndex, int newIndex) {
    setState(() {
      final sets = _selected[exerciseId]!;
      if (oldIndex < newIndex) newIndex -= 1;
      final moved = sets.removeAt(oldIndex);
      sets.insert(newIndex, moved);
    });
  }

  Future<void> _openExercisePicker() async {
    final picked = await showExercisePickerSheet(
      context,
      initialSelected: {..._selected.keys},
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Drop exercises the user deselected; keep existing sets for ones that
      // remain; add empty set lists for newly chosen exercises.
      _selected.removeWhere((id, _) => !picked.contains(id));
      for (final id in picked) {
        _selected.putIfAbsent(id, () => []);
      }
    });
  }

  /// One chosen exercise: drag handle, name, remove action, per-set editors,
  /// and an "Add set" button. [exerciseId] + [index] power the reorder handle.
  Widget _buildSelectedExerciseRow(
    String exerciseId,
    Exercise ex,
    List<_PlannedSetEntry> sets,
    int index,
    AppLocalizations l10n,
  ) {
    return Card(
      key: Key(exerciseId),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, size: 20),
                ),
                Icon(
                  ex.isWeightlifting
                      ? Icons.fitness_center
                      : Icons.directions_run,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.workoutFormRemoveExercise,
                  onPressed: () => setState(() => _selected.remove(ex.id)),
                ),
              ],
            ),
            const Divider(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) =>
                  _reorderSets(ex.id, oldIndex, newIndex),
              children: [
                for (var i = 0; i < sets.length; i++)
                  _buildSetRow(i, sets[i], sets, ex, l10n),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.workoutFormAddSet),
              onPressed: () => setState(() {
                _selected[ex.id]!.add(_PlannedSetEntry());
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    int index,
    _PlannedSetEntry entry,
    List<_PlannedSetEntry> sets,
    Exercise ex,
    AppLocalizations l10n,
  ) {
    return Container(
      key: ObjectKey(entry),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          if (ex.isWeightlifting) ...[
            Expanded(
              child: TextFormField(
                initialValue: entry.weightKg?.toStringAsFixed(0) ?? '',
                decoration: InputDecoration(
                  labelText: l10n.workoutFormWeightLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.weightKg = double.tryParse(v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: entry.reps?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: l10n.workoutFormRepsLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.reps = int.tryParse(v),
              ),
            ),
          ] else ...[
            Expanded(
              child: TextFormField(
                initialValue: entry.durationMinutes?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: l10n.workoutFormDurationLabel,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.durationMinutes = int.tryParse(v),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: entry.restSeconds == null
                  ? ''
                  : (entry.restSeconds! / 60).toString(),
              decoration: InputDecoration(
                labelText: l10n.workoutFormRestLabel,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => entry.restSeconds = _parseRestSeconds(v),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.workoutFormRemoveSet,
            onPressed: () => setState(() {
              sets.removeAt(index);
              if (sets.isEmpty) _selected.remove(ex.id);
            }),
          ),
        ],
      ),
    );
  }

  /// Parses the rest field (minutes, decimal allowed) into seconds. Empty or
  /// unparseable input → null, which fails the completeness check on save.
  int? _parseRestSeconds(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final minutes = double.tryParse(t);
    if (minutes == null || minutes <= 0) return null;
    return (minutes * 60).round();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selected.isEmpty) {
      showTopBanner(context, message: l10n.workoutFormSelectExercise);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final workout =
          widget.initial?.workout.copyWith(name: name, date: _date) ??
          newWorkout(name: name, date: _date);

      // Build exercise + set lists
      final exercises = <WorkoutExercise>[];
      final setGroups = <List<ExerciseSet>>[];
      var sortOrder = 0;

      // We need exercise names — fetch from provider cache
      final exercisesList = await ref.read(exerciseListProvider.future);
      final nameMap = {for (final ex in exercisesList) ex.id: ex.name};
      final exerciseMap = {for (final ex in exercisesList) ex.id: ex};

      // Every added set must be complete: reps/weight (or duration) AND rest.
      for (final entry in _selected.entries) {
        final ex = exerciseMap[entry.key];
        for (final plan in entry.value) {
          final baseOk = ex?.isWeightlifting == true
              ? (plan.reps ?? 0) > 0 && (plan.weightKg ?? 0) > 0
              : (plan.durationMinutes ?? 0) > 0;
          if (!baseOk || (plan.restSeconds ?? 0) <= 0) {
            if (mounted) {
              showTopBanner(context, message: l10n.workoutFormSetIncomplete);
            }
            return;
          }
        }
      }

      for (final entry in _selected.entries) {
        final exId = entry.key;
        final plannedSets = entry.value;
        if (plannedSets.isEmpty) continue;
        final we = newWorkoutExercise(
          workoutId: workout.id,
          exerciseId: exId,
          exerciseName: nameMap[exId] ?? '',
          sortOrder: sortOrder++,
        );
        exercises.add(we);

        final sets = plannedSets.asMap().entries.map((e) {
          final plan = e.value;
          return newPlannedSet(
            workoutExerciseId: we.id,
            setNumber: e.key + 1,
            reps: (plan.reps ?? 0) > 0 ? plan.reps : null,
            weightKg: (plan.weightKg ?? 0) > 0 ? plan.weightKg : null,
            restSeconds: (plan.restSeconds ?? 0) > 0 ? plan.restSeconds : null,
            durationMinutes: (plan.durationMinutes ?? 0) > 0
                ? plan.durationMinutes
                : null,
          );
        }).toList();
        setGroups.add(sets);
      }

      if (widget.initial != null) {
        await repo.updateWorkout(id: workout.id, name: name, date: _date);
        await repo.replaceExercises(
          workoutId: workout.id,
          exercises: exercises,
          setGroups: setGroups,
        );
      } else {
        await repo.insert(
          workout: workout,
          exercises: exercises,
          setGroups: setGroups,
        );
      }
      invalidateDashboard(ref);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
