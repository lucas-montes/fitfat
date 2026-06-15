import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../services/seance_foreground_service.dart';
import '../../../../models/exercise.dart';
import '../../../../models/workout.dart' as domain;
import '../../../providers/workout_provider.dart';
import '../../../providers/exercises.dart';
import 'guided_set_card.dart';
import 'freeform_set_card.dart';
import 'previous_sessions.dart';
import 'timer_widget.dart';
import 'add_set_form.dart';
import 'rest_timer_overlay.dart';
import 'summary_screen.dart';

class CurrentSeanceScreen extends ConsumerStatefulWidget {
  const CurrentSeanceScreen({super.key});

  @override
  ConsumerState<CurrentSeanceScreen> createState() =>
      _CurrentSeanceScreenState();
}

class _CurrentSeanceScreenState extends ConsumerState<CurrentSeanceScreen> {
  int? _selectedExerciseIndex;
  late PageController _pageController;
  final _exerciseSearchController = TextEditingController();
  bool _notificationSynced = false;
  int _prefillVersion = 0;
  int? _prefillReps;
  double? _prefillWeight;
  final _cardioDurationController = TextEditingController();
  int _cardioDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _exerciseSearchController.dispose();
    _cardioDurationController.dispose();
    super.dispose();
  }

  void _selectExercise(int index) {
    setState(() {
      _selectedExerciseIndex = index;
      _pageController = PageController(initialPage: index);
    });
    final workout = ref.read(activeWorkoutProvider);
    if (workout != null && index < workout.entries.length) {
      SeanceForegroundService.instance.updateExerciseName(
        workout.entries[index].exercise.name,
      );
    }
  }

  void _backToList() {
    setState(() => _selectedExerciseIndex = null);
  }

  void _prefillSet(domain.WeightSet set) {
    setState(() {
      _prefillReps = set.reps;
      _prefillWeight = set.weightKg;
      _prefillVersion++;
    });
  }

  Future<bool> _confirmDiscardEmptyWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardEmptySeance),
        content: Text(l10n.discardEmptySeanceContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workout = ref.watch(activeWorkoutProvider);

    if (workout == null) {
      return Scaffold(body: Center(child: Text(l10n.noActiveSeance)));
    }

    if (!_notificationSynced) {
      _notificationSynced = true;
      final notifTitle = AppLocalizations.of(context)!.activeWorkout;
      final initialExercise = workout.entries.isNotEmpty
          ? workout.entries[0].exercise.name
          : null;
      SeanceForegroundService.instance.start(
        workout.startTime,
        seanceName: workout.name,
        exerciseName: initialExercise,
        notificationTitle: notifTitle,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedExerciseIndex != null
              ? workout.entries[_selectedExerciseIndex!].exercise.name
              : workout.name,
        ),
        elevation: 0,
        leading: _selectedExerciseIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToList,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.backToApp,
                onPressed: () {
                  if (!context.canPop()) {
                    context.go('/exercise');
                  } else {
                    context.pop();
                  }
                },
              ),
        automaticallyImplyLeading: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              workout.isGuided ? Icons.list_alt : Icons.playlist_add,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: TimerWidget(startedAt: workout.startTime)),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: l10n.cancelSeance,
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
              context.go('/exercise');
            },
          ),
        ],
      ),
      body: _selectedExerciseIndex != null
          ? _buildDetailView(workout)
          : _buildExerciseListView(workout),
    );
  }

  Widget _buildExerciseListView(domain.Workout workout) {
    final l10n = AppLocalizations.of(context)!;
    final exercises = ref.watch(exerciseListProvider);
    final query = _exerciseSearchController.text.trim().toLowerCase();

    final addedNames = workout.entries
        .map((e) => e.exercise.name.toLowerCase())
        .toSet();

    final filtered = query.isEmpty
        ? <ExerciseDefinition>[]
        : exercises.where((e) {
            if (addedNames.contains(e.name.toLowerCase())) return false;
            if (!e.name.toLowerCase().contains(query)) return false;
            return true;
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (workout.entries.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l10n.exercises,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                l10n.exercisesCount(workout.entries.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...workout.entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isCardio = e.exercise.type == 'cardio';
            final completedSets = e.sets.where((s) => s.isCompleted).length;
            return Card(
              child: ListTile(
                leading: isCardio
                    ? const Icon(Icons.directions_run)
                    : (workout.isGuided
                          ? SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: e.sets.isEmpty
                                        ? 0
                                        : completedSets / e.sets.length,
                                    strokeWidth: 3,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                  Text(
                                    '$completedSets/${e.sets.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            )
                          : const Icon(Icons.fitness_center)),
                title: Text(e.exercise.name),
                subtitle: Text(
                  isCardio
                      ? (e.cardioDetail != null
                            ? '${e.cardioDetail!.durationMinutes} min'
                            : l10n.cardio)
                      : (workout.isGuided
                            ? '$completedSets/${e.sets.length} ${l10n.setsLower}'
                            : l10n.setsCount(e.sets.length)),
                ),
                onTap: () => _selectExercise(i),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .removeExercise(i),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        Text(
          workout.isGuided ? l10n.followPlan : l10n.addExercise,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseSearchController,
          decoration: InputDecoration(
            label: Text(
              workout.isGuided ? l10n.searchToAdd : l10n.searchExercises,
            ),
            hintText: workout.isGuided
                ? l10n.exerciseTypeToSearch
                : l10n.typeToFindExercises,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (query.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                workout.isGuided ? l10n.searchToAdd : l10n.typeToFindExercises,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                '${l10n.noExercisesFound} "$query"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...filtered.map((exercise) {
            final isCardio = exercise.type == 'cardio';
            return Card(
              child: ListTile(
                leading: Icon(
                  isCardio ? Icons.directions_run : Icons.fitness_center,
                ),
                title: Text(exercise.name),
                subtitle: Row(
                  children: [
                    Text(exercise.category),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isCardio
                            ? Colors.orange.withAlpha(30)
                            : Colors.blue.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCardio ? l10n.cardio : l10n.weightlifting,
                        style: TextStyle(
                          fontSize: 11,
                          color: isCardio ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.add_circle),
                onTap: () {
                  final notifier = ref.read(activeWorkoutProvider.notifier);
                  if (exercise.type == 'cardio') {
                    notifier.addCardioEntry(exercise);
                  } else {
                    notifier.addExercise(exercise);
                  }
                },
              ),
            );
          }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l10n.completeSeance),
            onPressed: () async {
              if (workout.entries.isEmpty) {
                final discard = await _confirmDiscardEmptyWorkout();
                if (!discard || !context.mounted) return;
              }

              final completed = domain.Workout(
                id: workout.id,
                name: workout.name,
                startTime: workout.startTime,
                endTime: DateTime.now(),
                entries: workout.entries,
                notes: workout.notes,
                source: workout.source,
                plannedWorkoutId: workout.plannedWorkoutId,
                isGuided: workout.isGuided,
              );

              ref.read(activeWorkoutProvider.notifier).completeWorkout();
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutSummaryScreen(workout: completed),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(domain.Workout workout) {
    final l10n = AppLocalizations.of(context)!;
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedExerciseIndex = index),
      itemBuilder: (context, index) {
        final entry = workout.entries[index];
        final isCardio = entry.exercise.type == 'cardio';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.exercise.category,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCardio
                      ? Colors.orange.withAlpha(30)
                      : Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCardio ? Icons.directions_run : Icons.fitness_center,
                      size: 14,
                      color: isCardio ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCardio ? l10n.cardio : l10n.weightlifting,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isCardio ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (isCardio)
                _buildCardioDetail(entry, l10n)
              else ...[
                // Weightlifting entry: show sets + add form
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.sets} (${entry.sets.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (workout.isGuided)
                      Text(
                        '${entry.sets.where((s) => s.isCompleted).length}/${entry.sets.length} ${l10n.done}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (entry.sets.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${entry.totalReps} ${l10n.repsLower}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${entry.totalWeight.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (entry.sets.every((s) => s.isCompleted) &&
                          workout.isGuided)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              l10n.done,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (!workout.isGuided) ...[
                  const SizedBox(height: 8),
                  AddSetForm(
                    key: ValueKey('add-set-$_prefillVersion'),
                    initialReps: _prefillReps,
                    initialWeight: _prefillWeight,
                    onAdd: (reps, weight) => ref
                        .read(activeWorkoutProvider.notifier)
                        .addSet(index, reps, weight),
                  ),
                  const SizedBox(height: 16),
                ],
                ...List.generate(entry.sets.length, (i) {
                  final reversedIndex = entry.sets.length - 1 - i;
                  final set = entry.sets[reversedIndex];
                  if (workout.isGuided) {
                    return GuidedSetCard(
                      set: set,
                      index: reversedIndex,
                      onTap: () {
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .toggleSetCompleted(index, reversedIndex);
                      },
                      onLongPress: () =>
                          _editSetDialog(index, reversedIndex, set),
                      onPrefill: () => _prefillSet(set),
                    );
                  }
                  return FreeformSetCard(
                    set: set,
                    index: reversedIndex,
                    onLongPress: () =>
                        _editSetDialog(index, reversedIndex, set),
                    onPrefill: () => _prefillSet(set),
                  );
                }),
                if (workout.isGuided &&
                    entry.sets.any((s) => s.isCompleted) &&
                    !entry.sets.every((s) => s.isCompleted))
                  RestTimerOverlay(restSeconds: 60),
                PreviousSessionsPanel(exerciseName: entry.exercise.name),
              ],
            ],
          ),
        );
      },
      itemCount: workout.entries.length,
    );
  }

  Widget _buildCardioDetail(domain.WorkoutEntry entry, AppLocalizations l10n) {
    final currentDuration = entry.cardioDetail?.durationMinutes ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.cardioDuration}: $currentDuration ${l10n.minutesLower}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardioDurationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text(l10n.minutes),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (val) {
                  _cardioDurationMinutes = int.tryParse(val) ?? 0;
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.timer, size: 18),
              label: Text(l10n.setDuration),
              onPressed: () {
                final minutes = _cardioDurationMinutes;
                if (minutes > 0) {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .setCardioDuration(_selectedExerciseIndex ?? 0, minutes);
                  _cardioDurationController.clear();
                  _cardioDurationMinutes = 0;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Show current duration if set
        if (currentDuration > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '$currentDuration ${l10n.minutesLower}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editSetDialog(
    int exerciseIndex,
    int setIndex,
    domain.WeightSet set,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) {
        final repsC = TextEditingController(text: set.reps.toString());
        final weightC = TextEditingController(text: set.weightKg.toString());
        return AlertDialog(
          title: Text(l10n.editSet),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text(l10n.reps),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  label: Text(l10n.weightKg),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                repsC.dispose();
                weightC.dispose();
                Navigator.pop(ctx);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsC.text);
                final weight = double.tryParse(weightC.text);
                if (reps != null && weight != null) {
                  Navigator.pop(ctx, {
                    'reps': reps.toDouble(),
                    'weight': weight,
                  });
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      ref
          .read(activeWorkoutProvider.notifier)
          .updateSet(
            exerciseIndex,
            setIndex,
            result['reps']!.toInt(),
            result['weight']!,
          );
    }
  }
}
