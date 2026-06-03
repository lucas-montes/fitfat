import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/exercise.dart';
import '../../../providers/seances/history.dart';
import '../../../services/workout_services.dart';
import 'summary_card.dart';
import 'record_card.dart';

class ExerciseHistoryScreen extends ConsumerStatefulWidget {
  const ExerciseHistoryScreen({required this.exercise, super.key});

  final ExerciseDefinition exercise;

  @override
  ConsumerState<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends ConsumerState<ExerciseHistoryScreen> {
  final _searchController = TextEditingController();
  final _service = ProgressionService();
  String _dateFilter = 'all'; // 'all', 'month', '3months', 'year'
  int _selectedTab = 0; // 0 = History, 1 = Records

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Seance> _getSeances() {
    final history = ref.watch(seanceHistoryProvider);
    final all = history.where(
      (s) =>
          s.completedAt != null &&
          s.exercises.any((e) => e.exercise.name == widget.exercise.name),
    );

    // Date filter
    final now = DateTime.now();
    final filtered = all.where((s) {
      final date = s.completedAt ?? s.startedAt;
      switch (_dateFilter) {
        case 'month':
          return date.isAfter(now.subtract(const Duration(days: 30)));
        case '3months':
          return date.isAfter(now.subtract(const Duration(days: 90)));
        case 'year':
          return date.isAfter(now.subtract(const Duration(days: 365)));
        default:
          return true;
      }
    });

    // Text search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      return filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(query) ||
                DateFormat(
                  'MMM d, yyyy',
                ).format(s.completedAt!).toLowerCase().contains(query),
          )
          .toList()
        ..sort(
          (a, b) => (b.completedAt ?? b.startedAt).compareTo(
            a.completedAt ?? a.startedAt,
          ),
        );
    }

    return filtered.toList()..sort(
      (a, b) => (b.completedAt ?? b.startedAt).compareTo(
        a.completedAt ?? a.startedAt,
      ),
    );
  }

  List<ExerciseSet> _getAllSets(List<Seance> seances) {
    final sets = <ExerciseSet>[];
    for (final seance in seances) {
      final entry = seance.exercises.firstWhere(
        (e) => e.exercise.name == widget.exercise.name,
      );
      sets.addAll(entry.sets);
    }
    return sets;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seances = _getSeances();
    final allSets = _getAllSets(seances);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _dateFilter = value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'all',
                child: Text(
                  '${l10n.allTime}${_dateFilter == 'all' ? ' ✓' : ''}',
                ),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text(
                  '${l10n.pastMonth}${_dateFilter == 'month' ? ' ✓' : ''}',
                ),
              ),
              PopupMenuItem(
                value: '3months',
                child: Text(
                  '${l10n.past3Months}${_dateFilter == '3months' ? ' ✓' : ''}',
                ),
              ),
              PopupMenuItem(
                value: 'year',
                child: Text(
                  '${l10n.pastYear}${_dateFilter == 'year' ? ' ✓' : ''}',
                ),
              ),
            ],
          ),
        ],
      ),
      body: seances.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.noHistoryFor(widget.exercise.name),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.completeWorkoutToSee,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary stats
                SummaryCard(
                  seances: seances,
                  service: _service,
                  exerciseName: widget.exercise.name,
                ),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedTab == 0
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _selectedTab == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outline.withAlpha(60),
                              ),
                            ),
                          ),
                          onPressed: () => setState(() => _selectedTab = 0),
                          child: Text(l10n.history),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: _selectedTab == 1
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _selectedTab == 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outline.withAlpha(60),
                              ),
                            ),
                          ),
                          onPressed: () => setState(() => _selectedTab = 1),
                          child: Text(l10n.records),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedTab == 0
                      ? _buildHistoryTab(seances)
                      : _buildRecordsTab(allSets),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryTab(List<Seance> seances) {
    final l10n = AppLocalizations.of(context)!;
    // Prepare chart data
    final volumeData = <FlSpot>[];
    final rmData = <FlSpot>[];

    for (var i = 0; i < seances.length; i++) {
      final seance = seances[i];
      final entry = seance.exercises.firstWhere(
        (e) => e.exercise.name == widget.exercise.name,
      );
      final dateMs = (seance.completedAt ?? seance.startedAt)
          .millisecondsSinceEpoch
          .toDouble();
      final vol = _service.totalVolume(entry.sets);
      volumeData.add(FlSpot(dateMs, vol));

      final bestSet = _service.findBestSet(entry.sets);
      if (bestSet != null) {
        final rm = _service.epleyOneRM(bestSet.weight, bestSet.reps) ?? 0;
        rmData.add(FlSpot(dateMs, rm));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Volume chart
        if (volumeData.length >= 2) ...[
          Text(
            l10n.volumeProgression,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'kg',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      l10n.volume,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      l10n.date,
                      style: TextStyle(fontSize: 10),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          value.toInt(),
                        );
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: volumeData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // e1RM chart
          if (rmData.length >= 2) ...[
            Text(
              l10n.estimated1RM,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'kg',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        l10n.oneRM,
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        l10n.date,
                        style: const TextStyle(fontSize: 10),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rmData,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.green,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
        // Search
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            label: Text(l10n.searchHistory),
            hintText: l10n.searchByDateWorkout,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.sessionsCount(seances.length),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        // History list
        ...seances.map((seance) {
          final entry = seance.exercises.firstWhere(
            (e) => e.exercise.name == widget.exercise.name,
          );
          final bestSet = _service.findBestSet(entry.sets);
          final estRm = bestSet != null
              ? _service.epleyOneRM(bestSet.weight, bestSet.reps)
              : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(seance.completedAt!),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        DateFormat('HH:mm').format(seance.completedAt!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.setsCount(entry.sets.length)} · '
                    '${_service.totalVolume(entry.sets).toStringAsFixed(0)}kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...entry.sets.asMap().entries.map((e) {
                    final s = e.value;
                    final isPR = _service.findBestSet(entry.sets) == s;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Set ${e.key + 1}: ${s.reps} reps × ${s.weight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isPR ? FontWeight.bold : null,
                              color: isPR ? Colors.green.shade700 : null,
                            ),
                          ),
                          if (isPR) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.emoji_events,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  if (estRm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${l10n.best} ${l10n.oneRM}: ${estRm.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecordsTab(List<ExerciseSet> allSets) {
    final l10n = AppLocalizations.of(context)!;
    final bestSet = _service.findBestSet(allSets);
    final maxWeightSet = _service.findMaxWeight(allSets);
    final maxVolSet = _service.findMaxVolumeSet(allSets);
    final bestRm = bestSet != null
        ? _service.epleyOneRM(bestSet.weight, bestSet.reps)
        : null;
    final totalVol = _service.totalVolume(allSets);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        RecordCard(
          icon: Icons.emoji_events,
          title: l10n.bestEstimated1RM,
          value: bestRm != null
              ? '${bestRm.toStringAsFixed(1)} kg'
              : l10n.notAvailable,
          subtitle: bestSet != null
              ? '${bestSet.reps} reps @ ${bestSet.weight.toStringAsFixed(1)} kg'
              : null,
          color: Colors.amber,
        ),
        const SizedBox(height: 12),
        RecordCard(
          icon: Icons.fitness_center,
          title: l10n.maxWeight,
          value: maxWeightSet != null
              ? '${maxWeightSet.weight.toStringAsFixed(1)} kg'
              : l10n.notAvailable,
          subtitle: maxWeightSet != null ? '${maxWeightSet.reps} reps' : null,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        RecordCard(
          icon: Icons.trending_up,
          title: l10n.maxVolumeSet,
          value: maxVolSet != null
              ? '${(maxVolSet.reps * maxVolSet.weight).toStringAsFixed(0)} kg'
              : l10n.notAvailable,
          subtitle: maxVolSet != null
              ? '${maxVolSet.reps} reps × ${maxVolSet.weight.toStringAsFixed(1)} kg'
              : null,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        RecordCard(
          icon: Icons.bar_chart,
          title: l10n.totalVolume,
          value: '${totalVol.toStringAsFixed(0)} kg',
          subtitle: '${l10n.across} ${l10n.setsCount(allSets.length)}',
          color: Colors.purple,
        ),
      ],
    );
  }
}
