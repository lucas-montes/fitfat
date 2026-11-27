import 'package:material_ui/material_ui.dart';
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
import '../../goals/services/goal_tracking.dart';
import '../../goals/widgets/goal_widgets.dart';
import 'package:intl/intl.dart';

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

    final visible =
        [
          for (final g in goals)
            if (!dismissed.contains(g.id)) g,
        ]..sort((a, b) {
          final r = _statusRank(
            a.status.storage,
          ).compareTo(_statusRank(b.status.storage));
          if (r != 0) return r;
          final ae = a.endDate ?? DateTime(9999);
          final be = b.endDate ?? DateTime(9999);
          return ae.compareTo(be);
        });
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: l10n.initiativesEmptyAllTitle,
        description: l10n.initiativesEmptyAll,
        ctaLabel: widget.onAdd == null ? null : l10n.goalsNew,
        onCtaPressed: widget.onAdd,
      );
    }
    final theme = Theme.of(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final groups = [
      (
        null,
        [
          for (final g in visible)
            if (g.status == GoalStatus.active) g,
        ],
      ),
      (
        l10n.goalsStatusPlanned,
        [
          for (final g in visible)
            if (g.status == GoalStatus.planned) g,
        ],
      ),
      (
        l10n.goalsStatusDone,
        [
          for (final g in visible)
            if (g.status == GoalStatus.done || g.status == GoalStatus.aborted)
              g,
        ],
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FitFatTokens.spaceL,
        FitFatTokens.spaceXs,
        FitFatTokens.spaceL,
        96,
      ),
      children: [
        for (final (label, list) in groups)
          if (list.isNotEmpty) ...[
            if (label != null) header(label),
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
                child: _GoalCard(key: ValueKey(g.id), goal: g),
              ),
          ],
      ],
    );
  }
}

/// One goal row in the Initiatives list.
final class _GoalCard extends ConsumerWidget {
  final Goal goal;

  const _GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                container
                    .read(dismissedTaskIdsProvider.notifier)
                    .remove(t.item.id);
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

        // Captured before the await so no BuildContext is used across the gap.

        final overlay = Overlay.of(context);
        final goalSnapshot = await container
            .read(goalRepositoryProvider)
            .getGoalById(goal.id);
        final snapshotTasks = cascade
            ? links.map((e) => e.item).toList()
            : <Task>[];
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
              await container
                  .read(goalRepositoryProvider)
                  .upsertGoal(goalSnapshot);
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
      child: _GoalCardBody(goal: goal),
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
}

/// Title and end date (or status), the progress bar, where the number comes
/// from (with the step button for manual goals; long-press for an exact
/// value), and the linked tasks done with the next one.
final class _GoalCardBody extends ConsumerWidget {
  const _GoalCardBody({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status =
        ref.watch(goalStatusProvider(goal.id)).value ??
        const GoalStatusView(
          points: [],
          current: null,
          progress: null,
          source: null,
        );
    final tasks = ref.watch(tasksByGoalProvider(goal.id)).value ?? const [];
    final doneTasks = tasks.where((t) => t.item.done).length;
    final next = tasks
        .where((t) => !t.item.done && !t.item.isCancelled)
        .firstOrNull;
    final manual =
        goal.isManual &&
        goal.targetType != GoalTargetType.none &&
        goal.status == GoalStatus.active;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(FitFatTokens.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FitFatTokens.spaceS,
            children: [
              Row(
                spacing: FitFatTokens.spaceS,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (goal.status == GoalStatus.active && goal.endDate != null)
                    Text(
                      l10n.goalBy(
                        DateFormat.yMMM(locale).format(goal.endDate!),
                      ),
                      style: muted,
                    )
                  else if (goal.status != GoalStatus.active)
                    Text(goalStatusLabel(goal.status, l10n), style: muted),
                  if (manual)
                    GestureDetector(
                      onLongPress: () =>
                          showRecordValueSheet(context, ref, goal, status),
                      child: FilledButton.tonalIcon(
                        key: ValueKey('goalStep-${goal.id}'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () => stepGoal(ref, goal, status),
                        icon: Icon(
                          goal.targetType == GoalTargetType.boolean
                              ? Icons.check
                              : Icons.add,
                          size: 16,
                        ),
                        label: Text(
                          goal.targetType == GoalTargetType.boolean
                              ? l10n.goalsAchieved
                              : '1',
                        ),
                      ),
                    ),
                ],
              ),
              if (goal.targetType != GoalTargetType.none)
                GoalProgressBar(goal: goal, status: status),
              if (goal.targetType != GoalTargetType.none)
                GoalSourceLine(goal: goal, status: status),
              if (tasks.isNotEmpty)
                Row(
                  spacing: 4,
                  children: [
                    Icon(Icons.check, size: 14, color: scheme.onSurfaceVariant),
                    Expanded(
                      child: Text(
                        [
                          l10n.goalTasksDone(doneTasks, tasks.length),
                          if (next != null) l10n.goalNext(next.item.title),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
