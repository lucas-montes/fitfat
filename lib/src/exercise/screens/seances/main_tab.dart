import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../providers/seances/history.dart';
import '../../providers/seance.dart';
import 'template_card.dart';
import 'history_card.dart';
import 'create.dart';
import 'library.dart';

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
                    running.name,
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
                return TemplateCard(template: t);
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
            (seance) => SeanceHistoryCard(seance: seance),
          ),
      ],
    );
  }
}
