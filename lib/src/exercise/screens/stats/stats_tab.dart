import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../../exercise/providers/history_provider.dart';
import '../../../models/workout.dart' as domain;
import 'stat_item.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final workouts = ref.watch(workoutHistoryProvider);

    // Compute all-time stats from new model
    final totalWorkouts = workouts.length;
    final totalVolume = workouts.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );
    final totalMinutes = workouts.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );
    final totalCardioMinutes = workouts.fold<int>(
      0,
      (sum, w) => sum + w.totalCardioMinutes,
    );

    // Compute this-week stats
    final now = DateTime.now();
    final weekStart = now.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final thisWeek = workouts.where((w) {
      final t = w.endTime ?? w.startTime;
      return !t.isBefore(weekStart);
    }).toList();
    final weekVolume = thisWeek.fold<double>(
      0,
      (sum, w) => sum + w.totalVolume,
    );
    final weekDuration = thisWeek.fold<int>(
      0,
      (sum, w) => sum + w.duration.inMinutes,
    );

    // Build 84-day summaries for the heatmap
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
                if (totalCardioMinutes > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatItem(
                        icon: Icons.directions_run,
                        label: l10n.cardio,
                        value: '${totalCardioMinutes}m',
                      ),
                    ],
                  ),
                ],
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
          weekVolume: weekVolume,
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
            (max, d) => d.volume > max ? d.volume : max,
          ),
        ),
        const SizedBox(height: 16),

        // Trends
        Text(l10n.trends, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _CardioByWeekCard(workouts: workouts),
        const SizedBox(height: 16),
        _VolumeByExerciseCard(workouts: workouts),
      ],
    );
  }

  List<_HeatmapDay> _buildHeatmapDays(
    List<domain.Workout> workouts,
    DateTime startDate,
  ) {
    final days = <_HeatmapDay>[];
    for (var i = 0; i < 84; i++) {
      final date = startDate.add(Duration(days: i));
      final dayWorkouts = workouts.where((w) {
        final t = w.endTime ?? w.startTime;
        return t.year == date.year &&
            t.month == date.month &&
            t.day == date.day;
      }).toList();

      days.add(
        _HeatmapDay(
          date: date,
          volume: dayWorkouts.fold<double>(0, (sum, w) => sum + w.totalVolume),
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

// ---------------------------------------------------------------------------
// Internal data class for heatmap days
// ---------------------------------------------------------------------------
class _HeatmapDay {
  const _HeatmapDay({
    required this.date,
    required this.volume,
    required this.hasWorkout,
    required this.workouts,
    required this.duration,
  });

  final DateTime date;
  final double volume;
  final bool hasWorkout;
  final List<domain.Workout> workouts;
  final Duration duration;
}

// ---------------------------------------------------------------------------
// This-week stats card
// ---------------------------------------------------------------------------
class _WeekStatsCard extends StatelessWidget {
  const _WeekStatsCard({
    required this.weekSessions,
    required this.weekVolume,
    required this.weekDuration,
  });

  final int weekSessions;
  final double weekVolume;
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
            label: l10n.volume,
            value: '${weekVolume.toStringAsFixed(0)} kg',
            icon: Icons.fitness_center,
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

// ---------------------------------------------------------------------------
// Heatmap grid (84-day activity grid)
// ---------------------------------------------------------------------------
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
                      '${day.volume.toStringAsFixed(0)} kg',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showDayDetail(context, day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _heatmapColor(
                          context,
                          day.volume,
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
                  '${day.volume.toStringAsFixed(0)} kg · '
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
                        leading: Icon(
                          w.totalCardioMinutes > 0
                              ? Icons.directions_run
                              : Icons.fitness_center,
                        ),
                        title: Text(w.name),
                        subtitle: Text(
                          '${DateFormat('HH:mm').format(w.endTime ?? w.startTime)} · '
                          '${w.entries.length} ${l10n.exercises} · '
                          '${_formatDuration(w.duration)}',
                        ),
                        trailing: Text(
                          _formatVolume(
                            w.totalCardioMinutes > 0
                                ? w.totalCardioMinutes.toDouble()
                                : w.totalVolume,
                          ),
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

  String _formatVolume(double volume) => '${volume.toStringAsFixed(0)} kg';

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes}m';
  }
}

// ---------------------------------------------------------------------------
// Heatmap legend dot
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// Cardio by week chart
// ---------------------------------------------------------------------------
class _CardioByWeekCard extends StatelessWidget {
  const _CardioByWeekCard({required this.workouts});

  final List<domain.Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Compute cardio minutes per week
    final cardioByWeek = <String, int>{};
    for (final w in workouts) {
      if (w.totalCardioMinutes <= 0) continue;
      final weekKey = _isoWeekKey(w.endTime ?? w.startTime);
      cardioByWeek.update(
        weekKey,
        (v) => v + w.totalCardioMinutes,
        ifAbsent: () => w.totalCardioMinutes,
      );
    }

    if (cardioByWeek.isEmpty) return const SizedBox.shrink();

    // Sort weeks descending
    final sortedWeeks = cardioByWeek.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final recentWeeks = sortedWeeks.take(8).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.cardio} ${l10n.thisWeek}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...recentWeeks.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(entry.key, style: theme.textTheme.bodySmall),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (entry.value / 300.0).clamp(0.0, 1.0),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}m', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _isoWeekKey(DateTime date) {
    final dayOfYear = int.parse(
      DateUtils.dateOnly(
        date,
      ).difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    final weekNumber = ((dayOfYear - date.weekday + 10) / 7).floor();
    return 'W${weekNumber.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Volume by exercise card
// ---------------------------------------------------------------------------
class _VolumeByExerciseCard extends StatelessWidget {
  const _VolumeByExerciseCard({required this.workouts});

  final List<domain.Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Compute volume per exercise
    final volByExercise = <String, double>{};
    for (final w in workouts) {
      for (final entry in w.entries) {
        if (entry.cardioDetail != null) continue;
        final vol = entry.totalWeight;
        if (vol > 0) {
          volByExercise.update(
            entry.exercise.name,
            (v) => v + vol,
            ifAbsent: () => vol,
          );
        }
      }
    }

    if (volByExercise.isEmpty) return const SizedBox.shrink();

    // Top 10 exercises by volume
    final topExercises = volByExercise.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = topExercises.take(10).toList();
    final maxVol = top10.first.value;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.volumeProgression, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...top10.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (entry.value / maxVol).clamp(0.0, 1.0),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(
                        '${entry.value.toStringAsFixed(0)} kg',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
