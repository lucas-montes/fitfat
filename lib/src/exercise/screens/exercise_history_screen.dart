import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../providers/seance.dart';
import '../services/workout_services.dart';

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
                (s.name?.toLowerCase().contains(query) ?? false) ||
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
                child: Text('All time${_dateFilter == 'all' ? ' ✓' : ''}'),
              ),
              PopupMenuItem(
                value: 'month',
                child: Text('Past month${_dateFilter == 'month' ? ' ✓' : ''}'),
              ),
              PopupMenuItem(
                value: '3months',
                child: Text(
                  'Past 3 months${_dateFilter == '3months' ? ' ✓' : ''}',
                ),
              ),
              PopupMenuItem(
                value: 'year',
                child: Text('Past year${_dateFilter == 'year' ? ' ✓' : ''}'),
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
                    'No history for ${widget.exercise.name} yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a workout with this exercise to see it here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Summary stats
                _SummaryCard(
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
                          child: const Text('History'),
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
                          child: const Text('Records'),
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
            'Volume Progression',
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
                    axisNameWidget: const Text(
                      'Volume',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Date',
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
              'Estimated 1RM Progression',
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
                      axisNameWidget: const Text(
                        'e1RM',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Date',
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
            label: const Text('Search history'),
            hintText: 'Search by date or workout name...',
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
          '${seances.length} session${seances.length == 1 ? '' : 's'}',
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
                    '${entry.sets.length} set${entry.sets.length == 1 ? '' : 's'} · '
                    '${_service.totalVolume(entry.sets).toStringAsFixed(0)}kg volume',
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
                        'Best set e1RM: ${estRm.toStringAsFixed(1)} kg',
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
        _RecordCard(
          icon: Icons.emoji_events,
          title: 'Best Estimated 1RM',
          value: bestRm != null ? '${bestRm.toStringAsFixed(1)} kg' : 'N/A',
          subtitle: bestSet != null
              ? '${bestSet.reps} reps @ ${bestSet.weight.toStringAsFixed(1)} kg'
              : null,
          color: Colors.amber,
        ),
        const SizedBox(height: 12),
        _RecordCard(
          icon: Icons.fitness_center,
          title: 'Max Weight',
          value: maxWeightSet != null
              ? '${maxWeightSet.weight.toStringAsFixed(1)} kg'
              : 'N/A',
          subtitle: maxWeightSet != null ? '${maxWeightSet.reps} reps' : null,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _RecordCard(
          icon: Icons.trending_up,
          title: 'Max Volume (Set)',
          value: maxVolSet != null
              ? '${(maxVolSet.reps * maxVolSet.weight).toStringAsFixed(0)} kg'
              : 'N/A',
          subtitle: maxVolSet != null
              ? '${maxVolSet.reps} reps × ${maxVolSet.weight.toStringAsFixed(1)} kg'
              : null,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _RecordCard(
          icon: Icons.bar_chart,
          title: 'Total Volume',
          value: '${totalVol.toStringAsFixed(0)} kg',
          subtitle:
              'Across ${allSets.length} set${allSets.length == 1 ? '' : 's'}',
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.seances,
    required this.service,
    required this.exerciseName,
  });

  final List<Seance> seances;
  final ProgressionService service;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
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
            _Stat(label: 'Sessions', value: '$totalSessions'),
            _Stat(
              label: 'Volume',
              value: '${totalVolume.toStringAsFixed(0)} kg',
            ),
            _Stat(label: 'Time', value: '${totalMinutes} min'),
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
