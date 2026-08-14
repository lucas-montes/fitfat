import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise_set.dart';
import '../../notifications/active_workout_notifier.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/workouts.dart';
import '../repositories/workout_repository.dart';
import '../../notifications/rest_timer.dart';
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
              _ExerciseBlockCard(block: block, l10n: l10n),
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
  final AppLocalizations l10n;

  const _ExerciseBlockCard({required this.block, required this.l10n});

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
          // Header row (planned only — this is the planning screen)
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
                  flex: 8,
                  child: Text(
                    l10n.workoutDetailSetHeaderPlanned,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          for (final set in block.sets) _SetRow(set: set, l10n: l10n),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

final class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final AppLocalizations l10n;

  const _SetRow({required this.set, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final plannedBase = set.reps != null
        ? l10n.workoutDetailPlannedSetReps(
            set.reps.toString(),
            set.weightKg == null ? '?' : formatDecimal(set.weightKg!),
          )
        : set.durationMinutes != null
        ? l10n.workoutDetailPlannedSetDuration(set.durationMinutes.toString())
        : l10n.workoutDetailPlannedSetEmpty;

    final planned = set.restSeconds != null
        ? l10n.workoutDetailPlannedSetRest(
            plannedBase,
            formatRestDuration(Duration(seconds: set.restSeconds!)),
          )
        : plannedBase;

    return Padding(
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
          Expanded(flex: 8, child: Text(planned, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
