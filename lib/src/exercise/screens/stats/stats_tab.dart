import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../providers/workout_history.dart';
import '../../../models/workout.dart';
import 'stat_item.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutHistoryProvider);

    return workoutsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (workouts) => _StatsContent(workouts: workouts),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final totalWorkouts = workouts.length;
    final totalMinutes = workouts.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );

    // Compute this-week stats
    final now = DateTime.now();
    final weekStart = now.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );

    final thisWeek = workouts.where((w) {
      final t = w.completedAt ?? w.startedAt;
      if (t == null) return false;
      return !t.isBefore(weekStart);
    }).toList();

    final weekDuration = thisWeek.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );

    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 83));
    final heatmapDays = _buildHeatmapDays(workouts, startDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // All-time overview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.allTime, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StatItem(
                      icon: Icons.fitness_center,
                      label: l10n.workouts,
                      value: '$totalWorkouts',
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
        Text(l10n.thisWeek, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _WeekStatsCard(
          weekSessions: thisWeek.length,
          weekDuration: weekDuration,
        ),
        const SizedBox(height: 16),

        // Heatmap
        Text(l10n.activity, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _HeatmapGrid(
          days: heatmapDays,
          maxVolume: heatmapDays.fold<double>(
            0,
            (max, d) => d.hasWorkout && d.duration.inMinutes > max
                ? d.duration.inMinutes.toDouble()
                : max,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<_HeatmapDay> _buildHeatmapDays(
    List<Workout> workouts,
    DateTime startDate,
  ) {
    final days = <_HeatmapDay>[];
    for (var i = 0; i < 84; i++) {
      final date = startDate.add(Duration(days: i));
      final dayWorkouts = workouts.where((w) {
        final t = w.completedAt ?? w.startedAt;
        if (t == null) return false;
        return t.year == date.year &&
            t.month == date.month &&
            t.day == date.day;
      }).toList();

      days.add(
        _HeatmapDay(
          date: date,
          hasWorkout: dayWorkouts.isNotEmpty,
          workouts: dayWorkouts,
          duration: dayWorkouts.fold<Duration>(
            Duration.zero,
            (sum, w) => sum + w.duration,
          ),
        ),
      );
    }
    return days;
  }
}

class _HeatmapDay {
  const _HeatmapDay({
    required this.date,
    required this.hasWorkout,
    required this.workouts,
    required this.duration,
  });

  final DateTime date;
  final bool hasWorkout;
  final List<Workout> workouts;
  final Duration duration;
}

class _WeekStatsCard extends StatelessWidget {
  const _WeekStatsCard({
    required this.weekSessions,
    required this.weekDuration,
  });

  final int weekSessions;
  final int weekDuration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatCard(
            label: l10n.thisWeek,
            value: '$weekSessions',
            icon: Icons.calendar_view_week,
          ),
          _StatCard(
            label: l10n.duration,
            value: '${weekDuration}m',
            icon: Icons.timer,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 3,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days, required this.maxVolume});

  final List<_HeatmapDay> days;
  final double maxVolume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.trainingHeatmap,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.last84Days,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekdayLabels
                  .map(
                    (label) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(label, style: theme.textTheme.bodySmall),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                return Tooltip(
                  message:
                      '${DateFormat('EEE, MMM d').format(day.date)} · '
                      '${day.duration.inMinutes} min',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: day.hasWorkout
                        ? () => _showDayDetail(context, day)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _heatmapColor(
                          context,
                          day.duration.inMinutes.toDouble(),
                          maxVolume,
                          day.hasWorkout,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d').format(day.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: day.hasWorkout
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LegendDot(
                  color: _heatmapColor(context, 0, maxVolume, false),
                  label: '0',
                ),
                _LegendDot(
                  color: _heatmapColor(
                    context,
                    maxVolume * 0.33,
                    maxVolume,
                    true,
                  ),
                  label: l10n.heatmapLegendLow,
                ),
                _LegendDot(
                  color: _heatmapColor(
                    context,
                    maxVolume * 0.66,
                    maxVolume,
                    true,
                  ),
                  label: l10n.heatmapLegendMid,
                ),
                _LegendDot(
                  color: _heatmapColor(context, maxVolume, maxVolume, true),
                  label: l10n.heatmapLegendHigh,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _heatmapColor(
    BuildContext context,
    double volume,
    double maxVolume,
    bool hasWorkout,
  ) {
    final theme = Theme.of(context);
    if (!hasWorkout || maxVolume <= 0) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    final normalized = (volume / maxVolume).clamp(0.0, 1.0);
    return Color.lerp(
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.primary,
          0.15 + (normalized * 0.85),
        ) ??
        theme.colorScheme.primary;
  }

  void _showDayDetail(BuildContext context, _HeatmapDay day) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(day.date),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${day.workouts.length} ${l10n.workouts} · '
                  '${_formatDuration(day.duration)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (day.workouts.isEmpty)
                  Text(
                    l10n.noTrainingRecorded,
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  ...day.workouts.map(
                    (w) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(w.name),
                        subtitle: Text(
                          '${DateFormat('HH:mm').format(w.completedAt ?? w.startedAt ?? now)} · '
                          '${_formatDuration(w.duration)}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime get now => DateTime.now();

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
