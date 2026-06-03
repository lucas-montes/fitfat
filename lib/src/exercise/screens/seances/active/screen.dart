import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../exercise/providers/seances/history.dart';

import '../../../../services/seance_foreground_service.dart';
import '../../../../models/exercise.dart';
import '../../../providers/seance.dart';
import '../../../providers/exercises.dart';

import '../../../services/workout_services.dart';

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
  final _prService = ProgressionService();
  bool _notificationSynced = false;
  int _prefillVersion = 0;
  int? _prefillReps;
  double? _prefillWeight;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _exerciseSearchController.dispose();
    super.dispose();
  }

  void _selectExercise(int index) {
    setState(() {
      _selectedExerciseIndex = index;
      _pageController = PageController(initialPage: index);
    });
    final seance = ref.read(activeSeanceProvider);
    if (seance != null && index < seance.exercises.length) {
      SeanceForegroundService.instance.updateExerciseName(
        seance.exercises[index].exercise.name,
      );
    }
  }

  void _backToList() {
    setState(() => _selectedExerciseIndex = null);
  }

  void _prefillSet(ExerciseSet set) {
    setState(() {
      _prefillReps = set.reps;
      _prefillWeight = set.weight;
      _prefillVersion++;
    });
  }

  Future<bool> _confirmDiscardEmptySeance() async {
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
    final seance = ref.watch(activeSeanceProvider);

    if (seance == null) {
      return Scaffold(body: Center(child: Text(l10n.noActiveSeance)));
    }

    if (!_notificationSynced) {
      _notificationSynced = true;
      final notifTitle = AppLocalizations.of(context)!.activeWorkout;
      final initialExercise = seance.exercises.isNotEmpty
          ? seance.exercises[0].exercise.name
          : null;
      SeanceForegroundService.instance.start(
        seance.startedAt,
        seanceName: seance.name,
        exerciseName: initialExercise,
        notificationTitle: notifTitle,
      );
    }

    final guided = seance.isGuided;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedExerciseIndex != null
              ? seance.exercises[_selectedExerciseIndex!].exercise.name
              : seance.name,
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
              guided ? Icons.list_alt : Icons.playlist_add,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: TimerWidget(seance: seance)),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: l10n.cancelSeance,
            onPressed: () {
              ref.read(activeSeanceProvider.notifier).cancelSeance();
              context.go('/exercise');
            },
          ),
        ],
      ),
      body: _selectedExerciseIndex != null
          ? _buildDetailView(seance, guided)
          : _buildExerciseListView(seance, guided),
    );
  }

  Widget _buildExerciseListView(Seance seance, bool guided) {
    final l10n = AppLocalizations.of(context)!;
    final exercises = ref.watch(exerciseListProvider);
    final query = _exerciseSearchController.text.trim().toLowerCase();

    final addedNames = seance.exercises
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
        if (seance.exercises.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l10n.exercises,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                l10n.exercisesCount(seance.exercises.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...seance.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final completedSets = e.sets.where((s) => s.isCompleted).length;
            return Card(
              child: ListTile(
                leading: guided
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
                    : const Icon(Icons.fitness_center),
                title: Text(e.exercise.name),
                subtitle: Text(
                  guided
                      ? '$completedSets/${e.sets.length} ${l10n.setsLower}'
                      : l10n.setsCount(e.sets.length),
                ),
                onTap: () => _selectExercise(i),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () =>
                      ref.read(activeSeanceProvider.notifier).removeExercise(i),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        Text(
          guided ? l10n.followPlan : l10n.addExercise,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseSearchController,
          decoration: InputDecoration(
            label: Text(guided ? l10n.searchToAdd : l10n.searchExercises),
            hintText: guided
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
                guided ? l10n.searchToAdd : l10n.typeToFindExercises,
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
            return Card(
              child: ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.category),
                trailing: const Icon(Icons.add_circle),
                onTap: () => ref
                    .read(activeSeanceProvider.notifier)
                    .addExercise(exercise),
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
              if (seance.exercises.isEmpty) {
                final discard = await _confirmDiscardEmptySeance();
                if (!discard || !context.mounted) return;
              }

              ref.read(activeSeanceProvider.notifier).completeSeance();
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SeanceSummaryScreen(seance: seance),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(Seance seance, bool guided) {
    final l10n = AppLocalizations.of(context)!;
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedExerciseIndex = index),
      itemBuilder: (context, index) {
        final entry = seance.exercises[index];
        final history = ref.watch(seanceHistoryProvider);
        final historicalSets = history
            .where(
              (s) =>
                  s.id != seance.id &&
                  s.exercises.any(
                    (e) => e.exercise.name == entry.exercise.name,
                  ),
            )
            .expand(
              (s) => s.exercises
                  .firstWhere((e) => e.exercise.name == entry.exercise.name)
                  .sets,
            )
            .toList();
        final prService = _prService;
        final bestHistorical = prService.findBestSet(historicalSets);
        final bestVolume = bestHistorical != null
            ? bestHistorical.reps * bestHistorical.weight
            : 0.0;
        final currentBest = prService.findBestSet(entry.sets);
        final currentBestVolume = currentBest != null
            ? currentBest.reps * currentBest.weight
            : 0.0;
        final isPr = currentBest != null && currentBestVolume > bestVolume;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.exercise.category,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.sets} (${entry.sets.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (guided)
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
                    if (isPr && bestVolume > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            l10n.pr,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    if (entry.sets.every((s) => s.isCompleted) && guided)
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
              if (!guided) ...[
                const SizedBox(height: 8),
                AddSetForm(
                  key: ValueKey('add-set-$_prefillVersion'),
                  initialReps: _prefillReps,
                  initialWeight: _prefillWeight,
                  onAdd: (reps, weight) => ref
                      .read(activeSeanceProvider.notifier)
                      .addSet(index, reps, weight),
                ),
                const SizedBox(height: 16),
              ],
              ...List.generate(entry.sets.length, (i) {
                final reversedIndex = entry.sets.length - 1 - i;
                final set = entry.sets[reversedIndex];
                final currentVol = set.reps * set.weight;
                final setPr =
                    currentVol >= bestVolume &&
                    bestVolume > 0 &&
                    currentVol > 0;
                if (guided) {
                  return GuidedSetCard(
                    set: set,
                    index: entry.sets.length - i,
                    isPr: setPr,
                    onTap: () {
                      ref
                          .read(activeSeanceProvider.notifier)
                          .toggleSetCompleted(index, reversedIndex);
                    },
                    onLongPress: () =>
                        _editSetDialog(index, reversedIndex, set),
                    onPrefill: () => _prefillSet(set),
                  );
                }
                return FreeformSetCard(
                  set: set,
                  index: entry.sets.length - i,
                  isPr: setPr,
                  onLongPress: () => _editSetDialog(index, reversedIndex, set),
                  onPrefill: () => _prefillSet(set),
                );
              }),
              if (guided &&
                  entry.sets.any((s) => s.isCompleted) &&
                  !entry.sets.every((s) => s.isCompleted))
                RestTimerOverlay(seance: seance),
              PreviousSessionsPanel(exerciseName: entry.exercise.name),
            ],
          ),
        );
      },
      itemCount: seance.exercises.length,
    );
  }

  Future<void> _editSetDialog(
    int exerciseIndex,
    int setIndex,
    ExerciseSet set,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) {
        final repsC = TextEditingController(text: set.reps.toString());
        final weightC = TextEditingController(text: set.weight.toString());
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
          .read(activeSeanceProvider.notifier)
          .updateSet(
            exerciseIndex,
            setIndex,
            result['reps']!.toInt(),
            result['weight']!,
          );
    }
  }
}
