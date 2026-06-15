import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../exercise/providers/workout_provider.dart';
import '../../../models/workout.dart' as domain;

/// Top card in the Training tab.
///
/// Shows either:
/// - Running workout card (if active workout in progress)
/// - Start card with "Follow today's plan" or "Start workout" + Quick Log pill
class StartWorkoutCard extends ConsumerWidget {
  const StartWorkoutCard({super.key, this.todaysPlannedWorkouts = const []});

  /// Planned workouts scheduled for today (not yet completed).
  final List<domain.PlannedWorkout> todaysPlannedWorkouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);

    if (activeWorkout != null && activeWorkout.isActive) {
      return _buildRunningCard(context, ref, l10n, theme, activeWorkout);
    }

    return _buildStartCard(context, ref, l10n, theme);
  }

  Widget _buildRunningCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    domain.Workout workout,
  ) {
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.workoutInProgress,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workout.name,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.exercisesCount(workout.entries.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: Text(l10n.viewWorkout),
                    onPressed: () => context.push('/current-seance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.stopWorkout),
                    onPressed: () => ref
                        .read(activeWorkoutProvider.notifier)
                        .cancelWorkout(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final hasPlan = todaysPlannedWorkouts.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasPlan ? l10n.followTodaysPlan : l10n.startWorkout,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      hasPlan ? Icons.calendar_today : Icons.play_arrow,
                    ),
                    label: Text(
                      hasPlan ? l10n.followTodaysPlan : l10n.startWorkout,
                    ),
                    onPressed: () {
                      if (hasPlan) {
                        final plan = todaysPlannedWorkouts.first;
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .startWorkoutFromPlanned(plan);
                      } else {
                        ref.read(activeWorkoutProvider.notifier).startWorkout();
                      }
                      context.push('/current-seance');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
