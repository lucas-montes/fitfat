import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/exercise.dart';

class SeanceSummaryScreen extends StatelessWidget {
  const SeanceSummaryScreen({required this.seance, super.key});

  final Seance seance;

  int get _totalSets =>
      seance.exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get _totalReps => seance.exercises.fold(0, (sum, e) => sum + e.totalReps);

  double get _totalVolume => seance.exercises.fold<double>(
    0,
    (sum, entry) =>
        sum +
        entry.sets.fold<double>(0, (s, set) => s + (set.reps * set.weight)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = seance.duration;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutSummary),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card — totals at a glance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seance.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryStat(
                        label: l10n.duration,
                        value:
                            '${duration.inHours}h ${(duration.inMinutes % 60)}m',
                      ),
                      _SummaryStat(
                        label: l10n.exercises,
                        value: '${seance.exercises.length}',
                      ),
                      _SummaryStat(label: l10n.sets, value: '$_totalSets'),
                      _SummaryStat(
                        label: l10n.volume,
                        value: '${_totalVolume.toStringAsFixed(0)} kg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${l10n.totalReps}: $_totalReps',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Per-exercise breakdown
          Text(
            l10n.exerciseBreakdown,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...seance.exercises.map((entry) {
            final exSets = entry.sets.length;
            final exReps = entry.totalReps;
            final exVolume = entry.sets.fold<double>(
              0,
              (s, set) => s + (set.reps * set.weight),
            );
            final bestSet = entry.sets.isEmpty
                ? null
                : entry.sets.reduce(
                    (a, b) => (a.weight * a.reps) > (b.weight * b.reps) ? a : b,
                  );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.exercise.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (bestSet != null &&
                            (bestSet.weight * bestSet.reps) > 0)
                          Chip(
                            label: Text(l10n.best),
                            avatar: const Icon(Icons.emoji_events, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$exSets ${l10n.setsLower} · $exReps ${l10n.repsLower}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${exVolume.toStringAsFixed(0)} kg',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (bestSet != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${l10n.best}: ${bestSet.reps}x${bestSet.weight.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle),
              label: Text(l10n.finish),
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) =>
                      route.isFirst || route.settings.name == '/exercise',
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
