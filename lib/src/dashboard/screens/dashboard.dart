import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/dashboard.dart';

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final caloriesAsync = ref.watch(todayCaloriesProvider);
    final latestAsync = ref.watch(latestWorkoutProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardAppBar)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's Calories card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dashboardTodayCalories,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  caloriesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text(l10n.dashboardError('$e')),
                    data: (cal) => Text(
                      l10n.dashboardCaloriesValue(cal.toStringAsFixed(0)),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Latest Workout card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.dashboardLatestWorkout,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  latestAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text(l10n.dashboardError('$e')),
                    data: (workout) {
                      if (workout == null) {
                        return Text(
                          l10n.dashboardNoWorkouts,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      final dateStr =
                          '${workout.date.day.toString().padLeft(2, '0')}.'
                          '${workout.date.month.toString().padLeft(2, '0')}.'
                          '${workout.date.year}';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (workout.duration > Duration.zero) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.dashboardDurationMin(
                                workout.duration.inMinutes,
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
