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

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: FitFatTokens.spaceM,
        vertical: 4,
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
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        if (isExperiment) {
                          _deleteExperiment(context, ref, item.id);
                        } else {
                          _deleteGoal(context, ref, item.id);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: Text(l10n.commonDelete),
                        ),
                      ),
                    ],
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
    );
  }

  Future<void> _deleteExperiment(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final behavior = ref.read(settingsProvider).cascadeDeleteBehavior;
    final links = await ref.read(linksRepositoryProvider).tasksForExperiment(id);
    final choice = await showCascadeDeleteDialog(
      context,
      title: l10n.experimentFormDeleteConfirmTitle,
      behavior: behavior,
      linkedTaskCount: links.length,
    );
    if (choice == null || choice == CascadeChoice.cancel) return;
    final cascade = choice == CascadeChoice.cascade;
    await ref.read(experimentReminderSchedulerProvider).cancelForExperiment(id);
    await ref.read(experimentRepositoryProvider).delete(id, cascadeTasks: cascade);
    ref.invalidate(experimentListProvider);
    ref.invalidate(experimentByIdProvider(id));
    if (cascade) {
      ref.invalidate(dayEntriesProvider);
      ref.invalidate(rangeEntriesProvider);
      ref.invalidate(monthEntriesProvider);
    }
  }

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final behavior = ref.read(settingsProvider).cascadeDeleteBehavior;
    final links = await ref.read(linksRepositoryProvider).tasksForGoal(id);
    final choice = await showCascadeDeleteDialog(
      context,
      title: l10n.goalsDeleteConfirmTitle,
      behavior: behavior,
      linkedTaskCount: links.length,
    );
    if (choice == null || choice == CascadeChoice.cancel) return;
    final cascade = choice == CascadeChoice.cascade;
    await ref.read(goalReminderSchedulerProvider).cancelForGoal(id);
    await ref.read(goalRepositoryProvider).deleteGoal(id, cascadeTasks: cascade);
    ref.invalidate(goalListProvider);
    ref.invalidate(goalByIdProvider(id));
    if (cascade) {
      ref.invalidate(dayEntriesProvider);
      ref.invalidate(rangeEntriesProvider);
      ref.invalidate(monthEntriesProvider);
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
