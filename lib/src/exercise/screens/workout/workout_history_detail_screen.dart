import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../adapters/drift/workout_repository.dart';
import '../../../models/workout.dart';
import '../../providers/exercises.dart';

/// Screen that shows the detail of a completed workout from history.
///
/// Displays the workout date, duration, and a list of exercises with their
/// individual sets (read-only).
class WorkoutHistoryDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutHistoryDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutHistoryDetailScreen> createState() =>
      _WorkoutHistoryDetailScreenState();
}

class _WorkoutHistoryDetailScreenState
    extends ConsumerState<WorkoutHistoryDetailScreen> {
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

    final dateStr = DateFormat(
      'EEEE, MMM d, y',
    ).format(_workout!.completedAt ?? _workout!.startedAt!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header: date + duration ──
        Center(
          child: Column(
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDuration(_workout!.duration),
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.duration,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Exercise groups ──
        ..._buildExerciseGroups(l10n),
      ],
    );
  }

  List<Widget> _buildExerciseGroups(AppLocalizations l10n) {
    final exercises = ref.read(exerciseListProvider);
    final groups = <String, List<Widget>>{};
    final order = <String>[];

    for (final set in _weightSets) {
      final key = set.exerciseId;
      if (!groups.containsKey(key)) {
        order.add(key);
        final ex = exercises.where((e) => e.id == key).firstOrNull;
        groups[key] = [
          _ExerciseHeader(
            icon: Icons.fitness_center,
            name: ex?.name ?? key,
            count:
                '${_weightSets.where((s) => s.exerciseId == key).length} sets',
          ),
        ];
      }
      groups[key]!.add(_WeightSetRow(set: set));
    }

    for (final set in _cardioSets) {
      final key = set.exerciseId;
      if (!groups.containsKey(key)) {
        order.add(key);
        final ex = exercises.where((e) => e.id == key).firstOrNull;
        groups[key] = [
          _ExerciseHeader(
            icon: Icons.directions_run,
            name: ex?.name ?? key,
            count:
                '${_cardioSets.where((s) => s.exerciseId == key).length} sets',
          ),
        ];
      }
      groups[key]!.add(_CardioSetRow(set: set));
    }

    return [
      for (final key in order) ...[...groups[key]!, const SizedBox(height: 16)],
    ];
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseHeader extends StatelessWidget {
  final IconData icon;
  final String name;
  final String count;

  const _ExerciseHeader({
    required this.icon,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            count,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightSetRow extends StatelessWidget {
  final WeightSet set;

  const _WeightSetRow({required this.set});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Row(
        children: [
          Icon(
            set.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: set.isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '${set.effectiveReps} × ${set.effectiveWeightKg} kg',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (set.notes != null && set.notes!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                set.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardioSetRow extends StatelessWidget {
  final CardioSet set;

  const _CardioSetRow({required this.set});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Row(
        children: [
          Icon(
            set.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: set.isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '${set.effectiveDurationMinutes} min',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (set.notes != null && set.notes!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                set.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
