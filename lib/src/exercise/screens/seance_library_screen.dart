import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seance.dart';
import '../../l10n/app_localizations.dart';
import '../../services/seance_foreground_service.dart';
import 'create_seance_screen.dart';

class SeanceLibraryScreen extends ConsumerWidget {
  const SeanceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templateListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Template Library')),
      body: templates.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No templates yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create your first template'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateSeanceScreen(),
                        ),
                      );
                      await ref
                          .read(templateListProvider.notifier)
                          .loadTemplates();
                    },
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: templates.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = templates[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.exercises.length} exercise${t.exercises.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (t.exercises.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  t.exercises.map((e) => e.name).join(', '),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          onPressed: () {
                            final active = ref.read(activeSeanceProvider);
                            if (active != null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Workout already running'),
                                  content: const Text(
                                    'A workout is already in progress. Cancel it and start a new one?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        ref
                                            .read(activeSeanceProvider.notifier)
                                            .cancelSeance();
                                        ref
                                            .read(activeSeanceProvider.notifier)
                                            .startSeanceFromTemplate(t);
                                        // Update notification title and exercise name
                                        SeanceForegroundService.instance.start(
                                          DateTime.now(),
                                          seanceName: t.name,
                                          exerciseName: t.exercises.isNotEmpty
                                              ? t.exercises[0].name
                                              : null,
                                          notificationTitle:
                                              AppLocalizations.of(
                                                context,
                                              ).activeWorkout,
                                        );
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop();
                                        context.push('/current-seance');
                                      },
                                      child: const Text('Start new workout'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ref
                                  .read(activeSeanceProvider.notifier)
                                  .startSeanceFromTemplate(t);
                              // set localized notification title
                              SeanceForegroundService.instance.start(
                                DateTime.now(),
                                seanceName: t.name,
                                exerciseName: t.exercises.isNotEmpty
                                    ? t.exercises[0].name
                                    : null,
                                notificationTitle: AppLocalizations.of(
                                  context,
                                ).activeWorkout,
                              );
                              Navigator.of(context).pop();
                              context.push('/current-seance');
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CreateSeanceScreen(template: t),
                                  ),
                                );
                                await ref
                                    .read(templateListProvider.notifier)
                                    .loadTemplates();
                              case 'clone':
                                final cloned = await ref
                                    .read(templateListProvider.notifier)
                                    .cloneTemplate(t.id);
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
                                    .deleteTemplate(t.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'clone', child: Text('Clone')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateSeanceScreen()));
          await ref.read(templateListProvider.notifier).loadTemplates();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
