import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/seance.dart';
import '../../../models/exercise.dart';
import '../../../models/seance.dart';
import 'create.dart';

class SeanceHistoryCard extends ConsumerWidget {
  const SeanceHistoryCard({super.key, required this.seance});
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
                Text(seance.name, style: Theme.of(context).textTheme.bodySmall),
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
