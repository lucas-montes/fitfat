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
import '../../planner/providers/planner.dart';
import '../../settings/providers/settings.dart';
import '../../ui/cascade_delete_dialog.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';

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

    final experiments = experimentsAsync.value ?? const <Experiment>[];
    final goals = goalsAsync.value ?? const <Goal>[];

    if (experimentsAsync.isLoading || goalsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (experimentsAsync.hasError || goalsAsync.hasError) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.explore_outlined,
                  title: l10n.initiativesEmptyAllTitle,
                  description: l10n.initiativesEmptyAll,
                  ctaLabel: widget.onAdd == null ? null : l10n.experimentsFab,
                  onCtaPressed: widget.onAdd,
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _InitiativeCard(item: items[i]),
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
    final kindColor = isExperiment
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    final cardColor = isExperiment
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.22)
        : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.22);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        Haptics.mediumImpact();
        final behavior = ref.read(settingsProvider).cascadeDeleteBehavior;
        final links = isExperiment
            ? await ref
                .read(linksRepositoryProvider)
                .tasksForExperiment(item.id)
            : await ref.read(linksRepositoryProvider).tasksForGoal(item.id);
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
        try {
          if (isExperiment) {
            await ref
                .read(experimentReminderSchedulerProvider)
                .cancelForExperiment(item.id);
            await ref
                .read(experimentRepositoryProvider)
                .delete(item.id, cascadeTasks: cascade);
            ref.invalidate(experimentListProvider);
            ref.invalidate(experimentByIdProvider(item.id));
            ref.invalidate(experimentCheckinsProvider(item.id));
            ref.invalidate(experimentLinkedTasksProvider(item.id));
            ref.invalidate(goalsByExperimentProvider(item.id));
            ref.invalidate(notesByExperimentProvider(item.id));
          } else {
            await ref.read(goalReminderSchedulerProvider).cancelForGoal(item.id);
            await ref.read(goalRepositoryProvider).deleteGoal(item.id, cascadeTasks: cascade);
            ref.invalidate(goalListProvider);
            ref.invalidate(goalByIdProvider(item.id));
            ref.invalidate(goalProgressProvider(item.id));
            ref.invalidate(latestGoalProgressProvider(item.id));
            ref.invalidate(tasksByGoalProvider(item.id));
          }
          if (cascade) {
            ref.invalidate(dayEntriesProvider);
            ref.invalidate(rangeEntriesProvider);
            ref.invalidate(monthEntriesProvider);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorWithMessage('$e'))),
            );
          }
          return false;
        }
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
          side: BorderSide(color: kindColor.withValues(alpha: 0.35), width: 1.2),
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
          child: Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExperiment
                          ? Icons.science_outlined
                          : Icons.flag_outlined,
                      size: 18,
                      color: kindColor,
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
