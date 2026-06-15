import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../models/workout.dart' as domain;

/// Card displaying a single completed [domain.Workout] in history lists.
class WorkoutHistoryCard extends ConsumerWidget {
  const WorkoutHistoryCard({super.key, required this.workout});

  final domain.Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(workout.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Flexible(
                  child: Text(
                    workout.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _sourceIcon(context, workout.source),
              ],
            ),
            const SizedBox(height: 8),
            if (workout.entries.isEmpty)
              Text(
                l10n.noExercises,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...workout.entries.map((entry) {
                final isCardio = entry.cardioDetail != null;
                final summary = isCardio
                    ? '${entry.cardioDetail!.durationMinutes} min'
                    : entry.sets
                          .map(
                            (s) => '${s.reps}×${s.weightKg.toStringAsFixed(0)}',
                          )
                          .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.exercise.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (summary.isNotEmpty)
                        Flexible(
                          child: Text(
                            summary,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            if (workout.endTime != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDuration(workout.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns a small source-indicator icon for the given [source] value.
  /// - `quick_log` → amber lightning bolt
  /// - `coach`    → primary-colored school/book icon
  /// - otherwise  → grey edit icon
  Widget _sourceIcon(BuildContext context, String source) {
    IconData icon;
    Color color;
    String tooltip;

    switch (source) {
      case 'quick_log':
        icon = Icons.flash_on;
        color = Colors.amber;
        tooltip = 'Quick logged';
      case 'coach':
        icon = Icons.school;
        color = Theme.of(context).colorScheme.primary;
        tooltip = 'From coach';
      default:
        icon = Icons.edit_note;
        color = Colors.grey;
        tooltip = 'Manual';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }
}
