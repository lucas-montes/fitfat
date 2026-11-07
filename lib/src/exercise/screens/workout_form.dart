import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/units.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../planner/providers/planner.dart' show taskRepositoryProvider;
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/units.dart';
import '../../notifications/rest_timer.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../../dashboard/providers/dashboard.dart';
import '../repositories/workout_repository.dart';
import 'exercise_picker_sheet.dart';

/// One set in the form before saving.
///
/// A pending workout uses the planned fields (reps/weight or
/// duration/distance, plus rest); a completed workout uses the actual fields,
/// records when each set was finished, and derives rest from the gap between
/// consecutive set times. The unused group stays null, which is also what makes
/// a completed set "not done": no actuals at all is deliberately stored as null
/// rather than zero so it stays out of completed counts and averages.
final class _SetEntry {
  /// Existing `exercise_sets.id`, or a fresh one for a set added while editing
  /// a completed workout. Preserved across a completed edit so sync sees an
  /// update rather than a delete-and-recreate.
  final String id;

  int? reps;
  double? weightKg;
  int? durationMinutes;
  double? distanceMeters;
  int? restSeconds;

  int? actualReps;
  double? actualWeightKg;
  int? actualDurationMinutes;
  double? actualDistanceMeters;

  /// The completion time as loaded from the row. Kept verbatim (seconds
  /// included) so opening the form and saving does not rewrite a timestamp.
  DateTime? originalCompletedAt;

  /// Time of day shown in the editor. Null until the user picks one, or when
  /// the set never recorded a completion time.
  TimeOfDay? doneAt;

  /// True once the user picked a time here. This is what tells the rest
  /// calculation to re-derive rest from the set times instead of trusting the
  /// value the rest timer recorded.
  bool doneAtEdited = false;

  /// Rest the rest timer recorded after this set; null when it was never used.
  int? actualRestSeconds;

  _SetEntry({String? id}) : id = id ?? const Uuid().v7();
}

/// One exercise's draft state: the existing workout-exercise id (null for a
/// newly added exercise) plus its notes and sets.
final class _ExerciseEntry {
  final String? workoutExerciseId;
  final String? notes;
  final List<_SetEntry> sets;

  _ExerciseEntry({this.workoutExerciseId, this.notes, required this.sets});
}

final class WorkoutFormScreen extends ConsumerStatefulWidget {
  /// When null the form creates a new workout. When set it edits that workout:
  /// a pending one edits the **plan**, a completed one edits the **actuals**
  /// that were recorded, preserving ids and planned values.
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

  /// Create-only: also drop a linked "do this workout" task onto the planner
  /// (tasks.workout_id), on by default so the workout shows up in the day
  /// timeline without a second manual step.
  bool _addToPlanner = true;

  /// Selected exercise ids → draft state. Order is preserved (Dart Maps keep
  /// insertion order) and is user-reorderable via the drag handle.
  Map<String, _ExerciseEntry> _selected = {};

  // Memoized id→exercise lookup over the ~3,800-row catalog: rebuilt only
  // when the provider's list instance actually changes, not on every
  // add/remove/reorder setState (perf T02).
  List<Exercise>? _byIdSource;
  Map<String, Exercise>? _byIdCache;

  bool get _isCompletedEdit => widget.initial?.workout.isCompleted ?? false;

  /// A completed set counts as done when its primary measure is present. This
  /// matches what `_saveCompleted` stores, so the rest preview and the saved
  /// rows cannot disagree about which sets took part.
  bool _entryDone(_SetEntry entry, Exercise? ex) => ex?.isWeightlifting != false
      ? !_unset(entry.actualReps) && !_unset(entry.actualWeightKg)
      : !_unset(entry.actualDurationMinutes);

  /// Completion time for a set, pinned to the workout's date.
  ///
  /// An untouched timestamp keeps its original instant (seconds included) so
  /// merely fixing a weight does not move the set. A time the user picked
  /// replaces the clock time on the workout's date. Null means "unknown": the
  /// repository then keeps the stored timestamp, or stamps one for a set that
  /// is being logged for the first time.
  DateTime? _resolveCompletedAt(_SetEntry entry) {
    if (entry.doneAtEdited) {
      final at = entry.doneAt;
      return at == null
          ? null
          : DateTime(_date.year, _date.month, _date.day, at.hour, at.minute);
    }
    final original = entry.originalCompletedAt;
    if (original == null) return null;
    if (original.year == _date.year &&
        original.month == _date.month &&
        original.day == _date.day) {
      return original;
    }
    // The workout date moved: keep the clock time, put it on the new day.
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      original.hour,
      original.minute,
      original.second,
      original.millisecond,
    );
  }

  /// Completion time per set; null for sets that were not done (or whose time
  /// is unknown), which also breaks the rest chain around them.
  List<DateTime?> _completedTimes(List<_SetEntry> sets, Exercise? ex) => [
    for (final set in sets)
      _entryDone(set, ex) ? _resolveCompletedAt(set) : null,
  ];

  /// Rest taken after each set, as it will be saved. Shared by the editor's
  /// preview and the save itself so the number on screen is the stored one.
  List<int?> _restsAfter(List<_SetEntry> sets, Exercise? ex) =>
      restAfterFromTimes(
        times: _completedTimes(sets, ex),
        recorded: [for (final set in sets) set.actualRestSeconds],
        timesEdited: [for (final set in sets) set.doneAtEdited],
      );

  Map<String, Exercise> _byIdFor(List<Exercise> exercises) {
    if (_byIdCache != null && identical(_byIdSource, exercises)) {
      return _byIdCache!;
    }
    _byIdSource = exercises;
    return _byIdCache = {for (final ex in exercises) ex.id: ex};
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    final initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.workout.name;
      _date = initial.workout.date;
      for (final block in initial.exercises) {
        _selected[block.exercise.exerciseId] = _ExerciseEntry(
          workoutExerciseId: block.exercise.id,
          notes: block.exercise.notes,
          sets: [
            for (final set in block.sets)
              _isCompletedEdit
                  // A completed session only ever edits what was logged.
                  ? (_SetEntry(id: set.id)
                      ..actualReps = set.actualReps
                      ..actualWeightKg = set.actualWeightKg
                      ..actualDurationMinutes = set.actualDurationMinutes
                      ..actualDistanceMeters = set.actualDistanceMeters
                      ..actualRestSeconds = set.actualRestSeconds
                      ..originalCompletedAt = set.completedAt
                      ..doneAt = set.completedAt == null
                          ? null
                          : TimeOfDay.fromDateTime(set.completedAt!))
                  : (_SetEntry()
                      ..reps = set.reps
                      ..weightKg = set.weightKg
                      ..durationMinutes = set.durationMinutes
                      ..distanceMeters = set.distanceMeters
                      ..restSeconds = set.restSeconds),
          ],
        );
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
    final unit = ref.watch(settingsProvider).weightUnit;

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
            // Create-only: drop the new workout onto today's planner as a
            // "do this workout" task (1:1 via tasks.workout_id).
            if (widget.initial == null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workoutFormAddPlannerTask),
                subtitle: Text(l10n.workoutFormAddPlannerTaskSubtitle),
                value: _addToPlanner,
                onChanged: (v) => setState(() => _addToPlanner = v),
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
                final byId = _byIdFor(exercises);
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
                        unit,
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

  /// Reorders the sets within an exercise (drag the set chip handle).
  void _reorderSets(String exerciseId, int oldIndex, int newIndex) {
    setState(() {
      final sets = _selected[exerciseId]!.sets;
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
        _selected.putIfAbsent(id, () => _ExerciseEntry(sets: []));
      }
    });
  }

  /// One chosen exercise: drag handle, name, remove action, per-set editors,
  /// and an "Add set" button. [exerciseId] + [index] power the reorder handle.
  Widget _buildSelectedExerciseRow(
    String exerciseId,
    Exercise ex,
    _ExerciseEntry entry,
    int index,
    AppLocalizations l10n,
    WeightUnit unit,
  ) {
    final sets = entry.sets;
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
                  _buildSetRow(i, sets[i], sets, ex, l10n, unit),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.workoutFormAddSet),
              onPressed: () => setState(() {
                // A completed session gets an empty "not done" set; there is
                // no plan to prefill. A planned set prefills the default rest.
                if (_isCompletedEdit) {
                  sets.add(_SetEntry());
                  return;
                }
                final defaultRest = ref
                    .read(settingsProvider)
                    .defaultRestSeconds;
                sets.add(
                  _SetEntry()
                    ..restSeconds = defaultRest > 0 ? defaultRest : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    int index,
    _SetEntry entry,
    List<_SetEntry> sets,
    Exercise ex,
    AppLocalizations l10n,
    WeightUnit unit,
  ) {
    // A completed session edits actuals, a pending one edits the plan. The
    // field layout is the same either way so the two modes read alike.
    final weight = _isCompletedEdit ? entry.actualWeightKg : entry.weightKg;
    final reps = _isCompletedEdit ? entry.actualReps : entry.reps;
    final duration = _isCompletedEdit
        ? entry.actualDurationMinutes
        : entry.durationMinutes;
    final distance = _isCompletedEdit
        ? entry.actualDistanceMeters
        : entry.distanceMeters;

    void setWeight(String v) {
      final parsed = double.tryParse(v.replaceAll(',', '.'));
      final kg = parsed == null ? null : weightToKg(parsed, unit);
      if (_isCompletedEdit) {
        entry.actualWeightKg = kg;
      } else {
        entry.weightKg = kg;
      }
    }

    final fields = Row(
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
              key: ValueKey('${entry.id}-weight'),
              initialValue: weight == null
                  ? ''
                  : formatWeightValue(weight, unit),
              decoration: InputDecoration(
                labelText: weightUnitLabel(unit),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: setWeight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('${entry.id}-reps'),
              initialValue: reps?.toString() ?? '',
              decoration: InputDecoration(
                labelText: l10n.workoutFormRepsLabel,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (_isCompletedEdit) {
                  entry.actualReps = parsed;
                } else {
                  entry.reps = parsed;
                }
              },
            ),
          ),
        ] else ...[
          Expanded(
            child: TextFormField(
              key: ValueKey('${entry.id}-duration'),
              initialValue: duration?.toString() ?? '',
              decoration: InputDecoration(
                labelText: l10n.workoutFormDurationLabel,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (_isCompletedEdit) {
                  entry.actualDurationMinutes = parsed;
                } else {
                  entry.durationMinutes = parsed;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('${entry.id}-distance'),
              initialValue: distance == null ? '' : formatDecimal(distance),
              decoration: InputDecoration(
                labelText: l10n.workoutFormDistanceLabel,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.'));
                if (_isCompletedEdit) {
                  entry.actualDistanceMeters = parsed;
                } else {
                  entry.distanceMeters = parsed;
                }
              },
            ),
          ),
        ],
        // Rest is a plan value; a completed session already has a recorded
        // actual rest and must not invite rewriting it here.
        if (!_isCompletedEdit) ...[
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('${entry.id}-rest'),
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
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: l10n.workoutFormRemoveSet,
          onPressed: () => setState(() {
            sets.removeAt(index);
            if (sets.isEmpty) _selected.remove(ex.id);
          }),
        ),
      ],
    );

    return Container(
      key: ObjectKey(entry),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
      ),
      child: _isCompletedEdit
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                fields,
                const SizedBox(height: 2),
                _buildSetTimeRow(entry, index, sets, ex, l10n),
              ],
            )
          : fields,
    );
  }

  /// Completed-mode footer: when the set was finished, plus the rest that
  /// follows the previous set. The rest is the gap between the two times, which
  /// is why editing a time here can fix a session logged without the timer.
  Widget _buildSetTimeRow(
    _SetEntry entry,
    int index,
    List<_SetEntry> sets,
    Exercise ex,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final restBefore = index == 0 ? null : _restsAfter(sets, ex)[index - 1];
    final at = entry.doneAt;
    final label = at == null
        ? l10n.workoutFormSetTimeEmpty
        : '${l10n.workoutFormSetDoneAt} '
              '${MaterialLocalizations.of(context).formatTimeOfDay(at, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';

    return Row(
      children: [
        Tooltip(
          message: l10n.workoutFormSetDoneAtTooltip,
          child: InkWell(
            onTap: () => _pickSetTime(entry, sets, index),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: at == null ? muted : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        if (restBefore != null)
          Text(
            l10n.workoutSummarySetRest(
              formatRestDuration(Duration(seconds: restBefore)),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }

  Future<void> _pickSetTime(
    _SetEntry entry,
    List<_SetEntry> sets,
    int index,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _initialTimeFor(entry, sets, index),
    );
    if (picked == null || !mounted) return;
    setState(() {
      entry.doneAt = picked;
      entry.doneAtEdited = true;
    });
  }

  /// First guess for the picker: the set's own time, else a few minutes after
  /// the previous set, else when the session started. Retyping the whole
  /// timeline is the point here, so the default has to move forward with it.
  TimeOfDay _initialTimeFor(_SetEntry entry, List<_SetEntry> sets, int index) {
    if (entry.doneAt != null) return entry.doneAt!;
    for (var i = index - 1; i >= 0; i--) {
      final previous = sets[i].doneAt;
      if (previous == null) continue;
      final minutes = previous.hour * 60 + previous.minute + 3;
      return TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
    }
    final session = widget.initial?.workout;
    final started = session?.startedAt ?? session?.completedAt;
    return started == null ? TimeOfDay.now() : TimeOfDay.fromDateTime(started);
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

  /// True when a numeric entry is absent or non-positive. Zero is treated as
  /// "not done" so a cleared field and a typed 0 behave the same.
  bool _unset(num? value) => value == null || value <= 0;

  /// A completed set is either fully logged or fully blank. Half a set is a
  /// typo, not a record, so saving refuses it rather than storing a partial
  /// actual that would count as done.
  bool _completedSetIsValid(_SetEntry entry, Exercise? ex) {
    if (ex?.isWeightlifting != false) {
      final repsSet = !_unset(entry.actualReps);
      final weightSet = !_unset(entry.actualWeightKg);
      return repsSet == weightSet;
    }
    final durationSet = !_unset(entry.actualDurationMinutes);
    final distanceSet = !_unset(entry.actualDistanceMeters);
    // Duration is the primary cardio measure; distance is optional.
    return durationSet || !distanceSet;
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

      // We need exercise names — fetch from provider cache
      final exercisesList = await ref.read(exerciseListProvider.future);
      final nameMap = {for (final ex in exercisesList) ex.id: ex.name};
      final exerciseMap = {for (final ex in exercisesList) ex.id: ex};

      if (_isCompletedEdit) {
        await _saveCompleted(
          repo: repo,
          workout: workout,
          name: name,
          exerciseMap: exerciseMap,
          nameMap: nameMap,
          l10n: l10n,
        );
        return;
      }

      // Build exercise + set lists
      final exercises = <WorkoutExercise>[];
      final setGroups = <List<ExerciseSet>>[];
      var sortOrder = 0;

      // Every added set must be complete: reps/weight (or duration) AND rest.
      for (final entry in _selected.entries) {
        final ex = exerciseMap[entry.key];
        for (final plan in entry.value.sets) {
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
        final plannedSets = entry.value.sets;
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
            // Was dropped before: cardio plans lost their distance on save.
            distanceMeters: (plan.distanceMeters ?? 0) > 0
                ? plan.distanceMeters
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
        if (_addToPlanner) {
          await ref
              .read(taskRepositoryProvider)
              .createForWorkout(workoutId: workout.id, title: name, day: _date);
        }
      }
      _invalidate();

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

  /// Completed-mode save: actuals only, ids preserved.
  Future<void> _saveCompleted({
    required WorkoutRepository repo,
    required Workout workout,
    required String name,
    required Map<String, Exercise> exerciseMap,
    required Map<String, String> nameMap,
    required AppLocalizations l10n,
  }) async {
    final exercises = <WorkoutExercise>[];
    final setGroups = <List<ExerciseSet>>[];
    var sortOrder = 0;

    for (final entry in _selected.entries) {
      final ex = exerciseMap[entry.key];
      if (entry.value.sets.isEmpty) continue;

      for (final set in entry.value.sets) {
        if (!_completedSetIsValid(set, ex)) {
          if (mounted) {
            showTopBanner(context, message: l10n.workoutFormSetIncomplete);
          }
          return;
        }
      }

      final existingId = entry.value.workoutExerciseId;
      final we = existingId == null
          ? newWorkoutExercise(
              workoutId: workout.id,
              exerciseId: entry.key,
              exerciseName: nameMap[entry.key] ?? '',
              sortOrder: sortOrder,
              notes: entry.value.notes,
            )
          : WorkoutExercise(
              id: existingId,
              workoutId: workout.id,
              exerciseId: entry.key,
              exerciseName: nameMap[entry.key] ?? '',
              sortOrder: sortOrder,
              notes: entry.value.notes,
            );
      sortOrder++;
      exercises.add(we);

      final isWeightlifting = ex?.isWeightlifting != false;
      final times = _completedTimes(entry.value.sets, ex);
      final rests = _restsAfter(entry.value.sets, ex);
      final sets = <ExerciseSet>[];
      for (var i = 0; i < entry.value.sets.length; i++) {
        final set = entry.value.sets[i];
        final done = _entryDone(set, ex);
        sets.add(
          ExerciseSet(
            id: set.id,
            workoutExerciseId: we.id,
            setNumber: i + 1,
            actualReps: done && isWeightlifting ? set.actualReps : null,
            actualWeightKg: done && isWeightlifting ? set.actualWeightKg : null,
            actualDurationMinutes: done && !isWeightlifting
                ? set.actualDurationMinutes
                : null,
            actualDistanceMeters:
                done && !isWeightlifting && !_unset(set.actualDistanceMeters)
                ? set.actualDistanceMeters
                : null,
            // A not-done set has no timestamp and no rest; a done one keeps the
            // time it had, or the time just entered here.
            completedAt: done ? times[i] : null,
            actualRestSeconds: done ? rests[i] : null,
          ),
        );
      }
      setGroups.add(sets);
    }

    await repo.saveCompletedWorkout(
      workout: workout,
      exercises: exercises,
      setGroups: setGroups,
    );
    _invalidate();

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _invalidate() {
    final id = widget.initial?.workout.id;
    invalidateDashboard(ref);
    ref.invalidate(workoutListProvider);
    if (id != null) ref.invalidate(workoutDetailProvider(id));
  }
}
