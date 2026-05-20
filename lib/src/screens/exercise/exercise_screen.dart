import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../testing_flags.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_models.dart';
import '../../models/seance_models.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/seance_providers.dart';
import 'seance_library_screen.dart';
import 'create_seance_screen.dart';
import '../../widgets/appbar_seance_indicator.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSeance = ref.watch(activeSeanceProvider);

    if (activeSeance != null) {
      return const CurrentSeanceScreen();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            elevation: 0,
            title: const SizedBox.shrink(),
            actions: const [SeanceAppBarAction()],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Exercises'),
                Tab(text: 'Seances'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const ExercisesListTab(),
            const SeancesHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class ExercisesListTab extends ConsumerWidget {
  const ExercisesListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exerciseListProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          child: ListTile(
            title: Text(exercise.name),
            subtitle: Text(exercise.category),
            trailing: const Icon(Icons.info_outline),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: exercises.length,
    );
  }
}

class SeancesHistoryTab extends ConsumerWidget {
  const SeancesHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seances = ref.watch(seanceHistoryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Blank Seance'),
                      onPressed: () => ref.read(activeSeanceProvider.notifier).startSeance(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.library_books),
                      label: const Text('Templates / Start from Template'),
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const SeanceLibraryScreen(),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: seances.isEmpty
              ? const Center(child: Text('No seances yet'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemBuilder: (context, index) {
                    final seance = seances[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${seance.exercises.length} exercise${seance.exercises.length == 1 ? '' : 's'}',
                        ),
                        subtitle: Text(
                          '${DateFormat('MMM d, h:mm a').format(seance.startedAt)} • '
                          '${_formatDuration(seance.duration)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                // Create a template derived from this seance's exercises
                                final exercises = seance.exercises.map((e) {
                                  final lastSet = e.sets.isNotEmpty ? e.sets.last : null;
                                  return ExerciseTemplate(
                                    id: e.id,
                                    name: e.exercise.name,
                                    sets: e.sets.isNotEmpty ? e.sets.length : 3,
                                    reps: lastSet?.reps ?? 8,
                                    plannedWeightKg: lastSet?.weight,
                                    restSeconds: 60,
                                  );
                                }).toList();
                                final template = SeanceTemplate(
                                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                                  name: 'From ${DateFormat('MMM d').format(seance.startedAt)}',
                                  exercises: exercises,
                                );
                                await ref.read(templateListProvider.notifier).createTemplate(template);
                                final created = ref.read(templateListProvider).last;
                                // ignore: use_build_context_synchronously
                                await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => CreateSeanceScreen(template: created),
                                ));
                              },
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.history),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemCount: seances.length,
                ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class CurrentSeanceScreen extends ConsumerStatefulWidget {
  const CurrentSeanceScreen({super.key});

  @override
  ConsumerState<CurrentSeanceScreen> createState() => _CurrentSeanceScreenState();
}

class _CurrentSeanceScreenState extends ConsumerState<CurrentSeanceScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seance = ref.watch(activeSeanceProvider);
    final exercises = ref.watch(exerciseListProvider);

    if (seance == null) {
      return const Scaffold(
        body: Center(child: Text('No active seance')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Seance'),
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TimerWidget(seance: seance),
            ),
          ),
        ],
      ),
      body: seance.exercises.isEmpty
          ? _buildExerciseSelector(context, ref, exercises)
          : PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                return _buildExerciseDetail(
                  context,
                  ref,
                  seance,
                  index,
                  exercises,
                );
              },
              itemCount: seance.exercises.length,
            ),
      floatingActionButton: seance.exercises.isEmpty
          ? null
          : FloatingActionButton.extended(
              label: const Text('Complete Seance'),
              icon: const Icon(Icons.check),
              onPressed: () => ref.read(activeSeanceProvider.notifier).completeSeance(),
            ),
    );
  }

  Widget _buildExerciseSelector(
    BuildContext context,
    WidgetRef ref,
    List<ExerciseDefinition> exercises,
  ) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Select exercise to add'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
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
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: exercises.length,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseDetail(
    BuildContext context,
    WidgetRef ref,
    Seance seance,
    int exerciseIndex,
    List<ExerciseDefinition> exercises,
  ) {
    final entry = seance.exercises[exerciseIndex];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.exercise.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              entry.exercise.category,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Sets (${entry.sets.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(
              entry.sets.length,
              (i) {
                final set = entry.sets[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Set ${i + 1}'),
                        Text('${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Add Set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AddSetForm(
              onAdd: (reps, weight) {
                ref
                    .read(activeSeanceProvider.notifier)
                    .addSet(exerciseIndex, reps, weight);
              },
            ),
            const SizedBox(height: 24),
            if (entry.sets.isNotEmpty) ...[
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
                      Text('Total Weight: ${entry.totalWeight.toStringAsFixed(1)}kg'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
    if (disableUiTimers) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.seance.startedAt);
        });
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    return Text(
      '$minutes:${seconds.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class AddSetForm extends StatefulWidget {
  const AddSetForm({required this.onAdd, super.key});

  final Function(int reps, double weight) onAdd;

  @override
  State<AddSetForm> createState() => _AddSetFormState();
}

class _AddSetFormState extends State<AddSetForm> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();

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
