import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';

/// A horizontal card in the upcoming workouts carousel.
///
/// Shows the day label, date, workout name, and a "Start" prompt.
class UpcomingCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Workout workout;
  final VoidCallback onTap;

  const UpcomingCard({
    super.key,
    required this.l10n,
    required this.workout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = workout.scheduledDate!;
    final dayLabel = DateFormat('E').format(date);
    final dateLabel = DateFormat('MMM d').format(date);

    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  workout.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.startWorkout,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
