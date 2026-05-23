import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/exercise_models.dart';
import '../../models/seance_models.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/seance_providers.dart';
import 'create_seance_screen.dart';
import 'seance_library_screen.dart';

class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Seances'),
              Tab(text: 'Exercises'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [SeancesHistoryTab(), ExercisesListTab()],
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
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                        'Running Seance',
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
                    running.name ?? 'Unnamed seance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${running.exercises.length} exercise${running.exercises.length == 1 ? '' : 's'}',
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
                          label: const Text('View'),
                          onPressed: () => context.push('/current-seance'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
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
                context.push('/current-seance');
              });
            } else {
              ref
                  .read(activeSeanceProvider.notifier)
                  .startSeanceFromTemplate(template);
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
          '${seance.exercises.length} exercise${seance.exercises.length == 1 ? '' : 's'} • ${DateFormat('MMM d, h:mm a').format(seance.startedAt)} • ${_formatDuration(seance.duration)}${hasMore ? ' • +${seance.exercises.length - 3} more' : ''}',
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
