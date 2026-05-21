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
    final hasActiveSeance = activeSeance != null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            elevation: 0,
            title: const SizedBox.shrink(),
            actions: const [SeanceAppBarAction()],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Seances'),
                Tab(text: 'Exercises'),
                Tab(text: 'Current Seance'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const SeancesHistoryTab(),
            const ExercisesListTab(),
            hasActiveSeance
                ? const CurrentSeanceScreen()
                : const Center(child: Text('No active seance')),
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
    final templates = ref.watch(templateListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Start seance section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Seance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Blank Seance'),
                    onPressed: () {
                      final active = ref.read(activeSeanceProvider);
                      if (active != null) {
                        confirmReplaceSeance(context, ref, () {
                          ref.read(activeSeanceProvider.notifier).startSeance();
                          DefaultTabController.of(context).animateTo(2);
                        });
                      } else {
                        ref.read(activeSeanceProvider.notifier).startSeance();
                        DefaultTabController.of(context).animateTo(2);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Templates section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Templates', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateSeanceScreen()),
                );
                await ref.read(templateListProvider.notifier).loadTemplates();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (templates.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final t = templates[index];
                return _TemplateCard(template: t);
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No templates yet. Create one to quickly start a seance!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (templates.isNotEmpty) ...[
          TextButton.icon(
            icon: const Icon(Icons.library_books, size: 18),
            label: const Text('Browse all templates'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SeanceLibraryScreen()),
              );
              await ref.read(templateListProvider.notifier).loadTemplates();
            },
          ),
        ],
        const SizedBox(height: 16),
        // History section
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (seances.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No seances yet. Start your first one above!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...seances.reversed.map(
            (seance) => _SeanceHistoryCard(seance: seance),
          ),
      ],
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});

  final SeanceTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final active = ref.read(activeSeanceProvider);
            if (active != null) {
              confirmReplaceSeance(context, ref, () {
                ref
                    .read(activeSeanceProvider.notifier)
                    .startSeanceFromTemplate(template);
                DefaultTabController.of(context).animateTo(2);
              });
            } else {
              ref
                  .read(activeSeanceProvider.notifier)
                  .startSeanceFromTemplate(template);
              DefaultTabController.of(context).animateTo(2);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateSeanceScreen(template: template),
                              ),
                            );
                            await ref
                                .read(templateListProvider.notifier)
                                .loadTemplates();
                          case 'clone':
                            final cloned = await ref
                                .read(templateListProvider.notifier)
                                .cloneTemplate(template.id);
                            if (context.mounted) {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateSeanceScreen(template: cloned),
                                ),
                              );
                              await ref
                                  .read(templateListProvider.notifier)
                                  .loadTemplates();
                            }
                          case 'delete':
                            await ref
                                .read(templateListProvider.notifier)
                                .deleteTemplate(template.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'clone', child: Text('Clone')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${template.exercises.length} exercise${template.exercises.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 14),
                    const SizedBox(width: 4),
                    Text('Start', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeanceHistoryCard extends ConsumerWidget {
  const _SeanceHistoryCard({required this.seance});

  final Seance seance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseNames = seance.exercises
        .map((e) => e.exercise.name)
        .take(3)
        .join(', ');
    final hasMore = seance.exercises.length > 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(exerciseNames.isNotEmpty ? exerciseNames : 'Empty seance'),
        subtitle: Text(
          '${seance.exercises.length} exercise${seance.exercises.length == 1 ? '' : 's'} • '
          '${DateFormat('MMM d, h:mm a').format(seance.startedAt)} • '
          '${_formatDuration(seance.duration)}${hasMore ? ' • +${seance.exercises.length - 3} more' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'create-template') {
              final exercises = seance.exercises.map((e) {
                return ExerciseTemplate(
                  id: e.id,
                  name: e.exercise.name,
                  plannedSets: e.sets.isNotEmpty
                      ? e.sets
                            .map(
                              (s) =>
                                  PlannedSet(reps: s.reps, weightKg: s.weight),
                            )
                            .toList()
                      : [const PlannedSet(reps: 8)],
                );
              }).toList();
              final template = SeanceTemplate(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: 'From ${DateFormat('MMM d').format(seance.startedAt)}',
                exercises: exercises,
              );
              await ref
                  .read(templateListProvider.notifier)
                  .createTemplate(template);
              final created = ref.read(templateListProvider).last;
              if (context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateSeanceScreen(template: created),
                  ),
                );
                await ref.read(templateListProvider.notifier).loadTemplates();
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'create-template',
              child: Text('Create template from this'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

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
    setState(() {
      _selectedExerciseIndex = null;
    });
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
            : null,
        automaticallyImplyLeading: _selectedExerciseIndex != null,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: TimerWidget(seance: seance)),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Cancel seance',
            onPressed: () =>
                ref.read(activeSeanceProvider.notifier).cancelSeance(),
          ),
        ],
      ),
      body: _selectedExerciseIndex != null
          ? _buildDetailView(seance)
          : _buildExerciseListView(seance),
      floatingActionButton:
          _selectedExerciseIndex == null && seance.exercises.isNotEmpty
          ? FloatingActionButton.extended(
              label: const Text('Complete Seance'),
              icon: const Icon(Icons.check),
              onPressed: () =>
                  ref.read(activeSeanceProvider.notifier).completeSeance(),
            )
          : (_selectedExerciseIndex != null &&
                _selectedExerciseIndex == seance.exercises.length - 1)
          ? FloatingActionButton.extended(
              label: const Text('Complete Seance'),
              icon: const Icon(Icons.check),
              onPressed: () =>
                  ref.read(activeSeanceProvider.notifier).completeSeance(),
            )
          : null,
    );
  }

  Widget _buildExerciseListView(Seance seance) {
    final exercises = ref.watch(exerciseListProvider);
    // NOTE: query is empty by default — no exercises shown until user types.
    final query = _exerciseSearchController.text.trim().toLowerCase();
    // Filter: only show exercises matching the query AND not already in the seance
    // NOTE: Match by name too, not just ID, because template-started seances use
    // template IDs that don't match the global exercise list IDs.
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Already added exercises — each has a remove button and chevron to enter detail
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
                // NOTE: entire row is tappable to enter detail view
                onTap: () => _selectExercise(i),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    ref.read(activeSeanceProvider.notifier).removeExercise(i);
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        // Search field — no exercise list shown below unless user types
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
        // Only show results when the user has typed something
        if (filtered.isNotEmpty)
          ...filtered.map((exercise) {
            return Card(
              child: ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.category),
                trailing: addedNames.contains(exercise.name.toLowerCase())
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.add_circle),
                onTap: addedNames.contains(exercise.name.toLowerCase())
                    ? null
                    : () => ref
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
      ],
    );
  }

  Widget _buildDetailView(Seance seance) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _selectedExerciseIndex = index);
      },
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
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Set ${i + 1}'),
                        Text(
                          '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Text('Add Set', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              AddSetForm(
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
}

// ---------------------------------------------------------------------------
// Seance guard helper
// ---------------------------------------------------------------------------

void confirmReplaceSeance(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Seance already running'),
      content: const Text(
        'A seance is already in progress. Cancel it and start a new one?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(activeSeanceProvider.notifier).cancelSeance();
            Navigator.pop(ctx);
            onConfirm();
          },
          child: const Text('Start new seance'),
        ),
      ],
    ),
  );
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
