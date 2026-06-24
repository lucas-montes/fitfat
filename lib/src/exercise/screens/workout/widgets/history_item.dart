import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../models/workout.dart';

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) {
    return '${h}h ${m}min';
  }
  return '${m}min';
}

/// A card showing a completed workout in the history list.
///
/// Displays the workout name, completion date, and duration.
/// Tapping navigates to the workout history detail screen.
class HistoryItem extends StatelessWidget {
  final Workout workout;

  const HistoryItem({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEE, MMM d',
    ).format(workout.completedAt ?? workout.startedAt!);
    final dur = workout.duration;
    final durationStr = _formatDuration(dur);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(workout.name),
        subtitle: Text('$dateStr · $durationStr'),
        onTap: () => context.push('/workout-history/${workout.id}'),
      ),
    );
  }
}
