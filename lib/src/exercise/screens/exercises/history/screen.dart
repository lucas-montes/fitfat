import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart';
import '../../../providers/exercise_history.dart';
import 'summary_card.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({required this.exercise, super.key});

  final ExerciseDefinition exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(exerciseHistoryProvider(exercise.id));

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (data) {
          if (data.sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noHistory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noHistoryContent,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              SummaryCard(
                sessionsCount: data.sessionsCount,
                totalVolume: data.totalVolume,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.history,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              for (final session in data.sessions)
                _SessionCard(session: session),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final ExerciseHistorySession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr =
        '${session.date.day.toString().padLeft(2, '0')}/'
        '${session.date.month.toString().padLeft(2, '0')}/'
        '${session.date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.workoutName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            for (final set in session.sets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${set.effectiveReps} × ${set.effectiveWeightKg.toStringAsFixed(1)} kg'
                  '${set.isCompleted ? '' : ' (planned)'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (session.sets.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l10n.volume}: ${session.sets.fold<double>(0, (sum, s) => sum + s.totalWeight).toStringAsFixed(0)} kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
