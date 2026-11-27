import 'dart:async';

import 'package:material_ui/material_ui.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../exercise/screens/workout_detail.dart';
import '../../exercise/providers/workout_templates.dart';
import '../../exercise/providers/workouts.dart';
import '../providers/dismissed.dart';
import '../../goals/screens/goal_form_screen.dart';
import '../../models/planner_entry.dart';
import '../../models/task.dart';
import '../../notifications/task_reminders.dart';
import '../../tags/providers/tags.dart';
import '../../settings/providers/settings.dart';
import 'initiatives_view.dart';
import '../widgets/quick_add_sheet.dart';
import '../../goals/providers/goals.dart';
import '../../models/goal.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/planner.dart';
import '../repositories/task_repository.dart';
import 'planner_item_detail.dart';
import 'planner_item_form.dart';

enum _PlannerViewMode { day, week, month }

enum _PlanMode { timeline, initiatives }

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
    // Prompt for notification + exact-alarm permissions on user-initiated
    // scheduling (timed and untimed alike), never on bulk startup reschedules.
    // Exact denial silently falls back to inexact.
    await scheduler.requestPermissions();
    await scheduler.requestExactAlarmsPermission();
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
    final isToday = _isSameDay(_selectedDay, _startOfDay(DateTime.now()));
    final tasksMode = _planMode == _PlanMode.timeline;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannerAppBar),
        actions: [
          if (tasksMode && (!isToday || _viewMode != _PlannerViewMode.day))
            IconButton(
              tooltip: l10n.plannerGoToday,
              icon: const Icon(Icons.today_outlined),
              onPressed: () {
                _goToToday();
                setState(() => _viewMode = _PlannerViewMode.day);
              },
            ),
          if (tasksMode)
            PopupMenuButton<_PlannerViewMode>(
              tooltip: l10n.plannerViewsTooltip,
              icon: Icon(switch (_viewMode) {
                _PlannerViewMode.day => Icons.calendar_today_outlined,
                _PlannerViewMode.week => Icons.view_week_outlined,
                _PlannerViewMode.month => Icons.calendar_month_outlined,
              }),
              initialValue: _viewMode,
              onSelected: (m) => setState(() => _viewMode = m),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _PlannerViewMode.day,
                  child: Text(l10n.plannerViewDay),
                ),
                PopupMenuItem(
                  value: _PlannerViewMode.week,
                  child: Text(l10n.plannerViewWeek),
                ),
                PopupMenuItem(
                  value: _PlannerViewMode.month,
                  child: Text(l10n.plannerViewMonth),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PlanMode>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  ButtonSegment(
                    value: _PlanMode.timeline,
                    label: Text(l10n.plannerTabTasks),
                  ),
                  ButtonSegment(
                    value: _PlanMode.initiatives,
                    label: Text(l10n.plannerTabGoals),
                  ),
                ],
                selected: {_planMode},
                onSelectionChanged: (selection) =>
                    setState(() => _planMode = selection.first),
              ),
            ),
          ),
          Expanded(
            child: _planMode == _PlanMode.initiatives
                ? InitiativesView(onAdd: _newGoal)
                : switch (_viewMode) {
                    _PlannerViewMode.day => _DayFlowView(
                      key: _dayFlowKey,
                      initialDay: _selectedDay,
                      isSameDay: _isSameDay,
                      onSelectedDayChanged: (day) =>
                          setState(() => _selectedDay = _startOfDay(day)),
                      onAddItem: _quickAdd,
                      onToggleDone: _toggleDone,
                      onToggleCancelled: _toggleCancelled,
                      onOpenDetail: _openDetail,
                      onEditItem: _editItem,
                      onDeleteItem: _deleteItem,
                      onOpenWorkout: _openWorkout,
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
        heroTag: null,
        tooltip: tasksMode ? l10n.plannerAddTask : l10n.goalsNew,
        onPressed: tasksMode ? _quickAdd : _newGoal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _newGoal() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const GoalFormScreen()));
  }

  /// + on Today: the quick-add sheet. Each Add inserts a task and keeps the
  /// sheet open; More options continues in the full form.
  Future<void> _quickAdd() async {
    final goals = [
      for (final g in await ref.read(goalListProvider.future))
        if (g.status == GoalStatus.active || g.status == GoalStatus.planned) g,
    ];
    if (!mounted) return;
    final more = await showQuickAddSheet(
      context,
      day: _selectedDay,
      goals: goals,
      onAdd: _insertQuick,
    );
    if (more != null && mounted) await _addItem(initialTitle: more.title);
  }

  Future<void> _insertQuick(QuickTask t) async {
    final repo = ref.read(taskRepositoryProvider);
    final day = _startOfDay(t.day);
    final existing = [
      for (final entry
          in ref.read(dayEntriesProvider(day)).value ?? const <PlannerEntry>[])
        if (entry is TaskEntry) entry.task,
    ];
    var next = 0;
    for (final it in existing) {
      if (it.sortOrder >= next) next = it.sortOrder + 1;
    }
    final item = newTask(
      day: day,
      title: t.title,
      sortOrder: next,
      startTimeMinutes: t.startMinutes,
      endTimeMinutes: t.endMinutes,
      recurrence: t.recurrence,
    );
    await repo.insert(item);
    if (t.recurrence != null) {
      await repo.update(item.copyWith(seriesId: item.id));
    }
    if (t.goalId != null) {
      await ref.read(linksRepositoryProvider).linkTaskGoal(item.id, t.goalId!);
      ref.invalidate(tasksByGoalProvider(t.goalId!));
    }
    if (mounted) await _syncReminder(item);
    ref.invalidate(dayEntriesProvider(day));
    invalidateDashboard(ref);
    if (t.recurrence != null) {
      unawaited(
        repo.materializeUpTo(item.day.add(_plannerHorizon)).catchError((_) {}),
      );
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

  Future<void> _addItem({String? initialTitle}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showPlannerItemDialog(
      context,
      dialogTitle: l10n.plannerAddTask,
      initialTitle: initialTitle,
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
          ref.read(dismissedTaskIdsProvider.notifier).remove(item.id);
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
        ref.read(dismissedTaskIdsProvider.notifier).remove(item.id);
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

/// One day inside [_DayFlowView]: date header, an "Anytime" group for untimed
/// tasks, and an hourly grid for timed ones. Today's page opens scrolled to
/// roughly the current hour.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entriesAsync = ref.watch(dayEntriesProvider(widget.day));
    final dismissed = ref.watch(dismissedTaskIdsProvider);
    final cbs = widget.callbacks;

    final tasks = [
      for (final entry in entriesAsync.value ?? const <PlannerEntry>[])
        if (entry is TaskEntry &&
            !entry.task.isCancelled &&
            !dismissed.contains(entry.task.id))
          entry.task,
    ];
    final timed = [
      for (final t in tasks)
        if (t.startTimeMinutes != null) t,
    ]..sort((a, b) => a.startTimeMinutes!.compareTo(b.startTimeMinutes!));
    final anytime = [
      for (final t in tasks)
        if (t.startTimeMinutes == null) t,
    ];
    final done = tasks.where((t) => t.done).length;
    final now = DateTime.now();
    final isToday = cbs.isSameDay(widget.day, now);
    final nowMinutes = now.hour * 60 + now.minute;

    void step(int delta) => context
        .findAncestorStateOfType<_DayFlowViewState>()
        ?.animateToDate(_dayPageIndex(widget.day) + delta);

    Widget row(Task t) => _TaskRow(
      key: ValueKey(t.id),
      item: t,
      onToggleDone: () => cbs.onToggleDone(t),
      onToggleCancelled: () {
        ref.read(dismissedTaskIdsProvider.notifier).add(t.id);
        cbs.onToggleCancelled(t);
      },
      onOpenDetail: () => cbs.onOpenDetail(t),
      onEdit: () => cbs.onEditItem(t),
      onDelete: () {
        ref.read(dismissedTaskIdsProvider.notifier).add(t.id);
        cbs.onDeleteItem(t);
      },
      onOpenWorkout: () => cbs.onOpenWorkout(t),
    );

    Widget card(List<Widget> rows) => Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && rows[i] is! _NowLine && rows[i - 1] is! _NowLine)
              Divider(
                height: 1,
                indent: FitFatTokens.spaceL,
                endIndent: FitFatTokens.spaceL,
                color: scheme.outlineVariant,
              ),
            rows[i],
          ],
        ],
      ),
    );

    // The now line goes before the first task that starts after now.
    final timedRows = <Widget>[];
    var nowPlaced = !isToday;
    for (final t in timed) {
      if (!nowPlaced && t.startTimeMinutes! > nowMinutes) {
        timedRows.add(const _NowLine());
        nowPlaced = true;
      }
      timedRows.add(row(t));
    }
    if (!nowPlaced && timed.isNotEmpty) timedRows.add(const _NowLine());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => step(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isToday
                          ? l10n.plannerToday
                          : DateFormat.EEEE(locale).format(widget.day),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      [
                        DateFormat.MMMd(locale).format(widget.day),
                        if (tasks.isNotEmpty)
                          l10n.plannerDoneOf(done, tasks.length),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => step(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? EmptyState(
                  icon: Icons.event_note,
                  title: l10n.emptyPlannerTitle,
                  description: l10n.emptyPlannerBody,
                  ctaLabel: l10n.emptyPlannerCta,
                  onCtaPressed: cbs.onAddItem,
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    FitFatTokens.spaceL,
                    FitFatTokens.spaceXs,
                    FitFatTokens.spaceL,
                    96,
                  ),
                  children: [
                    if (timedRows.isNotEmpty) card(timedRows),
                    if (anytime.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                        child: Text(
                          l10n.plannerAnytime.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      card([for (final t in anytime) row(t)]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// The red current-time line in today's list.
final class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final now = TimeOfDay.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FitFatTokens.spaceL),
      child: Row(
        spacing: 6,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(now, alwaysUse24HourFormat: true),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: color)),
        ],
      ),
    );
  }
}

/// untimed ones. Tapping a column header jumps to that day.
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
          child: Builder(
            builder: (context) {
              final entries = entriesAsync.value ?? const <PlannerEntry>[];
              if (entriesAsync.isLoading && !entriesAsync.hasValue) {
                return const Center(child: CircularProgressIndicator());
              }
              if (entriesAsync.hasError && !entriesAsync.hasValue) {
                return Center(
                  child: Text(l10n.errorWithMessage('${entriesAsync.error}')),
                );
              }
              final weekTasks = [
                for (final entry in entries)
                  if (entry is TaskEntry) entry.task,
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
final class _WeekDayColumn extends ConsumerWidget {
  final DateTime day;
  final List<Task> tasks;
  final _WeekCallbacks callbacks;

  const _WeekDayColumn({
    required this.day,
    required this.tasks,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final material = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isToday = _startOf(day) == _startOf(now);
    final dismissed = ref.watch(dismissedTaskIdsProvider);

    // Cancelled tasks are dropped from the planning surfaces.
    final dayTasks = tasks
        .where(
          (it) =>
              _startOf(it.day) == _startOf(day) &&
              !it.isCancelled &&
              !dismissed.contains(it.id),
        )
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

/// The month overview: the calendar grid showing plain tasks (dot marker).
/// Picking a day jumps to the day flow.
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

    // Tasks mark their day.
    final taskDays = <DateTime>{};
    for (final entry in entriesAsync.value ?? const <PlannerEntry>[]) {
      switch (entry) {
        case TaskEntry(:final task):
          if (!task.isCancelled) taskDays.add(_startOfDay(task.day));
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
        defaultBuilder: (context, day, focusedMonth) =>
            _dayCell(context, day, focusedMonth, taskDays: taskDays),
      ),
    );
  }

  /// Custom cell for days worth marking: a task dot, the selected-day fill,
  /// and today's outline. Plain days return null so the stock rendering
  /// applies.
  Widget? _dayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedMonth, {
    required Set<DateTime> taskDays,
  }) {
    final d = _startOfDay(day);
    final hasTask = taskDays.contains(d);
    final isSelected = widget.isSameDay(day, widget.selectedDay);
    final isToday = widget.isSameDay(d, _startOfDay(DateTime.now()));
    if (!hasTask && !isSelected && !isToday) return null;

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

/// One task in the day list: start / end on the left (timed tasks), the
/// checkbox, the title and a meta line (tags, repeat, linked workout, note).
/// Swipe right cancels (or reopens), swipe left deletes; tap opens the detail,
/// long-press edits.
final class _TaskRow extends StatelessWidget {
  final Task item;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleCancelled;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenWorkout;

  const _TaskRow({
    super.key,
    required this.item,
    required this.onToggleDone,
    required this.onToggleCancelled,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenWorkout,
  });

  String _hm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final cancelled = item.isCancelled;
    final faded = item.done || cancelled;
    final note = item.notes?.trim();
    final metaStyle = theme.textTheme.bodySmall?.copyWith(color: muted);
    final meta = <Widget>[
      for (final tag in item.tags ?? const <String>[])
        Text('#$tag', style: metaStyle),
      if (item.recurrence != null || item.seriesId != null)
        Icon(Icons.repeat, size: 14, color: muted),
      if (item.workoutId != null)
        InkWell(
          onTap: onOpenWorkout,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Icon(Icons.fitness_center, size: 14, color: muted),
              Text(l10n.plannerLinkedWorkout, style: metaStyle),
            ],
          ),
        ),
      if (note != null && note.isNotEmpty)
        Flexible(
          child: Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
    ];
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: scheme.tertiary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(
          cancelled ? Icons.undo : Icons.cancel_outlined,
          color: scheme.onTertiary,
        ),
      ),
      secondaryBackground: Container(
        color: scheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: scheme.onError),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onToggleCancelled();
        } else {
          onDelete();
        }
      },
      child: InkWell(
        onTap: onOpenDetail,
        onLongPress: onEdit,
        child: Opacity(
          opacity: faded ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FitFatTokens.spaceL,
              FitFatTokens.spaceXs,
              FitFatTokens.spaceS,
              FitFatTokens.spaceXs,
            ),
            child: Row(
              children: [
                if (item.startTimeMinutes != null)
                  SizedBox(
                    width: 44,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hm(item.startTimeMinutes!),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (item.endTimeMinutes != null)
                          Text(
                            _hm(item.endTimeMinutes!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                Checkbox(
                  value: item.done,
                  visualDensity: VisualDensity.compact,
                  onChanged: cancelled ? null : (_) => onToggleDone(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            decoration: faded
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (cancelled)
                          Text(l10n.plannerTaskCancelled, style: metaStyle),
                        if (meta.isNotEmpty) Row(spacing: 6, children: meta),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
