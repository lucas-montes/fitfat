import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/active_workout.dart';
import '../../providers/exercises.dart';
import '../../../adapters/drift/workout_repository.dart';
import '../../../models/workout.dart';

/// Screen that shows all sets for one exercise within the active workout.
///
/// Features:
/// - Inline add-set form at the top (empty fields, no defaults)
/// - Tap an existing set to copy its values into the form
/// - Long-press for Edit, Toggle complete, and Delete
/// - Leading icon tap toggles completion directly
class ExerciseWorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final String exerciseId;

  const ExerciseWorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.exerciseId,
  });

  @override
  ConsumerState<ExerciseWorkoutDetailScreen> createState() =>
      _ExerciseWorkoutDetailScreenState();
}

class _ExerciseWorkoutDetailScreenState
    extends ConsumerState<ExerciseWorkoutDetailScreen> {
  List<WeightSet> _weightSets = [];
  List<CardioSet> _cardioSets = [];
  bool _loading = true;
  String? _error;

  // Form controllers (start empty — no defaults)
  final _repsCtl = TextEditingController();
  final _weightCtl = TextEditingController();
  final _durationCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  @override
  void dispose() {
    _repsCtl.dispose();
    _weightCtl.dispose();
    _durationCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final allWeight = await repo.getWeightSets(widget.workoutId);
      final allCardio = await repo.getCardioSets(widget.workoutId);

      setState(() {
        _weightSets = allWeight
            .where((s) => s.exerciseId == widget.exerciseId)
            .toList();
        _cardioSets = allCardio
            .where((s) => s.exerciseId == widget.exerciseId)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  ExerciseDefinition? _findExercise() {
    final exercises = ref.read(exerciseListProvider);
    try {
      return exercises.firstWhere((e) => e.id == widget.exerciseId);
    } catch (_) {
      return null;
    }
  }

  int _nextSortOrder() {
    final maxWeight = _weightSets.isEmpty
        ? -1
        : _weightSets.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
    final maxCardio = _cardioSets.isEmpty
        ? -1
        : _cardioSets.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b);
    return (maxWeight > maxCardio ? maxWeight : maxCardio) + 1;
  }

  // ── Toggle completion ──

  Future<void> _toggleWeightSetCompletion(WeightSet set) async {
    if (set.isCompleted) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateWeightSet(
            set.copyWith(completedAt: null, clearCompletedAt: true),
          );
    } else {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateWeightSet(
            set.copyWith(
              actualReps: set.plannedReps,
              actualWeightKg: set.plannedWeightKg,
              completedAt: DateTime.now(),
            ),
          );
    }
    _loadSets();
  }

  Future<void> _toggleCardioSetCompletion(CardioSet set) async {
    if (set.isCompleted) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateCardioSet(
            set.copyWith(completedAt: null, clearCompletedAt: true),
          );
    } else {
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateCardioSet(
            set.copyWith(
              actualDurationMinutes: set.plannedDurationMinutes,
              completedAt: DateTime.now(),
            ),
          );
    }
    _loadSets();
  }

  // ── Populate form from existing set (tap to copy) ──

  void _populateFromWeightSet(WeightSet set) {
    _repsCtl.text = set.effectiveReps.toString();
    _weightCtl.text = set.effectiveWeightKg.toString();
    _notesCtl.text = set.notes ?? '';
  }

  void _populateFromCardioSet(CardioSet set) {
    _durationCtl.text = set.effectiveDurationMinutes.toString();
    _notesCtl.text = set.notes ?? '';
  }

  // ── Inline form add-set ──

  Future<void> _addSetFromForm(ExerciseDefinition exercise) async {
    if (exercise.type == ExerciseType.weightlifting) {
      final reps = int.tryParse(_repsCtl.text);
      final weight = double.tryParse(_weightCtl.text);
      if (reps == null || reps <= 0 || weight == null || weight < 0) return;
      await ref
          .read(activeWorkoutProvider.notifier)
          .addWeightSet(
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            plannedReps: reps,
            plannedWeightKg: weight,
            notes: _nullIfEmpty(_notesCtl.text),
            sortOrder: _nextSortOrder(),
          );
    } else {
      final dur = int.tryParse(_durationCtl.text);
      if (dur == null || dur <= 0) return;
      await ref
          .read(activeWorkoutProvider.notifier)
          .addCardioSet(
            workoutId: widget.workoutId,
            exerciseId: widget.exerciseId,
            plannedDurationMinutes: dur,
            notes: _nullIfEmpty(_notesCtl.text),
            sortOrder: _nextSortOrder(),
          );
    }
    // Clear form on successful add
    _repsCtl.clear();
    _weightCtl.clear();
    _durationCtl.clear();
    _notesCtl.clear();
    _loadSets();
  }

  // ── Edit set (via dialog) ──

  Future<void> _editWeightSet(WeightSet set) async {
    final result = await _showSetFormDialog(
      title: 'Edit Set',
      isWeight: true,
      initialReps: set.plannedReps,
      initialWeight: set.plannedWeightKg,
      initialNotes: set.notes,
    );
    if (result == null || !mounted) return;
    await ref
        .read(activeWorkoutProvider.notifier)
        .updateWeightSet(
          set.copyWith(
            plannedReps: result.$1,
            plannedWeightKg: result.$2,
            notes: result.$3,
          ),
        );
    _loadSets();
  }

  Future<void> _editCardioSet(CardioSet set) async {
    final result = await _showSetFormDialog(
      title: 'Edit Set',
      isWeight: false,
      initialDuration: set.plannedDurationMinutes,
      initialNotes: set.notes,
    );
    if (result == null || !mounted) return;
    await ref
        .read(activeWorkoutProvider.notifier)
        .updateCardioSet(
          set.copyWith(plannedDurationMinutes: result.$1, notes: result.$3),
        );
    _loadSets();
  }

  // ── Delete set ──

  Future<void> _deleteSet(String setId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete set'),
        content: const Text('Remove this set?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(ctx)!.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(activeWorkoutProvider.notifier).removeSet(setId);
      _loadSets();
    }
  }

  // ── Shared Form Dialog (used for edit only now) ──

  /// Returns (intValue, doubleValue, String? notes) for weight,
  /// or (intValue, 0.0, String? notes) for cardio (second value unused).
  Future<(int, double, String?)?> _showSetFormDialog({
    required String title,
    required bool isWeight,
    int initialReps = 10,
    double initialWeight = 20.0,
    int initialDuration = 10,
    String? initialNotes,
  }) async {
    final repsCtl = TextEditingController(text: initialReps.toString());
    final weightCtl = isWeight
        ? TextEditingController(text: initialWeight.toString())
        : null;
    final durationCtl = !isWeight
        ? TextEditingController(text: initialDuration.toString())
        : null;
    final notesCtl = TextEditingController(text: initialNotes ?? '');

    final result = await showDialog<_FormResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWeight) ...[
                TextField(
                  controller: repsCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: durationCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: notesCtl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              final reps = int.tryParse(repsCtl.text);
              if (reps == null || reps <= 0) return;
              if (isWeight) {
                final weight = double.tryParse(weightCtl!.text);
                if (weight == null || weight < 0) return;
                Navigator.pop(
                  ctx,
                  _FormResult(reps, weight, _nullIfEmpty(notesCtl.text)),
                );
              } else {
                final dur = int.tryParse(durationCtl!.text);
                if (dur == null || dur <= 0) return;
                Navigator.pop(
                  ctx,
                  _FormResult(dur, 0, _nullIfEmpty(notesCtl.text)),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    repsCtl.dispose();
    weightCtl?.dispose();
    durationCtl?.dispose();
    notesCtl.dispose();

    if (result == null) return null;
    return (result.intValue, result.doubleValue, result.notes);
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  // ── Inline add-set form widget ──

  Widget _buildAddForm(ExerciseDefinition exercise) {
    final isWeight = exercise.type == ExerciseType.weightlifting;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addSet, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (isWeight) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repsCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightCtl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              TextField(
                controller: _durationCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (min)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtl,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _addSetFromForm(exercise),
                child: Text(l10n.addSet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = _findExercise();

    return Scaffold(
      appBar: AppBar(title: Text(exercise?.name ?? l10n.exercise)),
      body: _buildBody(l10n, exercise),
      // FAB removed — inline form at top replaces it
    );
  }

  Widget _buildBody(AppLocalizations l10n, ExerciseDefinition? exercise) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (exercise == null) {
      return Center(child: const Text('Exercise not found'));
    }

    final hasWeightSets = _weightSets.isNotEmpty;
    final hasCardioSets = _cardioSets.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Inline add-set form ──
        _buildAddForm(exercise),
        const SizedBox(height: 8),

        // ── Existing sets ──
        if (hasWeightSets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Weight Sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._weightSets.map(
            (set) => _WeightSetTile(
              set: set,
              onTap: () => _populateFromWeightSet(set),
              onEdit: () => _editWeightSet(set),
              onDelete: () => _deleteSet(set.id),
              onToggleComplete: () => _toggleWeightSetCompletion(set),
            ),
          ),
        ],
        if (hasWeightSets && hasCardioSets) const SizedBox(height: 16),
        if (hasCardioSets) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Cardio Sets',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._cardioSets.map(
            (set) => _CardioSetTile(
              set: set,
              onTap: () => _populateFromCardioSet(set),
              onEdit: () => _editCardioSet(set),
              onDelete: () => _deleteSet(set.id),
              onToggleComplete: () => _toggleCardioSetCompletion(set),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form result helper
// ─────────────────────────────────────────────────────────────────────────────

class _FormResult {
  final int intValue;
  final double doubleValue;
  final String? notes;
  const _FormResult(this.intValue, this.doubleValue, this.notes);
}

// ─────────────────────────────────────────────────────────────────────────────
// Weight set tile
// ─────────────────────────────────────────────────────────────────────────────

class _WeightSetTile extends StatelessWidget {
  final WeightSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _WeightSetTile({
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text('${set.effectiveReps} × ${set.effectiveWeightKg} kg'),
          subtitle: set.notes != null && set.notes!.isNotEmpty
              ? Text(set.notes!, style: const TextStyle(fontSize: 12))
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cardio set tile
// ─────────────────────────────────────────────────────────────────────────────

class _CardioSetTile extends StatelessWidget {
  final CardioSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _CardioSetTile({
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text('${set.effectiveDurationMinutes} min'),
          subtitle: set.notes != null && set.notes!.isNotEmpty
              ? Text(set.notes!, style: const TextStyle(fontSize: 12))
              : null,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
