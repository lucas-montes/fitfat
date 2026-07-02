import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise_set.dart';
import '../../models/workout.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';

final class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(workoutDetailProvider(workoutId));

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.workoutDetailAppBar)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.workoutDetailAppBar)),
        body: Center(child: Text(l10n.errorWithMessage('$e'))),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.workoutDetailAppBar)),
            body: Center(child: Text(l10n.workoutDetailNotFound)),
          );
        }
        return _WorkoutDetailContent(
          detail: detail,
          workoutId: workoutId,
          l10n: l10n,
          ref: ref,
        );
      },
    );
  }
}

final class _WorkoutDetailContent extends StatelessWidget {
  final WorkoutWithDetails detail;
  final String workoutId;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _WorkoutDetailContent({
    required this.detail,
    required this.workoutId,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final w = detail.workout;
    final theme = Theme.of(context);

    final statusColor = w.isCompleted
        ? Colors.green
        : w.isActive
        ? Colors.orange
        : Colors.grey;
    final statusLabel = w.isCompleted
        ? l10n.statusCompleted
        : w.isActive
        ? l10n.statusActive
        : l10n.statusPending;

    final dateStr =
        '${w.date.day.toString().padLeft(2, '0')}.'
        '${w.date.month.toString().padLeft(2, '0')}.'
        '${w.date.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          if (w.isPending)
            TextButton.icon(
              onPressed: () => _startWorkout(context, ref, w.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutDetailBtnStart),
            ),
          if (w.isActive)
            TextButton.icon(
              onPressed: () => _completeWorkout(context, ref, w.id),
              icon: const Icon(Icons.check),
              label: Text(l10n.workoutDetailBtnComplete),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(dateStr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (w.isActive && w.startedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.workoutDetailStartedAt(
                        '${w.startedAt!.hour.toString().padLeft(2, '0')}:'
                        '${w.startedAt!.minute.toString().padLeft(2, '0')}',
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (w.isCompleted && w.duration > Duration.zero) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.dashboardDurationMin(w.duration.inMinutes),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercises
          Text(l10n.workoutDetailExercises, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (detail.exercises.isEmpty)
            Text(l10n.workoutDetailNoExercises)
          else
            for (final block in detail.exercises)
              _ExerciseBlockCard(
                block: block,
                workout: w,
                l10n: l10n,
                ref: ref,
              ),
        ],
      ),
    );
  }

  Future<void> _startWorkout(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    await ref.read(workoutRepositoryProvider).start(id);
    ref.invalidate(workoutDetailProvider(workoutId));
    ref.invalidate(workoutListProvider);
  }

  Future<void> _completeWorkout(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    await ref.read(workoutRepositoryProvider).complete(id);
    ref.invalidate(workoutDetailProvider(workoutId));
    ref.invalidate(workoutListProvider);
  }
}

final class _ExerciseBlockCard extends StatelessWidget {
  final ExerciseBlock block;
  final Workout workout;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _ExerciseBlockCard({
    required this.block,
    required this.workout,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(block.exercise.exerciseName),
        leading: const Icon(Icons.fitness_center),
        subtitle: Text(l10n.workoutDetailSetCount(block.sets.length)),
        initiallyExpanded: true,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    l10n.workoutDetailSetHeaderHash,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.workoutDetailSetHeaderPlanned,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.workoutDetailSetHeaderActual,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          for (final set in block.sets)
            _SetRow(
              set: set,
              workout: workout,
              l10n: l10n,
              workoutExerciseId: block.exercise.id,
              ref: ref,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

final class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final Workout workout;
  final AppLocalizations l10n;
  final String workoutExerciseId;
  final WidgetRef ref;

  const _SetRow({
    required this.set,
    required this.workout,
    required this.l10n,
    required this.workoutExerciseId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isEditable = !workout.isPending;

    final planned = set.reps != null
        ? l10n.workoutDetailPlannedSetReps(
            set.reps.toString(),
            set.weightKg?.toStringAsFixed(0) ?? '?',
          )
        : set.durationMinutes != null
        ? l10n.workoutDetailPlannedSetDuration(set.durationMinutes.toString())
        : l10n.workoutDetailPlannedSetEmpty;

    final actual = set.actualReps != null
        ? l10n.workoutDetailActualSetReps(
            set.actualReps.toString(),
            set.actualWeightKg?.toStringAsFixed(0) ?? '?',
          )
        : set.actualWeightKg != null
        ? l10n.workoutDetailActualSetWeight(
            set.actualWeightKg!.toStringAsFixed(0),
          )
        : set.durationMinutes != null && set.actualReps != null
        ? l10n.workoutDetailActualSetDuration(set.actualReps.toString())
        : l10n.workoutDetailActualSetEmpty;

    return InkWell(
      onTap: isEditable ? () => _editActuals(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${set.setNumber}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: Text(
                planned,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: set.isCompleted ? Colors.grey : null,
                  decoration: set.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            Expanded(
              child: Text(
                actual,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: set.isCompleted ? FontWeight.w600 : null,
                  color: set.isCompleted ? Colors.green : null,
                ),
              ),
            ),
            if (isEditable)
              const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _editActuals(BuildContext context) async {
    final result = await showDialog<_SetActuals>(
      context: context,
      builder: (ctx) => _SetActualsDialog(set: set, l10n: l10n),
    );
    if (result == null) return;

    await ref
        .read(workoutRepositoryProvider)
        .updateSetActuals(
          setId: set.id,
          actualReps: result.reps,
          actualWeightKg: result.weightKg,
          durationMinutes: result.durationMinutes,
          distanceMeters: result.distanceMeters,
        );
    ref.invalidate(workoutDetailProvider(workoutExerciseId));
  }
}

final class _SetActuals {
  final int? reps;
  final double? weightKg;
  final int? durationMinutes;
  final double? distanceMeters;
  const _SetActuals({
    this.reps,
    this.weightKg,
    this.durationMinutes,
    this.distanceMeters,
  });
}

final class _SetActualsDialog extends StatefulWidget {
  final ExerciseSet set;
  final AppLocalizations l10n;
  const _SetActualsDialog({required this.set, required this.l10n});

  @override
  State<_SetActualsDialog> createState() => _SetActualsDialogState();
}

final class _SetActualsDialogState extends State<_SetActualsDialog> {
  late final TextEditingController _repsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _distanceCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _repsCtrl = TextEditingController(
      text: (s.actualReps ?? s.reps)?.toString() ?? '',
    );
    _weightCtrl = TextEditingController(
      text: (s.actualWeightKg ?? s.weightKg)?.toStringAsFixed(1) ?? '',
    );
    _durationCtrl = TextEditingController(
      text:
          (s.actualWeightKg != null ? s.durationMinutes : null)?.toString() ??
          '',
    );
    _distanceCtrl = TextEditingController(
      text: s.distanceMeters?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final s = widget.set;
    final isWeightlifting = s.reps != null || s.weightKg != null;
    final isCardio = s.durationMinutes != null || s.distanceMeters != null;

    return AlertDialog(
      title: Text(l10n.workoutDetailSetActualsTitle(s.setNumber)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isWeightlifting) ...[
              TextField(
                controller: _repsCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualRepsLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _weightCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualWeightLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (isCardio) ...[
              TextField(
                controller: _durationCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDurationLabel,
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _distanceCtrl,
                decoration: InputDecoration(
                  labelText: l10n.workoutDetailActualDistanceLabel,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              _SetActuals(
                reps: int.tryParse(_repsCtrl.text),
                weightKg: double.tryParse(_weightCtrl.text),
                durationMinutes: int.tryParse(_durationCtrl.text),
                distanceMeters: double.tryParse(_distanceCtrl.text),
              ),
            );
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
