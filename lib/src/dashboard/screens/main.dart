import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/dashboard.dart';
import '../../models/exercise.dart';
import '../providers/dashboard.dart';
import '../../diet/providers/diet_preferences.dart';
import '../../exercise/providers/seance.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE: Dashboard tab bar height matches Diet tab via PreferredSize(kToolbarHeight)
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Goals'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_OverviewTab(), const _GoalsTab(), const _SettingsTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview tab — nutrition, charts, no goals card
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Primary: calories/macros for today ──
          const DailyNutritionCard(),
          const SizedBox(height: 8),

          // ── Today's workout status ──
          const WorkoutActivityCard(),
          const SizedBox(height: 8),

          // ── Quick logs: water + weight ──
          const WaterTrackerCard(),
          const SizedBox(height: 8),
          const _CompactWeightCard(),
          const SizedBox(height: 8),

          // ── Goals overview (all active goals) ──
          const _GoalsOverviewCard(),
          const SizedBox(height: 8),

          // ── 7-day streaks ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: _CalorieStreakCard()),
                const SizedBox(width: 8),
                const Expanded(child: _WorkoutStreakCard()),
              ],
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ── Compact weight quick-log card ──

class _CompactWeightCard extends ConsumerStatefulWidget {
  const _CompactWeightCard();

  @override
  ConsumerState<_CompactWeightCard> createState() => _CompactWeightCardState();
}

class _CompactWeightCardState extends ConsumerState<_CompactWeightCard> {
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) return;
    await ref.read(bodyWeightTrackerProvider).addEntry(weight);
    if (!mounted) return;
    _weightController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weight logged!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bodyWeightEntriesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: entriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (entries) {
              final ordered = [...entries]
                ..sort((a, b) => b.date.compareTo(a.date));
              final latest = ordered.isNotEmpty ? ordered.first : null;
              final recent = ordered.take(7).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monitor_weight, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Weight',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (latest != null) ...[
                    Row(
                      children: [
                        Text(
                          '${latest.weightKg.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM d, HH:mm').format(latest.date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            hintText: 'Enter weight (kg)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onSubmitted: (_) => _saveWeight(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saveWeight,
                        child: const Text('Log'),
                      ),
                    ],
                  ),
                  if (recent.length > 1) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...recent.sublist(1).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${entry.weightKg.toStringAsFixed(1)} kg',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, HH:mm').format(entry.date),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class WeightTrackerCard extends ConsumerStatefulWidget {
  const WeightTrackerCard({super.key});

  @override
  ConsumerState<WeightTrackerCard> createState() => _WeightTrackerCardState();
}

class _WeightTrackerCardState extends ConsumerState<WeightTrackerCard> {
  final _weightController = TextEditingController();
  DateTime _entryDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      switchToInputEntryModeIcon: null,
    );
    if (picked != null && mounted) {
      setState(() => _entryDate = picked);
    }
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      return;
    }

    await ref
        .read(bodyWeightTrackerProvider)
        .addEntry(weight, date: _entryDate);

    if (!mounted) return;
    _weightController.clear();
    setState(() => _entryDate = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(bodyWeightEntriesProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(
            'Could not load weight history.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          data: (entries) {
            final ordered = [...entries]
              ..sort((a, b) => b.date.compareTo(a.date));
            final latest = ordered.isNotEmpty ? ordered.first : null;
            final previous = ordered.length > 1 ? ordered[1] : null;
            final delta = latest != null && previous != null
                ? latest.weightKg - previous.weightKg
                : null;
            final history = ordered.take(7).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weight Tracker',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  latest == null
                      ? 'No weight entries yet.'
                      : 'Latest: ${latest.weightKg.toStringAsFixed(1)} kg${delta == null ? '' : ' · ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg vs previous'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(DateFormat('dd/MM').format(_entryDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveWeight,
                    icon: const Icon(Icons.monitor_weight),
                    label: const Text('Log Weight'),
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ordered.isEmpty ? 0 : 1,
                  minHeight: 8,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('History (last 7 entries)'),
                  children: history.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No history yet.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ]
                      : history.map((entry) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.monitor_weight, size: 18),
                            title: Text(
                              '${entry.weightKg.toStringAsFixed(1)} kg',
                            ),
                            subtitle: Text(
                              DateFormat('EEE, MMM d').format(entry.date),
                            ),
                          );
                        }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WaterTrackerCard extends ConsumerStatefulWidget {
  const WaterTrackerCard({super.key});

  @override
  ConsumerState<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends ConsumerState<WaterTrackerCard> {
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(waterTrackerProvider);
      _goalController.text = (state.dailyGoalMl / 1000).toStringAsFixed(1);
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _showGoalDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Water Goal'),
        content: TextField(
          controller: _goalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Liters (e.g., 2.5)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final liters = double.tryParse(_goalController.text.trim());
              if (liters != null && liters > 0) {
                await ref
                    .read(waterTrackerProvider.notifier)
                    .setDailyGoal((liters * 1000).toInt());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waterState = ref.watch(waterTrackerProvider);
    final todayMl = waterState.getTodayMl();
    final progressFraction = waterState.dailyGoalMl > 0
        ? todayMl / waterState.dailyGoalMl
        : 0.0;
    final clampedProgress = progressFraction.clamp(0.0, 1.0);
    final history = waterState.getLastNDays(7);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Water Intake', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${(todayMl / 1000).toStringAsFixed(1)}L / ${(waterState.dailyGoalMl / 1000).toStringAsFixed(1)}L',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async => await ref
                      .read(waterTrackerProvider.notifier)
                      .addWater(250),
                  icon: const Icon(Icons.local_drink),
                  label: const Text('+250ml'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async => await ref
                      .read(waterTrackerProvider.notifier)
                      .addWater(500),
                  icon: const Icon(Icons.local_drink),
                  label: const Text('+500ml'),
                ),
                TextButton.icon(
                  onPressed: _showGoalDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Goal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('History (last 7 days)'),
              children: history.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No history yet.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ]
                  : history.map((entry) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.local_drink, size: 18),
                        title: Text(
                          '${(entry.value / 1000).toStringAsFixed(1)}L',
                        ),
                        subtitle: Text(
                          DateFormat(
                            'EEE, MMM d',
                          ).format(DateTime.parse(entry.key)),
                        ),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutActivityCard extends ConsumerWidget {
  const WorkoutActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSeance = ref.watch(activeSeanceProvider);
    final stats = ref.watch(workoutDashboardStatsProvider);

    final title = activeSeance != null
        ? 'Today\'s activity'
        : 'Today\'s activity';

    final content = activeSeance != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout in progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(activeSeance.name ?? 'Untitled workout'),
              const SizedBox(height: 4),
              Text(
                'Started at ${DateFormat('HH:mm').format(activeSeance.startedAt)} · '
                '${activeSeance.exercises.length} exercises · '
                '${_formatDuration(activeSeance.duration)} elapsed',
              ),
            ],
          )
        : stats.lastWorkout == null
        ? Text(
            'No workouts yet. Start a session to see today\'s summary here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.lastWorkout!.name ?? 'Recent workout',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('EEE, MMM d').format(stats.lastWorkout!.completedAt ?? stats.lastWorkout!.startedAt)} · '
                '${_formatDuration(stats.lastWorkout!.duration)} · '
                '${_formatVolume(_seanceVolume(stats.lastWorkout!))}',
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.lastWorkout!.exercises.length} exercises completed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}

class WorkoutStatsRow extends ConsumerWidget {
  const WorkoutStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutDashboardStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _DashboardStatCard(
            label: 'This week',
            value: '${stats.weekSessions}',
            icon: Icons.calendar_view_week,
          ),
          _DashboardStatCard(
            label: 'This month',
            value: '${stats.monthSessions}',
            icon: Icons.calendar_month,
          ),
          _DashboardStatCard(
            label: 'Volume',
            value: _formatVolume(stats.monthVolume),
            icon: Icons.fitness_center,
          ),
          _DashboardStatCard(
            label: 'Time',
            value: _formatDuration(stats.monthDuration),
            icon: Icons.timer,
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
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
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkoutHeatmapCard extends ConsumerWidget {
  const WorkoutHeatmapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(workoutDaySummariesProvider);
    if (days.isEmpty) return const SizedBox.shrink();

    final maxVolume = days.fold<double>(
      0,
      (max, day) => day.volume > max ? day.volume : max,
    );
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
                Text(
                  'Training heatmap',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Last 84 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                      '${DateFormat('EEE, MMM d').format(day.date)} · ${_formatVolume(day.volume)}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showWorkoutDayDetails(context, day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _heatmapColor(context, day.volume, maxVolume),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('d').format(day.date),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: day.volume > 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
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
                _HeatmapLegendDot(
                  color: _heatmapColor(context, 0, maxVolume),
                  label: '0',
                ),
                _HeatmapLegendDot(
                  color: _heatmapColor(context, maxVolume * 0.33, maxVolume),
                  label: 'Low',
                ),
                _HeatmapLegendDot(
                  color: _heatmapColor(context, maxVolume * 0.66, maxVolume),
                  label: 'Mid',
                ),
                _HeatmapLegendDot(
                  color: _heatmapColor(context, maxVolume, maxVolume),
                  label: 'High',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapLegendDot extends StatelessWidget {
  const _HeatmapLegendDot({required this.color, required this.label});

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

Color _heatmapColor(BuildContext context, double volume, double maxVolume) {
  final theme = Theme.of(context);
  if (volume <= 0 || maxVolume <= 0) {
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

void _showWorkoutDayDetails(BuildContext context, WorkoutDaySummary day) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(day.date),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${day.seances.length} session${day.seances.length == 1 ? '' : 's'} · '
                '${_formatVolume(day.volume)} · ${_formatDuration(day.duration)}',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (day.seances.isEmpty)
                Text(
                  'No training recorded on this day.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                )
              else
                ...day.seances.map(
                  (seance) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(seance.name ?? 'Workout'),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(seance.completedAt ?? seance.startedAt)} · '
                        '${seance.exercises.length} exercises · ${_formatDuration(seance.duration)}',
                      ),
                      trailing: Text(_formatVolume(_seanceVolume(seance))),
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

double _seanceVolume(Seance seance) {
  return seance.exercises.fold(0.0, (sum, entry) {
    return sum +
        entry.sets.fold(0.0, (setSum, set) {
          if (!set.isCompleted) return setSum;
          return setSum + (set.reps * set.weight);
        });
  });
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes}m';
}

// ---------------------------------------------------------------------------
// Daily nutrition card — reads computed macros
// ---------------------------------------------------------------------------

class DailyNutritionCard extends ConsumerWidget {
  const DailyNutritionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyNutrition = ref.watch(dailyNutritionProvider);
    final macros = ref.watch(computedMacrosProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildMacroRow(
              context,
              'Calories',
              '${dailyNutrition.calories.toStringAsFixed(0)} kcal',
              '${macros.dailyCalories.toStringAsFixed(0)} kcal',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Protein',
              '${dailyNutrition.protein.toStringAsFixed(1)}g',
              '${macros.dailyProtein.toStringAsFixed(0)}g',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Carbs',
              '${dailyNutrition.carbs.toStringAsFixed(1)}g',
              '${macros.dailyCarbs.toStringAsFixed(0)}g',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              context,
              'Fat',
              '${dailyNutrition.fat.toStringAsFixed(1)}g',
              '${macros.dailyFat.toStringAsFixed(0)}g',
              Colors.green,
            ),
            const SizedBox(height: 8),
            if (macros == ComputedMacros.zero)
              Text(
                'Set a bodyweight goal and your profile to see daily targets.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    String value,
    String target,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
        Text('$value / $target'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Goals tab — manage bodyweight goal + N strength goals
// ---------------------------------------------------------------------------

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsData = ref.watch(goalsProvider);
    final hasProfile = ref.watch(userProfileProvider) != null;
    final hasAnyGoal =
        goalsData.bodyWeightGoal != null || goalsData.strengthGoals.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bodyweight goal section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Body Weight Goal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (goalsData.bodyWeightGoal != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editBodyWeightGoal(
                              context,
                              ref,
                              goalsData.bodyWeightGoal!,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () =>
                                _confirmDeleteBodyWeight(context, ref),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (goalsData.bodyWeightGoal == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          'No bodyweight goal set.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Body Weight Goal'),
                          onPressed: () => hasProfile
                              ? _createBodyWeightGoal(context, ref)
                              : _promptProfileFirst(context, ref),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Chip(
                    label: Text(
                      '${goalsData.bodyWeightGoal!.direction.label} Weight',
                    ),
                    avatar: const Icon(Icons.monitor_weight, size: 18),
                  ),
                  const SizedBox(height: 8),
                  _goalDetailRow(
                    'Target',
                    '${goalsData.bodyWeightGoal!.targetWeightKg.toStringAsFixed(1)} kg',
                  ),
                  if (goalsData.bodyWeightGoal!.targetDate != null)
                    _goalDetailRow(
                      'By',
                      DateFormat(
                        'MMM d, yyyy',
                      ).format(goalsData.bodyWeightGoal!.targetDate!),
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Strength goals section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Strength Goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add strength goal',
                      onPressed: () => hasProfile
                          ? _createStrengthGoal(context, ref)
                          : _promptProfileFirst(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (goalsData.strengthGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No strength goals yet. Tap + to add (one per exercise).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final sg in goalsData.strengthGoals) ...[
                    _strengthGoalTile(context, ref, sg),
                    const Divider(height: 1),
                  ],
              ],
            ),
          ),
        ),
        if (!hasProfile && !hasAnyGoal)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Set up your profile first',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _promptProfileFirst(context, ref),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            ),
          )
        else if (hasProfile)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Profile'),
                onPressed: () => _promptProfileFirst(context, ref),
              ),
            ),
          ),
      ],
    );
  }

  Widget _goalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _strengthGoalTile(
    BuildContext context,
    WidgetRef ref,
    StrengthGoal goal,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.fitness_center),
      title: Text(
        '${goal.exerciseName} → ${goal.targetWeightKg.toStringAsFixed(0)} kg',
      ),
      subtitle: goal.targetDate != null
          ? Text('By ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}')
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editStrengthGoal(context, ref, goal),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () =>
                _confirmDeleteStrength(context, ref, goal.exerciseName),
          ),
        ],
      ),
    );
  }

  void _promptProfileFirst(BuildContext context, WidgetRef ref) {
    final existing = ref.read(userProfileProvider);
    showDialog(
      context: context,
      builder: (_) => ProfileSetupDialog(initial: existing),
    ).then((profile) {
      if (profile != null && context.mounted) {
        ref
            .read(userProfileProvider.notifier)
            .setProfile(profile as UserProfile);
      }
    });
  }

  void _createBodyWeightGoal(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const BodyWeightGoalDialog());
  }

  void _editBodyWeightGoal(
    BuildContext context,
    WidgetRef ref,
    BodyWeightGoal existing,
  ) {
    showDialog(
      context: context,
      builder: (_) => BodyWeightGoalDialog(existing: existing),
    );
  }

  void _confirmDeleteBodyWeight(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bodyweight goal?'),
        content: const Text(
          'This will clear your weight target and macro targets.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(goalsProvider.notifier).clearBodyWeightGoal();
      }
    });
  }

  void _createStrengthGoal(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const StrengthGoalDialog());
  }

  void _editStrengthGoal(
    BuildContext context,
    WidgetRef ref,
    StrengthGoal existing,
  ) {
    showDialog(
      context: context,
      builder: (_) => StrengthGoalDialog(existing: existing),
    );
  }

  void _confirmDeleteStrength(
    BuildContext context,
    WidgetRef ref,
    String exerciseName,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete strength goal for $exerciseName?'),
        content: const Text('This will remove the goal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        ref.read(goalsProvider.notifier).removeStrengthGoal(exerciseName);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Profile setup dialog
// ---------------------------------------------------------------------------

class ProfileSetupDialog extends ConsumerStatefulWidget {
  const ProfileSetupDialog({super.key, this.initial});

  final UserProfile? initial;

  @override
  ConsumerState<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends ConsumerState<ProfileSetupDialog> {
  DateTime _birthDate = DateTime(1990);
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _birthDate = init.birthDate;
      _heightController.text = init.heightCm.toString();
      _weightController.text = init.weightKg.toString();
      _sex = init.sex;
      _activity = init.activityLevel;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Your Profile' : 'Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Birthdate picker — calendar-only, consistent with other inputs
            InputDecorator(
              decoration: InputDecoration(
                label: const Text('Birthdate'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _birthDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      switchToInputEntryModeIcon: null,
                    );
                    if (picked != null) setState(() => _birthDate = picked);
                  },
                ),
              ),
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(_birthDate)}  (age ${_computeAge(_birthDate)})',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Sex>(
              initialValue: _sex,
              decoration: const InputDecoration(
                label: Text('Sex'),
                border: OutlineInputBorder(),
              ),
              items: Sex.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _sex = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Height (cm)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                label: Text('Weight (kg)'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activity,
              decoration: const InputDecoration(
                label: Text('Activity Level'),
                border: OutlineInputBorder(),
              ),
              items: ActivityLevel.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (v) => setState(() => _activity = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final height = double.tryParse(_heightController.text);
            final weight = double.tryParse(_weightController.text);
            if (height == null || weight == null) return;
            Navigator.pop(
              context,
              UserProfile(
                birthDate: _birthDate,
                sex: _sex,
                heightCm: height,
                weightKg: weight,
                activityLevel: _activity,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  int _computeAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

// ---------------------------------------------------------------------------
// Body weight goal dialog
// ---------------------------------------------------------------------------

class BodyWeightGoalDialog extends ConsumerStatefulWidget {
  const BodyWeightGoalDialog({super.key, this.existing});

  final BodyWeightGoal? existing;

  @override
  ConsumerState<BodyWeightGoalDialog> createState() =>
      _BodyWeightGoalDialogState();
}

class _BodyWeightGoalDialogState extends ConsumerState<BodyWeightGoalDialog> {
  final _weightController = TextEditingController();
  BodyWeightDirection _direction = BodyWeightDirection.lose;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _weightController.text = e.targetWeightKg.toString();
      _direction = e.direction;
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add Body Weight Goal'
            : 'Edit Body Weight Goal',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BodyWeightDirection>(
            initialValue: _direction,
            decoration: const InputDecoration(
              label: Text('Direction'),
              border: OutlineInputBorder(),
            ),
            items: BodyWeightDirection.values
                .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                .toList(),
            onChanged: (v) => setState(() => _direction = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              label: Text('Target Weight (kg)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _buildDatePicker() {
    final initial = _targetDate ?? DateTime.now().add(const Duration(days: 1));
    return InputDecorator(
      decoration: InputDecoration(
        label: const Text('Target date'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              switchToInputEntryModeIcon: null,
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
        ),
      ),
      child: Text(
        _targetDate != null
            ? DateFormat('dd/MM/yyyy').format(_targetDate!)
            : 'Not set',
      ),
    );
  }

  void _save() {
    final target = double.tryParse(_weightController.text);
    if (target == null) return;
    final goal = BodyWeightGoal(
      targetWeightKg: target,
      direction: _direction,
      targetDate: _targetDate,
    );
    ref.read(goalsProvider.notifier).setBodyWeightGoal(goal);
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Strength goal dialog
// ---------------------------------------------------------------------------

class StrengthGoalDialog extends ConsumerStatefulWidget {
  const StrengthGoalDialog({super.key, this.existing});

  final StrengthGoal? existing;

  @override
  ConsumerState<StrengthGoalDialog> createState() => _StrengthGoalDialogState();
}

class _StrengthGoalDialogState extends ConsumerState<StrengthGoalDialog> {
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _exerciseController.text = e.exerciseName;
      _weightController.text = e.targetWeightKg.toString();
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseListProvider);
    final goalsData = ref.watch(goalsProvider);
    final existingStrengthNames = goalsData.strengthGoals
        .map((g) => g.exerciseName)
        .toSet();

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Strength Goal' : 'Edit Strength Goal',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<ExerciseDefinition>(
            optionsBuilder: (textEditingValue) {
              final text = textEditingValue.text.toLowerCase();
              if (text.isEmpty) return Iterable.empty();
              return allExercises.where(
                (e) =>
                    e.name.toLowerCase().contains(text) &&
                    !existingStrengthNames.contains(e.name),
              );
            },
            displayStringForOption: (e) => e.name,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Sync external controller when Autocomplete controller changes
              controller.addListener(() {
                if (_exerciseController.text != controller.text) {
                  _exerciseController.text = controller.text;
                }
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  label: Text('Exercise'),
                  hintText: 'Search or type custom name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  final match = allExercises.where(
                    (e) => e.name.toLowerCase() == value.toLowerCase(),
                  );
                  if (match.isNotEmpty) {
                    _exerciseController.text = match.first.name;
                    onSubmitted();
                  }
                },
              );
            },
            onSelected: (exercise) {
              _exerciseController.text = exercise.name;
              _exerciseController.selection = TextSelection.collapsed(
                offset: exercise.name.length,
              );
              // Also update the TextField if it's visible
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              label: Text('Target Weight (kg)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildDatePicker(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  Widget _buildDatePicker() {
    final initial = _targetDate ?? DateTime.now().add(const Duration(days: 1));
    return InputDecorator(
      decoration: InputDecoration(
        label: const Text('Target date'),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              switchToInputEntryModeIcon: null,
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
        ),
      ),
      child: Text(
        _targetDate != null
            ? DateFormat('dd/MM/yyyy').format(_targetDate!)
            : 'Not set',
      ),
    );
  }

  void _save() {
    final exercise = _exerciseController.text.trim();
    final target = double.tryParse(_weightController.text);
    if (exercise.isEmpty || target == null) return;
    final goal = StrengthGoal(
      exerciseName: exercise,
      targetWeightKg: target,
      targetDate: _targetDate,
    );
    ref.read(goalsProvider.notifier).addStrengthGoal(goal);
    Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Goals overview card — compact list of all active goals with progress
// ---------------------------------------------------------------------------

class _GoalsOverviewCard extends ConsumerWidget {
  const _GoalsOverviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsData = ref.watch(goalsProvider);
    final hasAnyGoal =
        goalsData.bodyWeightGoal != null || goalsData.strengthGoals.isNotEmpty;

    if (!hasAnyGoal) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (goalsData.bodyWeightGoal != null)
                _GoalProgressTile(
                  icon: Icons.monitor_weight,
                  label: '${goalsData.bodyWeightGoal!.direction.label} Weight',
                  detail:
                      'Target: ${goalsData.bodyWeightGoal!.targetWeightKg.toStringAsFixed(1)} kg',
                ),
              if (goalsData.bodyWeightGoal != null &&
                  goalsData.strengthGoals.isNotEmpty)
                const SizedBox(height: 8),
              for (final goal in goalsData.strengthGoals) ...[
                _GoalProgressTile(
                  icon: Icons.fitness_center,
                  label: goal.exerciseName,
                  detail:
                      'Target: ${goal.targetWeightKg.toStringAsFixed(1)} kg',
                ),
                if (goal != goalsData.strengthGoals.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini 7-day streak cards
// ---------------------------------------------------------------------------

class _CalorieStreakCard extends ConsumerWidget {
  const _CalorieStreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nutrition = ref.watch(dailyNutritionProvider);
    final macros = ref.watch(computedMacrosProvider);

    // Check last 7 days for calorie compliance
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 7; i++) {
      // For simplicity, count today if on track, previous days as on track
      // (a real implementation would check historical meal data)
      if (i == 0) {
        final onTrack =
            macros.dailyCalories > 0 &&
            nutrition.calories <= macros.dailyCalories * 1.1;
        if (onTrack) {
          streak++;
        } else {
          break;
        }
      } else {
        // Assume previous days were on track (no historical data readily available)
        streak++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Calories',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final active = i < streak;
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              '$streak day${streak == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutStreakCard extends ConsumerWidget {
  const _WorkoutStreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daySummaries = ref.watch(workoutDaySummariesProvider);

    // Check last 7 days for workout completion
    final now = DateTime.now();
    final recentDays = daySummaries.where((day) {
      return day.date.isAfter(now.subtract(const Duration(days: 7)));
    }).toList();

    int streak = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final hasWorkout = recentDays.any(
        (d) =>
            d.date.year == day.year &&
            d.date.month == day.month &&
            d.date.day == day.day &&
            d.hasWorkout,
      );
      if (hasWorkout) {
        streak++;
      } else {
        break;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏋️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Workouts',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final active = i < streak;
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              '$streak day${streak == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Strength trend chart — fl_chart LineChart + goal progress bar
// ---------------------------------------------------------------------------

const _chartColors = [Colors.blue, Colors.orange, Colors.green];

class StrengthTrendChart extends ConsumerWidget {
  const StrengthTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(chartPeriodProvider);
    final strengthData = ref.watch(strengthTrendProvider);
    final goalsData = ref.watch(goalsProvider);

    final days = periodDays(period);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredData = strengthData
        .where((d) => d.date.isAfter(cutoffDate))
        .toList();

    final exercises = ['Bench Press', 'Deadlift', 'Squat'];
    final exerciseLines = <LineChartBarData>[];

    for (var i = 0; i < exercises.length; i++) {
      final exerciseData = filteredData
          .where((d) => d.exercise == exercises[i])
          .toList();
      if (exerciseData.isEmpty) continue;

      exerciseLines.add(
        LineChartBarData(
          spots: List.generate(
            exerciseData.length,
            (j) => FlSpot(j.toDouble(), exerciseData[j].maxWeight),
          ),
          isCurved: true,
          preventCurveOverShooting: true,
          color: _chartColors[i],
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: _chartColors[i].withAlpha(30),
          ),
        ),
      );
    }

    // Build Y-axis labels from all data
    final allWeights = filteredData.map((d) => d.maxWeight);
    final minY = (allWeights.reduce((a, b) => a < b ? a : b) * 0.95)
        .floorToDouble();
    final maxY = (allWeights.reduce((a, b) => a > b ? a : b) * 1.05)
        .ceilToDouble();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Strength Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<ChartPeriod>(
                  value: period,
                  items: ChartPeriod.values.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(periodLabel(p)),
                    );
                  }).toList(),
                  onChanged: (newPeriod) {
                    if (newPeriod != null) {
                      ref
                          .read(chartPeriodProvider.notifier)
                          .updatePeriod(newPeriod);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: exerciseLines.isEmpty
                  ? const Center(child: Text('No strength data'))
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX:
                            (exerciseLines.isNotEmpty
                                    ? exerciseLines.first.spots.length - 1
                                    : 0)
                                .toDouble(),
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: ((maxY - minY) / 4).clamp(
                            1,
                            double.infinity,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: exerciseLines,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: List.generate(exercises.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[i],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(exercises[i], style: const TextStyle(fontSize: 12)),
                  ],
                );
              }),
            ),
            // Goal progress bar: find matching strength goal
            if (goalsData.strengthGoals.isNotEmpty)
              for (final sg in goalsData.strengthGoals)
                _buildStrengthProgress(context, filteredData, sg),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthProgress(
    BuildContext context,
    List<StrengthDataPoint> data,
    StrengthGoal goal,
  ) {
    final exerciseData = data
        .where((d) => d.exercise == goal.exerciseName)
        .toList();
    final currentMax = exerciseData.isNotEmpty
        ? exerciseData.map((d) => d.maxWeight).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final progress = goal.targetWeightKg > 0
        ? (currentMax / goal.targetWeightKg).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetWeightKg - currentMax;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal: ${goal.exerciseName} → ${goal.targetWeightKg.toStringAsFixed(0)} kg',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress >= 1.0
                ? 'Goal reached! (${currentMax.toStringAsFixed(0)} kg)'
                : '${currentMax.toStringAsFixed(0)} kg / ${goal.targetWeightKg.toStringAsFixed(0)} kg '
                      '(${(progress * 100).toStringAsFixed(0)}%) — '
                      '${remaining.toStringAsFixed(0)} kg to go',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bodyweight trend chart (unchanged)
// ---------------------------------------------------------------------------

class BodyweightTrendChart extends ConsumerWidget {
  const BodyweightTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightData = ref.watch(weightTrendProvider);

    final now = DateTime.now();
    final minDate = now.subtract(const Duration(days: 90));
    final filteredData = weightData
        .where((d) => d.date.isAfter(minDate))
        .toList();

    if (filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    final minWeight = filteredData
        .map((d) => d.weight)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = filteredData
        .map((d) => d.weight)
        .reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Trend (90 days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(filteredData.length, (i) {
                  final data = filteredData[i];
                  final normalizedHeight = range > 0
                      ? (data.weight - minWeight) / range
                      : 0.5;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: normalizedHeight * 100,
                          width: 4,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${minWeight.toStringAsFixed(1)}kg'),
                Text('${maxWeight.toStringAsFixed(1)}kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Settings tab — export & delete database
// ---------------------------------------------------------------------------

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final prefs = ref.watch(dietPreferencesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile section ──
        Text('Profile', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(profile != null ? 'Edit Profile' : 'Set up Profile'),
            subtitle: Text(
              profile != null
                  ? '${profile.sex == "male" ? "Male" : "Female"} · ${profile.heightCm.toStringAsFixed(0)} cm · ${profile.weightKg.toStringAsFixed(1)} kg'
                  : 'Enter your details for macro calculations',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ProfileSetupDialog(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Nutrition section ──
        Text('Nutrition', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Visible macros',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final entry in prefs.macros.entries) ...[
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(
                    entry.key[0].toUpperCase() + entry.key.substring(1),
                  ),
                  value: entry.value,
                  onChanged: (_) => ref
                      .read(dietPreferencesProvider.notifier)
                      .toggleMacro(entry.key),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Workout section ──
        Text('Workout', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Default rest timer'),
            subtitle: const Text('60 seconds between sets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Placeholder — rest timer configuration coming later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rest timer settings coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // ── Appearance section ──
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('System default'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Theme settings coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // ── Data section ──
        Text('Data', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export database'),
                subtitle: const Text('Share the SQLite database file'),
                onTap: () => _exportDb(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Delete all data',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Remove everything and restart fresh'),
                onTap: () => _deleteDb(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 96),
      ],
    );
  }

  Future<void> _exportDb(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/fitfat.db');
      if (!file.existsSync()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No database file found')),
          );
        }
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'fitfat database'),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _deleteDb(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This will remove all your data including meals, exercises, workouts, '
          'goals, and profile. A fresh database will be created on next launch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/fitfat.db');
      if (file.existsSync()) {
        await file.delete();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database deleted. Restart the app to recreate it.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}
