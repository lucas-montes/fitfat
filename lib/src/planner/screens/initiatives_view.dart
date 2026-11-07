import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../goals/notifications/goal_reminder.dart';
import '../../goals/providers/goals.dart';
import '../../goals/screens/goal_detail_screen.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../planner/providers/dismissed.dart';
import '../../planner/providers/planner.dart';
import '../../planner/repositories/links_repository.dart' show LabeledTask;
import '../../settings/providers/settings.dart';
import '../../ui/cascade_delete_dialog.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/top_banner.dart';

/// "Initiatives" view (inside the Plan tab): goals grouped by lifecycle status.
final class InitiativesView extends ConsumerStatefulWidget {
  final VoidCallback? onAdd;

  const InitiativesView({super.key, this.onAdd});

  @override
  ConsumerState<InitiativesView> createState() => _InitiativesViewState();
}

final class _InitiativesViewState extends ConsumerState<InitiativesView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goalsAsync = ref.watch(goalListProvider);
    final dismissed = ref.watch(dismissedTaskIdsProvider);

    final goals = goalsAsync.value ?? const <Goal>[];

    if (goalsAsync.isLoading && !goalsAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (goalsAsync.hasError && !goalsAsync.hasValue) {
      return Center(
        child: Text(l10n.errorWithMessage('${goalsAsync.error}')),
      );
    }

    final items = [...goals]
      ..sort((a, b) {
        final r = _statusRank(a.status.storage).compareTo(
          _statusRank(b.status.storage),
        );
        if (r != 0) return r;
        final aStart = a.startDate ?? DateTime(0);
        final bStart = b.startDate ?? DateTime(0);
        return aStart.compareTo(bStart);
      });
    final filtered = items.where((it) => !dismissed.contains(it.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.explore_outlined,
                  title: l10n.initiativesEmptyAllTitle,
                  description: l10n.initiativesEmptyAll,
                  ctaLabel: widget.onAdd == null ? null : l10n.goalsNew,
                  onCtaPressed: widget.onAdd,
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _GoalCard(goal: filtered[i]),
                ),
        ),
      ],
    );
  }
}

/// One goal row in the Initiatives list.
final class _GoalCard extends ConsumerWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final storage = goal.status.storage;
    final kindColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.52,
    );

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        Haptics.mediumImpact();
        final container = ProviderScope.containerOf(context);
        final behavior = container.read(settingsProvider).cascadeDeleteBehavior;
        final links = await container
            .read(linksRepositoryProvider)
            .tasksForGoal(goal.id);
        if (!context.mounted) return false;
        if (behavior == CascadeDeleteBehavior.ask) {
          final choice = await showCascadeDeleteDialog(
            context,
            title: l10n.goalsDeleteConfirmTitle,
            behavior: behavior,
            linkedTaskCount: links.length,
          );
          if (choice == null || choice == CascadeChoice.cancel) return false;
          final cascade = choice == CascadeChoice.cascade;
          container.read(dismissedTaskIdsProvider.notifier).add(goal.id);
          if (cascade) {
            for (final t in links) {
              container.read(dismissedTaskIdsProvider.notifier).add(t.item.id);
            }
          }
          try {
            await container
                .read(goalReminderSchedulerProvider)
                .cancelForGoal(goal.id);
            await container
                .read(goalRepositoryProvider)
                .deleteGoal(goal.id, cascadeTasks: cascade);
            container.invalidate(goalListProvider);
            container.invalidate(goalByIdProvider(goal.id));
            container.invalidate(goalProgressProvider(goal.id));
            container.invalidate(latestGoalProgressProvider(goal.id));
            container.invalidate(tasksByGoalProvider(goal.id));
            if (cascade) _invalidateTaskDays(container, links);
          } catch (e) {
            container.read(dismissedTaskIdsProvider.notifier).remove(goal.id);
            if (cascade) {
              for (final t in links) {
                container.read(dismissedTaskIdsProvider.notifier).remove(
                  t.item.id,
                );
              }
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.errorWithMessage('$e'))),
              );
            }
            return false;
          }
          return true;
        }

        final cascade = behavior == CascadeDeleteBehavior.alwaysCascade;
        final goalSnapshot = await container
            .read(goalRepositoryProvider)
            .getGoalById(goal.id);
        final snapshotTasks = cascade
            ? links.map((e) => e.item).toList()
            : <Task>[];
        final overlay = Overlay.of(context);
        container.read(dismissedTaskIdsProvider.notifier).add(goal.id);
        for (final t in snapshotTasks) {
          container.read(dismissedTaskIdsProvider.notifier).add(t.id);
        }
        try {
          await container
              .read(goalReminderSchedulerProvider)
              .cancelForGoal(goal.id);
          await container
              .read(goalRepositoryProvider)
              .deleteGoal(goal.id, cascadeTasks: cascade);
          container.invalidate(goalListProvider);
          container.invalidate(goalByIdProvider(goal.id));
          container.invalidate(goalProgressProvider(goal.id));
          container.invalidate(latestGoalProgressProvider(goal.id));
          container.invalidate(tasksByGoalProvider(goal.id));
          if (cascade) _invalidateTaskDays(container, links);
        } catch (e) {
          container.read(dismissedTaskIdsProvider.notifier).remove(goal.id);
          for (final t in snapshotTasks) {
            container.read(dismissedTaskIdsProvider.notifier).remove(t.id);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorWithMessage('$e'))),
            );
          }
          return false;
        }
        if (!context.mounted) return true;
        showTopBannerOverlay(
          overlay,
          message: l10n.goalDeleted(goal.title),
          actionLabel: l10n.commonUndo,
          onAction: () async {
            if (goalSnapshot != null) {
              await container.read(goalRepositoryProvider).upsertGoal(
                goalSnapshot,
              );
              for (final task in snapshotTasks) {
                await container.read(taskRepositoryProvider).insert(task);
                await container
                    .read(linksRepositoryProvider)
                    .linkTaskGoal(task.id, goal.id);
              }
            }
            container.read(dismissedTaskIdsProvider.notifier).remove(goal.id);
            for (final t in snapshotTasks) {
              container.read(dismissedTaskIdsProvider.notifier).remove(t.id);
            }
            container.invalidate(goalListProvider);
            container.invalidate(goalByIdProvider(goal.id));
            if (cascade) _invalidateTaskDays(container, links);
          },
        );
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: FitFatTokens.spaceM,
          vertical: 4,
        ),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: kindColor.withValues(alpha: 0.85),
            width: 1.6,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => GoalDetailScreen(goalId: goal.id),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 72,
                decoration: BoxDecoration(
                  color: kindColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(FitFatTokens.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kindColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kindColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 13,
                                  color: kindColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'GOAL',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: kindColor,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goal.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _statusDot(context, storage),
                          const SizedBox(width: 6),
                          Text(
                            goalStatusLabel(goal.status, l10n),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _GoalProgress(goal: goal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _invalidateTaskDays(
    ProviderContainer container,
    List<LabeledTask> links,
  ) {
    for (final link in links) {
      final d = link.item.day;
      container.invalidate(
        dayEntriesProvider(DateTime(d.year, d.month, d.day)),
      );
      final utc = DateTime.utc(d.year, d.month, d.day);
      final mondayUtc = utc.subtract(Duration(days: utc.weekday - 1));
      final weekStart = DateTime(
        mondayUtc.year,
        mondayUtc.month,
        mondayUtc.day,
      );
      final weekEnd = weekStart.add(const Duration(days: 6));
      container.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
      container.invalidate(monthEntriesProvider(DateTime(d.year, d.month, 1)));
    }
  }

  Widget _statusDot(BuildContext context, String storage) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (storage) {
      'planned' => scheme.outline,
      'active' => scheme.primary,
      'done' => Colors.green.shade600,
      'aborted' => scheme.error,
      _ => scheme.outline,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Live progress bar for a goal card, derived from its latest progress value.
final class _GoalProgress extends ConsumerWidget {
  final Goal goal;

  const _GoalProgress({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestGoalProgressProvider(goal.id)).value;
    final progress = goal.progressFrom(latest);
    if (progress == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: progress, minHeight: 6),
    );
  }
}

int _statusRank(String storage) => switch (storage) {
  'active' => 0,
  'planned' => 1,
  'done' => 2,
  'aborted' => 2,
  _ => 3,
};
