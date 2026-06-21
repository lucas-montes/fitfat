import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../adapters/drift/workout_repository.dart';
import '../../../models/workout.dart';
import '../../providers/exercises.dart';

/// Screen shown after completing a workout.
///
/// Displays the workout name, total duration, list of exercises with set
/// counts, and total volume. A "Done" button navigates to the Training tab.
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutSummaryScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  Workout? _workout;
  List<WeightSet> _weightSets = [];
  List<CardioSet> _cardioSets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final (workout, weightSets, cardioSets) = await repo.getById(
        widget.workoutId,
      );
      if (mounted) {
        setState(() {
          _workout = workout;
          _weightSets = weightSets;
          _cardioSets = cardioSets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<_ExerciseSummary> _buildExerciseSummaries() {
    final exercises = ref.read(exerciseListProvider);
    final Map<String, _ExerciseSummary> groups = {};

    for (final set in _weightSets) {
      final summary = groups.putIfAbsent(set.exerciseId, () {
        final exercise = exercises
            .where((e) => e.id == set.exerciseId)
            .firstOrNull;
        return _ExerciseSummary(
          exerciseName: exercise?.name ?? set.exerciseId,
          isWeight: true,
        );
      });
      summary.totalSets++;
      if (set.isCompleted) summary.completedSets++;
      summary.volume += set.effectiveReps * set.effectiveWeightKg;
    }

    for (final set in _cardioSets) {
      final summary = groups.putIfAbsent(set.exerciseId, () {
        final exercise = exercises
            .where((e) => e.id == set.exerciseId)
            .firstOrNull;
        return _ExerciseSummary(
          exerciseName: exercise?.name ?? set.exerciseId,
          isWeight: false,
        );
      });
      summary.totalSets++;
      if (set.isCompleted) summary.completedSets++;
      summary.volume += set.effectiveDurationMinutes.toDouble();
    }

    return groups.values.toList()
      ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(_workout?.name ?? l10n.workout)),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_workout == null) {
      return Center(child: const Text('Workout not found'));
    }

    final summaries = _buildExerciseSummaries();
    final totalVolume = summaries.fold<double>(0, (sum, s) => sum + s.volume);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Duration ──
        Center(
          child: Column(
            children: [
              Text(
                _formatDuration(_workout!.duration),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.duration,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Stats cards ──
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.exercises,
                value: '${summaries.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.setsLower,
                value: '${summaries.fold<int>(0, (s, e) => s + e.totalSets)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.volume,
                value: '${totalVolume.toStringAsFixed(0)} kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Exercises ──
        if (summaries.isNotEmpty) ...[
          Text(l10n.exercises, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summaries.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  s.isWeight ? Icons.fitness_center : Icons.directions_run,
                ),
                title: Text(s.exerciseName),
                subtitle: Text(
                  s.completedSets == s.totalSets
                      ? '${l10n.setsCount(s.totalSets)} · ${l10n.done}'
                      : '${s.completedSets}/${s.totalSets} ${l10n.setsLower}',
                ),
                trailing: s.volume > 0
                    ? Text(
                        '${s.volume.toStringAsFixed(0)} kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ── Done button ──
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => context.go('/exercise'),
            child: Text(l10n.done),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseSummary {
  final String exerciseName;
  final bool isWeight;
  int totalSets = 0;
  int completedSets = 0;
  double volume = 0;

  _ExerciseSummary({required this.exerciseName, required this.isWeight});
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
