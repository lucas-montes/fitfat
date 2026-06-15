import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../exercise/providers/planned_workout_provider.dart';
import '../../../exercise/providers/workout_provider.dart';
import '../../../models/workout.dart' as domain;
import 'create_planned_screen.dart';

/// Bottom sheet shown when the user taps a day on the calendar strip.
///
/// Displays planned workouts for that day with Start / Edit / Delete actions,
/// or an "Add planned workout" CTA if none exist.
class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({
    super.key,
    required this.date,
    required this.plannedWorkouts,
  });

  final DateTime date;
  final List<domain.PlannedWorkout> plannedWorkouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date header
          Text(dateStr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),

          if (plannedWorkouts.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.noPlannedWorkoutsForDay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addPlannedWorkout),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreatePlannedScreen(scheduledDate: date),
                    ),
                  );
                },
              ),
            ),
          ] else
            ...plannedWorkouts.map((plan) {
              final isCardio = plan.entries.any((e) => e.plannedCardio != null);
              final entrySummary = isCardio
                  ? l10n.cardio
                  : l10n.exercisesCount(plan.entries.length);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (plan.source == 'coach')
                            _sourceChip(
                              context: context,
                              icon: Icons.school,
                              label: 'From coach',
                              color: theme.colorScheme.primary,
                            ),
                          if (plan.source == 'from_template')
                            _sourceChip(
                              context: context,
                              icon: Icons.description,
                              label: 'From template',
                              color: theme.colorScheme.secondary,
                            ),
                          if (plan.isCompleted)
                            Chip(
                              label: Text(
                                l10n.completed,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.green.shade50,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(entrySummary, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      if (plan.isCompleted)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.close),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: Text(l10n.startPlan),
                                onPressed: () {
                                  if (plan.isCompleted) return;
                                  ref
                                      .read(activeWorkoutProvider.notifier)
                                      .startWorkoutFromPlanned(plan);
                                  Navigator.of(context).pop();
                                  context.push('/current-seance');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CreatePlannedScreen(
                                      scheduledDate: date,
                                      plannedWorkout: plan,
                                    ),
                                  ),
                                );
                              },
                              child: Text(l10n.edit),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.deletePlannedWorkout),
                                    content: Text(
                                      l10n.deletePlannedWorkoutContent,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: Text(l10n.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: Text(l10n.delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await ref
                                      .read(plannedWorkoutProvider.notifier)
                                      .deletePlannedWorkout(plan.id);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              },
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// A small compact chip showing a source-badge icon and label.
Widget _sourceChip({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
