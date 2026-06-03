import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../providers/seance.dart';
import '../../../services/seance_foreground_service.dart';
import '../../../models/seance.dart';
import 'create.dart';

class TemplateCard extends ConsumerWidget {
  const TemplateCard({super.key, required this.template});
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
