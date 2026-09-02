import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../exercise/screens/workout_detail.dart';
import '../../exercise/providers/workout_templates.dart';
import '../../exercise/providers/workouts.dart';
import '../../experiments/providers/experiments.dart';
import '../../experiments/screens/experiment_detail_screen.dart';
import '../../experiments/screens/experiment_form_screen.dart';
import '../../goals/screens/goal_form_screen.dart';
import '../../models/experiment.dart';
import '../../models/planner_entry.dart';
import '../../models/task.dart';
import '../../notifications/task_reminders.dart';
import '../../tags/providers/tags.dart';
import '../../settings/providers/settings.dart';
import 'initiatives_view.dart';
import '../../ui/haptics.dart';
import '../../ui/tag_colors.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/planner.dart';
import '../repositories/task_repository.dart';
import 'planner_item_detail.dart';
import 'planner_item_form.dart';

enum _PlannerViewMode { day, week, month }

enum _PlanMode { timeline, initiatives }

enum _AddChoice { task, experiment, goal }

/// Anchors for the infinite PageViews' page indices (one day / week page).
/// Index math happens in UTC — local days vary in length across DST
/// transitions, so `localA.difference(localB).inDays` can truncate onto the
/// previous day/week. UTC days are always exactly 24h long.
final DateTime _kDayEpochUtc = DateTime.utc(2020);
final DateTime _kWeekEpochUtc = DateTime.utc(2019, 12, 30); // a Monday

/// Upper bound for generated pages (matches the calendar's lastDay).
final DateTime _kLastDay = DateTime(2035, 12, 31);

/// Local start-of-day → page index.
int _dayPageIndex(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).difference(_kDayEpochUtc).inDays;

/// Page index → local start-of-day.
DateTime _dayFromIndex(int index) {
  final u = _kDayEpochUtc.add(Duration(days: index));
  return DateTime(u.year, u.month, u.day);
}

/// Monday of [day]'s week, as a page index.
int _weekPageIndex(DateTime day) {
  final monday = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).subtract(Duration(days: day.weekday - 1));
  return monday.difference(_kWeekEpochUtc).inDays ~/ 7;
}

/// Week page index → that week's Monday as a local start-of-day.
DateTime _weekStartFromIndex(int index) {
  final u = _kWeekEpochUtc.add(Duration(days: index * 7));
  return DateTime(u.year, u.month, u.day);
}

/// Min height of an empty hour slot in the day timeline.
const double _kHourRowMinHeight = 44;

void _invalidatePlannerForDay(WidgetRef ref, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  ref.invalidate(dayEntriesProvider(d));
  final weekStart = _weekStartFromIndex(_weekPageIndex(d));
  final weekEnd = weekStart.add(const Duration(days: 6));
  ref.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
  ref.invalidate(monthEntriesProvider(DateTime(d.year, d.month, 1)));
}

final class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

final class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _selectedDay;
  _PlannerViewMode _viewMode = _PlannerViewMode.day;
  _PlanMode _planMode = _PlanMode.timeline;

  // Allow the AppBar shortcuts to steer the active view.
  final GlobalKey<_DayFlowViewState> _dayFlowKey =
      GlobalKey<_DayFlowViewState>();
  final GlobalKey<_WeekFlowViewState> _weekFlowKey =
      GlobalKey<_WeekFlowViewState>();
  final GlobalKey<_MonthOverviewState> _monthKey =
      GlobalKey<_MonthOverviewState>();

  @override
  void initState() {
    super.initState();
    _selectedDay = _startOfDay(DateTime.now());
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
  Future<void> _syncReminder(Task item) async {
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<_PlanMode>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment(
                  value: _PlanMode.timeline,
                  icon: const Icon(Icons.view_agenda_outlined),
                  label: Text(l10n.plannerModeTimeline),
                ),
                ButtonSegment(
                  value: _PlanMode.initiatives,
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(l10n.plannerModeInitiatives),
                ),
              ],
              selected: {_planMode},
              onSelectionChanged: (selection) =>
                  setState(() => _planMode = selection.first),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_planMode == _PlanMode.timeline)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  if (!_isSameDay(_selectedDay, _startOfDay(DateTime.now())))
                    IconButton(
                      tooltip: l10n.plannerGoToday,
                      icon: const Icon(Icons.today_outlined),
                      onPressed: _goToToday,
                    ),
                  if (!_isSameDay(_selectedDay, _startOfDay(DateTime.now())))
                    const SizedBox(width: 8),
                  SegmentedButton<_PlannerViewMode>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: [
                      ButtonSegment(
                        value: _PlannerViewMode.day,
                        icon: const Icon(Icons.view_day_outlined),
                        tooltip: l10n.plannerViewDay,
                      ),
                      ButtonSegment(
                        value: _PlannerViewMode.week,
                        icon: const Icon(Icons.view_week_outlined),
                        tooltip: l10n.plannerViewWeek,
                      ),
                      ButtonSegment(
                        value: _PlannerViewMode.month,
                        icon: const Icon(Icons.calendar_month_outlined),
                        tooltip: l10n.plannerViewMonth,
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (selection) =>
                        setState(() => _viewMode = selection.first),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _planMode == _PlanMode.initiatives
                ? InitiativesView(onAdd: _showInitiativeSheet)
                : switch (_viewMode) {
              _PlannerViewMode.day => _DayFlowView(
                key: _dayFlowKey,
                initialDay: _selectedDay,
                isSameDay: _isSameDay,
                onSelectedDayChanged: (day) =>
                    setState(() => _selectedDay = _startOfDay(day)),
                onAddItem: _addItem,
                onToggleDone: _toggleDone,
                onToggleCancelled: _toggleCancelled,
                onOpenDetail: _openDetail,
                onEditItem: _editItem,
                onDeleteItem: _deleteItem,
                onOpenWorkout: _openWorkout,
                onOpenExperiment: _openExperimentDetail,
                onEditExperiment: _editExperiment,
              ),
              _PlannerViewMode.week => _WeekFlowView(
                key: _weekFlowKey,
                initialDay: _selectedDay,
                isSameDay: _isSameDay,
                onSelectedDayChanged: (day) =>
                    setState(() => _selectedDay = _startOfDay(day)),
                onJumpToDay: _jumpToDay,
                onToggleDone: _toggleDone,
                onToggleCancelled: _toggleCancelled,
                onOpenDetail: _openDetail,
                onEditItem: _editItem,
                onDeleteItem: _deleteItem,
                onOpenWorkout: _openWorkout,
                onOpenExperiment: _openExperimentDetail,
                onEditExperiment: _editExperiment,
              ),
              _PlannerViewMode.month => _MonthOverview(
                key: _monthKey,
                selectedDay: _selectedDay,
                isSameDay: _isSameDay,
                onDayPicked: _jumpToDay,
              ),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _planMode == _PlanMode.initiatives
            ? _showInitiativeSheet
            : _showAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// FAB opens a chooser instead of assuming what to create: tasks,
  /// experiments and goals are all reachable from every view.
  Future<void> _showAddSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.plannerAddTask),
              onTap: () => Navigator.of(ctx).pop(_AddChoice.task),
            ),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(l10n.experimentsFab),
              onTap: () => Navigator.of(ctx).pop(_AddChoice.experiment),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.goalsNew),
              onTap: () => Navigator.of(ctx).pop(_AddChoice.goal),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _AddChoice.task:
        await _addItem();
      case _AddChoice.experiment:
        await _addExperiment();
      case _AddChoice.goal:
        await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const GoalFormScreen()));
      case null:
        break;
    }
  }

  /// Initiatives-mode FAB: only experiments and goals (no day-bound task).
  Future<void> _showInitiativeSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(l10n.experimentsFab),
              onTap: () => Navigator.of(ctx).pop(_AddChoice.experiment),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.goalsNew),
              onTap: () => Navigator.of(ctx).pop(_AddChoice.goal),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _AddChoice.experiment:
        await _addExperiment();
      case _AddChoice.goal:
        await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const GoalFormScreen()));
      case _AddChoice.task:
      case null:
        break;
    }
  }

  /// Shows the current day's timeline (the default landing view).
  void _jumpToDay(DateTime day) => setState(() {
    _selectedDay = _startOfDay(day);
    _viewMode = _PlannerViewMode.day;
  });

  /// AppBar shortcut: bring whichever view is active back to today.
  void _goToToday() {
    final today = _startOfDay(DateTime.now());
    switch (_viewMode) {
      case _PlannerViewMode.day:
        _dayFlowKey.currentState?.animateToDate(_dayPageIndex(today));
      case _PlannerViewMode.week:
        _weekFlowKey.currentState?.animateToWeek(_weekPageIndex(today));
      case _PlannerViewMode.month:
        _monthKey.currentState?.focusDay(today);
    }
    setState(() => _selectedDay = today);
  }

  Future<void> _addExperiment() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ExperimentFormScreen()),
    );
    _refreshAfterExperimentChange(saved ?? false);
  }

  Future<void> _editExperiment(String experimentId) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExperimentFormScreen(experimentId: experimentId),
      ),
    );
    _refreshAfterExperimentChange(saved ?? false);
  }

  Future<void> _openExperimentDetail(String experimentId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExperimentDetailScreen(experimentId: experimentId),
      ),
    );
    // Detail edits (status/check-ins) live in planner_items rows too.
    _refreshAfterExperimentChange(true);
  }

  /// Experiments span many days, so every planner cache is dropped when one
  /// may have changed.
  void _refreshAfterExperimentChange(bool changed) {
    if (!changed) return;
    ref.invalidate(experimentListProvider);
    ref.invalidate(dayEntriesProvider);
    ref.invalidate(rangeEntriesProvider);
    ref.invalidate(monthEntriesProvider);
    invalidateDashboard(ref);
  }

  /// Opens the full read-mostly detail view for [item].
  Future<void> _openDetail(Task item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlannerItemDetailScreen(itemId: item.id),
      ),
    );
    ref.invalidate(dayEntriesProvider(item.day));
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
      carryOver,
    ) = result;
    final repo = ref.read(taskRepositoryProvider);
    // A chosen due date places the task on that day; otherwise it stays on
    // the day the form was opened from.
    final targetDay = dueDate != null ? _startOfDay(dueDate) : _selectedDay;
    final currentEntries = ref.read(dayEntriesProvider(_selectedDay)).value;
    final currentTasks = [
      for (final entry in currentEntries ?? const <PlannerEntry>[])
        if (entry is TaskEntry) entry.task,
    ];
    var nextSortOrder = 0;
    for (final item in currentTasks) {
      if (item.sortOrder >= nextSortOrder) {
        nextSortOrder = item.sortOrder + 1;
      }
    }
    final item = newTask(
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
      carryOver: carryOver,
    );
    await repo.insert(item);
    // New tags typed into the task form must surface in the Tags vocabulary.
    ref.invalidate(tagListProvider);
    ref.invalidate(tagNamesProvider);
    // A recurring task stores one anchor (seriesId == its own id) that
    // generates the rest.
    if (recurrence != null) {
      await repo.update(item.copyWith(seriesId: item.id));
    }
    await _syncReminder(item);
    ref.invalidate(dayEntriesProvider(_selectedDay));
    if (targetDay != _selectedDay) {
      ref.invalidate(dayEntriesProvider(targetDay));
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

  Future<void> _editItem(Task item) async {
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
        carryOver: carryOver,
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
    // Setting an (actually changed) due date moves the task to that day
    // (plain tasks and series anchors; generated occurrences keep their
    // materialized day). The form round-trips the original dueDate, so a
    // no-change edit compares equal and never moves the task — this guards
    // the "edited task jumps back to its old day" regression.
    bool dueDateChanged(DateTime? a, DateTime? b) {
      if (a == null || b == null) return a != b;
      return !_isSameDay(a, b);
    }

    final movedDay =
        !isGenerated && dueDate != null && dueDateChanged(dueDate, item.dueDate)
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
      carryOver: carryOver,
    );
    await repo.update(updated);
    // Cancel first so a removed/cleared due time also drops the old reminders;
    // scheduling replaces in place when the time still exists.
    await _cancelReminder(item.id);
    await _syncReminder(updated);
    ref.invalidate(dayEntriesProvider(_selectedDay));
    ref.invalidate(dayEntriesProvider(item.day));
    final destination = movedDay ?? item.day;
    if (destination != _selectedDay) {
      ref.invalidate(dayEntriesProvider(destination));
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
    Task item, {
    required String title,
    required bool carryOver,
    DateTime? dueDate,
    int? startTimeMinutes,
    int? endTimeMinutes,
    String? notes,
    String? workoutId,
    List<String>? tags,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
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
      carryOver: carryOver,
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
    ref.invalidate(dayEntriesProvider);
    invalidateDashboard(ref);
    unawaited(
      repo
          .materializeUpTo(updatedAnchor.day.add(_plannerHorizon))
          .catchError((_) {}),
    );
  }

  /// Opens the workout linked to a task (fitness badge on a tile).
  /// Routes by the workout's status the same way the workout/dashboard lists do.
  Future<void> _openWorkout(Task item) async {
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
    ref.invalidate(dayEntriesProvider(item.day));
    invalidateDashboard(ref);
  }

  Future<void> _toggleDone(Task item) async {
    unawaited(Haptics.selection());
    final updated = item.withTaskStatus(
      item.done ? TaskStatus.pending : TaskStatus.done,
    );
    await ref.read(taskRepositoryProvider).update(updated);
    if (updated.done) {
      await _cancelReminder(item.id);
    } else {
      await _cancelReminder(item.id);
      await _syncReminder(updated);
    }
    _invalidatePlannerForDay(ref, updated.day);
    if (updated.day != item.day) _invalidatePlannerForDay(ref, item.day);
    invalidateDashboard(ref);
  }

  /// Swipe-right action: cancels a pending/done task (reopening works via
  /// the Undo banner or the detail screen). Reminders follow the same rules
  /// as the done toggle. Cancelled tasks disappear from the timeline/week
  /// lists, so the banner is the immediate recovery path — like delete.
  Future<void> _toggleCancelled(Task item) async {
    unawaited(Haptics.selection());
    final updated = item.withTaskStatus(
      item.isCancelled ? TaskStatus.pending : TaskStatus.cancelled,
    );
    await ref.read(taskRepositoryProvider).update(updated);
    await _cancelReminder(item.id);
    if (!updated.isCancelled && !updated.done) {
      await _syncReminder(updated);
    }
    _invalidatePlannerForDay(ref, updated.day);
    if (updated.day != item.day) _invalidatePlannerForDay(ref, item.day);
    invalidateDashboard(ref);
    if (mounted && updated.isCancelled) {
      final l10n = AppLocalizations.of(context)!;
      showTopBannerOverlay(
        Overlay.of(context),
        message: l10n.plannerCancelled(item.title),
        actionLabel: l10n.commonUndo,
        // Restoring the untouched original item revives its exact previous
        // lifecycle (pending or done).
        onAction: () async {
          await ref.read(taskRepositoryProvider).update(item);
          await _cancelReminder(item.id);
          if (!item.done) await _syncReminder(item);
          _invalidatePlannerForDay(ref, item.day);
          invalidateDashboard(ref);
        },
      );
    }
  }

  Future<void> _deleteItem(Task item) async {
    unawaited(Haptics.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(taskRepositoryProvider);
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
      await ref.read(linksRepositoryProvider).detachTask(item.id);
      // Scheduled workout occurrence: record the exclusion so the template
      // materializer doesn't regenerate it on the next view of this day.
      final scheduledTemplateId = item.workoutTemplateId;
      if (scheduledTemplateId != null) {
        await ref
            .read(workoutTemplateRepositoryProvider)
            .excludeOccurrence(scheduledTemplateId, item.day);
      }
    }
    _invalidatePlannerForDay(ref, item.day);
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
          // Undoing a scheduled-occurrence delete re-includes the day so the
          // materializer keeps generating it.
          final scheduledTemplateId = item.workoutTemplateId;
          if (scheduledTemplateId != null) {
            await ref
                .read(workoutTemplateRepositoryProvider)
                .restoreOccurrence(scheduledTemplateId, item.day);
          }
        }
        _invalidatePlannerForDay(ref, item.day);
        invalidateDashboard(ref);
      },
    );
  }
}

/// True when the experiment's inclusive [startDate, endDate] range covers
/// [day] (all comparisons at start-of-day granularity).
bool _experimentCoversDay(Experiment experiment, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  final start = DateTime(
    experiment.startDate.year,
    experiment.startDate.month,
    experiment.startDate.day,
  );
  final end = experiment.endDate == null
      ? start
      : DateTime(
          experiment.endDate!.year,
          experiment.endDate!.month,
          experiment.endDate!.day,
        );
  return !start.isAfter(d) && !end.isBefore(d);
}

DateTime _startOf(DateTime day) => DateTime(day.year, day.month, day.day);

/// The day flow: an infinite horizontal `PageView` whose pages are hourly
/// timelines. Swiping left/right moves between days; each page reports itself
/// back so add/copy target the visible day.
final class _DayFlowView extends StatefulWidget {
  final DateTime initialDay;
  final bool Function(DateTime a, DateTime b) isSameDay;
  final void Function(DateTime day) onSelectedDayChanged;
  final VoidCallback onAddItem;
  final void Function(Task item) onToggleDone;
  final void Function(Task item) onToggleCancelled;
  final void Function(Task item) onOpenDetail;
  final void Function(Task item) onEditItem;
  final void Function(Task item) onDeleteItem;
  final void Function(Task item) onOpenWorkout;
  final void Function(String experimentId) onOpenExperiment;
  final void Function(String experimentId) onEditExperiment;

  const _DayFlowView({
    super.key,
    required this.initialDay,
    required this.isSameDay,
    required this.onSelectedDayChanged,
    required this.onAddItem,
    required this.onToggleDone,
    required this.onToggleCancelled,
    required this.onOpenDetail,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onOpenWorkout,
    required this.onOpenExperiment,
    required this.onEditExperiment,
  });

  @override
  State<_DayFlowView> createState() => _DayFlowViewState();
}

final class _DayFlowViewState extends State<_DayFlowView> {
  late final PageController _controller = PageController(
    initialPage: _dayPageIndex(widget.initialDay),
  );

  /// Animates the pager so the given page is front and center (the AppBar
  /// "today" shortcut).
  void animateToDate(int pageIndex) {
    if (!_controller.hasClients) {
      _controller.jumpToPage(pageIndex);
      return;
    }
    _controller.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _dayPageIndex(_kLastDay) + 1;
    return PageView.builder(
      controller: _controller,
      itemCount: pageCount,
      onPageChanged: (index) =>
          widget.onSelectedDayChanged(_dayFromIndex(index)),
      itemBuilder: (context, index) {
        return _DayTimelinePage(
          key: ValueKey(index),
          day: _dayFromIndex(index),
          callbacks: widget,
        );
      },
    );
  }
}

/// Bundles the host callbacks so the per-day page stays readable.
typedef _DayCallbacks = _DayFlowView;

/// One day inside [_DayFlowView]: date header, an all-day strip for
/// experiments covering the day, an "Anytime" group for untimed tasks, and an
/// hourly grid for timed ones. Today's page opens scrolled to roughly the
/// current hour.
final class _DayTimelinePage extends ConsumerStatefulWidget {
  final DateTime day;
  final _DayCallbacks callbacks;

  const _DayTimelinePage({
    super.key,
    required this.day,
    required this.callbacks,
  });

  @override
  ConsumerState<_DayTimelinePage> createState() => _DayTimelinePageState();
}

final class _DayTimelinePageState extends ConsumerState<_DayTimelinePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final entriesAsync = ref.watch(dayEntriesProvider(widget.day));
    final cbs = widget.callbacks;

    // The union provider already merges tasks and experiments for this day.
    final allTasks = [
      for (final entry in entriesAsync.value ?? const <PlannerEntry>[])
        if (entry is TaskEntry) entry.task,
    ];
    final activeExperiments = [
      for (final entry in entriesAsync.value ?? const <PlannerEntry>[])
        if (entry is ExperimentEntry) entry.experiment,
    ];
    // Cancelled tasks are dropped from the planning surfaces (recoverable
    // via the cancel Undo banner or the detail screen).
    final visibleTasks = [
      for (final t in allTasks)
        if (!t.isCancelled) t,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  material.formatMediumDate(widget.day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entriesAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : visibleTasks.isEmpty && activeExperiments.isEmpty
              ? EmptyState(
                  icon: Icons.event_note,
                  title: l10n.emptyPlannerTitle,
                  description: l10n.emptyPlannerBody,
                  ctaLabel: l10n.emptyPlannerCta,
                  onCtaPressed: cbs.onAddItem,
                )
              : _ErrorGuard(
                  hasError: entriesAsync.hasError,
                  message: entriesAsync.error?.toString(),
                  child: ListView(
                    controller: _scrollController,
                    children: _buildChildren(
                      l10n,
                      material,
                      visibleTasks,
                      activeExperiments,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren(
    AppLocalizations l10n,
    MaterialLocalizations material,
    List<Task> tasks,
    List<Experiment> activeExperiments,
  ) {
    final theme = Theme.of(context);
    final cbs = widget.callbacks;
    final children = <Widget>[];

    // All-day strip: experiments whose range covers this day.
    if (activeExperiments.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            l10n.plannerAllDay,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in activeExperiments)
                _AllDayChip(
                  experiment: e,
                  l10n: l10n,
                  onTap: () => cbs.onOpenExperiment(e.id),
                  onLongPress: () => cbs.onEditExperiment(e.id),
                ),
            ],
          ),
        ),
      );
    }

    // Untimed tasks pin to the top "Anytime" group; timed ones flow down the
    // hour grid below.
    final untimed = [
      for (final it in tasks)
        if (it.startTimeMinutes == null) it,
    ];
    final timed = [
      for (final it in tasks)
        if (it.startTimeMinutes != null) it,
    ];
    timed.sort((a, b) => a.startTimeMinutes!.compareTo(b.startTimeMinutes!));

    if (untimed.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.plannerAnytime,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
      for (final it in untimed) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _TimelineItemCard(
              key: ValueKey(it.id),
              item: it,
              l10n: l10n,
              onToggleDone: () => cbs.onToggleDone(it),
              onToggleCancelled: () => cbs.onToggleCancelled(it),
              onOpenDetail: () => cbs.onOpenDetail(it),
              onEdit: () => cbs.onEditItem(it),
              onDelete: () => cbs.onDeleteItem(it),
              onOpenWorkout: () => cbs.onOpenWorkout(it),
            ),
          ),
        );
      }
      children.add(const SizedBox(height: 8));
    }

    // Hour grid: one row per hour; tasks sit under their start hour.
    final byHour = <int, List<Task>>{};
    for (final it in timed) {
      byHour.putIfAbsent(it.startTimeMinutes! ~/ 60, () => []).add(it);
    }
    for (var hour = 0; hour < 24; hour++) {
      final slot = byHour[hour];
      final fmt = material.formatHour(
        TimeOfDay(hour: hour, minute: 0),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      children.add(
        Container(
          constraints: slot == null
              ? const BoxConstraints(minHeight: _kHourRowMinHeight)
              : null,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: 4),
                  child: Text(
                    fmt,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: slot == null
                    ? const SizedBox()
                    : Column(
                        children: [
                          for (final it in slot)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: _TimelineItemCard(
                                key: ValueKey(it.id),
                                item: it,
                                l10n: l10n,
                                timeLabel: _timeLabel(material, it),
                                onToggleDone: () => cbs.onToggleDone(it),
                                onToggleCancelled: () =>
                                    cbs.onToggleCancelled(it),
                                onOpenDetail: () => cbs.onOpenDetail(it),
                                onEdit: () => cbs.onEditItem(it),
                                onDelete: () => cbs.onDeleteItem(it),
                                onOpenWorkout: () => cbs.onOpenWorkout(it),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    }
    children.add(const SizedBox(height: 16));
    return children;
  }

  String _timeLabel(MaterialLocalizations material, Task item) {
    final startText = material.formatTimeOfDay(
      TimeOfDay(
        hour: item.startTimeMinutes! ~/ 60,
        minute: item.startTimeMinutes! % 60,
      ),
    );
    final end = item.endTimeMinutes;
    if (end == null) return startText;
    return '$startText – ${material.formatTimeOfDay(TimeOfDay(hour: end ~/ 60, minute: end % 60))}';
  }
}

/// Renders the load-error branch without losing the surrounding layout.
final class _ErrorGuard extends StatelessWidget {
  final bool hasError;
  final String? message;
  final Widget child;

  const _ErrorGuard({
    required this.hasError,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasError) return child;
    final l10n = AppLocalizations.of(context)!;
    return Center(child: Text(l10n.errorWithMessage(message ?? '')));
  }
}

/// A tinted chip for an experiment in the all-day strip. Tap opens the
/// experiment detail; long-press opens its edit form.
final class _AllDayChip extends StatelessWidget {
  final Experiment experiment;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AllDayChip({
    required this.experiment,
    required this.l10n,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.science_outlined,
              size: 14,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                experiment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The week flow: an infinite horizontal `PageView` whose pages are seven-day
/// overviews. Each column shows that day's experiments on top, timed tasks by
/// start time, then untimed ones. Tapping a column header jumps to that day.
final class _WeekFlowView extends StatefulWidget {
  final DateTime initialDay;
  final bool Function(DateTime a, DateTime b) isSameDay;
  final void Function(DateTime day) onSelectedDayChanged;
  final void Function(DateTime day) onJumpToDay;
  final void Function(Task item) onToggleDone;
  final void Function(Task item) onToggleCancelled;
  final void Function(Task item) onOpenDetail;
  final void Function(Task item) onEditItem;
  final void Function(Task item) onDeleteItem;
  final void Function(Task item) onOpenWorkout;
  final void Function(String experimentId) onOpenExperiment;
  final void Function(String experimentId) onEditExperiment;

  const _WeekFlowView({
    super.key,
    required this.initialDay,
    required this.isSameDay,
    required this.onSelectedDayChanged,
    required this.onJumpToDay,
    required this.onToggleDone,
    required this.onToggleCancelled,
    required this.onOpenDetail,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onOpenWorkout,
    required this.onOpenExperiment,
    required this.onEditExperiment,
  });

  @override
  State<_WeekFlowView> createState() => _WeekFlowViewState();
}

final class _WeekFlowViewState extends State<_WeekFlowView> {
  late final PageController _controller = PageController(
    initialPage: _weekPageIndex(widget.initialDay),
  );

  /// Animates the pager so the given week page is front and center (the
  /// AppBar "today" shortcut).
  void animateToWeek(int pageIndex) {
    if (!_controller.hasClients) {
      _controller.jumpToPage(pageIndex);
      return;
    }
    _controller.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _weekPageIndex(_kLastDay) + 1;
    return PageView.builder(
      controller: _controller,
      itemCount: pageCount,
      onPageChanged: (index) =>
          widget.onSelectedDayChanged(_weekStartFromIndex(index)),
      itemBuilder: (context, index) {
        return _WeekPage(
          key: ValueKey(index),
          weekStart: _weekStartFromIndex(index),
          callbacks: widget,
        );
      },
    );
  }
}

typedef _WeekCallbacks = _WeekFlowView;

/// One week page: range header + the Mon–Sun columns.
final class _WeekPage extends ConsumerWidget {
  final DateTime weekStart;
  final _WeekCallbacks callbacks;

  const _WeekPage({
    super.key,
    required this.weekStart,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final entriesAsync = ref.watch(rangeEntriesProvider((weekStart, weekEnd)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${material.formatMediumDate(weekStart)} – ${material.formatMediumDate(weekEnd)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
            data: (entries) {
              final weekTasks = [
                for (final entry in entries)
                  if (entry is TaskEntry) entry.task,
              ];
              final weekExperiments = [
                for (final entry in entries)
                  if (entry is ExperimentEntry) entry.experiment,
              ];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const VerticalDivider(width: 1),
                    Expanded(
                      child: _WeekDayColumn(
                        day: weekStart.add(Duration(days: i)),
                        tasks: weekTasks,
                        experiments: weekExperiments,
                        callbacks: callbacks,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One day column inside [_WeekPage].
final class _WeekDayColumn extends StatelessWidget {
  final DateTime day;
  final List<Task> tasks;
  final List<Experiment> experiments;
  final _WeekCallbacks callbacks;

  const _WeekDayColumn({
    required this.day,
    required this.tasks,
    required this.experiments,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final material = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isToday = _startOf(day) == _startOf(now);

    // Cancelled tasks are dropped from the planning surfaces.
    final dayTasks = tasks
        .where((it) => _startOf(it.day) == _startOf(day) && !it.isCancelled)
        .toList();
    final dayExperiments = experiments
        .where((e) => _experimentCoversDay(e, day))
        .toList();

    final timed = [
      for (final it in dayTasks)
        if (it.startTimeMinutes != null) it,
    ]..sort((a, b) => a.startTimeMinutes!.compareTo(b.startTimeMinutes!));
    final untimed = [
      for (final it in dayTasks)
        if (it.startTimeMinutes == null) it,
    ];

    final children = <Widget>[
      for (final e in dayExperiments)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: GestureDetector(
            onTap: () => callbacks.onOpenExperiment(e.id),
            onLongPress: () => callbacks.onEditExperiment(e.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 11,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      for (final it in timed)
        _WeekTaskCard(
          key: ValueKey(it.id),
          item: it,
          timeLabel: material.formatTimeOfDay(
            TimeOfDay(
              hour: it.startTimeMinutes! ~/ 60,
              minute: it.startTimeMinutes! % 60,
            ),
          ),
          onOpenDetail: () => callbacks.onOpenDetail(it),
          onEdit: () => callbacks.onEditItem(it),
        ),
      if (untimed.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
          child: Text(
            l10n.plannerAnytime,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final it in untimed)
          _WeekTaskCard(
            key: ValueKey(it.id),
            item: it,
            onOpenDetail: () => callbacks.onOpenDetail(it),
            onEdit: () => callbacks.onEditItem(it),
          ),
      ],
    ];

    return Column(
      children: [
        InkWell(
          onTap: () => callbacks.onJumpToDay(day),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? theme.colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  material.narrowWeekdays[day.weekday % 7],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: children.isEmpty
              ? const SizedBox()
              : ListView(padding: const EdgeInsets.all(2), children: children),
        ),
      ],
    );
  }
}

/// Compact task card for the week overview: time (timed only) above a
/// two-line title. Tap opens detail; long-press edits.
final class _WeekTaskCard extends StatelessWidget {
  final Task item;
  final String? timeLabel;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;

  const _WeekTaskCard({
    super.key,
    required this.item,
    this.timeLabel,
    required this.onOpenDetail,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = item.done || item.isCancelled;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: InkWell(
        onTap: onOpenDetail,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timeLabel != null)
                Text(
                  timeLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: muted ? TextDecoration.lineThrough : null,
                  color: muted
                      ? theme.colorScheme.outline
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The month overview: the calendar grid showing both plain tasks (dot
/// marker) and experiment ranges (tinted background). Picking a day jumps to
/// the day flow.
final class _MonthOverview extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final bool Function(DateTime a, DateTime b) isSameDay;
  final void Function(DateTime day) onDayPicked;

  const _MonthOverview({
    super.key,
    required this.selectedDay,
    required this.isSameDay,
    required this.onDayPicked,
  });

  @override
  ConsumerState<_MonthOverview> createState() => _MonthOverviewState();
}

final class _MonthOverviewState extends ConsumerState<_MonthOverview> {
  late DateTime _focusedDay = widget.selectedDay;

  /// Re-centers the grid on [day] without leaving the month view (the AppBar
  /// "today" shortcut).
  void focusDay(DateTime day) =>
      setState(() => _focusedDay = DateTime(day.year, day.month, day.day));

  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final entriesAsync = ref.watch(monthEntriesProvider(monthStart));

    // The union carries both halves: tasks mark their day, experiments tint
    // every day of their span.
    final taskDays = <DateTime>{};
    final experimentDays = <DateTime>{};
    for (final entry in entriesAsync.value ?? const <PlannerEntry>[]) {
      switch (entry) {
        case TaskEntry(:final task):
          if (!task.isCancelled) taskDays.add(_startOfDay(task.day));
        case ExperimentEntry(:final experiment):
          final start = _startOfDay(experiment.startDate);
          final end = experiment.endDate == null
              ? start
              : _startOfDay(experiment.endDate!);
          for (
            var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))
          ) {
            experimentDays.add(d);
          }
      }
    }

    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: _kLastDay,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      // The label is only shown by the (hidden) format toggle button;
      // the map must contain the fixed calendarFormat above.
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      selectedDayPredicate: (day) => widget.isSameDay(day, widget.selectedDay),
      onDaySelected: (selected, focused) {
        setState(() => _focusedDay = _startOfDay(focused));
        widget.onDayPicked(_startOfDay(selected));
      },
      onPageChanged: (focused) =>
          setState(() => _focusedDay = _startOfDay(focused)),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedMonth) => _dayCell(
          context,
          day,
          focusedMonth,
          taskDays: taskDays,
          experimentDays: experimentDays,
        ),
      ),
    );
  }

  /// Custom cell for days worth marking: experiment-range tint, a task dot,
  /// the selected-day fill, and today's outline. Plain days return null so
  /// the stock rendering applies.
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
    final isSelected = widget.isSameDay(day, widget.selectedDay);
    final isToday = widget.isSameDay(d, _startOfDay(DateTime.now()));
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
    } else if (inExperiment) {
      decoration = BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      );
    } else {
      decoration = BoxDecoration(
        color: null,
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
          if (hasTask)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 8,
              height: 8,
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

/// A planner task card used for both the Anytime group and the hourly slots.
/// Layout is identical for both: the done `Checkbox` is on the left, the
/// title beside it, and the time pill (scheduled only) plus the linked-workout
/// icon sit in a small meta row underneath the title.
///
/// Gestures: tap opens the full detail view; long-press edits in place.
/// Swipe left deletes; swipe right cancels (reopens a cancelled task). The
/// done checkbox is inert while cancelled — use swipe-right or the detail
/// actions to bring the task back.
final class _TimelineItemCard extends StatelessWidget {
  final Task item;
  final AppLocalizations l10n;
  final String? timeLabel;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleCancelled;
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
    required this.onToggleCancelled,
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
    final cancelled = item.isCancelled;

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

    // Meta row shown under the title: cancelled chip, time pill (scheduled) +
    // linked-workout icon + tag chips. All intentionally small; wraps on
    // narrow screens.
    final metaChildren = <Widget>[
      if (cancelled)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            l10n.plannerTaskCancelled,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
    ];
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
      direction: DismissDirection.horizontal,
      // Swipe right = cancel (reopen when already cancelled); swipe left =
      // delete.
      background: Container(
        color: theme.colorScheme.tertiary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(
          cancelled ? Icons.undo : Icons.cancel_outlined,
          color: theme.colorScheme.onTertiary,
        ),
      ),
      secondaryBackground: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onToggleCancelled();
        } else {
          onDelete();
        }
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Inert while cancelled: bring the task back first (swipe
              // right or the detail actions) before marking it done.
              Checkbox(
                value: item.done,
                onChanged: cancelled ? null : (_) => onToggleDone(),
              ),
              Expanded(
                child: InkWell(
                  // Tap opens the full detail screen; long-press edits in
                  // place.
                  onTap: onOpenDetail,
                  onLongPress: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: item.done || cancelled
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
