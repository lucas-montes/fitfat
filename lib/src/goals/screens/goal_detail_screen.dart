import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/goal_tracking.dart';
import '../widgets/goal_widgets.dart';
import '../../ui/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/goal.dart';
import '../../models/task.dart';
import '../../planner/providers/dismissed.dart';
import '../../planner/providers/planner.dart'
    show
        dayEntriesProvider,
        linksRepositoryProvider,
        monthEntriesProvider,
        rangeEntriesProvider,
        taskRepositoryProvider;
import '../../planner/repositories/task_repository.dart';
import '../../planner/screens/planner_item_form.dart';
import '../../settings/providers/settings.dart';
import '../../tags/widgets/tag_picker.dart';
import '../../ui/cascade_delete_dialog.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/top_banner.dart';
import '../notifications/goal_reminder.dart';
import '../providers/goals.dart';
import 'goal_form_screen.dart';

/// Detail view for a single [Goal]: status, priority tags, target progress
/// bar, a per-day progress log, and lifecycle actions (activate / done /
/// abort / reopen / edit / delete).
final class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goalAsync = ref.watch(goalByIdProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: Text(goalAsync.value?.title ?? ''),
        actions: [
          PopupMenuButton<String>(
            onSelected: (action) => _onAction(context, ref, action),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.goalsEdit),
                ),
              ),
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
      body: goalAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('$e')),
        data: (goal) {
          if (goal == null) {
            return Center(child: Text(l10n.goalsMissing));
          }
          return _GoalDetailView(goal: goal);
        },
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'edit':
        if (!context.mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => GoalFormScreen(goalId: goalId)),
        );
        ref.invalidate(goalByIdProvider(goalId));
        ref.invalidate(goalListProvider);
      case 'delete':
        {
          final container = ProviderScope.containerOf(context);
          final behavior = container
              .read(settingsProvider)
              .cascadeDeleteBehavior;
          final links = await container
              .read(linksRepositoryProvider)
              .tasksForGoal(goalId);
          if (!context.mounted) return;
          if (behavior == CascadeDeleteBehavior.ask) {
            final choice = await showCascadeDeleteDialog(
              context,
              title: l10n.goalsDeleteConfirmTitle,
              behavior: behavior,
              linkedTaskCount: links.length,
            );
            if (choice == null || choice == CascadeChoice.cancel) return;
            final cascade = choice == CascadeChoice.cascade;
            container.read(dismissedTaskIdsProvider.notifier).add(goalId);
            if (cascade) {
              for (final t in links) {
                container
                    .read(dismissedTaskIdsProvider.notifier)
                    .add(t.item.id);
              }
            }
            try {
              await container
                  .read(goalReminderSchedulerProvider)
                  .cancelForGoal(goalId);
              await container
                  .read(goalRepositoryProvider)
                  .deleteGoal(goalId, cascadeTasks: cascade);
              container.invalidate(goalListProvider);
              container.invalidate(goalByIdProvider(goalId));
              container.invalidate(goalProgressProvider(goalId));
              container.invalidate(latestGoalProgressProvider(goalId));
              container.invalidate(tasksByGoalProvider(goalId));
              if (cascade) {
                for (final link in links) {
                  final d = link.item.day;
                  container.invalidate(
                    dayEntriesProvider(DateTime(d.year, d.month, d.day)),
                  );
                  final utc = DateTime.utc(d.year, d.month, d.day);
                  final mondayUtc = utc.subtract(
                    Duration(days: utc.weekday - 1),
                  );
                  final weekStart = DateTime(
                    mondayUtc.year,
                    mondayUtc.month,
                    mondayUtc.day,
                  );
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  container.invalidate(
                    rangeEntriesProvider((weekStart, weekEnd)),
                  );
                  container.invalidate(
                    monthEntriesProvider(DateTime(d.year, d.month, 1)),
                  );
                }
              }
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              container.read(dismissedTaskIdsProvider.notifier).remove(goalId);
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
            }
          } else {
            final cascade = behavior == CascadeDeleteBehavior.alwaysCascade;
            // Captured before the await so no BuildContext is used across the gap.
            final overlay = Overlay.of(context);
            final goalSnapshot = await container
                .read(goalRepositoryProvider)
                .getGoalById(goalId);
            final snapshotTasks = cascade
                ? links.map((e) => e.item).toList()
                : <Task>[];
            container.read(dismissedTaskIdsProvider.notifier).add(goalId);
            for (final t in snapshotTasks) {
              container.read(dismissedTaskIdsProvider.notifier).add(t.id);
            }
            try {
              await container
                  .read(goalReminderSchedulerProvider)
                  .cancelForGoal(goalId);
              await container
                  .read(goalRepositoryProvider)
                  .deleteGoal(goalId, cascadeTasks: cascade);
              container.invalidate(goalListProvider);
              container.invalidate(goalByIdProvider(goalId));
              container.invalidate(goalProgressProvider(goalId));
              container.invalidate(latestGoalProgressProvider(goalId));
              container.invalidate(tasksByGoalProvider(goalId));
              if (cascade) {
                for (final link in links) {
                  final d = link.item.day;
                  container.invalidate(
                    dayEntriesProvider(DateTime(d.year, d.month, d.day)),
                  );
                  final utc = DateTime.utc(d.year, d.month, d.day);
                  final mondayUtc = utc.subtract(
                    Duration(days: utc.weekday - 1),
                  );
                  final weekStart = DateTime(
                    mondayUtc.year,
                    mondayUtc.month,
                    mondayUtc.day,
                  );
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  container.invalidate(
                    rangeEntriesProvider((weekStart, weekEnd)),
                  );
                  container.invalidate(
                    monthEntriesProvider(DateTime(d.year, d.month, 1)),
                  );
                }
              }
            } catch (e) {
              container.read(dismissedTaskIdsProvider.notifier).remove(goalId);
              for (final t in snapshotTasks) {
                container.read(dismissedTaskIdsProvider.notifier).remove(t.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorWithMessage('$e'))),
                );
              }
              return;
            }
            if (!context.mounted) return;
            Navigator.of(context).pop(true);
            final message = l10n.goalDeleted(goalSnapshot?.title ?? '');
            showTopBannerOverlay(
              overlay,
              message: message,
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
                        .linkTaskGoal(task.id, goalId);
                  }
                }
                container
                    .read(dismissedTaskIdsProvider.notifier)
                    .remove(goalId);
                for (final t in snapshotTasks) {
                  container
                      .read(dismissedTaskIdsProvider.notifier)
                      .remove(t.id);
                }
                container.invalidate(goalListProvider);
                container.invalidate(goalByIdProvider(goalId));
                if (cascade) {
                  for (final t in snapshotTasks) {
                    final d = t.day;
                    container.invalidate(
                      dayEntriesProvider(DateTime(d.year, d.month, d.day)),
                    );
                    final utc = DateTime.utc(d.year, d.month, d.day);
                    final mondayUtc = utc.subtract(
                      Duration(days: utc.weekday - 1),
                    );
                    final weekStart = DateTime(
                      mondayUtc.year,
                      mondayUtc.month,
                      mondayUtc.day,
                    );
                    final weekEnd = weekStart.add(const Duration(days: 6));
                    container.invalidate(
                      rangeEntriesProvider((weekStart, weekEnd)),
                    );
                    container.invalidate(
                      monthEntriesProvider(DateTime(d.year, d.month, 1)),
                    );
                  }
                }
              },
            );
          }
        }
        break;
    }
  }
}

String goalStatusLabel(GoalStatus status, AppLocalizations l10n) =>
    switch (status) {
      GoalStatus.planned => l10n.goalsStatusPlanned,
      GoalStatus.active => l10n.goalsStatusActive,
      GoalStatus.done => l10n.goalsStatusDone,
      GoalStatus.aborted => l10n.goalsStatusAborted,
    };

final class _GoalDetailView extends ConsumerStatefulWidget {
  final Goal goal;

  const _GoalDetailView({required this.goal});

  @override
  ConsumerState<_GoalDetailView> createState() => _GoalDetailViewState();
}

final class _GoalDetailViewState extends ConsumerState<_GoalDetailView> {
  void _refresh() {
    ref.invalidate(goalByIdProvider(widget.goal.id));
    ref.invalidate(latestGoalProgressProvider(widget.goal.id));
    ref.invalidate(goalProgressProvider(widget.goal.id));
    ref.invalidate(goalListProvider);
  }

  Future<void> _setStatus(GoalStatus status) async {
    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(goalRepositoryProvider)
        .setGoalStatus(widget.goal.id, status);
    // Reminders follow the lifecycle: active re-syncs (in case the goal or
    // its reminder changed), any other status drops the daily notification.
    final scheduler = ref.read(goalReminderSchedulerProvider);
    if (status == GoalStatus.active) {
      await scheduler.scheduleForGoal(
        widget.goal.copyWith(status: status),
        title: widget.goal.title,
        body: l10n.goalsReminderSubtitle,
      );
    } else {
      await scheduler.cancelForGoal(widget.goal.id);
    }
    _refresh();
  }

  Future<void> _recordProgress() async {
    final l10n = AppLocalizations.of(context)!;
    final valueCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var day = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.goalsRecordProgress),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.goal.unit == null
                      ? (widget.goal.targetType == GoalTargetType.boolean
                            ? l10n.goalsAchievedQuestion
                            : l10n.goalsCurrentValueLabel)
                      : '${l10n.goalsCurrentValueLabel} (${widget.goal.unit})',
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.goalsProgressNoteHint,
                ),
              ),
              const SizedBox(height: FitFatTokens.spaceS),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  MaterialLocalizations.of(ctx).formatMediumDate(day),
                ),
                subtitle: Text(l10n.goalsProgressDateLabel),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: day,
                    firstDate: widget.goal.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => day = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  valueCtrl.text.replaceAll(',', '.'),
                );
                if (value == null) return;
                _pendingValue = value;
                _pendingNote = noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim();
                _pendingDay = day;
                Navigator.of(ctx).pop(true);
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    await ref
        .read(goalRepositoryProvider)
        .recordProgress(
          goalId: widget.goal.id,
          day: _pendingDay ?? DateTime.now(),
          value: _pendingValue!,
          note: _pendingNote,
        );
    _pendingValue = null;
    _pendingNote = null;
    _pendingDay = null;
    _refresh();
  }

  double? _pendingValue;
  String? _pendingNote;
  DateTime? _pendingDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final goal = widget.goal;
    final status =
        ref.watch(goalStatusProvider(goal.id)).value ??
        const GoalStatusView(
          points: [],
          current: null,
          progress: null,
          source: null,
        );
    final log = ref.watch(goalProgressProvider(goal.id)).value ?? const [];
    final tasks = ref.watch(tasksByGoalProvider(goal.id)).value ?? const [];
    final hasTarget = goal.targetType != GoalTargetType.none;
    final unit = goalUnit(goal);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final header = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FitFatTokens.spaceS,
          children: [
            if (hasTarget)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: status.current == null
                                ? '–'
                                : goal.targetType == GoalTargetType.boolean
                                ? (status.current! >= 1
                                      ? l10n.goalsAchieved
                                      : l10n.goalsNotAchieved)
                                : '${formatGoalNumber(context, status.current!)}${unit.isEmpty ? '' : ' $unit'}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (goal.targetValue != null &&
                              goal.targetType == GoalTargetType.numeric)
                            TextSpan(
                              text:
                                  '  ${l10n.goalOf(formatGoalNumber(context, goal.targetValue!))}',
                              style: muted,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (goal.isManual && goal.status == GoalStatus.active)
                    FilledButton.tonalIcon(
                      onPressed: _recordProgress,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.goalRecord),
                    ),
                ],
              ),
            if (hasTarget) GoalProgressBar(goal: goal, status: status),
            if (hasTarget && status.points.length >= 2)
              SizedBox(
                height: 120,
                child: _GoalChart(goal: goal, points: status.points),
              ),
            if (hasTarget) GoalSourceLine(goal: goal, status: status),
            Text(
              [
                goalStatusLabel(goal.status, l10n),
                '${DateFormat.yMMMd(locale).format(goal.startDate)} → '
                    '${goal.endDate == null ? l10n.goalsNoEndDate : DateFormat.yMMMd(locale).format(goal.endDate!)}',
              ].join(' · '),
              style: muted,
            ),
            if (goal.description != null && goal.description!.isNotEmpty)
              Text(goal.description!),
            if (goal.tags?.isNotEmpty ?? false)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in goal.tags!) TagChip(name: tag)],
              ),
            Wrap(
              spacing: FitFatTokens.spaceS,
              children: [
                if (goal.status == GoalStatus.planned)
                  TextButton.icon(
                    onPressed: () => _setStatus(GoalStatus.active),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.goalsMarkActive),
                  ),
                if (goal.status == GoalStatus.active) ...[
                  TextButton.icon(
                    onPressed: () => _setStatus(GoalStatus.done),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l10n.goalsMarkDone),
                  ),
                  TextButton.icon(
                    onPressed: () => _setStatus(GoalStatus.aborted),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(l10n.goalsAbort),
                  ),
                ],
                if (goal.status == GoalStatus.done ||
                    goal.status == GoalStatus.aborted)
                  TextButton.icon(
                    onPressed: () => _setStatus(GoalStatus.active),
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.goalsReopen),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    // Progress rows, newest first: manual entries (deletable) or the tracked
    // series.
    final points = status.points.reversed.toList();
    final progressList = points.isEmpty
        ? [
            Padding(
              padding: const EdgeInsets.all(FitFatTokens.spaceL),
              child: Text(l10n.goalsNoProgressYet, style: muted),
            ),
          ]
        : [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < points.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: FitFatTokens.spaceL,
                        endIndent: FitFatTokens.spaceL,
                        color: scheme.outlineVariant,
                      ),
                    () {
                      final pt = points[i];
                      final prev = i + 1 < points.length
                          ? points[i + 1].value
                          : null;
                      final delta = prev == null ? null : pt.value - prev;
                      final entry = goal.isManual
                          ? log
                                .where(
                                  (e) =>
                                      e.day.year == pt.day.year &&
                                      e.day.month == pt.day.month &&
                                      e.day.day == pt.day.day,
                                )
                                .firstOrNull
                          : null;
                      final row = ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 64,
                          child: Text(
                            DateFormat.MMMd(locale).format(pt.day),
                            style: muted,
                          ),
                        ),
                        title: Text(
                          goal.targetType == GoalTargetType.boolean
                              ? (pt.value >= 1
                                    ? l10n.goalsAchieved
                                    : l10n.goalsNotAchieved)
                              : '${formatGoalNumber(context, pt.value)}${unit.isEmpty ? '' : ' $unit'}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: entry?.note == null
                            ? null
                            : Text(entry!.note!),
                        trailing: delta == null || delta == 0
                            ? null
                            : Text(
                                '${delta > 0 ? '+' : '−'}${formatGoalNumber(context, delta.abs())}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: delta > 0
                                      ? (theme
                                                .extension<FitFatColors>()
                                                ?.success ??
                                            scheme.primary)
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                      );
                      if (entry == null) return row;
                      return Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: scheme.errorContainer,
                          child: Icon(
                            Icons.delete_outline,
                            color: scheme.error,
                          ),
                        ),
                        onDismissed: (_) async {
                          await ref
                              .read(goalRepositoryProvider)
                              .deleteProgress(entry.id);
                          _refresh();
                        },
                        child: row,
                      );
                    }(),
                  ],
                ],
              ),
            ),
          ];

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              FitFatTokens.spaceXs,
              FitFatTokens.spaceL,
              FitFatTokens.spaceS,
            ),
            sliver: SliverToBoxAdapter(child: header),
          ),
          SliverToBoxAdapter(
            child: TabBar(
              tabs: [
                Tab(text: l10n.goalsProgressSection),
                Tab(text: l10n.goalTabTasks(tasks.length)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(FitFatTokens.spaceL),
              children: progressList,
            ),
            ListView(
              padding: const EdgeInsets.all(FitFatTokens.spaceL),
              children: [
                _GoalRelatedTasks(goalId: goal.id, onChanged: _refresh),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Related tasks linked to this goal via the `task_goals` junction table.
/// Read-mostly: unlink here; linking happens in the goal form.
final class _GoalRelatedTasks extends ConsumerWidget {
  final String goalId;
  final VoidCallback onChanged;

  const _GoalRelatedTasks({required this.goalId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksByGoalProvider(goalId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.goalsRelatedTasks, style: theme.textTheme.titleMedium),
        const SizedBox(height: FitFatTokens.spaceS),
        Wrap(
          spacing: FitFatTokens.spaceS,
          runSpacing: FitFatTokens.spaceS,
          children: [
            ActionChip(
              avatar: const Icon(Icons.link, size: 18),
              label: Text(l10n.goalLinkTask),
              onPressed: () => _openPicker(context, ref),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.plannerAddTask),
              onPressed: () => _createAndLink(context, ref),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        tasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: FitFatTokens.spaceL),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('$e'),
          data: (tasks) => tasks.isEmpty
              ? Text(
                  l10n.goalsNoLinkedTasks,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (final (:item, label: _) in tasks)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          item.done
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          color: item.done
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: item.done
                              ? TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.outline,
                                )
                              : null,
                        ),
                        subtitle: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(item.day),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.goalUnlinkTask,
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            await ref
                                .read(linksRepositoryProvider)
                                .unlinkTaskGoal(item.id, goalId);
                            ref.invalidate(tasksByGoalProvider(goalId));
                            onChanged();
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _GoalTaskPickerSheet(goalId: goalId),
    );
    ref.invalidate(tasksByGoalProvider(goalId));
  }

  Future<void> _createAndLink(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: l10n.plannerAddTask,
      initialDueDate: DateTime.now(),
    );
    if (result == null || !context.mounted) return;
    final (
      title,
      dueDate,
      startTimeMinutes,
      endTimeMinutes,
      notes,
      workoutId,
      tags,
      recurrence,
      carryOver,
    ) = result;
    final task = newTask(
      day: dueDate ?? DateTime.now(),
      title: title,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
      recurrence: recurrence,
      carryOver: carryOver,
    );
    final repo = ref.read(taskRepositoryProvider);
    await repo.insert(task);
    if (recurrence != null) {
      await repo.update(task.copyWith(seriesId: task.id));
    }
    await ref.read(linksRepositoryProvider).linkTaskGoal(task.id, goalId);
    if (!context.mounted) return;
    ref.invalidate(dayEntriesProvider(task.day));
    ref.invalidate(tasksByGoalProvider(goalId));
  }
}

final class _GoalTaskPickerSheet extends ConsumerStatefulWidget {
  final String goalId;

  const _GoalTaskPickerSheet({required this.goalId});

  @override
  ConsumerState<_GoalTaskPickerSheet> createState() =>
      _GoalTaskPickerSheetState();
}

final class _GoalTaskPickerSheetState
    extends ConsumerState<_GoalTaskPickerSheet> {
  final _controller = TextEditingController();
  List<Task>? _results;
  Set<String> _linkedIds = {};

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final results = await ref
        .read(taskRepositoryProvider)
        .searchTasks(_controller.text);
    final linked = await ref
        .read(linksRepositoryProvider)
        .tasksForGoal(widget.goalId);
    if (!mounted) return;
    setState(() {
      _results = results;
      _linkedIds = {for (final t in linked) t.item.id};
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.goalSearchTasksHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  onChanged: (_) => _search(),
                ),
              ),
              Expanded(
                child: _results == null
                    ? const Center(child: CircularProgressIndicator())
                    : _results!.isEmpty
                    ? Center(child: Text(l10n.goalsNoLinkedTasks))
                    : ListView(
                        children: [
                          for (final task in _results!)
                            ListTile(
                              leading: Icon(
                                _linkedIds.contains(task.id)
                                    ? Icons.link
                                    : Icons.add_link,
                                size: 20,
                              ),
                              title: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                final nav = Navigator.of(context);
                                await ref
                                    .read(linksRepositoryProvider)
                                    .linkTaskGoal(task.id, widget.goalId);
                                if (!mounted) return;
                                ref.invalidate(
                                  tasksByGoalProvider(widget.goalId),
                                );
                                nav.pop();
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every recorded value as a line, with the target as a dashed line.
final class _GoalChart extends StatelessWidget {
  const _GoalChart({required this.goal, required this.points});

  final Goal goal;
  final List<GoalPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success =
        Theme.of(context).extension<FitFatColors>()?.success ?? scheme.primary;
    final first = points.first.day;
    final spots = [
      for (final p in points)
        FlSpot(p.day.difference(first).inDays.toDouble(), p.value),
    ];
    final values = [for (final p in points) p.value, ?goal.targetValue];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() < 1 ? 1.0 : (hi - lo) * 0.12;
    return LineChart(
      LineChartData(
        minY: lo - pad,
        maxY: hi + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (goal.targetValue != null &&
                goal.targetType == GoalTargetType.numeric)
              HorizontalLine(
                y: goal.targetValue!,
                color: success,
                strokeWidth: 1.5,
                dashArray: [5, 4],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: scheme.primary,
            barWidth: 2.5,
            dotData: FlDotData(show: spots.length <= 30),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
