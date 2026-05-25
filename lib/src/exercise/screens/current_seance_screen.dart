import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../providers/seance.dart';

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
  }

  void _backToList() {
    setState(() => _selectedExerciseIndex = null);
  }

  Future<bool> _confirmDiscardEmptySeance() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard empty seance?'),
        content: const Text(
          'This seance has no exercises and will not be saved to history.',
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
      return const Scaffold(body: Center(child: Text('No active seance')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedExerciseIndex != null
              ? seance.exercises[_selectedExerciseIndex!].exercise.name
              : seance.name ?? 'Active Seance',
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
                  // If there's no previous route to pop to, go to Exercise tab
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
            padding: const EdgeInsets.all(16),
            child: Center(child: TimerWidget(seance: seance)),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Cancel seance',
            onPressed: () {
              ref.read(activeSeanceProvider.notifier).cancelSeance();
              context.go('/exercise');
            },
          ),
        ],
      ),
      body: _selectedExerciseIndex != null
          ? _buildDetailView(seance)
          : _buildExerciseListView(seance),
    );
  }

  Widget _buildExerciseListView(Seance seance) {
    final exercises = ref.watch(exerciseListProvider);
    final query = _exerciseSearchController.text.trim().toLowerCase();
    final addedNames = seance.exercises
        .map((e) => e.exercise.name.toLowerCase())
        .toSet();
    final filtered = query.isEmpty
        ? <ExerciseDefinition>[]
        : exercises.where((e) {
            final matches = e.name.toLowerCase().contains(query);
            return matches && !addedNames.contains(e.name.toLowerCase());
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (seance.exercises.isNotEmpty) ...[
          Text('Exercises', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...seance.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(e.exercise.name),
                subtitle: Text(
                  '${e.sets.length} set${e.sets.length == 1 ? '' : 's'}',
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
        Text('Add Exercise', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _exerciseSearchController,
          decoration: const InputDecoration(
            label: Text('Search exercises'),
            hintText: 'Type to find exercises...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (filtered.isNotEmpty)
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
          })
        else if (query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No exercises found matching "$query"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Complete Seance'),
            onPressed: () async {
              if (seance.exercises.isEmpty) {
                final discard = await _confirmDiscardEmptySeance();
                if (!discard || !context.mounted) return;
              }

              ref.read(activeSeanceProvider.notifier).completeSeance();
              if (context.mounted) {
                context.go('/exercise');
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(Seance seance) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedExerciseIndex = index),
      itemBuilder: (context, index) {
        final entry = seance.exercises[index];
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
              Text(
                'Sets (${entry.sets.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...List.generate(entry.sets.length, (i) {
                final set = entry.sets[i];
                final time = set.completedAt != null
                    ? DateFormat('HH:mm').format(set.completedAt!)
                    : null;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _editSetDialog(index, i, set),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Checkbox(
                            value: set.isCompleted,
                            onChanged: (_) => ref
                                .read(activeSeanceProvider.notifier)
                                .toggleSetCompleted(index, i),
                          ),
                          Expanded(child: Text('Set ${i + 1}')),
                          Text(
                            '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                          ),
                          if (time != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Text('Add Set', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              if (entry.sets.isNotEmpty)
                Card(
                  color: Colors.blue.withAlpha(26),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Total Reps: ${entry.totalReps}'),
                        Text(
                          'Total Weight: ${entry.totalWeight.toStringAsFixed(1)}kg',
                        ),
                      ],
                    ),
                  ),
                ),
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
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '$minutes:${seconds.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    if (oldWidget.initialReps != widget.initialReps &&
        widget.initialReps != null) {
      _repsController.text = widget.initialReps.toString();
    }
    if (oldWidget.initialWeight != widget.initialWeight &&
        widget.initialWeight != null) {
      _weightController.text = widget.initialWeight.toString();
    }
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
