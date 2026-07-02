import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../../models/exercise_set.dart';
import '../../models/workout_exercise.dart';
import '../providers/exercises.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';

/// A planned set entry used in the form before saving.
final class _PlannedSetEntry {
  int reps;
  double weightKg;
  int durationMinutes;
  _PlannedSetEntry({
    this.reps = 10,
    this.weightKg = 0,
    this.durationMinutes = 10,
  });
}

final class WorkoutFormScreen extends ConsumerStatefulWidget {
  const WorkoutFormScreen({super.key});

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

final class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late DateTime _date;
  bool _saving = false;

  /// Selected exercise ids → planned set configs.
  final Map<String, List<_PlannedSetEntry>> _selected = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Workout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Workout Name',
                hintText: 'e.g. Morning Push',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(
                '${_date.day.toString().padLeft(2, '0')}.'
                '${_date.month.toString().padLeft(2, '0')}.'
                '${_date.year}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            Text('Exercises', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (exercises) => exercises.isEmpty
                  ? const Text('No exercises available. Add some first.')
                  : Column(
                      children: exercises
                          .map((ex) => _buildExerciseRow(ex))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(Exercise ex) {
    final isSelected = _selected.containsKey(ex.id);
    final sets = _selected[ex.id];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected[ex.id] = List.generate(
                          3,
                          (_) => _PlannedSetEntry(
                            reps: ex.isWeightlifting ? 10 : 0,
                            weightKg: ex.isWeightlifting ? 0 : 0,
                            durationMinutes: ex.isCardio ? 10 : 0,
                          ),
                        );
                      } else {
                        _selected.remove(ex.id);
                      }
                    });
                  },
                ),
                Icon(
                  ex.isWeightlifting
                      ? Icons.fitness_center
                      : Icons.directions_run,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ex.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
                const Spacer(),
                Text(
                  ex.isWeightlifting ? 'Weightlifting' : 'Cardio',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (isSelected && sets != null) ...[
              const Divider(height: 8),
              for (var i = 0; i < sets.length; i++)
                _buildSetRow(i, sets[i], ex),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add set'),
                onPressed: () => setState(() {
                  _selected[ex.id]!.add(
                    _PlannedSetEntry(
                      reps: ex.isWeightlifting ? 10 : 0,
                      weightKg: ex.isWeightlifting ? 0 : 0,
                      durationMinutes: ex.isCardio ? 10 : 0,
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(int index, _PlannedSetEntry entry, Exercise ex) {
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
                initialValue: entry.reps.toString(),
                decoration: const InputDecoration(
                  labelText: 'Reps',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.reps = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: entry.weightKg.toStringAsFixed(0),
                decoration: const InputDecoration(
                  labelText: 'kg',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.weightKg = double.tryParse(v) ?? 0,
              ),
            ),
          ] else ...[
            Expanded(
              child: TextFormField(
                initialValue: entry.durationMinutes.toString(),
                decoration: const InputDecoration(
                  labelText: 'min',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => entry.durationMinutes = int.tryParse(v) ?? 0,
              ),
            ),
          ],
        ],
      ),
    );
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
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one exercise')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final name = _nameCtrl.text.trim();
      final workout = newWorkout(name: name, date: _date);

      // Build exercise + set lists
      final exercises = <WorkoutExercise>[];
      final setGroups = <List<ExerciseSet>>[];
      var sortOrder = 0;

      // We need exercise names — fetch from provider cache
      final exercisesList = await ref.read(exerciseListProvider.future);
      final nameMap = {for (final ex in exercisesList) ex.id: ex.name};

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
            reps: plan.reps > 0 ? plan.reps : null,
            weightKg: plan.weightKg > 0 ? plan.weightKg : null,
            durationMinutes: plan.durationMinutes > 0
                ? plan.durationMinutes
                : null,
          );
        }).toList();
        setGroups.add(sets);
      }

      await repo.insert(
        workout: workout,
        exercises: exercises,
        setGroups: setGroups,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
