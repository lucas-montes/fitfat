import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../providers/exercises.dart';
import 'exercise_form.dart';

final class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseListAppBar)),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (exercises) => exercises.isEmpty
            ? Center(child: Text(l10n.exerciseListEmpty))
            : ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (_, i) => _ExerciseTile(
                  exercise: exercises[i],
                  l10n: l10n,
                  onTap: () => _openForm(context, ref, exercises[i]),
                  onDelete: () => _deleteExercise(ref, exercises[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Exercise? existing,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: existing)),
    );
    if (saved == true) ref.invalidate(exerciseListProvider);
  }

  Future<void> _deleteExercise(WidgetRef ref, Exercise exercise) async {
    await ref.read(exerciseRepositoryProvider).delete(exercise.id);
    ref.invalidate(exerciseListProvider);
  }
}

final class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExerciseTile({
    required this.exercise,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(exercise.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.exerciseListDeleteTitle),
          content: Text(l10n.exerciseListDeleteConfirm(exercise.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        ),
      ).then((r) => r ?? false),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Icon(
          exercise.isWeightlifting
              ? Icons.fitness_center
              : Icons.directions_run,
        ),
        title: Text(exercise.name),
        subtitle: Text(
          exercise.isWeightlifting
              ? l10n.exerciseTypeWeightlifting
              : l10n.exerciseTypeCardio,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
