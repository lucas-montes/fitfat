import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart' as domain;

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({required this.workout, super.key});

  final domain.Workout workout;

  int get _totalSets =>
      workout.entries.fold(0, (sum, e) => sum + e.sets.length);

  int get _totalReps => workout.entries.fold(0, (sum, e) => sum + e.totalReps);

  double get _totalVolume => workout.entries.fold<double>(
    0,
    (sum, entry) =>
        sum +
        entry.sets.fold<double>(0, (s, set) => s + (set.reps * set.weightKg)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = workout.duration;

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
                    workout.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _statRow(l10n.duration, _formatDuration(duration)),
                  if (_totalSets > 0) _statRow(l10n.sets, '$_totalSets'),
                  if (_totalReps > 0) _statRow(l10n.totalReps, '$_totalReps'),
                  if (_totalVolume > 0)
                    _statRow(
                      l10n.totalVolume,
                      '${_totalVolume.toStringAsFixed(0)} kg',
                    ),
                  if (workout.totalCardioMinutes > 0)
                    _statRow(
                      l10n.duration,
                      '${workout.totalCardioMinutes} min cardio',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercise breakdown
          Text(
            l10n.exerciseBreakdown,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...workout.entries.map((entry) {
            final isCardio = entry.cardioDetail != null;
            final summary = isCardio
                ? '${entry.cardioDetail!.durationMinutes} min'
                : '${entry.sets.length} ${l10n.setsLower} · '
                      '${entry.totalReps} ${l10n.repsLower} · '
                      '${entry.totalWeight.toStringAsFixed(0)} kg';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  isCardio ? Icons.directions_run : Icons.fitness_center,
                ),
                title: Text(entry.exercise.name),
                subtitle: Text(summary),
              ),
            );
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.finish),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
