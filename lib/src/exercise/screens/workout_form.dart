import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/workout_exercise.dart';
import '../../ui/date_formats.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';
import 'exercise_form.dart';

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
  late final TextEditingController _searchCtrl;
  late DateTime _date;
  bool _saving = false;

  /// Debounce timer for the search field so filtering (and the lazy result
  /// list rebuild) only runs after the user pauses typing.
  Timer? _searchDebounce;

  /// Current name filter for the exercise picker (empty = show all). Updated
  /// after the debounce delay so keystrokes never rebuild thousands of rows.
  String _filter = '';

  /// Selected exercise ids → planned set configs.
  final Map<String, List<_PlannedSetEntry>> _selected = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
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
    _searchDebounce?.cancel();
    _nameCtrl.dispose();
    _searchCtrl.dispose();
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
            exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.errorWithMessage('$e')),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Text(l10n.workoutFormNoExercises);
                }
                // Search-first: nothing is listed until the user types.
                final query = _filter.trim().toLowerCase();
                final visible = query.isEmpty
                    ? const <Exercise>[]
                    : exercises
                          .where((ex) => ex.name.toLowerCase().contains(query))
                          .toList();
                const maxResults = 50;
                final byId = {for (final ex in exercises) ex.id: ex};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.workoutFormSearchHint,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 250),
                          () {
                            if (mounted) setState(() => _filter = v);
                          },
                        );
                      },
                    ),
                    if (query.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildCreateExerciseRow(l10n),
                      // Lazy, height-bounded result list (capped) so a broad
                      // query never builds thousands of tiles per keystroke.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: visible.length > maxResults
                              ? maxResults
                              : visible.length,
                          itemBuilder: (_, i) =>
                              _buildSearchResultRow(visible[i], l10n),
                        ),
                      ),
                    ],
                    if (_selected.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final entry in _selected.entries)
                        if (byId[entry.key] case final ex?)
                          _buildSelectedExerciseRow(ex, entry.value, l10n),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? l10n.workoutFormSaving : l10n.workoutFormSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create-new row: opens the exercise form prefilled with the current search
  /// query; on save the created exercise is reloaded and auto-selected.
  Widget _buildCreateExerciseRow(AppLocalizations l10n) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.add),
      title: Text(l10n.workoutFormCreateExercise(_filter.trim())),
      trailing: const Icon(Icons.add_circle),
      onTap: _createExercise,
    );
  }

  Future<void> _createExercise() async {
    final created = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseFormScreen(initialName: _filter.trim()),
      ),
    );
    if (created == null || !mounted) return;
    ref.invalidate(exerciseListProvider);
    final reloaded = await ref.read(exerciseListProvider.future);
    if (!mounted) return;
    Exercise? match;
    for (final ex in reloaded) {
      if (ex.id == created.id) {
        match = ex;
        break;
      }
    }
    setState(() {
      _filter = '';
      _searchCtrl.clear();
      if (match != null) _selected[match.id] = [];
    });
  }

  /// Search result row: tapping adds the exercise to the selection; an added
  /// row is marked with a check and is not tappable again.
  Widget _buildSearchResultRow(Exercise ex, AppLocalizations l10n) {
    final isSelected = _selected.containsKey(ex.id);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ex.isWeightlifting ? Icons.fitness_center : Icons.directions_run,
        size: 20,
      ),
      title: Text(ex.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ex.isWeightlifting
                ? l10n.exerciseTypeWeightlifting
                : l10n.exerciseTypeCardio,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            size: 20,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
      onTap: isSelected
          ? null
          : () => setState(() {
              // Selecting an exercise creates no sets; each set is added
              // explicitly via "Add set".
              _selected[ex.id] = [];
            }),
    );
  }

  /// One chosen exercise: header row (name, type, remove action), per-set
  /// editors, and an "Add set" button.
  Widget _buildSelectedExerciseRow(
    Exercise ex,
    List<_PlannedSetEntry> sets,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            for (var i = 0; i < sets.length; i++)
              _buildSetRow(i, sets[i], ex, l10n),
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
    Exercise ex,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: 4, bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${index + 1}.', textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          if (ex.isWeightlifting) ...[
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
            const SizedBox(width: 8),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.workoutFormSelectExercise)));
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.workoutFormSetIncomplete)),
              );
            }
            return;
          }
        }
      }

      for (final entry in _selected.entries) {
        final exId = entry.key;
        final plannedSets = entry.value;
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
}
