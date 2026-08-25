import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../exercise/providers/workouts.dart';
import '../../exercise/screens/workout_detail.dart';
import '../../models/task.dart';
import '../../models/planner_recurrence.dart';
import '../../notifications/task_reminders.dart';
import '../../settings/providers/settings.dart';
import '../../ui/date_formats.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../providers/planner.dart';
import 'planner_item_form.dart';

/// Read-mostly detail view for a single planner task: title + done toggle,
/// date/times, the full note, linked workout, tags and the recurrence summary,
/// with Edit (→ [PlannerItemFormScreen]) and Delete (confirmed) actions.
///
/// Two entry points push this screen (planner tile tap + dashboard upcoming
/// tasks row); popping back leaves the caller to invalidate its providers.
final class PlannerItemDetailScreen extends ConsumerStatefulWidget {
  final String itemId;

  const PlannerItemDetailScreen({super.key, required this.itemId});

  @override
  ConsumerState<PlannerItemDetailScreen> createState() =>
      _PlannerItemDetailScreenState();
}

final class _PlannerItemDetailScreenState
    extends ConsumerState<PlannerItemDetailScreen> {
  Task? _item;

  /// How far ahead recurring tasks are materialized (user-configurable).
  Duration get _plannerHorizon =>
      Duration(days: ref.read(settingsProvider).plannerHorizonDays);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final item = await ref.read(taskRepositoryProvider).getById(widget.itemId);
    if (mounted) setState(() => _item = item);
  }

  Future<void> _syncReminder(Task item) async {
    if (!ref.read(settingsProvider).plannerNotifications) return;
    final l10n = AppLocalizations.of(context)!;
    final scheduler = ref.read(taskReminderSchedulerProvider);
    if (item.startTimeMinutes != null) {
      await scheduler.requestPermissions();
    }
    await scheduler.scheduleForItem(
      item,
      dueSoonText: l10n.taskReminderDueSoon,
      dueNowText: l10n.taskReminderDueNow,
    );
  }

  Future<void> _cancelReminder(String taskId) async {
    if (!ref.read(settingsProvider).plannerNotifications) return;
    await ref.read(taskReminderSchedulerProvider).cancelForTask(taskId);
  }

  Future<void> _toggleDone(Task item) async {
    unawaited(Haptics.selection());
    final updated = item.withTaskStatus(
      item.done ? TaskStatus.pending : TaskStatus.done,
    );
    await _applyStatus(updated);
  }

  /// Marks the task cancelled (or back to pending when it already is).
  Future<void> _toggleCancelled(Task item) async {
    unawaited(Haptics.selection());
    final updated = item.withTaskStatus(
      item.isCancelled ? TaskStatus.pending : TaskStatus.cancelled,
    );
    await _applyStatus(updated);
  }

  /// Persists a lifecycle change: reminders follow the done rules (pending
  /// re-syncs, done/cancelled drop), providers are invalidated and the local
  /// copy refreshes.
  Future<void> _applyStatus(Task updated) async {
    await ref.read(taskRepositoryProvider).update(updated);
    if (updated.taskState == TaskStatus.pending) {
      await _cancelReminder(updated.id);
      await _syncReminder(updated);
    } else {
      await _cancelReminder(updated.id);
    }
    invalidateDashboard(ref);
    ref.invalidate(dayEntriesProvider(updated.day));
    if (mounted) setState(() => _item = updated);
  }

  Future<void> _edit(Task item) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: l10n.plannerEditTask,
      initialTitle: item.title,
      initialDueDate: item.dueDate,
      initialStartTimeMinutes: item.startTimeMinutes,
      initialEndTimeMinutes: item.endTimeMinutes,
      initialNotes: item.notes,
      initialWorkoutId: item.workoutId,
      initialTags: item.tags,
      initialRecurrence: item.recurrence,
      initialCarryOver: item.carryOver,
    );
    if (result == null || !mounted) return;
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
    final repo = ref.read(taskRepositoryProvider);
    final wasAnchor = item.recurrence != null;
    final isAnchor = recurrence != null;
    final seriesId = isAnchor
        ? (wasAnchor ? (item.seriesId ?? item.id) : item.id)
        : (wasAnchor ? null : item.seriesId);
    // Setting a due date moves the task to that day (plain tasks and series
    // anchors; generated occurrences keep their materialized day).
    final isGenerated = item.seriesId != null && item.seriesId != item.id;
    final movedDay = !isGenerated && dueDate != null
        ? DateTime(dueDate.year, dueDate.month, dueDate.day)
        : null;
    final updated = item.copyWith(
      day: movedDay,
      title: title,
      dueDate: dueDate,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
      recurrence: recurrence,
      seriesId: seriesId,
      carryOver: carryOver,
    );
    await repo.update(updated);
    await _cancelReminder(item.id);
    await _syncReminder(updated);
    invalidateDashboard(ref);
    if (isAnchor) {
      await repo.deleteFutureOccurrences(seriesId!, DateTime.now());
      unawaited(
        repo
            .materializeUpTo(updated.day.add(_plannerHorizon))
            .catchError((_) {}),
      );
    }
    ref.invalidate(dayEntriesProvider(item.day));
    final destination = movedDay ?? item.day;
    if (destination != item.day) {
      ref.invalidate(dayEntriesProvider(destination));
    }
    await _load();
  }

  Future<void> _delete(Task item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.plannerDetailDeleteTitle),
        content: Text(l10n.plannerDetailDeleteBody(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.plannerDetailDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    unawaited(Haptics.mediumImpact());
    final repo = ref.read(taskRepositoryProvider);
    final wasAnchor = item.seriesId == item.id;
    if (wasAnchor) {
      final occurrences = await repo.getBySeriesId(item.seriesId!);
      for (final it in occurrences) {
        await _cancelReminder(it.id);
      }
      await repo.deleteSeries(item.seriesId!);
    } else if (item.seriesId != null) {
      await _cancelReminder(item.id);
      await repo.deleteOccurrence(
        id: item.id,
        seriesId: item.seriesId!,
        day: item.day,
      );
    } else {
      await _cancelReminder(item.id);
      await repo.delete(item.id);
    }
    invalidateDashboard(ref);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openWorkout(String workoutId) async {
    final l10n = AppLocalizations.of(context)!;
    final details = await ref
        .read(workoutRepositoryProvider)
        .getWithDetails(workoutId);
    if (!mounted) return;
    if (details == null) {
      showTopBanner(context, message: l10n.plannerLinkedWorkout);
      return;
    }
    final workout = details.workout;
    if (workout.isActive) {
      context.go('/active-workout');
    } else if (workout.isCompleted) {
      context.go('/workout-summary/${workout.id}');
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
        ),
      );
    }
  }

  String _recurrenceSummary(
    AppLocalizations l10n,
    MaterialLocalizations materialL10n,
    PlannerRecurrence r,
  ) {
    final base = switch (r.type) {
      PlannerRecurrenceType.daily => l10n.plannerRepeatSummaryDaily,
      PlannerRecurrenceType.weekly => l10n.plannerRepeatSummaryWeekly(
        (r.weekdays ?? {})
            .map((w) => materialL10n.narrowWeekdays[w % 7])
            .join(', '),
      ),
      PlannerRecurrenceType.interval => l10n.plannerRepeatSummaryInterval(
        r.intervalDays ?? 1,
      ),
      PlannerRecurrenceType.monthly => l10n.plannerRepeatSummaryMonthly(
        r.monthDay ?? 1,
      ),
    };
    if (r.endDate != null) {
      return base +
          l10n.plannerRepeatSummaryEndsDate(
            materialL10n.formatMediumDate(r.endDate!),
          );
    }
    if (r.count != null) {
      return base + l10n.plannerRepeatSummaryEndsCount(r.count!);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final item = _item;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.plannerTaskDetailAppBar)),
      body: item == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(FitFatTokens.spaceL),
              children: [
                Row(
                  children: [
                    // Inert while cancelled — reopen first.
                    Checkbox(
                      value: item.done,
                      onChanged: item.isCancelled
                          ? null
                          : (_) => _toggleDone(item),
                    ),
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          decoration: item.done || item.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.done || item.isCancelled
                              ? theme.colorScheme.outline
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.isCancelled) ...[
                  const SizedBox(height: FitFatTokens.spaceS),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.plannerTaskCancelled,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: FitFatTokens.spaceM),
                _MetaLine(
                  icon: Icons.event_outlined,
                  text: item.dueDate != null
                      ? l10n.plannerDetailDueDate(
                          DateFormats.formatDate(context, item.dueDate!),
                        )
                      : DateFormats.formatDate(context, item.day),
                ),
                if (item.startTimeMinutes != null)
                  _MetaLine(
                    icon: Icons.schedule_outlined,
                    text: item.endTimeMinutes != null
                        ? l10n.plannerDetailTimeRange(
                            DateFormats.formatTime(
                              context,
                              TimeOfDay(
                                hour: item.startTimeMinutes! ~/ 60,
                                minute: item.startTimeMinutes! % 60,
                              ),
                            ),
                            DateFormats.formatTime(
                              context,
                              TimeOfDay(
                                hour: item.endTimeMinutes! ~/ 60,
                                minute: item.endTimeMinutes! % 60,
                              ),
                            ),
                          )
                        : DateFormats.formatTime(
                            context,
                            TimeOfDay(
                              hour: item.startTimeMinutes! ~/ 60,
                              minute: item.startTimeMinutes! % 60,
                            ),
                          ),
                  ),
                if (item.recurrence != null)
                  _MetaLine(
                    icon: Icons.event_repeat_outlined,
                    text: _recurrenceSummary(
                      l10n,
                      MaterialLocalizations.of(context),
                      item.recurrence!,
                    ),
                  ),
                _SectionHeader(
                  label: l10n.plannerDetailNotes,
                  hasContent: item.notes != null,
                ),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
                    child: Text(item.notes!, style: theme.textTheme.bodyLarge),
                  ),
                if (item.workoutId != null) ...[
                  _SectionHeader(
                    label: l10n.plannerDetailLinkedWorkout,
                    hasContent: true,
                  ),
                  _LinkedWorkoutTile(
                    workoutId: item.workoutId!,
                    onOpen: () => _openWorkout(item.workoutId!),
                  ),
                ],
                if (item.tags != null && item.tags!.isNotEmpty) ...[
                  _SectionHeader(
                    label: l10n.plannerDetailTags,
                    hasContent: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: FitFatTokens.spaceS),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in item.tags!) Chip(label: Text(tag)),
                      ],
                    ),
                  ),
                ],
                _MetaLine(
                  icon: Icons.history,
                  text: l10n.plannerDetailUpdatedAt(
                    DateFormats.formatDate(context, item.createdAt),
                  ),
                ),
                const SizedBox(height: FitFatTokens.spaceL),
                // Lifecycle actions, then the always-available edit/delete.
                Row(
                  children: [
                    if (!item.done && !item.isCancelled)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _toggleDone(item),
                          child: Text(l10n.plannerActionMarkDone),
                        ),
                      )
                    else if (item.isCancelled || item.done)
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () async {
                            final updated = item.withTaskStatus(
                              TaskStatus.pending,
                            );
                            await _applyStatus(updated);
                          },
                          child: Text(l10n.plannerActionReopen),
                        ),
                      ),
                    if (!item.isCancelled) ...[
                      const SizedBox(width: FitFatTokens.spaceM),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _toggleCancelled(item),
                          child: Text(l10n.plannerActionCancelTask),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: FitFatTokens.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _edit(item),
                        child: Text(l10n.plannerDetailEdit),
                      ),
                    ),
                    const SizedBox(width: FitFatTokens.spaceM),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _delete(item),
                        child: Text(l10n.plannerDetailDelete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

final class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _LinkedWorkoutTile extends ConsumerWidget {
  final String workoutId;
  final VoidCallback onOpen;

  const _LinkedWorkoutTile({required this.workoutId, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workouts = ref.watch(workoutListProvider).value;
    final name = workouts?.where((w) => w.id == workoutId).firstOrNull?.name;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(name ?? l10n.plannerLinkedWorkout),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  final String label;
  final bool hasContent;

  const _SectionHeader({required this.label, required this.hasContent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
