import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../services/seance_foreground_service.dart';
import '../../dashboard/screens/main.dart' as dashboard;
import '../../dashboard/providers/dashboard.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../../models/seance.dart';
import '../providers/seance.dart';
import 'exercise_history_screen.dart';
import 'create_seance_screen.dart';
import 'seance_library_screen.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.workoutsTab),
              Tab(text: l10n.exercises),
              Tab(text: l10n.statsTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SeancesHistoryTab(), ExercisesListTab(), StatsTab()],
        ),
      ),
    );
  }
}

class ExercisesListTab extends ConsumerStatefulWidget {
  const ExercisesListTab({super.key});

  @override
  ConsumerState<ExercisesListTab> createState() => _ExercisesListTabState();
}

class _ExercisesListTabState extends ConsumerState<ExercisesListTab> {
  final _searchController = TextEditingController();
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseListProvider);
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();
    final allCategories = exercises.map((e) => e.category).toSet().toList()
      ..sort();

    final filtered = exercises.where((e) {
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(e.category)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchExercisesHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (allCategories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noExercisesFoundSimple,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.noExercisesFoundAction,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return Card(
                      child: ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(exercise.category),
                        trailing: const Icon(Icons.info_outline),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseHistoryScreen(exercise: exercise),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SeancesHistoryTab extends ConsumerWidget {
  const SeancesHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seances = ref.watch(seanceHistoryProvider);
    final templates = ref.watch(templateListProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (ref.watch(activeSeanceProvider) case final running?)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.runningWorkout,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    running.name ?? l10n.unnamedWorkout,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.exercisesCount(running.exercises.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.visibility),
                          label: Text(l10n.viewWorkout),
                          onPressed: () => context.push('/current-seance'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.stopWorkout),
                          onPressed: () => ref
                              .read(activeSeanceProvider.notifier)
                              .cancelSeance(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.newSeance,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.startBlankSeance),
                      onPressed: () {
                        ref.read(activeSeanceProvider.notifier).startSeance();
                        context.push('/current-seance');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.templates,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.create),
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
                l10n.noTemplatesYet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (templates.isNotEmpty) ...[
          TextButton.icon(
            icon: const Icon(Icons.library_books, size: 18),
            label: Text(l10n.browseAllTemplates),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SeanceLibraryScreen()),
              );
              await ref.read(templateListProvider.notifier).loadTemplates();
            },
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.history, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (seances.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.noWorkoutsYet,
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

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final daySummaries = ref.watch(workoutDaySummariesProvider);

    final totalWorkouts = daySummaries.fold<int>(
      0,
      (sum, day) => sum + (day.hasWorkout ? 1 : 0),
    );
    final totalVolume = daySummaries.fold<double>(
      0,
      (sum, day) => sum + day.volume,
    );
    final totalDuration = daySummaries.fold<Duration>(
      Duration.zero,
      (sum, day) => sum + day.duration,
    );
    final totalMinutes = totalDuration.inMinutes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Overview stats row
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.allTime,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.fitness_center,
                      label: l10n.workouts,
                      value: '$totalWorkouts',
                    ),
                    _StatItem(
                      icon: Icons.monitor_weight,
                      label: l10n.volume,
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                    ),
                    _StatItem(
                      icon: Icons.timer,
                      label: l10n.duration,
                      value: '${totalMinutes}m',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // This week
        Text(l10n.thisWeek, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const dashboard.WorkoutStatsRow(),
        const SizedBox(height: 16),
        // Heatmap
        Text(l10n.activity, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const dashboard.WorkoutHeatmapCard(),
        const SizedBox(height: 16),
        // Charts
        Text(l10n.trends, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        dashboard.StrengthTrendChart(),
        const SizedBox(height: 16),
        dashboard.BodyweightTrendChart(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template});
  final SeanceTemplate template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
                // update notification
                SeanceForegroundService.instance.start(
                  DateTime.now(),
                  seanceName: template.name,
                  exerciseName: template.exercises.isNotEmpty
                      ? template.exercises[0].name
                      : null,
                  notificationTitle: AppLocalizations.of(
                    context,
                  )!.activeWorkout,
                );
                context.push('/current-seance');
              });
            } else {
              ref
                  .read(activeSeanceProvider.notifier)
                  .startSeanceFromTemplate(template);
              SeanceForegroundService.instance.start(
                DateTime.now(),
                seanceName: template.name,
                exerciseName: template.exercises.isNotEmpty
                    ? template.exercises[0].name
                    : null,
                notificationTitle: AppLocalizations.of(context)!.activeWorkout,
              );
              context.push('/current-seance');
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
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'clone', child: Text(l10n.clone)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.exercisesCount(template.exercises.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      l10n.start,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(seance.startedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateStr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  seance.name ?? l10n.workout,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showMenu(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (seance.exercises.isEmpty)
              Text(
                l10n.noExercises,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...seance.exercises.map((entry) {
                final setCount = entry.sets.length;
                final setSummary = entry.sets
                    .map((s) => '${s.reps}×${s.weight.toStringAsFixed(0)}')
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.exercise.name}: ${l10n.setsCount(setCount)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (setSummary.isNotEmpty)
                        Flexible(
                          child: Text(
                            setSummary,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 4),
            Text(
              _formatDuration(seance.duration),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(AppLocalizations.of(context)!.createTemplateFrom),
              onTap: () async {
                Navigator.pop(ctx);
                final exercises = seance.exercises.map((e) {
                  return ExerciseTemplate(
                    id: e.id,
                    name: e.exercise.name,
                    plannedSets: e.sets.isNotEmpty
                        ? e.sets
                              .map(
                                (s) => PlannedSet(
                                  reps: s.reps,
                                  weightKg: s.weight,
                                ),
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
              },
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

void confirmReplaceSeance(
  BuildContext context,
  WidgetRef ref,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(l10n.workoutAlreadyRunning),
        content: Text(l10n.workoutAlreadyRunningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(activeSeanceProvider.notifier).cancelSeance();
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(l10n.startNewWorkout),
          ),
        ],
      );
    },
  );
}
