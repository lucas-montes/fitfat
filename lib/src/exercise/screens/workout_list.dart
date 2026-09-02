import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/workout.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/status_badge.dart';
import '../providers/workouts.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../settings/providers/settings.dart';
import 'exercise_list.dart';
import 'workout_detail.dart';
import 'workout_form.dart';
import 'workout_templates_screen.dart';

final class WorkoutListScreen extends ConsumerStatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  ConsumerState<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

final class _WorkoutListScreenState extends ConsumerState<WorkoutListScreen> {
  /// Local mirror of the provider data. Lets us remove a deleted item from
  /// the tree synchronously (required by [Dismissible]) before the async
  /// delete + provider refresh completes.
  List<Workout>? _workouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workoutsAsync = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutListAppBar),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: l10n.templatesTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutTemplatesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fitness_center),
            tooltip: l10n.workoutListManageBtn,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseListScreen()),
            ),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => _workouts == null
            ? const Center(child: CircularProgressIndicator())
            : _buildList(l10n, _workouts!),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (workouts) {
          _workouts = workouts;
          return workouts.isEmpty
              ? EmptyState(
                  icon: Icons.fitness_center,
                  title: l10n.emptyWorkoutsTitle,
                  description: l10n.emptyWorkoutsBody,
                  ctaLabel: l10n.emptyWorkoutsCta,
                  onCtaPressed: () => _openForm(context, ref),
                )
              : _buildList(l10n, workouts);
        },
      ),
      floatingActionButton: FloatingActionButton(heroTag: null, 
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n, List<Workout> workouts) =>
      ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (_, i) => _WorkoutTile(
          workout: workouts[i],
          l10n: l10n,
          onTap: () => _openDetail(context, ref, workouts[i]),
          onEdit: () => _editWorkout(context, ref, workouts[i]),
          onDelete: () => _deleteWorkout(context, ref, workouts[i]),
          onDuplicate: () => _duplicateWorkout(context, ref, workouts[i]),
          onLongPress: () => _showTileMenu(context, ref, workouts[i]),
        ),
      );

  void _removeLocally(Workout workout) {
    if (_workouts == null) return;
    setState(() {
      _workouts!.removeWhere((w) => w.id == workout.id);
    });
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const WorkoutFormScreen()));
    if (saved == true) ref.invalidate(workoutListProvider);
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    if (workout.isActive) {
      context.go('/active-workout');
      return;
    }
    if (workout.isCompleted) {
      context.go('/workout-summary/${workout.id}');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
      ),
    );
    ref.invalidate(workoutListProvider);
  }

  Future<void> _editWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final detail = await ref.read(workoutDetailProvider(workout.id).future);
    if (detail == null || !context.mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(initial: detail)),
    );
    if (saved == true) ref.invalidate(workoutListProvider);
  }

  Future<void> _duplicateWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await ref
        .read(workoutRepositoryProvider)
        .copyWorkout(sourceWorkoutId: workout.id);
    ref.invalidate(workoutListProvider);
  }

  /// Long-press tile menu: Duplicate (independent copy) and Replay (next
  /// lineage occurrence prefilled per the replay-prefill setting).
  Future<void> _showTileMenu(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.replay),
              title: Text(l10n.workoutActionReplay),
              onTap: () => Navigator.of(ctx).pop('replay'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(l10n.workoutActionDuplicate),
              onTap: () => Navigator.of(ctx).pop('duplicate'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'replay':
        await _replayWorkout(context, ref, workout);
      case 'duplicate':
        await _duplicateWorkout(context, ref, workout);
    }
  }

  /// Creates the next replay occurrence (prefill per settings) and opens it
  /// in the editable workout form.
  Future<void> _replayWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final prefill = ref.read(settingsProvider).replayPrefill;
    final created = await ref
        .read(workoutRepositoryProvider)
        .replayWorkout(sourceWorkoutId: workout.id, prefill: prefill);
    ref.invalidate(workoutListProvider);
    if (!context.mounted) return;
    final detail = await ref.read(workoutDetailProvider(created.id).future);
    if (detail == null || !context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(initial: detail)),
    );
    if (context.mounted) {
      ref.invalidate(workoutListProvider);
      invalidateDashboard(ref);
    }
  }

  Future<void> _deleteWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    // Remove the tile synchronously so the Dismissible is gone from the tree
    // before the async delete + provider refresh finishes.
    _removeLocally(workout);
    final snapshot = await ref
        .read(workoutRepositoryProvider)
        .deleteWithSnapshot(workout.id);
    ref.invalidate(workoutListProvider);
    invalidateDashboard(ref);
    if (context.mounted) {
      showTopBanner(
        context,
        message: l10n.workoutDeleted(workout.name),
        actionLabel: l10n.commonUndo,
        onAction: () async {
          await ref.read(workoutRepositoryProvider).restore(snapshot);
          ref.invalidate(workoutListProvider);
          invalidateDashboard(ref);
        },
      );
    }
  }
}

final class _WorkoutTile extends StatelessWidget {
  final Workout workout;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onLongPress;

  const _WorkoutTile({
    required this.workout,
    required this.l10n,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColors = theme.extension<FitFatColors>()!;
    final statusColor = workout.isCompleted
        ? statusColors.success
        : workout.isActive
        ? statusColors.warning
        : theme.colorScheme.outline;
    final statusLabel = workout.isCompleted
        ? l10n.statusCompleted
        : workout.isActive
        ? l10n.statusActive
        : l10n.statusPending;

    final dateStr = DateFormats.formatDate(context, workout.date);

    final canEdit = workout.isPending;

    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.horizontal,
      // Swipe right → edit (only for not-yet-started workouts).
      background: canEdit
          ? Container(
              color: theme.colorScheme.primary,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Icon(Icons.edit, color: theme.colorScheme.onPrimary),
            )
          : const SizedBox.shrink(),
      // Swipe left → delete.
      secondaryBackground: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!canEdit) return false;
          onEdit();
          // Don't actually remove the tile; editing just opens the form.
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) onDelete();
      },
      child: ListTile(
        title: Text(workout.name),
        subtitle: Text(dateStr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(label: statusLabel, color: statusColor),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
