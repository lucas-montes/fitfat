import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'stat_item.dart';
import '../../../dashboard/providers/dashboard.dart';
import '../../../dashboard/screens/main.dart' as dashboard;

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final daySummaries = ref.watch(workoutDaySummariesProvider);

    final totalWorkouts = daySummaries.fold<int>(
      0,
      (sum, day) => sum + (day.hasWorkout ? 1 : 0),
    );
    final totalVolume = daySummaries.fold<double>(
      0,
      (sum, day) => sum + day.volume,
    );
    final totalDuration = daySummaries.fold<Duration>(
      Duration.zero,
      (sum, day) => sum + day.duration,
    );
    final totalMinutes = totalDuration.inMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Overview stats row
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.allTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StatItem(
                      icon: Icons.fitness_center,
                      label: l10n.workouts,
                      value: '$totalWorkouts',
                    ),
                    StatItem(
                      icon: Icons.monitor_weight,
                      label: l10n.volume,
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                    ),
                    StatItem(
                      icon: Icons.timer,
                      label: l10n.duration,
                      value: '${totalMinutes}m',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // This week
        Text(l10n.thisWeek, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const dashboard.WorkoutStatsRow(),
        const SizedBox(height: 16),
        // Heatmap
        Text(l10n.activity, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const dashboard.WorkoutHeatmapCard(),
        const SizedBox(height: 16),
        // Charts
        Text(l10n.trends, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        dashboard.StrengthTrendChart(),
        const SizedBox(height: 16),
        dashboard.BodyweightTrendChart(),
      ],
    );
  }
}
