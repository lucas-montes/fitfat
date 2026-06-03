import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/exercise.dart';
import '../../../services/workout_services.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.seances,
    required this.service,
    required this.exerciseName,
  });

  final List<Seance> seances;
  final ProgressionService service;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalSessions = seances.length;
    final totalVolume = seances.fold<double>(
      0,
      (sum, s) =>
          sum +
          service.totalVolume(
            s.exercises.firstWhere((e) => e.exercise.name == exerciseName).sets,
          ),
    );
    final totalMinutes = seances.fold<int>(
      0,
      (sum, s) => sum + (s.completedAt!.difference(s.startedAt).inMinutes),
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: l10n.sessions, value: '$totalSessions'),
            _Stat(
              label: l10n.volume,
              value: '${totalVolume.toStringAsFixed(0)} kg',
            ),
            _Stat(label: l10n.time, value: '$totalMinutes min'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

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
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
