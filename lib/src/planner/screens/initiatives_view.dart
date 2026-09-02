import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../experiments/providers/experiments.dart';
import '../../experiments/screens/experiment_detail_screen.dart';
import '../../goals/providers/goals.dart';
import '../../goals/screens/goal_detail_screen.dart';
import '../../experiments/notifications/experiment_reminder.dart';
import '../../experiments/providers/experiments_repository.dart';
import '../../goals/notifications/goal_reminder.dart';
import '../../models/experiment.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../planner/providers/dismissed.dart';
import '../../planner/providers/planner.dart';
import '../../settings/providers/settings.dart';
import '../../ui/cascade_delete_dialog.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/theme_extensions.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/top_banner.dart';

/// One row in the merged Initiatives list (experiments + goals unified).
final class _Initiative {
  final _InitiativeKind kind;
  final String id;
  final String title;
  final int statusRank;
  final DateTime? start;
  final DateTime? end;
  final Object entity;

  const _Initiative({
    required this.kind,
    required this.id,
    required this.title,
    required this.statusRank,
    required this.start,
    required this.end,
    required this.entity,
  });
}

enum _InitiativeKind { experiment, goal }

/// Unified "Initiatives" view (inside the Plan tab): experiments and goals
/// merged into one list, grouped by lifecycle status, with a single tag-filter
/// chip row at the top. Tag chips are intentionally *not* shown on the cards
/// here — filtering lives in the chip row so the list stays scannable.
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
    final experimentsAsync = ref.watch(experimentListProvider);
    final goalsAsync = ref.watch(goalListProvider);
    final dismissed = ref.watch(dismissedTaskIdsProvider);

    final experiments = experimentsAsync.value ?? const <Experiment>[];
    final goals = goalsAsync.value ?? const <Goal>[];

    if ((experimentsAsync.isLoading && !experimentsAsync.hasValue) ||
        (goalsAsync.isLoading && !goalsAsync.hasValue)) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((experimentsAsync.hasError && !experimentsAsync.hasValue) ||
        (goalsAsync.hasError && !goalsAsync.hasValue)) {
      final error =
          experimentsAsync.error ?? goalsAsync.error ?? Object();
      return Center(child: Text(l10n.errorWithMessage('$error')));
    }

    final items = <_Initiative>[
      for (final e in experiments)
        _Initiative(
          kind: _InitiativeKind.experiment,
          id: e.id,
          title: e.name,
          statusRank: _statusRank(e.status.storage),
          start: e.startDate,
          end: e.endDate,
          entity: e,
        ),
      for (final g in goals)
        _Initiative(
          kind: _InitiativeKind.goal,
          id: g.id,
          title: g.title,
          statusRank: _statusRank(g.status.storage),
          start: g.startDate,
          end: g.endDate,
          entity: g,
        ),
    ];

    items.sort((a, b) {
      final r = a.statusRank.compareTo(b.statusRank);
      if (r != 0) return r;
      final aStart = a.start ?? DateTime(0);
      final bStart = b.start ?? DateTime(0);
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
                  ctaLabel: widget.onAdd == null ? null : l10n.experimentsFab,
                  onCtaPressed: widget.onAdd,
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _InitiativeCard(item: filtered[i]),
                ),
        ),
      ],
    );
  }
}

/// One experiment/goal row in the merged list.
final class _InitiativeCard extends ConsumerWidget {
  final _Initiative item;

  const _InitiativeCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isExperiment = item.kind == _InitiativeKind.experiment;
    final storage = isExperiment
        ? (item.entity as Experiment).status.storage
        : (item.entity as Goal).status.storage;
    final fitFatColors = theme.extension<FitFatColors>()!;
    final kindColor = isExperiment
        ? theme.colorScheme.primary
        : fitFatColors.warning;
    final cardColor = isExperiment
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.52)
        : fitFatColors.warning.withValues(alpha: 0.16);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        Haptics.mediumImpact();
        final container = ProviderScope.containerOf(context);
        final behavior = container.read(settingsProvider).cascadeDeleteBehavior;
        final links = isExperiment
            ? await container
                .read(linksRepositoryProvider)
                .tasksForExperiment(item.id)
            : await container.read(linksRepositoryProvider).tasksForGoal(item.id);
        if (!context.mounted) return false;
        if (behavior == CascadeDeleteBehavior.ask) {
          final title = isExperiment
              ? l10n.experimentFormDeleteConfirmTitle
              : l10n.goalsDeleteConfirmTitle;
          final choice = await showCascadeDeleteDialog(
            context,
            title: title,
            behavior: behavior,
            linkedTaskCount: links.length,
          );
          if (choice == null || choice == CascadeChoice.cancel) return false;
          final cascade = choice == CascadeChoice.cascade;
          container.read(dismissedTaskIdsProvider.notifier).add(item.id);
          if (cascade) {
            for (final t in links) {
              container.read(dismissedTaskIdsProvider.notifier).add(t.item.id);
            }
          }
          try {
            if (isExperiment) {
              await container
                  .read(experimentReminderSchedulerProvider)
                  .cancelForExperiment(item.id);
              await container
                  .read(experimentRepositoryProvider)
                  .delete(item.id, cascadeTasks: cascade);
              container.invalidate(experimentListProvider);
              container.invalidate(experimentByIdProvider(item.id));
              container.invalidate(experimentCheckinsProvider(item.id));
              container.invalidate(experimentLinkedTasksProvider(item.id));
              container.invalidate(goalsByExperimentProvider(item.id));
              container.invalidate(notesByExperimentProvider(item.id));
            } else {
              await container.read(goalReminderSchedulerProvider).cancelForGoal(item.id);
              await container.read(goalRepositoryProvider).deleteGoal(item.id, cascadeTasks: cascade);
              container.invalidate(goalListProvider);
              container.invalidate(goalByIdProvider(item.id));
              container.invalidate(goalProgressProvider(item.id));
              container.invalidate(latestGoalProgressProvider(item.id));
              container.invalidate(tasksByGoalProvider(item.id));
            }
            if (cascade) {
              for (final link in links) {
                final d = link.item.day;
                container.invalidate(dayEntriesProvider(DateTime(d.year, d.month, d.day)));
                final utc = DateTime.utc(d.year, d.month, d.day);
                final mondayUtc = utc.subtract(Duration(days: utc.weekday - 1));
                final weekStart = DateTime(mondayUtc.year, mondayUtc.month, mondayUtc.day);
                final weekEnd = weekStart.add(const Duration(days: 6));
                container.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
                container.invalidate(monthEntriesProvider(DateTime(d.year, d.month, 1)));
              }
            }
          } catch (e) {
            container.read(dismissedTaskIdsProvider.notifier).remove(item.id);
            if (cascade) {
              for (final t in links) {
                container.read(dismissedTaskIdsProvider.notifier).remove(t.item.id);
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
        } else {
          final cascade = behavior == CascadeDeleteBehavior.alwaysCascade;
          final expSnapshot = isExperiment
              ? await container.read(experimentRepositoryProvider).getById(item.id)
              : null;
          final goalSnapshot = isExperiment
              ? null
              : await container.read(goalRepositoryProvider).getGoalById(item.id);
          final snapshotTasks = cascade ? links.map((e) => e.item).toList() : <Task>[];
          final overlay = Overlay.of(context);
          container.read(dismissedTaskIdsProvider.notifier).add(item.id);
          for (final t in snapshotTasks) {
            container.read(dismissedTaskIdsProvider.notifier).add(t.id);
          }
          try {
            if (isExperiment) {
              await container
                  .read(experimentReminderSchedulerProvider)
                  .cancelForExperiment(item.id);
              await container
                  .read(experimentRepositoryProvider)
                  .delete(item.id, cascadeTasks: cascade);
              container.invalidate(experimentListProvider);
              container.invalidate(experimentByIdProvider(item.id));
              container.invalidate(experimentCheckinsProvider(item.id));
              container.invalidate(experimentLinkedTasksProvider(item.id));
              container.invalidate(goalsByExperimentProvider(item.id));
              container.invalidate(notesByExperimentProvider(item.id));
            } else {
              await container.read(goalReminderSchedulerProvider).cancelForGoal(item.id);
              await container.read(goalRepositoryProvider).deleteGoal(item.id, cascadeTasks: cascade);
              container.invalidate(goalListProvider);
              container.invalidate(goalByIdProvider(item.id));
              container.invalidate(goalProgressProvider(item.id));
              container.invalidate(latestGoalProgressProvider(item.id));
              container.invalidate(tasksByGoalProvider(item.id));
            }
            if (cascade) {
              for (final link in links) {
                final d = link.item.day;
                container.invalidate(dayEntriesProvider(DateTime(d.year, d.month, d.day)));
                final utc = DateTime.utc(d.year, d.month, d.day);
                final mondayUtc = utc.subtract(Duration(days: utc.weekday - 1));
                final weekStart = DateTime(mondayUtc.year, mondayUtc.month, mondayUtc.day);
                final weekEnd = weekStart.add(const Duration(days: 6));
                container.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
                container.invalidate(monthEntriesProvider(DateTime(d.year, d.month, 1)));
              }
            }
          } catch (e) {
            container.read(dismissedTaskIdsProvider.notifier).remove(item.id);
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
          final message = isExperiment
              ? l10n.experimentDeleted(item.title)
              : l10n.goalDeleted(item.title);
          showTopBannerOverlay(
            overlay,
            message: message,
            actionLabel: l10n.commonUndo,
            onAction: () async {
              if (isExperiment && expSnapshot != null) {
                await container.read(experimentRepositoryProvider).upsert(expSnapshot);
                for (final task in snapshotTasks) {
                  await container.read(taskRepositoryProvider).insert(task);
                  await container.read(linksRepositoryProvider).linkTaskExperiment(task.id, item.id);
                }
              } else if (goalSnapshot != null) {
                await container.read(goalRepositoryProvider).upsertGoal(goalSnapshot);
                for (final task in snapshotTasks) {
                  await container.read(taskRepositoryProvider).insert(task);
                  await container.read(linksRepositoryProvider).linkTaskGoal(task.id, item.id);
                }
              }
              container.read(dismissedTaskIdsProvider.notifier).remove(item.id);
              for (final t in snapshotTasks) {
                container.read(dismissedTaskIdsProvider.notifier).remove(t.id);
              }
              if (isExperiment) {
                container.invalidate(experimentListProvider);
                container.invalidate(experimentByIdProvider(item.id));
              } else {
                container.invalidate(goalListProvider);
                container.invalidate(goalByIdProvider(item.id));
              }
              if (cascade) {
                for (final t in snapshotTasks) {
                  final d = t.day;
                  container.invalidate(dayEntriesProvider(DateTime(d.year, d.month, d.day)));
                  final utc = DateTime.utc(d.year, d.month, d.day);
                  final mondayUtc = utc.subtract(Duration(days: utc.weekday - 1));
                  final weekStart = DateTime(mondayUtc.year, mondayUtc.month, mondayUtc.day);
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  container.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
                  container.invalidate(monthEntriesProvider(DateTime(d.year, d.month, 1)));
                }
              }
            },
          );
          return true;
        }
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
          side: BorderSide(color: kindColor.withValues(alpha: 0.85), width: 1.6),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => isExperiment
                  ? ExperimentDetailScreen(experimentId: item.id)
                  : GoalDetailScreen(goalId: item.id),
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
                                  isExperiment
                                      ? Icons.science_outlined
                                      : Icons.flag_outlined,
                                  size: 13,
                                  color: kindColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExperiment ? 'EXPERIMENT' : 'GOAL',
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
                              item.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _statusDot(context, storage),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(l10n, isExperiment, storage),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isExperiment)
                        Text(
                          _dateRange(context, item.start, item.end),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        _GoalProgress(goal: item.entity as Goal),
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

  String _dateRange(BuildContext context, DateTime? start, DateTime? end) {
    if (start == null) return '';
    final startText = DateFormats.formatDate(context, start);
    if (end == null) return startText;
    return '$startText – ${DateFormats.formatDate(context, end)}';
  }
}

/// Live progress bar for a goal card, derived from its latest progress value.
final class _GoalProgress extends ConsumerWidget {
  final Goal goal;

  const _GoalProgress({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest =
        ref.watch(latestGoalProgressProvider(goal.id)).value;
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

String _statusLabel(
  AppLocalizations l10n,
  bool isExperiment,
  String storage,
) =>
    isExperiment
        ? switch (storage) {
            'planned' => l10n.experimentStatusPlanned,
            'active' => l10n.experimentStatusActive,
            'done' => l10n.experimentStatusDone,
            'aborted' => l10n.experimentStatusAborted,
            _ => storage,
          }
        : goalStatusLabel(GoalStatusStorage.parse(storage), l10n);
