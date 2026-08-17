import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard.dart';
import '../../exercise/screens/workout_detail.dart';
import '../../exercise/providers/workouts.dart';
import '../../models/planner_item.dart';
import '../../notifications/task_reminders.dart';
import '../../settings/providers/settings.dart';
import '../../ui/haptics.dart';
import '../../ui/tag_colors.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../providers/planner.dart';
import '../repositories/planner_repository.dart';
import 'planner_item_dialog.dart';

final class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

enum _PlannerViewMode { day, month }

final class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  /// Fixed anchor for the infinite day pager; all real days are after it.
  static final DateTime _anchorDate = DateTime(2000);

  late DateTime _selectedDay;
  late final PageController _pageController;
  _PlannerViewMode _viewMode = _PlannerViewMode.day;

  @override
  void initState() {
    super.initState();
    _selectedDay = _startOfDay(DateTime.now());
    _pageController = PageController(initialPage: _dayIndex(_selectedDay));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  /// Whole-day offset of [day] from `_anchorDate`. Computed in UTC so DST
  /// transitions never skew the page index.
  static int _dayIndex(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day)
          .difference(
            DateTime.utc(_anchorDate.year, _anchorDate.month, _anchorDate.day),
          )
          .inDays;

  /// Start-of-day for the day [index] days after `_anchorDate`.
  static DateTime _dayFromIndex(int index) {
    final day = DateTime.utc(
      _anchorDate.year,
      _anchorDate.month,
      _anchorDate.day,
    ).add(Duration(days: index));
    return DateTime(day.year, day.month, day.day);
  }

  bool get _isToday => _selectedDay == _startOfDay(DateTime.now());

  void _previousDay() =>
      _animateToDay(_selectedDay.subtract(const Duration(days: 1)));

  void _nextDay() => _animateToDay(_selectedDay.add(const Duration(days: 1)));

  void _goToday() => _animateToDay(_startOfDay(DateTime.now()));

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == _PlannerViewMode.day
          ? _PlannerViewMode.month
          : _PlannerViewMode.day;
    });
    // When returning to the day pager, snap it to the selected day so the
    // two views stay in sync.
    if (_viewMode == _PlannerViewMode.day) {
      _pageController.jumpToPage(_dayIndex(_selectedDay));
    }
  }

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

  /// Animates the day pager to [day]; `onPageChanged` keeps `_selectedDay`
  /// in sync once the page settles.
  void _animateToDay(DateTime day) {
    _pageController.animateToPage(
      _dayIndex(day),
      duration: FitFatTokens.motionNormal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plannerAppBar),
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == _PlannerViewMode.day
                  ? Icons.calendar_month
                  : Icons.view_agenda,
            ),
            tooltip: _viewMode == _PlannerViewMode.day
                ? l10n.plannerViewMonth
                : l10n.plannerViewDay,
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: l10n.plannerCopyPrevious,
            onPressed: _copyFromPreviousDay,
          ),
        ],
      ),
      body: _viewMode == _PlannerViewMode.day
          ? Column(
              children: [
                _DayNavHeader(
                  selectedDay: _selectedDay,
                  isToday: _isToday,
                  onPrevious: _previousDay,
                  onNext: _nextDay,
                  onToday: _goToday,
                ),
                const Divider(height: 1),
                Expanded(
                  // Infinite horizontal pager: page index = whole-day offset from
                  // `_anchorDate`. Each `_DayPage` watches its own day's items so
                  // adjacent days load independently of the selected day.
                  // Swiping the body is disabled so a horizontal drag on a task
                  // card triggers its swipe-to-delete instead of changing the day;
                  // day changes happen from the header (buttons + swipe gesture).
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) => setState(() {
                      _selectedDay = _dayFromIndex(index);
                    }),
                    itemBuilder: (context, index) => _DayPage(
                      day: _dayFromIndex(index),
                      l10n: l10n,
                      onAddItem: _addItem,
                      onToggleDone: _toggleDone,
                      onEdit: _editItem,
                      onDelete: _deleteItem,
                      onOpenWorkout: _openWorkout,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                CalendarDatePicker(
                  key: ValueKey(_selectedDay),
                  initialDate: _selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  currentDate: _startOfDay(DateTime.now()),
                  onDateChanged: (day) =>
                      setState(() => _selectedDay = _startOfDay(day)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _DayPage(
                    day: _selectedDay,
                    l10n: l10n,
                    onAddItem: _addItem,
                    onToggleDone: _toggleDone,
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                    onOpenWorkout: _openWorkout,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
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
      day: _selectedDay,
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
    invalidateDashboard(ref);
    // Best-effort eager materialization of future occurrences; the per-day
    // provider also materializes lazily on view, so a failure here can't block
    // the UI (this is what previously made new recurring tasks "appear only
    // after a restart").
    if (recurrence != null) {
      unawaited(
        repo
            .materializeUpTo(_selectedDay.add(const Duration(days: 90)))
            .catchError((_) {}),
      );
    }
  }

  Future<void> _editItem(PlannerItem item) async {
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
    final wasAnchor = item.recurrence != null;
    final isAnchor = recurrence != null;
    // Anchor keeps its existing series id (or adopts its own id); a task that
    // gains a rule starts a fresh series. Turning the rule off detaches it; a
    // plain occurrence stays linked to its original series.
    final seriesId = isAnchor
        ? (wasAnchor ? (item.seriesId ?? item.id) : item.id)
        : (wasAnchor ? null : item.seriesId);
    final updated = item.copyWith(
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
    invalidateDashboard(ref);
    // Editing the anchor re-generates future occurrences from the (possibly
    // changed) rule; the anchor's past/own row is untouched. Best-effort:
    // the per-day provider also materializes lazily on view.
    if (isAnchor) {
      await repo.deleteFutureOccurrences(seriesId!, DateTime.now());
      unawaited(
        repo
            .materializeUpTo(updated.day.add(const Duration(days: 90)))
            .catchError((_) {}),
      );
    }
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
      showTopBanner(context, message: AppLocalizations.of(context)!.plannerLinkedWorkout);
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

    if (wasAnchor && item.seriesId != null) {
      // Deleting the anchor removes the whole series (anchor + occurrences).
      final occurrences = await repo.getBySeriesId(item.seriesId!);
      for (final it in occurrences) {
        await _cancelReminder(it.id);
      }
      await repo.deleteSeries(item.seriesId!);
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
                await repo.materializeUpTo(
                  item.day.add(const Duration(days: 90)),
                );
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
    final overlay = Overlay.of(context);
    final yesterday = _selectedDay.subtract(const Duration(days: 1));
    final previousItems = await repo.getByDay(yesterday);
    final pendingCount = previousItems.where((e) => !e.done).length;
    if (!mounted) return;

    if (pendingCount == 0) {
      showTopBanner(context, message: l10n.plannerCopyNothing);
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

    final copied = await repo.copyFromPreviousDay(_selectedDay);
    if (!mounted) return;
    // The copied tasks got fresh ids; re-schedule reminders for the ones that
    // carried a due time (past-due ones are skipped by the scheduler).
    final copiedItems = await repo.getByDay(_selectedDay);
    if (!mounted) return;
    for (final it in copiedItems) {
      await _syncReminder(it);
    }
    showTopBannerOverlay(overlay, message: l10n.plannerCopyDone(copied));
    ref.invalidate(plannerItemsProvider(_selectedDay));
    invalidateDashboard(ref);
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
  final void Function(PlannerItem item) onEdit;
  final void Function(PlannerItem item) onDelete;
  final void Function(PlannerItem item) onOpenWorkout;

  const _DayPage({
    required this.day,
    required this.l10n,
    required this.onAddItem,
    required this.onToggleDone,
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
        timed.sort((a, b) => a.startTimeMinutes!.compareTo(b.startTimeMinutes!));

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
                : '$startText – ${fmt(
                    TimeOfDay(
                      hour: timedItem.endTimeMinutes! ~/ 60,
                      minute: timedItem.endTimeMinutes! % 60,
                    ),
                  )}';
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

final class _DayNavHeader extends StatelessWidget {
  final DateTime selectedDay;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _DayNavHeader({
    required this.selectedDay,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    // Swiping horizontally on the header changes the day (right = previous,
    // left = next) without affecting the task list body below.
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity == null) return;
        if (velocity < 0) {
          onNext();
        } else if (velocity > 0) {
          onPrevious();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.plannerPreviousDay,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Center(
                child: Text(
                  materialL10n.formatMediumDate(selectedDay),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.plannerNextDay,
              onPressed: onNext,
            ),
            TextButton(
              onPressed: isToday ? null : onToday,
              child: Text(l10n.plannerToday),
            ),
          ],
        ),
      ),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenWorkout;

  const _TimelineItemCard({
    super.key,
    required this.item,
    required this.l10n,
    this.timeLabel,
    required this.onToggleDone,
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
                  onTap: onEdit,
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
