import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';
import 'elapsed_timer_widget.dart';

/// Card shown at the top of the training list tab.
///
/// Displays one of three states:
/// - Active workout with resume button + live elapsed timer
/// - Today's scheduled workout with start button
/// - Empty state with free-form start button
class TodayCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Workout? activeWorkout;
  final Workout? todayWorkout;
  final VoidCallback onResumeActive;
  final void Function(String id) onStartScheduled;
  final VoidCallback onStartFreeform;

  const TodayCard({
    super.key,
    required this.l10n,
    this.activeWorkout,
    this.todayWorkout,
    required this.onResumeActive,
    required this.onStartScheduled,
    required this.onStartFreeform,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeWorkout != null && activeWorkout!.isActive) ...[
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWorkout!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        ElapsedTimerWidget(
                          startedAt: activeWorkout!.startedAt!,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onResumeActive,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.resumeWorkout),
                ),
              ),
            ] else if (todayWorkout != null) ...[
              Row(
                children: [
                  const Icon(Icons.fitness_center, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayWorkout!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.today} · ${DateFormat('HH:mm').format(todayWorkout!.scheduledDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onStartScheduled(todayWorkout!.id),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startWorkout),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 28,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noPlannedWorkoutsForDay,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onStartFreeform,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.startBlankSeance),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
