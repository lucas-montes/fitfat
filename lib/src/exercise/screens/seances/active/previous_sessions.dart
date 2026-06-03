import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../providers/seances/history.dart';

class PreviousSessionsPanel extends ConsumerWidget {
  const PreviousSessionsPanel({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(seanceHistoryProvider);
    final relatedSeances =
        history
            .where(
              (s) =>
                  s.completedAt != null &&
                  s.exercises.any((e) => e.exercise.name == exerciseName),
            )
            .toList()
          ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    final recent = relatedSeances.take(5).toList();

    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        title: Text(
          l10n.previousSessions(recent.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(l10n.tapToExpand),
        initiallyExpanded: false,
        children: recent.map((s) {
          final entry = s.exercises.firstWhere(
            (e) => e.exercise.name == exerciseName,
          );
          final dateStr =
              '${s.completedAt!.day.toString().padLeft(2, '0')}/'
              '${s.completedAt!.month.toString().padLeft(2, '0')}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...entry.sets.map(
                      (set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
