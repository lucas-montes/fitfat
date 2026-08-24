import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../exercise/screens/workout_detail.dart';
import '../../exercise/providers/workouts.dart';
import '../../experiments/providers/experiments.dart';
import '../../experiments/screens/experiments_screen.dart';
import '../../models/planner_item.dart';
import '../../notifications/task_reminders.dart';
import '../../settings/providers/settings.dart';
import '../../ui/haptics.dart';
import '../../ui/tag_colors.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/planner.dart';
import '../repositories/planner_repository.dart';
import 'planner_item_detail.dart';
import 'planner_item_form.dart';

final class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

enum _PlannerViewMode { calendar, experiments }

enum _PlannerMenuAction { copyPreviousDay }

final class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  _PlannerViewMode _viewMode = _PlannerViewMode.calendar;

  @override
  void initState() {
    super.initState();
    _selectedDay = _startOfDay(DateTime.now());
    _focusedDay = _selectedDay;
  }

  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// How far ahead recurring tasks are materialized (user-configurable).
  Duration get _plannerHorizon =>
      Duration(days: ref.read(settingsProvider).plannerHorizonDays);

  /// Schedules reminders for [item] (no-op when the app-wide toggle is off or
  /// the item is untimed/past-due). Called after any mutation that creates or
  /// re-times a task.
  Future<void> _syncReminder(PlannerItem item) async {
    if (!ref.read(settingsProvider).plannerNotifications) return;
    final l10n = AppLocalizations.of(context)!;
    final scheduler = ref.read(taskReminderSchedulerProvider);
    // Prompt for the notification permission only when the task actually gets
    // a reminder (user-initiated flow), never on bulk startup reschedules.
    if (item.startTimeMinutes != null) {
      await scheduler.requestPermissions();
    }
    await scheduler.scheduleForItem(
      item,
      dueSoonText: l10n.taskReminderDueSoon,
      dueNowText: l10n.taskReminderDueNow,
    );
  }

  /// Cancels reminders for [taskId] (done/delete/edit-away-time).
  Future<void> _cancelReminder(String taskId) async {
    if (!ref.read(settingsProvider).plannerNotifications) return;
    await ref.read(taskReminderSchedulerProvider).cancelForTask(taskId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannerAppBar),
        actions: [
          if (_viewMode == _PlannerViewMode.calendar)
            PopupMenuButton<_PlannerMenuAction>(
              tooltip: l10n.plannerMoreActions,
              onSelected: (action) {
                switch (action) {
                  case _PlannerMenuAction.copyPreviousDay:
                    _copyFromPreviousDay();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _PlannerMenuAction.copyPreviousDay,
                  child: ListTile(
                    leading: const Icon(Icons.copy_all),
                    title: Text(l10n.plannerCopyPrevious),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<_PlannerViewMode>(
              segments: [
                ButtonSegment(
                  value: _PlannerViewMode.calendar,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(l10n.plannerSegmentCalendar),
                ),
                ButtonSegment(
                  value: _PlannerViewMode.experiments,
                  icon: const Icon(Icons.science_outlined),
                  label: Text(l10n.plannerSegmentExperiments),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (selection) =>
                  setState(() => _viewMode = selection.first),
            ),
          ),
        ),
      ),
      body: _viewMode == _PlannerViewMode.calendar
          ? _CalendarView(
              selectedDay: _selectedDay,
              focusedDay: _focusedDay,
              isSameDay: _isSameDay,
              onDaySelected: (day, focused) => setState(() {
                _selectedDay = day;
                _focusedDay = focused;
              }),
              onPageChanged: (focused) => setState(() => _focusedDay = focused),
              onAddItem: _addItem,
              onToggleDone: _toggleDone,
              onOpenDetail: _openDetail,
              onEdit: _editItem,
              onDelete: _deleteItem,
              onOpenWorkout: _openWorkout,
            )
          : const ExperimentsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _viewMode == _PlannerViewMode.calendar
            ? _addItem
            : _addExperiment,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addExperiment() async {
    if (await ExperimentsView.openForm(context)) {
      ref.invalidate(experimentListProvider);
    }
  }

  /// Opens the full read-mostly detail view for [item]; the planner tile now
  /// navigates here (edit stays on the pencil icon).
  Future<void> _openDetail(PlannerItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlannerItemDetailScreen(itemId: item.id),
      ),
    );
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: l10n.plannerAddTask,
      initialDueDate: _selectedDay,
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
    ) = result;
    final repo = ref.read(plannerRepositoryProvider);
    // A chosen due date places the task on that day; otherwise it stays on
    // the day the form was opened from.
    final targetDay = dueDate != null ? _startOfDay(dueDate) : _selectedDay;
    final current =
        ref.read(plannerItemsProvider(_selectedDay)).value ??
        const <PlannerItem>[];
    var nextSortOrder = 0;
    for (final item in current) {
      if (item.sortOrder >= nextSortOrder) {
        nextSortOrder = item.sortOrder + 1;
      }
    }
    final item = newPlannerItem(
      day: targetDay,
      title: title,
      sortOrder: nextSortOrder,
      dueDate: dueDate,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
      recurrence: recurrence,
    );
    await repo.insert(item);
    // A recurring task stores one anchor (seriesId == its own id) that
    // generates the rest.
    if (recurrence != null) {
      await repo.update(item.copyWith(seriesId: item.id));
    }
    await _syncReminder(item);
    ref.invalidate(plannerItemsProvider(_selectedDay));
    if (targetDay != _selectedDay) {
      ref.invalidate(plannerItemsProvider(targetDay));
    }
    invalidateDashboard(ref);
    // Best-effort eager materialization of future occurrences; the per-day
    // provider also materializes lazily on view, so a failure here can't block
    // the UI (this is what previously made new recurring tasks "appear only
    // after a restart").
    if (recurrence != null) {
      unawaited(
        repo.materializeUpTo(item.day.add(_plannerHorizon)).catchError((_) {}),
      );
    }
  }

  /// Asks the user whether a recurring-task change applies to this occurrence
  /// only or to this and all following ones. Returns 'this' / 'following' /
  /// null (cancelled).
  Future<String?> _confirmScope({
    required String title,
    required String body,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('this'),
            child: Text(l10n.plannerScopeThis),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('following'),
            child: Text(l10n.plannerScopeFollowing),
          ),
        ],
      ),
    );
  }

  Future<void> _editItem(PlannerItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final isGenerated = item.seriesId != null && item.seriesId != item.id;
    String? scope = 'this';
    if (isGenerated) {
      scope = await _confirmScope(
        title: l10n.plannerEditScopeTitle,
        body: l10n.plannerScopeBody,
      );
      if (scope == null || !mounted) return;
    }
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
    ) = result;
    final repo = ref.read(plannerRepositoryProvider);

    if (scope == 'following') {
      await _editFollowing(
        item,
        title: title,
        dueDate: dueDate,
        startTimeMinutes: startTimeMinutes,
        endTimeMinutes: endTimeMinutes,
        notes: notes,
        workoutId: workoutId,
        tags: tags,
      );
      return;
    }

    final wasAnchor = item.recurrence != null;
    final isAnchor = recurrence != null;
    // Anchor keeps its existing series id (or adopts its own id); a task that
    // gains a rule starts a fresh series. Turning the rule off detaches it; a
    // plain occurrence stays linked to its original series.
    final seriesId = isAnchor
        ? (wasAnchor ? (item.seriesId ?? item.id) : item.id)
        : (wasAnchor ? null : item.seriesId);
    // Setting a due date moves the task to that day (plain tasks and series
    // anchors; generated occurrences keep their materialized day).
    final movedDay = !isGenerated && dueDate != null
        ? _startOfDay(dueDate)
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
    );
    await repo.update(updated);
    // Cancel first so a removed/cleared due time also drops the old reminders;
    // scheduling replaces in place when the time still exists.
    await _cancelReminder(item.id);
    await _syncReminder(updated);
    ref.invalidate(plannerItemsProvider(_selectedDay));
    final destination = movedDay ?? _selectedDay;
    if (destination != _selectedDay) {
      ref.invalidate(plannerItemsProvider(destination));
    }
    invalidateDashboard(ref);
    // Editing the anchor re-generates future occurrences from the (possibly
    // changed) rule; the anchor's past/own row is untouched. Best-effort:
    // the per-day provider also materializes lazily on view.
    if (isAnchor) {
      await repo.deleteFutureOccurrences(seriesId!, DateTime.now());
      unawaited(
        repo
            .materializeUpTo(updated.day.add(_plannerHorizon))
            .catchError((_) {}),
      );
    }
  }

  /// "Edit → this and all following": applies the edited non-rule fields to the
  /// series anchor, updates every existing future occurrence (from the target's
  /// day on), and re-materializes any missing future days. Reminders for the
  /// whole series are re-synced since times may have changed.
  Future<void> _editFollowing(
    PlannerItem item, {
    required String title,
    DateTime? dueDate,
    int? startTimeMinutes,
    int? endTimeMinutes,
    String? notes,
    String? workoutId,
    List<String>? tags,
  }) async {
    final repo = ref.read(plannerRepositoryProvider);
    final seriesId = item.seriesId!;
    final anchor = await repo.getById(seriesId);
    if (anchor == null || anchor.recurrence == null || !mounted) return;
    final updatedAnchor = anchor.copyWith(
      title: title,
      dueDate: dueDate,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
    );
    await repo.update(updatedAnchor);
    await repo.updateFutureOccurrences(
      seriesId,
      from: item.day,
      title: title,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      notes: notes,
      workoutId: workoutId,
      tags: tags,
    );
    final all = await repo.getBySeriesId(seriesId);
    for (final it in all) {
      await _cancelReminder(it.id);
      await _syncReminder(it);
    }
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
    unawaited(
      repo
          .materializeUpTo(updatedAnchor.day.add(_plannerHorizon))
          .catchError((_) {}),
    );
  }

  /// Opens the workout linked to a planner item (fitness badge on a tile).
  /// Routes by the workout's status the same way the workout/dashboard lists do.
  Future<void> _openWorkout(PlannerItem item) async {
    final id = item.workoutId;
    if (id == null || !mounted) return;
    final details = await ref
        .read(workoutRepositoryProvider)
        .getWithDetails(id);
    if (!mounted) return;
    if (details == null) {
      showTopBanner(
        context,
        message: AppLocalizations.of(context)!.plannerLinkedWorkout,
      );
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
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
  }

  Future<void> _toggleDone(PlannerItem item) async {
    unawaited(Haptics.selection());
    final updated = item.copyWith(done: !item.done);
    await ref.read(plannerRepositoryProvider).update(updated);
    if (updated.done) {
      await _cancelReminder(item.id);
    } else {
      await _cancelReminder(item.id);
      await _syncReminder(updated);
    }
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
  }

  Future<void> _deleteItem(PlannerItem item) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(plannerRepositoryProvider);
    final overlay = Overlay.of(context);
    final wasAnchor = item.seriesId == item.id;
    final isGenerated = item.seriesId != null && !wasAnchor;

    String? scope = 'this';
    DateTime? previousEndDate;
    if (isGenerated) {
      scope = await _confirmScope(
        title: l10n.plannerDeleteScopeTitle,
        body: l10n.plannerScopeBody,
      );
      if (scope == null || !mounted) return;
    }

    if (wasAnchor && item.seriesId != null) {
      // Deleting the anchor removes the whole series (anchor + occurrences).
      final occurrences = await repo.getBySeriesId(item.seriesId!);
      for (final it in occurrences) {
        await _cancelReminder(it.id);
      }
      await repo.deleteSeries(item.seriesId!);
    } else if (scope == 'following') {
      // Deleting this occurrence and all following ones: drop the rows and
      // halt regeneration by shortening the anchor's rule. Remember the
      // previous endDate so Undo can restore it.
      final all = await repo.getBySeriesId(item.seriesId!);
      for (final it in all) {
        await _cancelReminder(it.id);
      }
      previousEndDate = await repo.stopSeriesOnOrAfter(
        item.seriesId!,
        item.day,
      );
    } else if (item.seriesId != null) {
      // Deleting one generated occurrence: drop it and exclude its day on the
      // anchor so the materializer does not regenerate it.
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
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
    showTopBannerOverlay(
      overlay,
      message: l10n.plannerDeleted(item.title),
      actionLabel: l10n.commonUndo,
      onAction: () async {
        if (wasAnchor && item.seriesId != null) {
          await repo.restore(item);
          await repo.materializeUpTo(item.day.add(_plannerHorizon));
          final restored = await repo.getBySeriesId(item.seriesId!);
          for (final it in restored) {
            await _syncReminder(it);
          }
        } else if (scope == 'following') {
          // Undo a "this and all following" delete: restore the previous end
          // date and re-materialize the deleted future occurrences.
          await repo.restoreSeriesEndDate(item.seriesId!, previousEndDate);
          await repo.materializeUpTo(item.day.add(_plannerHorizon));
          final restored = await repo.getBySeriesId(item.seriesId!);
          for (final it in restored) {
            await _syncReminder(it);
          }
        } else if (item.seriesId != null) {
          await repo.restore(item);
          await repo.removeExclusion(item.seriesId!, item.day);
          await _syncReminder(item);
        } else {
          await repo.restore(item);
          await _syncReminder(item);
        }
        ref.invalidate(plannerItemsProvider(_selectedDay));
        invalidateDashboard(ref);
      },
    );
  }

  Future<void> _copyFromPreviousDay() async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(plannerRepositoryProvider);
    final yesterday = _selectedDay.subtract(const Duration(days: 1));
    final previousItems = await repo.getByDay(yesterday);
    final pendingCount = previousItems.where((e) => !e.done).length;
    if (!mounted) return;

    if (pendingCount == 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.plannerCopyConfirmTitle),
        content: Text(l10n.plannerCopyConfirmBody(pendingCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await repo.copyFromPreviousDay(_selectedDay);
    if (!mounted) return;
    // The copied tasks got fresh ids; re-schedule reminders for the ones that
    // carried a due time (past-due ones are skipped by the scheduler).
    final copiedItems = await repo.getByDay(_selectedDay);
    if (!mounted) return;
    for (final it in copiedItems) {
      await _syncReminder(it);
    }
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
  }
}

/// The calendar half of the planner: a month grid showing both plain tasks
/// (dot marker) and experiment ranges (tinted background), with the selected
/// day's task list underneath. Task tap edits in place; long-press opens the
/// detail screen.
final class _CalendarView extends ConsumerWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final bool Function(DateTime a, DateTime b) isSameDay;
  final void Function(DateTime day, DateTime focused) onDaySelected;
  final void Function(DateTime focused) onPageChanged;
  final VoidCallback onAddItem;
  final void Function(PlannerItem item) onToggleDone;
  final void Function(PlannerItem item) onOpenDetail;
  final void Function(PlannerItem item) onEdit;
  final void Function(PlannerItem item) onDelete;
  final void Function(PlannerItem item) onOpenWorkout;

  const _CalendarView({
    required this.selectedDay,
    required this.focusedDay,
    required this.isSameDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onAddItem,
    required this.onToggleDone,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenWorkout,
  });

  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthStart = DateTime(focusedDay.year, focusedDay.month, 1);
    final itemsAsync = ref.watch(plannerMonthItemsProvider(monthStart));
    final experimentsAsync = ref.watch(experimentListProvider);

    final taskDays = <DateTime>{};
    for (final item in itemsAsync.value ?? const <PlannerItem>[]) {
      if (!item.isExperiment) taskDays.add(_startOfDay(item.day));
    }
    final experimentDays = <DateTime>{};
    for (final experiment in experimentsAsync.value ?? const []) {
      final start = _startOfDay(experiment.startDate);
      final end = experiment.endDate == null
          ? start
          : _startOfDay(experiment.endDate!);
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        experimentDays.add(d);
      }
    }

    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
          availableCalendarFormats: const {},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          onDaySelected: (selected, focused) =>
              onDaySelected(_startOfDay(selected), focused),
          onPageChanged: onPageChanged,
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedMonth) => _dayCell(
              context,
              day,
              focusedMonth,
              taskDays: taskDays,
              experimentDays: experimentDays,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _DayPage(
            day: selectedDay,
            l10n: l10n,
            onAddItem: onAddItem,
            onToggleDone: onToggleDone,
            onOpenDetail: onOpenDetail,
            onEdit: onEdit,
            onDelete: onDelete,
            onOpenWorkout: onOpenWorkout,
          ),
        ),
      ],
    );
  }

  /// Custom cell for days worth marking: experiment-range tint, a task dot,
  /// the selected-day fill, and today's outline. Plain days return null so the
  /// stock rendering applies.
  Widget? _dayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedMonth, {
    required Set<DateTime> taskDays,
    required Set<DateTime> experimentDays,
  }) {
    final d = _startOfDay(day);
    final inExperiment = experimentDays.contains(d);
    final hasTask = taskDays.contains(d);
    final isSelected = isSameDay(day, selectedDay);
    final isToday = isSameDay(d, _startOfDay(DateTime.now()));
    if (!inExperiment && !hasTask && !isSelected && !isToday) return null;

    final scheme = Theme.of(context).colorScheme;
    final isOutside =
        day.month != focusedMonth.month || day.year != focusedMonth.year;

    BoxDecoration decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: scheme.primary)),
        borderRadius: BorderRadius.circular(8),
      );
    } else {
      decoration = BoxDecoration(
        color: inExperiment
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : null,
        borderRadius: BorderRadius.circular(8),
      );
    }

    final textColor = isSelected
        ? scheme.onPrimary
        : isOutside
        ? scheme.onSurfaceVariant
        : scheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
          if (hasTask && !isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? scheme.onPrimary : scheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// One day's task list inside the infinite day `PageView`. Watches its own
/// day's items via `plannerItemsProvider(day)`, so adjacent days load
/// independently of the selected day.
///
/// Gesture behavior: a horizontal drag that starts ON a tile is claimed by
/// the tile's `Dismissible` (swipe-to-delete); a drag that starts elsewhere
/// moves the `PageView` and changes the selected day.
final class _DayPage extends ConsumerWidget {
  final DateTime day;
  final AppLocalizations l10n;
  final VoidCallback onAddItem;
  final void Function(PlannerItem item) onToggleDone;
  final void Function(PlannerItem item) onOpenDetail;
  final void Function(PlannerItem item) onEdit;
  final void Function(PlannerItem item) onDelete;
  final void Function(PlannerItem item) onOpenWorkout;

  const _DayPage({
    required this.day,
    required this.l10n,
    required this.onAddItem,
    required this.onToggleDone,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenWorkout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(plannerItemsProvider(day));
    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.event_note,
            title: l10n.emptyPlannerTitle,
            description: l10n.emptyPlannerBody,
            ctaLabel: l10n.emptyPlannerCta,
            onCtaPressed: onAddItem,
          );
        }

        // Untimed tasks (no start time) pin to the top "Anytime" group; timed
        // tasks flow down the timeline in start-time order.
        final untimed = <PlannerItem>[
          for (final it in items)
            if (it.startTimeMinutes == null) it,
        ];
        final timed = <PlannerItem>[
          for (final it in items)
            if (it.startTimeMinutes != null) it,
        ];
        timed.sort(
          (a, b) => a.startTimeMinutes!.compareTo(b.startTimeMinutes!),
        );

        final children = <Widget>[];
        if (untimed.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.plannerAnytime,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
          for (final it in untimed) {
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _TimelineItemCard(
                  key: ValueKey(it.id),
                  item: it,
                  l10n: l10n,
                  onToggleDone: () => onToggleDone(it),
                  onOpenDetail: () => onOpenDetail(it),
                  onEdit: () => onEdit(it),
                  onDelete: () => onDelete(it),
                  onOpenWorkout: () => onOpenWorkout(it),
                ),
              ),
            );
          }
        }
        if (timed.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                l10n.plannerTimelineScheduled,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
          for (final timedItem in timed) {
            final fmt = MaterialLocalizations.of(context).formatTimeOfDay;
            final startText = fmt(
              TimeOfDay(
                hour: timedItem.startTimeMinutes! ~/ 60,
                minute: timedItem.startTimeMinutes! % 60,
              ),
            );
            final timeText = timedItem.endTimeMinutes == null
                ? startText
                : '$startText – ${fmt(TimeOfDay(hour: timedItem.endTimeMinutes! ~/ 60, minute: timedItem.endTimeMinutes! % 60))}';
            children.add(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: _TimelineItemCard(
                  key: ValueKey(timedItem.id),
                  item: timedItem,
                  l10n: l10n,
                  timeLabel: timeText,
                  onToggleDone: () => onToggleDone(timedItem),
                  onOpenDetail: () => onOpenDetail(timedItem),
                  onEdit: () => onEdit(timedItem),
                  onDelete: () => onDelete(timedItem),
                  onOpenWorkout: () => onOpenWorkout(timedItem),
                ),
              ),
            );
          }
        }
        return ListView(children: children);
      },
    );
  }
}

/// A planner task card used for both Scheduled and Anytime groups. Layout is
/// identical for both: the done `Checkbox` is on the left, the title beside
/// it, and the time pill (scheduled only) plus the linked-workout icon sit in
/// a small meta row underneath the title.
final class _TimelineItemCard extends StatelessWidget {
  final PlannerItem item;
  final AppLocalizations l10n;
  final String? timeLabel;
  final VoidCallback onToggleDone;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenWorkout;

  const _TimelineItemCard({
    super.key,
    required this.item,
    required this.l10n,
    this.timeLabel,
    required this.onToggleDone,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = item.notes;
    final hasNotes = notes != null && notes.isNotEmpty;
    final hasWorkout = item.workoutId != null;

    final timePill = timeLabel != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 3),
                Text(
                  timeLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        : null;

    // Meta row shown under the title: time pill (scheduled) + linked-workout
    // icon + tag chips. All intentionally small; wraps on narrow screens.
    final metaChildren = <Widget>[];
    if (timePill != null) metaChildren.add(timePill);
    if (hasWorkout) {
      metaChildren.add(
        IconButton(
          icon: const Icon(Icons.fitness_center, size: 16),
          tooltip: l10n.plannerLinkedWorkout,
          onPressed: onOpenWorkout,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
        ),
      );
    }
    if (item.recurrence != null || item.seriesId != null) {
      metaChildren.add(
        Icon(Icons.repeat, size: 14, color: theme.colorScheme.onSurfaceVariant),
      );
    }
    if (item.tags != null) {
      for (final tag in item.tags!) {
        final (bg, fg) = TagColors.forTag(tag);
        metaChildren.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: fg,
              ),
            ),
          ),
        );
      }
    }

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(value: item.done, onChanged: (_) => onToggleDone()),
              Expanded(
                child: InkWell(
                  // Tap edits in place; long-press opens the full detail
                  // screen.
                  onTap: onEdit,
                  onLongPress: onOpenDetail,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: item.done
                            ? TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.outline,
                              )
                            : null,
                      ),
                      if (hasNotes)
                        Text(
                          notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (metaChildren.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: metaChildren,
                          ),
                        ),
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
}
