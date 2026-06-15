import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../exercise/providers/exercises.dart';
import '../../../exercise/providers/planned_workout_provider.dart';
import '../../../exercise/providers/seance.dart';
import '../../../models/exercise.dart';
import '../../../models/workout.dart' as domain;

/// A full-screen form to create or edit a planned workout.
class CreatePlannedScreen extends ConsumerStatefulWidget {
  const CreatePlannedScreen({
    super.key,
    required this.scheduledDate,
    this.plannedWorkout,
  });

  final DateTime scheduledDate;
  final domain.PlannedWorkout? plannedWorkout;

  bool get isEditing => plannedWorkout != null;

  @override
  ConsumerState<CreatePlannedScreen> createState() =>
      _CreatePlannedScreenState();
}

class _CreatePlannedScreenState extends ConsumerState<CreatePlannedScreen> {
  final _nameController = TextEditingController();
  late DateTime _scheduledDate;
  final _searchController = TextEditingController();

  /// Entries being configured for the planned workout.
  final List<_EntryConfig> _entries = [];

  @override
  void initState() {
    super.initState();
    _scheduledDate = widget.scheduledDate;

    if (widget.isEditing) {
      _nameController.text = widget.plannedWorkout!.name;
      for (final entry in widget.plannedWorkout!.entries) {
        _entries.add(
          _EntryConfig(
            exercise: entry.exercise,
            reps: entry.plannedReps,
            weightKg: entry.plannedWeightKg,
            durationMinutes: entry.plannedCardio?.plannedDurationMinutes,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    for (final e in _entries) {
      e.repsController.dispose();
      e.weightController.dispose();
      e.durationController.dispose();
    }
    super.dispose();
  }

  void _addExercise(ExerciseDefinition exercise) {
    setState(() {
      _entries.add(_EntryConfig(exercise: exercise));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _entries[index].repsController.dispose();
      _entries[index].weightController.dispose();
      _entries[index].durationController.dispose();
      _entries.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _copyFromTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final templates = ref.read(templateListProvider);

    if (templates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noTemplatesAvailable)));
      }
      return;
    }

    final template = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectTemplate),
        children: templates
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.of(ctx).pop(t),
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text(l10n.exercisesCount(t.exercises.length)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            )
            .toList(),
      ),
    );

    if (template == null || !context.mounted) return;

    final name = template.name as String;
    _nameController.text = name;

    // Use createFromTemplate to build the plan, then extract entries
    try {
      final saved = await ref
          .read(plannedWorkoutProvider.notifier)
          .createFromTemplate(
            templateId: (template as dynamic).id,
            scheduledDate: _scheduledDate,
            name: name,
          );
      if (context.mounted) {
        setState(() {
          _nameController.text = saved.name;
          _entries.clear();
          for (final entry in saved.entries) {
            _entries.add(
              _EntryConfig(
                exercise: entry.exercise,
                reps: entry.plannedReps,
                weightKg: entry.plannedWeightKg,
                durationMinutes: entry.plannedCardio?.plannedDurationMinutes,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  Widget _buildAddExerciseSection() {
    final l10n = AppLocalizations.of(context)!;
    final exercises = ref.watch(exerciseListProvider);
    final query = _searchController.text.trim().toLowerCase();

    final addedIds = _entries.map((e) => e.exercise.id).toSet();
    final filtered = query.isEmpty
        ? <ExerciseDefinition>[]
        : exercises.where((e) {
            if (addedIds.contains(e.id)) return false;
            if (!e.name.toLowerCase().contains(query)) return false;
            return true;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchExercises,
            prefixIcon: const Icon(Icons.search, size: 20),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        ...filtered.map((exercise) {
          final isCardio = exercise.type == 'cardio';
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ListTile(
              dense: true,
              leading: Icon(
                isCardio ? Icons.directions_run : Icons.fitness_center,
                size: 18,
              ),
              title: Text(exercise.name, style: const TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.add, size: 18),
              onTap: () {
                _addExercise(exercise);
                _searchController.clear();
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEntryCard(int index, _EntryConfig entry) {
    final l10n = AppLocalizations.of(context)!;
    final isCardio = entry.exercise.type == 'cardio';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCardio ? Icons.directions_run : Icons.fitness_center,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.exercise.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  onPressed: () => _removeExercise(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isCardio) ...[
              TextField(
                controller: entry.durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text(l10n.minutes),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.repsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        label: Text(l10n.reps),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: entry.weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        label: Text(l10n.weightKg),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterWorkoutName)));
      return;
    }
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.addAtLeastOneExercise)));
      return;
    }

    final plannedEntries = <domain.PlannedEntry>[];
    for (var i = 0; i < _entries.length; i++) {
      final cfg = _entries[i];
      final isCardio = cfg.exercise.type == 'cardio';

      if (isCardio) {
        final dur = int.tryParse(cfg.durationController.text);
        plannedEntries.add(
          domain.PlannedEntry(
            id: const Uuid().v4(),
            exercise: cfg.exercise,
            plannedReps: 0,
            plannedWeightKg: 0,
            sortOrder: i,
            plannedCardio: domain.PlannedCardio(
              plannedDurationMinutes: dur ?? 30,
            ),
          ),
        );
      } else {
        final reps = int.tryParse(cfg.repsController.text) ?? 10;
        final weight = double.tryParse(cfg.weightController.text) ?? 20.0;
        plannedEntries.add(
          domain.PlannedEntry(
            id: const Uuid().v4(),
            exercise: cfg.exercise,
            plannedReps: reps,
            plannedWeightKg: weight,
            sortOrder: i,
          ),
        );
      }
    }

    final plan = domain.PlannedWorkout(
      id: widget.plannedWorkout?.id ?? const Uuid().v4(),
      scheduledDate: _scheduledDate,
      name: _nameController.text.trim(),
      entries: plannedEntries,
      source: widget.plannedWorkout?.source ?? 'manual',
      templateId: widget.plannedWorkout?.templateId,
    );

    try {
      if (widget.isEditing) {
        await ref
            .read(plannedWorkoutProvider.notifier)
            .updatePlannedWorkout(plan);
      } else {
        await ref
            .read(plannedWorkoutProvider.notifier)
            .createPlannedWorkout(plan);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.plannedWorkoutSaved)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr =
        '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editPlannedWorkout : l10n.planWorkout,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              label: Text(l10n.workoutName),
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Date
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                label: Text(l10n.date),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(dateStr),
            ),
          ),
          const SizedBox(height: 16),

          // Copy from template
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.content_copy, size: 18),
              label: Text(l10n.copyFromTemplate),
              onPressed: _copyFromTemplate,
            ),
          ),
          const SizedBox(height: 16),

          // Exercises header
          Text(l10n.exercises, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // Existing entries
          ...List.generate(
            _entries.length,
            (i) => _buildEntryCard(i, _entries[i]),
          ),

          // Add exercise picker
          _buildAddExerciseSection(),

          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(widget.isEditing ? Icons.save : Icons.check, size: 18),
              label: Text(widget.isEditing ? l10n.saveChanges : l10n.savePlan),
              onPressed: _save,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Internal model for building entries in the create screen.
class _EntryConfig {
  _EntryConfig({
    required this.exercise,
    int? reps,
    double? weightKg,
    int? durationMinutes,
  }) : repsController = TextEditingController(text: reps?.toString() ?? ''),
       weightController = TextEditingController(
         text: weightKg?.toString() ?? '',
       ),
       durationController = TextEditingController(
         text: durationMinutes?.toString() ?? '',
       );

  final ExerciseDefinition exercise;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController durationController;
}
