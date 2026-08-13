import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise_set.dart';
import '../../models/workout.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/haptics.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';
import 'workout_form.dart';

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

    // This detail is the pending/planning screen, so the status is always
    // pending here.
    final statusLabel = l10n.statusPending;
    final statusColor = theme.colorScheme.outline;

    final dateStr = DateFormats.formatDate(context, w.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          if (w.isPending) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.commonEdit,
              onPressed: () => _editWorkout(context, ref, detail),
            ),
            TextButton.icon(
              onPressed: () => _startWorkout(context, ref, w.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.workoutDetailBtnStart),
            ),
          ],
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
                      StatusBadge(label: statusLabel, color: statusColor),
                      const Spacer(),
                      Text(dateStr, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercises
          Text(l10n.workoutDetailExercises, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (detail.exercises.isEmpty)
            EmptyState(
              icon: Icons.fitness_center,
              title: l10n.emptyWorkoutDetailTitle,
              description: l10n.emptyWorkoutDetailBody,
            )
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
    final startedAt = DateTime.now();
    await ref
        .read(activeWorkoutNotifierProvider)
        .startWorkoutNotification(
          workoutName: detail.workout.name,
          startedAt: startedAt,
          l10n: l10n,
        );
    await ref.read(workoutRepositoryProvider).start(id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.workoutStarted)));
    }
    ref.invalidate(workoutDetailProvider(workoutId));
    ref.invalidate(workoutListProvider);
    if (context.mounted) {
      final router = GoRouter.of(context);
      // Pop the planning detail pushed from the list.
      Navigator.of(context).pop();
      // Replace with the active view (no back to planning).
      router.go('/active-workout');
    }
  }

  Future<void> _editWorkout(
    BuildContext context,
    WidgetRef ref,
    WorkoutWithDetails detail,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(initial: detail)),
    );
    if (saved == true) ref.invalidate(workoutDetailProvider(workoutId));
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
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.workoutDetailSetHeaderHash,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.workoutDetailSetHeaderPlanned,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 5,
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
            _SetRow(set: set, workout: workout, l10n: l10n, ref: ref),
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
  final WidgetRef ref;

  const _SetRow({
    required this.set,
    required this.workout,
    required this.l10n,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditable = !workout.isPending;

    final planned = set.reps != null
        ? l10n.workoutDetailPlannedSetReps(
            set.reps.toString(),
            set.weightKg == null ? '?' : formatDecimal(set.weightKg!),
          )
        : set.durationMinutes != null
        ? l10n.workoutDetailPlannedSetDuration(set.durationMinutes.toString())
        : l10n.workoutDetailPlannedSetEmpty;

    final actual = set.actualReps != null
        ? l10n.workoutDetailActualSetReps(
            set.actualReps.toString(),
            set.actualWeightKg == null
                ? '?'
                : formatDecimal(set.actualWeightKg!),
          )
        : set.actualWeightKg != null
        ? l10n.workoutDetailActualSetWeight(formatDecimal(set.actualWeightKg!))
        : set.durationMinutes != null && set.actualReps != null
        ? l10n.workoutDetailActualSetDuration(set.actualReps.toString())
        : l10n.workoutDetailActualSetEmpty;

    return InkWell(
      onTap: isEditable ? () => _editActuals(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${set.setNumber}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                planned,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: set.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                  decoration: set.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                actual,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: set.isCompleted ? FontWeight.w600 : null,
                  color: set.isCompleted
                      ? theme.extension<FitFatColors>()!.success
                      : null,
                ),
              ),
            ),
            if (isEditable)
              Tooltip(
                message: l10n.commonEdit,
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
    unawaited(Haptics.lightImpact());
    ref.invalidate(workoutDetailProvider(workout.id));
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
