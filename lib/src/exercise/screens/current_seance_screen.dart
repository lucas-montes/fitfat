import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/seance_foreground_service.dart';
import '../../models/exercise.dart';
import '../providers/seance.dart';
import '../services/workout_services.dart';

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
  final _selectedCategories = <String>{};
  final _prService = ProgressionService();
  bool _notificationSynced = false;

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
    // Update foreground notification with current exercise
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

  Future<bool> _confirmDiscardEmptySeance() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard empty workout?'),
        content: const Text(
          'This workout has no exercises and will not be saved to history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final seance = ref.watch(activeSeanceProvider);

    if (seance == null) {
      return const Scaffold(body: Center(child: Text('No active workout')));
    }

    // Ensure foreground notification has localized title and initial exercise
    if (!_notificationSynced) {
      _notificationSynced = true;
      final notifTitle = AppLocalizations.of(context).activeWorkout;
      final initialExercise = seance.exercises.isNotEmpty
          ? seance.exercises[0].exercise.name
          : null;
      // Update the foreground service with localized title
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
              : seance.name ?? 'Active Workout',
        ),
        elevation: 0,
        leading: _selectedExerciseIndex != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToList,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to app',
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
          // Mode icon indicator (icon-only, no text)
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
            tooltip: 'Cancel workout',
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
    final exercises = ref.watch(exerciseListProvider);
    final seances = ref.watch(seanceHistoryProvider);
    final query = _exerciseSearchController.text.trim().toLowerCase();
    final allCategories = exercises.map((e) => e.category).toSet().toList()
      ..sort();

    final addedNames = seance.exercises
        .map((e) => e.exercise.name.toLowerCase())
        .toSet();

    // Compute recently used exercises from history
    final recentlyUsedOrder = <String>[];
    for (final s in seances.reversed) {
      for (final entry in s.exercises) {
        final name = entry.exercise.name.toLowerCase();
        if (!recentlyUsedOrder.contains(name)) {
          recentlyUsedOrder.add(name);
          if (recentlyUsedOrder.length >= 5) break;
        }
      }
      if (recentlyUsedOrder.length >= 5) break;
    }
    final recentlyUsed =
        exercises
            .where(
              (e) =>
                  recentlyUsedOrder.contains(e.name.toLowerCase()) &&
                  !addedNames.contains(e.name.toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => recentlyUsedOrder
                .indexOf(a.name.toLowerCase())
                .compareTo(recentlyUsedOrder.indexOf(b.name.toLowerCase())),
          );

    final filtered = exercises.where((e) {
      if (!addedNames.contains(e.name.toLowerCase())) {
        if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
          return false;
        }
        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(e.category)) {
          return false;
        }
        return true;
      }
      return false;
    }).toList();

    // Group filtered by category
    final grouped = <String, List<ExerciseDefinition>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (seance.exercises.isNotEmpty) ...[
          Row(
            children: [
              Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${seance.exercises.length} exercise${seance.exercises.length == 1 ? '' : 's'}',
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
                      ? '$completedSets/${e.sets.length} sets'
                      : '${e.sets.length} set${e.sets.length == 1 ? '' : 's'}',
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
          guided ? 'Follow the plan' : 'Add Exercise',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseSearchController,
          decoration: InputDecoration(
            label: Text(guided ? 'Search to add' : 'Search exercises'),
            hintText: guided
                ? 'Type to search exercises...'
                : 'Type to find exercises...',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        // Category filter chips
        if (allCategories.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = allCategories[i];
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        // Recently used section (when search is empty)
        if (query.isEmpty &&
            _selectedCategories.isEmpty &&
            recentlyUsed.isNotEmpty) ...[
          Text(
            'Recently used',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ...recentlyUsed.map((exercise) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(exercise.name),
                subtitle: Text(exercise.category),
                trailing: const Icon(Icons.add_circle),
                onTap: () => ref
                    .read(activeSeanceProvider.notifier)
                    .addExercise(exercise),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        // Filtered results grouped by category
        if (filtered.isNotEmpty)
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (query.isNotEmpty || _selectedCategories.isNotEmpty) ...[
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                ...entry.value.map((exercise) {
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
                const SizedBox(height: 8),
              ],
            );
          })
        else if (query.isNotEmpty || _selectedCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No exercises found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try a different search or clear filters',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Complete Workout'),
            onPressed: () async {
              if (seance.exercises.isEmpty) {
                final discard = await _confirmDiscardEmptySeance();
                if (!discard || !context.mounted) return;
              }

              ref.read(activeSeanceProvider.notifier).completeSeance();
              if (context.mounted) {
                // Show summary before returning to exercise
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
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedExerciseIndex = index),
      itemBuilder: (context, index) {
        final entry = seance.exercises[index];
        // Compute PRs by comparing current sets to historical best
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
        // A set is a PR if it beats the best historical set
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
                    'Sets (${entry.sets.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (guided)
                    Text(
                      '${entry.sets.where((s) => s.isCompleted).length}/${entry.sets.length} done',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Compact summary row
              if (entry.sets.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${entry.totalReps} reps',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${entry.totalWeight.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isPr &&
                        currentBest != null &&
                        currentBestVolume > bestVolume &&
                        bestVolume > 0)
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
                            'PR!',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    if (currentBest != null)
                      Text(
                        'e1RM: ${_prService.epleyOneRM(currentBest.weight, currentBest.reps)?.toStringAsFixed(1) ?? '-'} kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
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
                            'Done!',
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
              // Add Set form at the top (free-form only)
              if (!guided) ...[
                const SizedBox(height: 8),
                AddSetForm(
                  initialReps: entry.sets.isNotEmpty
                      ? entry.sets.last.reps
                      : null,
                  initialWeight: entry.sets.isNotEmpty
                      ? entry.sets.last.weight
                      : null,
                  onAdd: (reps, weight) => ref
                      .read(activeSeanceProvider.notifier)
                      .addSet(index, reps, weight),
                ),
                const SizedBox(height: 16),
              ],
              ...List.generate(entry.sets.length, (i) {
                final set = entry.sets[i];
                final currentVol = set.reps * set.weight;
                final setPr =
                    currentVol >= bestVolume &&
                    bestVolume > 0 &&
                    currentVol > 0;
                if (guided) {
                  return _GuidedSetCard(
                    set: set,
                    index: i,
                    isPr: setPr,
                    onTap: () {
                      ref
                          .read(activeSeanceProvider.notifier)
                          .toggleSetCompleted(index, i);
                    },
                    onLongPress: () => _editSetDialog(index, i, set),
                  );
                } else {
                  return _FreeformSetCard(
                    set: set,
                    index: i,
                    isPr: setPr,
                    onLongPress: () => _editSetDialog(index, i, set),
                  );
                }
              }),
              // Rest timer appears after completing a set in guided mode
              if (guided &&
                  entry.sets.any((s) => s.isCompleted) &&
                  !entry.sets.every((s) => s.isCompleted))
                _RestTimerOverlay(seance: seance),
              // Previous sessions history panel
              _PreviousSessionsPanel(exerciseName: entry.exercise.name),
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
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) {
        final repsC = TextEditingController(text: set.reps.toString());
        final weightC = TextEditingController(text: set.weight.toString());
        return AlertDialog(
          title: const Text('Edit Set'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text('Reps'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text('Weight (kg)'),
                  border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
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
              child: const Text('Save'),
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

// ── Previous sessions history panel ──

class _PreviousSessionsPanel extends ConsumerWidget {
  const _PreviousSessionsPanel({required this.exerciseName});

  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(seanceHistoryProvider);
    final relatedSeances = history
        .where(
          (s) =>
              s.completedAt != null &&
              s.exercises.any((e) => e.exercise.name == exerciseName),
        )
        .take(5)
        .toList();

    if (relatedSeances.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        title: Text(
          'Previous sessions (${relatedSeances.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: const Text('Tap to expand'),
        initiallyExpanded: false,
        children: relatedSeances.map((s) {
          final entry = s.exercises.firstWhere(
            (e) => e.exercise.name == exerciseName,
          );
          final dateStr =
              '${s.completedAt!.day.toString().padLeft(2, '0')}/'
              '${s.completedAt!.month.toString().padLeft(2, '0')}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...entry.sets.map(
                      (set) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Guided mode set card with swipe-to-complete ──

class _GuidedSetCard extends StatelessWidget {
  const _GuidedSetCard({
    required this.set,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    this.isPr = false,
  });

  final ExerciseSet set;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: set.isCompleted ? Colors.green.withAlpha(20) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: set.isCompleted ? Colors.green : null,
                  border: Border.all(
                    color: set.isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: set.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: set.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: set.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: set.isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (set.isCompleted)
                Text(
                  DateFormat('HH:mm').format(set.completedAt!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                )
              else
                Text(
                  'Tap to complete',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              if (isPr)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Dismissible for swipe-to-complete in guided mode
    if (!set.isCompleted) {
      return Dismissible(
        key: ValueKey('guided-set-$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => onTap(),
        child: card,
      );
    }

    return card;
  }
}

// ── Free-form mode set card ──

class _FreeformSetCard extends StatelessWidget {
  const _FreeformSetCard({
    required this.set,
    required this.index,
    required this.onLongPress,
    this.isPr = false,
  });

  final ExerciseSet set;
  final int index;
  final VoidCallback onLongPress;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                set.completedAt != null
                    ? DateFormat('HH:mm').format(set.completedAt!)
                    : '—',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (isPr)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timer widget ──

class TimerWidget extends ConsumerStatefulWidget {
  const TimerWidget({required this.seance, super.key});

  final Seance seance;

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> {
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = Duration.zero;
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(
          () => _elapsed = DateTime.now().difference(widget.seance.startedAt),
        );
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _elapsed.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;
    final timeText = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '$minutes:${seconds.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        timeText,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Add Set Form ──

class AddSetForm extends StatefulWidget {
  const AddSetForm({
    super.key,
    required this.onAdd,
    this.initialReps,
    this.initialWeight,
  });

  final Function(int reps, double weight) onAdd;
  final int? initialReps;
  final double? initialWeight;

  @override
  State<AddSetForm> createState() => _AddSetFormState();
}

class _AddSetFormState extends State<AddSetForm> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(AddSetForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Do not overwrite user input — pre-fill only happens once in initState
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text('Reps'),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  label: Text('Weight (kg)'),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Set'),
          onPressed: () {
            final reps = int.tryParse(_repsController.text) ?? 0;
            final weight = double.tryParse(_weightController.text) ?? 0;
            if (reps > 0 && weight > 0) {
              widget.onAdd(reps, weight);
              _repsController.clear();
              _weightController.clear();
            }
          },
        ),
      ],
    );
  }
}

// ── Rest Timer Overlay ──

class _RestTimerOverlay extends ConsumerStatefulWidget {
  const _RestTimerOverlay({required this.seance});

  final Seance seance;

  @override
  ConsumerState<_RestTimerOverlay> createState() => _RestTimerOverlayState();
}

class _RestTimerOverlayState extends ConsumerState<_RestTimerOverlay> {
  @override
  void initState() {
    super.initState();
    final restSeconds = widget.seance.restBetweenSets.inSeconds;
    Future.microtask(() {
      ref.read(restTimerProvider.notifier).startRest(restSeconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(restTimerProvider);
    if (!timer.isRunning && timer.remainingSeconds == 0) {
      return const SizedBox.shrink();
    }

    final minutes = timer.remainingSeconds ~/ 60;
    final seconds = timer.remainingSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        color: timer.isFinished
            ? Colors.green.withAlpha(26)
            : Colors.orange.withAlpha(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.timer, size: 20),
                  Text(
                    'Rest Timer',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(restTimerProvider.notifier).skipRest(),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                timer.isFinished
                    ? 'Rest over!'
                    : '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: timer.isFinished ? Colors.green : null,
                ),
              ),
              if (timer.isFinished) ...[
                const SizedBox(height: 8),
                const Text(
                  'Get ready for your next set!',
                  style: TextStyle(color: Colors.green),
                ),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: timer.progress,
                color: timer.isFinished ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Seance Summary Screen (EX07) ──

class SeanceSummaryScreen extends StatelessWidget {
  const SeanceSummaryScreen({required this.seance, super.key});

  final Seance seance;

  @override
  Widget build(BuildContext context) {
    final duration = seance.duration;
    final totalVolume = seance.exercises.fold<double>(
      0,
      (sum, entry) =>
          sum +
          entry.sets.fold<double>(0, (s, set) => s + (set.reps * set.weight)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seance name & duration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seance.name ?? 'Untitled Workout',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${duration.inHours}h ${(duration.inMinutes % 60)}m',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${totalVolume.toStringAsFixed(0)} kg',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exercises',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${seance.exercises.length}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Per-exercise breakdown
          Text(
            'Exercise Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...seance.exercises.map((entry) {
            final totalSets = entry.sets.length;
            final completedSets = entry.sets.where((s) => s.isCompleted).length;
            final exVolume = entry.sets.fold<double>(
              0,
              (s, set) => s + (set.reps * set.weight),
            );
            final bestSet = entry.sets.isEmpty
                ? null
                : entry.sets.reduce(
                    (a, b) => (a.weight * a.reps) > (b.weight * b.reps) ? a : b,
                  );
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.exercise.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (bestSet != null &&
                            (bestSet.weight * bestSet.reps) > 0)
                          Chip(
                            label: const Text('Best'),
                            avatar: const Icon(Icons.emoji_events, size: 16),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedSets/$totalSets sets | ${exVolume.toStringAsFixed(0)} kg volume',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (bestSet != null)
                      Text(
                        'Best: ${bestSet.reps}x${bestSet.weight.toStringAsFixed(1)}kg',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          // Finish button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Finish'),
              onPressed: () {
                Navigator.of(context).popUntil(
                  (route) =>
                      route.isFirst || route.settings.name == '/exercise',
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
