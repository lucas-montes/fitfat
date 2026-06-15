import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:fitfat/src/exercise/providers/exercises.dart';
import 'package:fitfat/src/exercise/providers/workout_provider.dart';
import 'package:fitfat/src/exercise/providers/history_provider.dart';

class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({super.key});

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  final _searchController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  ExerciseDefinition? _selectedExercise;
  String? _errorText;

  @override
  void dispose() {
    _searchController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectExercise(ExerciseDefinition exercise) {
    setState(() {
      _selectedExercise = exercise;
      _errorText = null;
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedExercise = null;
      _repsController.clear();
      _weightController.clear();
      _durationController.clear();
      _notesController.clear();
      _searchController.clear();
      _errorText = null;
    });
  }

  Future<void> _saveQuickLog() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedExercise == null) {
      setState(() => _errorText = l10n.quickLogSelectExercise);
      return;
    }

    final isCardio = _selectedExercise!.type == 'cardio';
    int? reps;
    double? weightKg;
    int? durationMinutes;

    if (isCardio) {
      final parsed = int.tryParse(_durationController.text);
      if (parsed == null || parsed <= 0) {
        setState(() => _errorText = l10n.quickLogEnterDuration);
        return;
      }
      durationMinutes = parsed;
    } else {
      final repsParsed = int.tryParse(_repsController.text);
      final weightParsed = double.tryParse(_weightController.text);
      if (repsParsed == null || repsParsed <= 0) {
        setState(() => _errorText = l10n.quickLogEnterReps);
        return;
      }
      if (weightParsed == null || weightParsed <= 0) {
        setState(() => _errorText = l10n.quickLogEnterWeight);
        return;
      }
      reps = repsParsed;
      weightKg = weightParsed;
    }

    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) {
      // pass notes below
    }

    ref
        .read(activeWorkoutProvider.notifier)
        .quickLogWorkout(
          name: '${l10n.quickLog} — ${_selectedExercise!.name}',
          exercise: _selectedExercise!,
          reps: reps,
          weightKg: weightKg,
          durationMinutes: durationMinutes,
        );

    // Refresh timeline
    await ref.read(workoutHistoryProvider.notifier).loadHistory();

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.quickLogSaved),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercises = ref.watch(exerciseListProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filtered = query.isEmpty
        ? exercises
        : exercises.where((e) => e.name.toLowerCase().contains(query)).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            l10n.quickLogTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.quickLogSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _selectedExercise == null
                ? _buildExerciseList(filtered, l10n)
                : _buildInputForm(l10n),
          ),

          // Error
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ),

          // Save button
          if (_selectedExercise != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: Text(l10n.logWorkout),
                onPressed: _saveQuickLog,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
    List<ExerciseDefinition> exercises,
    AppLocalizations l10n,
  ) {
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          l10n.noExercisesFoundSimple,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isCardio = exercise.type == 'cardio';
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            leading: Icon(
              isCardio ? Icons.directions_run : Icons.fitness_center,
              size: 20,
            ),
            title: Text(exercise.name, style: const TextStyle(fontSize: 14)),
            subtitle: Row(
              children: [
                Text(exercise.category, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isCardio
                        ? Colors.orange.withAlpha(30)
                        : Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCardio ? l10n.cardio : l10n.weightlifting,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCardio ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.add_circle, size: 18),
            onTap: () => _selectExercise(exercise),
          ),
        );
      },
    );
  }

  Widget _buildInputForm(AppLocalizations l10n) {
    final isCardio = _selectedExercise!.type == 'cardio';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected exercise chip
          InputChip(
            label: Text(_selectedExercise!.name),
            avatar: Icon(
              isCardio ? Icons.directions_run : Icons.fitness_center,
              size: 18,
            ),
            onDeleted: _resetSelection,
          ),
          const SizedBox(height: 16),

          // Type-specific inputs
          if (isCardio) ...[
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                label: Text(l10n.minutes),
                hintText: l10n.quickLogDurationHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(l10n.reps),
                      hintText: l10n.quickLogRepsHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text(l10n.weightKg),
                      hintText: l10n.quickLogWeightHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              label: Text(l10n.quickLogNotes),
              hintText: l10n.quickLogNotesHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
