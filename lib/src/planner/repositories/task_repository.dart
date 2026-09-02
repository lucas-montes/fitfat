import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/planner_recurrence.dart';
import '../../models/task.dart';
import '../../tags/repositories/tag_repository.dart';

/// Data access for plain planner tasks (schema v27: the `tasks` table; the
/// experiment half of the former planner items lives in
/// [ExperimentRepository]).
final class TaskRepository {
  final db.AppDatabase _database;
  const TaskRepository(this._database);

  /// Tasks scheduled on [day], ordered by sort order.
  Future<List<Task>> getByDay(DateTime day) async {
    final startOfDay = _startOfDay(day);
    final rows =
        await (_database.select(_database.tasks)
              ..where((t) => t.date.equals(startOfDay.millisecondsSinceEpoch))
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Pending tasks with a start time, on or after [from] (inclusive), ordered
  /// by day then start time. Used by the dashboard's upcoming timed-tasks card.
  Future<List<Task>> getUpcomingWithStartTime(DateTime from) async {
    final fromStart = _startOfDay(from);
    final rows =
        await (_database.select(_database.tasks)
              ..where(
                (t) =>
                    t.done.equals(0) &
                    // Cancelled tasks are neither upcoming nor copyable.
                    (t.taskStatus.isNull() |
                        t.taskStatus.isNotIn([TaskStatus.cancelled.storage])) &
                    t.startTimeMinutes.isNotNull() &
                    t.date.isBiggerOrEqualValue(
                      fromStart.millisecondsSinceEpoch,
                    ),
              )
            ..orderBy([
              (t) => OrderingTerm(expression: t.date),
              (t) => OrderingTerm(expression: t.startTimeMinutes),
            ]))
        .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Pending tasks on or after [from] (inclusive), ordered by day then start
  /// time — untimed tasks come after the timed ones of the same day instead
  /// of being excluded, so the dashboard's upcoming card surfaces them too.
  /// The reminder scheduler keeps using [getUpcomingWithStartTime], whose
  /// timed-only semantics it depends on.
  Future<List<Task>> getUpcoming(DateTime from) async {
    final fromStart = _startOfDay(from);
    final rows =
        await (_database.select(_database.tasks)
              ..where(
                (t) =>
                    t.done.equals(0) &
                    // Cancelled tasks are neither upcoming nor copyable.
                    (t.taskStatus.isNull() |
                        t.taskStatus.isNotIn([TaskStatus.cancelled.storage])) &
                    t.date.isBiggerOrEqualValue(
                      fromStart.millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.date)]))
            .get();
    final tasks = rows.map(_toDomain).toList();
    int rank(Task t) => t.startTimeMinutes ?? 24 * 60;
    tasks.sort((a, b) {
      if (a.day != b.day) return a.day.compareTo(b.day);
      return rank(a).compareTo(rank(b));
    });
    return _attachTags(tasks);
  }

  Future<void> insert(Task item) async {
    await _database
        .into(_database.tasks)
        .insert(_companionFor(item, createdAt: item.createdAt));
    final tags = item.tags;
    if (tags != null) {
      await _tags.setTaskTags(item.id, tags);
    }
  }

  Future<void> update(Task item) async {
    await (_database.update(
      _database.tasks,
    )..where((t) => t.id.equals(item.id))).write(
      db.TasksCompanion(
        // `date` (the task's day) is written too: setting a due date on edit
        // moves the task to that day. All other callers pass items whose day
        // equals the stored one, so this is a no-op for them.
        date: Value(_startOfDay(item.day).millisecondsSinceEpoch),
        title: Value(item.title),
        done: Value(item.done ? 1 : 0),
        dueDate: Value(item.dueDate?.millisecondsSinceEpoch),
        startTimeMinutes: Value(item.startTimeMinutes),
        endTimeMinutes: Value(item.endTimeMinutes),
        notes: Value(item.notes),
        workoutId: Value(item.workoutId),
        workoutTemplateId: Value(item.workoutTemplateId),
        recurrence: Value(encodeRecurrenceJson(item.recurrence)),
        seriesId: Value(item.seriesId),
        taskStatus: Value(item.taskStatus?.storage),
        carryOver: Value(item.carryOver),
      ),
    );
    // Only rewrite tag links when the caller supplied tags; incidental updates
    // (rollover, recurrence edits) that didn't load tags must not wipe them.
    final tags = item.tags;
    if (tags != null) {
      await _tags.setTaskTags(item.id, tags);
    }
  }

  /// Full insert companion for a task.
  db.TasksCompanion _companionFor(Task item, {required DateTime createdAt}) =>
      db.TasksCompanion.insert(
        id: item.id,
        date: _startOfDay(item.day).millisecondsSinceEpoch,
        title: item.title,
        done: item.done ? 1 : 0,
        sortOrder: item.sortOrder,
        dueDate: Value(item.dueDate?.millisecondsSinceEpoch),
        startTimeMinutes: Value(item.startTimeMinutes),
        endTimeMinutes: Value(item.endTimeMinutes),
        notes: Value(item.notes),
        workoutId: Value(item.workoutId),
        workoutTemplateId: Value(item.workoutTemplateId),
        recurrence: Value(encodeRecurrenceJson(item.recurrence)),
        seriesId: Value(item.seriesId),
        taskStatus: Value(item.taskStatus?.storage),
        carryOver: Value(item.carryOver),
        createdAt: createdAt.millisecondsSinceEpoch,
      );

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.tasks,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Re-inserts a previously deleted [item] with its original id — the undo
  /// path for delete. Shares the create path so both stay consistent.
  Future<void> restore(Task item) => insert(item);

  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (_database.update(_database.tasks)..where((t) => t.id.equals(id)))
        .write(db.TasksCompanion(sortOrder: Value(sortOrder)));
  }

  /// Day rollover: past pending single (non-recurring) tasks are either moved
  /// to today (carry-over on) or marked cancelled (carry-over off). Recurring
  /// series are skipped — their anchor already regenerates future days.
  /// Idempotent; called on app start/resume. Returns the affected count so
  /// callers only invalidate providers when something changed.
  Future<int> rolloverPastTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows =
        await (_database.select(_database.tasks)..where(
              (t) =>
                  t.seriesId.isNull() &
                  t.date.isSmallerThanValue(today.millisecondsSinceEpoch) &
                  t.done.equals(0) &
                  (t.taskStatus.isNull() |
                      t.taskStatus.equals(TaskStatus.pending.storage)),
            ))
            .get();
    for (final row in rows) {
      final item = _toDomain(row);
      if (!item.carryOver) {
        await update(item.withTaskStatus(TaskStatus.cancelled));
        continue;
      }
      var moved = item.copyWith(day: today);
      // Keep dueDate in lockstep with the carried day: a stale earlier
      // dueDate would resurface on the next edit and regress the task back
      // to its old day (the "edited task jumps to yesterday" bug).
      final due = moved.dueDate;
      if (due != null && due.isBefore(today)) {
        moved = moved.copyWith(dueDate: today);
      }
      await update(moved);
    }
    return rows.length;
  }

  /// All distinct tags across every task, sorted. Powers the autocomplete
  /// suggestions in the add/edit dialog.
  Future<List<String>> distinctTags() async {
    final result = await _database.customSelect(
      'SELECT DISTINCT t.name AS name FROM tags t '
      'INNER JOIN task_tags l ON l.tag_id = t.id '
      'ORDER BY t.name COLLATE NOCASE',
    ).get();
    return result.map((r) => r.read<String>('name')).toList();
  }

  /// Recurring "anchor" tasks (those carrying a rule) whose series can still
  /// produce occurrences on or before [upTo]. Used to materialize occurrences.
  Future<List<Task>> getRecurringAnchors(DateTime upTo) async {
    final rows =
        await (_database.select(_database.tasks)
              ..where(
                (t) =>
                    t.recurrence.isNotNull() &
                    t.date.isSmallerOrEqualValue(
                      _startOfDay(upTo).millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.date)]))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Ensures every occurrence of every series that falls on [day] exists as a
  /// concrete task row. Idempotent: existing occurrences are left untouched.
  Future<void> materializeForDay(DateTime day) async {
    final d = _startOfDay(day);
    final anchors = await getRecurringAnchors(d);
    await _materializeDay(anchors, d);
    await materializeScheduledWorkouts(d);
  }

  /// Materializes planner tasks for workout templates whose repeat rule
  /// fires on [day] (schema v28). Each occurrence becomes a task carrying
  /// `workout_template_id`; starting it instantiates the session. Idempotent
  /// and exclusion-aware (deleted occurrences stay deleted).
  Future<int> materializeScheduledWorkouts(DateTime day) async {
    final d = _startOfDay(day);
    final dayMs = d.millisecondsSinceEpoch;
    final rows = await (_database.select(
      _database.workoutTemplates,
    )..where((t) => t.recurrence.isNotNull())).get();
    var created = 0;
    for (final row in rows) {
      final rule = decodeRecurrenceJson(row.recurrence);
      if (rule == null || !rule.isValid) continue;
      final anchor = DateTime.fromMillisecondsSinceEpoch(row.startDate);
      if (!rule.isOccurrenceOn(anchor, d)) continue;
      final excluded = _decodeDays(row.excludedDates);
      if (excluded?.contains(dayMs) ?? false) continue;
      final existing =
          await (_database.select(_database.tasks)..where(
                (t) =>
                    t.workoutTemplateId.equals(row.id) & t.date.equals(dayMs),
              ))
              .get();
      if (existing.isNotEmpty) continue;
      await _database
          .into(_database.tasks)
          .insert(
            db.TasksCompanion.insert(
              id: const Uuid().v7(),
              date: dayMs,
              title: row.name,
              done: 0,
              sortOrder: 0,
              workoutTemplateId: Value(row.id),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      created++;
    }
    return created;
  }

  /// Materializes occurrences for every day from the earliest anchor up to
  /// [upTo]. Used to seed near-future days after creating/editing a series.
  Future<void> materializeUpTo(DateTime upTo) async {
    final end = _startOfDay(upTo);
    final anchors = await getRecurringAnchors(end);
    if (anchors.isEmpty) return;
    var earliest = anchors.first.day;
    for (final a in anchors) {
      if (a.day.isBefore(earliest)) earliest = a.day;
    }
    await _database.transaction(() async {
      for (
        var d = earliest;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))
      ) {
        await _materializeDay(anchors, d);
      }
    });
  }

  Future<void> _materializeDay(List<Task> anchors, DateTime d) async {
    final dMillis = d.millisecondsSinceEpoch;
    for (final anchor in anchors) {
      final rule = anchor.recurrence;
      if (rule == null || anchor.seriesId == null) continue;
      // Respect explicitly deleted occurrences so they are not regenerated.
      if (rule.excludedDates?.contains(dMillis) ?? false) continue;
      if (!rule.isOccurrenceOn(anchor.day, d)) continue;
      final existing =
          await (_database.select(_database.tasks)..where(
                (t) =>
                    t.date.equals(dMillis) &
                    t.seriesId.equals(anchor.seriesId!),
              ))
              .get();
      if (existing.isNotEmpty) continue;
      final newId = const Uuid().v7();
      await _database
          .into(_database.tasks)
          .insert(
            db.TasksCompanion.insert(
              id: newId,
              date: dMillis,
              title: anchor.title,
              done: 0,
              sortOrder: anchor.sortOrder,
              dueDate: Value(anchor.dueDate == null ? null : dMillis),
              startTimeMinutes: Value(anchor.startTimeMinutes),
              endTimeMinutes: Value(anchor.endTimeMinutes),
              notes: Value(anchor.notes),
              workoutId: Value(anchor.workoutId),
              workoutTemplateId: Value(anchor.workoutTemplateId),
              seriesId: Value(anchor.seriesId),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      if (anchor.tags != null && anchor.tags!.isNotEmpty) {
        await _tags.setTaskTags(newId, anchor.tags!);
      }
    }
  }

  /// Loads a single task by id (used to read/update the anchor of a recurring
  /// series, whose id equals its `seriesId`).
  Future<Task?> getById(String id) async {
    final row = await (_database.select(
      _database.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([_toDomain(row)])).first;
  }

  /// All occurrences (anchor + generated) of a recurring series.
  Future<List<Task>> getBySeriesId(String seriesId) async {
    final rows = await (_database.select(
      _database.tasks,
    )..where((t) => t.seriesId.equals(seriesId))).get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Deletes one generated occurrence of a series and records its day as an
  /// excluded date on the anchor, so the materializer won't recreate it.
  Future<void> deleteOccurrence({
    required String id,
    required String seriesId,
    required DateTime day,
  }) async {
    await (_database.delete(
      _database.tasks,
    )..where((t) => t.id.equals(id))).go();
    await _setExclusion(seriesId, day, add: true);
  }

  /// Re-adds a previously deleted occurrence by clearing its excluded date.
  Future<void> removeExclusion(String seriesId, DateTime day) async {
    await _setExclusion(seriesId, day, add: false);
  }

  Future<void> _setExclusion(
    String seriesId,
    DateTime day, {
    required bool add,
  }) async {
    final anchor = await getById(seriesId);
    if (anchor == null) return;
    final rule = anchor.recurrence;
    if (rule == null) return;
    final set = <int>{...(rule.excludedDates ?? const {})};
    if (add) {
      set.add(_startOfDay(day).millisecondsSinceEpoch);
    } else {
      set.remove(_startOfDay(day).millisecondsSinceEpoch);
    }
    final updatedRule = PlannerRecurrence(
      type: rule.type,
      weekdays: rule.weekdays,
      intervalDays: rule.intervalDays,
      monthDay: rule.monthDay,
      endDate: rule.endDate,
      count: rule.count,
      excludedDates: set.isEmpty ? null : set,
    );
    await update(anchor.copyWith(recurrence: updatedRule));
  }

  /// Deletes every task in a series (anchor + all occurrences).
  Future<void> deleteSeries(String seriesId) async {
    await (_database.delete(
      _database.tasks,
    )..where((t) => t.seriesId.equals(seriesId))).go();
  }

  /// Deletes future (strictly after [from]) generated occurrences of a series,
  /// leaving the anchor and past occurrences intact. Used when an anchor's
  /// rule changes so stale future instances are dropped before re-materializing.
  Future<void> deleteFutureOccurrences(String seriesId, DateTime from) async {
    await (_database.delete(_database.tasks)..where(
          (t) =>
              t.seriesId.equals(seriesId) &
              t.date.isBiggerThanValue(
                _startOfDay(from).millisecondsSinceEpoch,
              ),
        ))
        .go();
  }

  /// Updates the non-rule fields of every generated occurrence of a series
  /// with a date on or after [from] (start-of-day, inclusive). The anchor
  /// (whose id equals the seriesId) is excluded. Used by
  /// "edit → this and all following".
  Future<void> updateFutureOccurrences(
    String seriesId, {
    required DateTime from,
    required String title,
    int? startTimeMinutes,
    int? endTimeMinutes,
    String? notes,
    String? workoutId,
    String? workoutTemplateId,
    List<String>? tags,
  }) async {
    final fromStart = _startOfDay(from).millisecondsSinceEpoch;
    await (_database.update(_database.tasks)..where(
          (t) =>
              t.seriesId.equals(seriesId) &
              t.id.isNotValue(seriesId) &
              t.date.isBiggerOrEqualValue(fromStart),
        ))
        .write(
          db.TasksCompanion(
            title: Value(title),
            startTimeMinutes: Value(startTimeMinutes),
            endTimeMinutes: Value(endTimeMinutes),
            notes: Value(notes),
            workoutId: Value(workoutId),
            workoutTemplateId: Value(workoutTemplateId),
          ),
        );
    if (tags != null) {
      final affected = await (_database.select(_database.tasks)..where(
            (t) =>
                t.seriesId.equals(seriesId) &
                t.id.isNotValue(seriesId) &
                t.date.isBiggerOrEqualValue(fromStart),
          ))
          .get();
      for (final row in affected) {
        await _tags.setTaskTags(row.id, tags);
      }
    }
  }

  /// Deletes a generated occurrence and every later occurrence of the series
  /// (date >= start-of-day [day]) and halts regeneration by setting the
  /// anchor's `recurrence.endDate` to the day before [day]. The anchor itself
  /// (id == seriesId) is never deleted. Returns the anchor's previous endDate
  /// (for undo), or null when the anchor/rule is missing. Used by
  /// "delete → this and all following".
  Future<DateTime?> stopSeriesOnOrAfter(String seriesId, DateTime day) async {
    final dayStart = _startOfDay(day).millisecondsSinceEpoch;
    DateTime? previousEndDate;
    await _database.transaction(() async {
      await (_database.delete(_database.tasks)..where(
            (t) =>
                t.seriesId.equals(seriesId) &
                t.id.isNotValue(seriesId) &
                t.date.isBiggerOrEqualValue(dayStart),
          ))
          .go();
      final anchor = await getById(seriesId);
      if (anchor == null) return;
      final rule = anchor.recurrence;
      if (rule == null) return;
      previousEndDate = rule.endDate;
      final updatedRule = PlannerRecurrence(
        type: rule.type,
        weekdays: rule.weekdays,
        intervalDays: rule.intervalDays,
        monthDay: rule.monthDay,
        endDate: _startOfDay(day).subtract(const Duration(days: 1)),
        count: rule.count,
        excludedDates: rule.excludedDates,
      );
      await update(anchor.copyWith(recurrence: updatedRule));
    });
    return previousEndDate;
  }

  /// Restores a series anchor's `recurrence.endDate` — the undo counterpart of
  /// [stopSeriesOnOrAfter]. Re-materializing is left to the caller.
  Future<void> restoreSeriesEndDate(String seriesId, DateTime? endDate) async {
    final anchor = await getById(seriesId);
    if (anchor == null) return;
    final rule = anchor.recurrence;
    if (rule == null) return;
    final updatedRule = PlannerRecurrence(
      type: rule.type,
      weekdays: rule.weekdays,
      intervalDays: rule.intervalDays,
      monthDay: rule.monthDay,
      endDate: endDate,
      count: rule.count,
      excludedDates: rule.excludedDates,
    );
    await update(anchor.copyWith(recurrence: updatedRule));
  }

  /// Tasks whose title contains [query] (case-insensitive), newest first.
  /// Powers link-a-task pickers.
  Future<List<Task>> searchTasks(String query, {int limit = 50}) async {
    final pattern = '%${query.trim()}%';
    final rows =
        await (_database.select(_database.tasks)
              ..where((t) => t.title.like(pattern))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Creates the "do this workout" planner task for a workout: a pending
  /// task on [day] carrying [workoutId] so the two stay 1:1 linked. Used by
  /// the workout form ("add planner task") and by replay so each occurrence
  /// regenerates its task automatically.
  Future<Task> createForWorkout({
    required String workoutId,
    required String title,
    required DateTime day,
    String? notes,
    int? startTimeMinutes,
    int? endTimeMinutes,
    List<String>? tags,
    int sortOrder = 0,
  }) async {
    final task = newTask(
      day: day,
      title: title,
      notes: notes,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      tags: tags,
      sortOrder: sortOrder,
      workoutId: workoutId,
    );
    await insert(task);
    return task;
  }

  /// The task linked to [workoutId] via its `workout_id` column, if any.
  Future<Task?> getByWorkoutId(String workoutId) async {
    final rows = await (_database.select(
      _database.tasks,
    )..where((t) => t.workoutId.equals(workoutId))).get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  /// All tasks with `date` within [start, end] (start-of-day bounds,
  /// inclusive). Combined with the matching experiment query this powers the
  /// timeline union.
  Future<List<Task>> getByRange(DateTime start, DateTime end) async {
    final fromMs = _startOfDay(start).millisecondsSinceEpoch;
    final toMs = _startOfDay(end).millisecondsSinceEpoch;
    final rows =
        await (_database.select(_database.tasks)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(fromMs) &
                  t.date.isSmallerOrEqualValue(toMs),
            ))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  Task _toDomain(db.Task row) => taskFromRow(row);

  /// Every task regardless of date (used by data push/sync).
  Future<List<Task>> getAll() async {
    final rows = await _database.select(_database.tasks).get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Normalizes any [DateTime] to the start of its day so every day is a
  /// stable query key, matching how `date` is stored.
  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  /// Tag (priority) access for this task table.
  TagRepository get _tags => TagRepository(_database);

  /// Populates [Task.tags] for a batch of tasks in a single lookup.
  Future<List<Task>> _attachTags(List<Task> tasks) async {
    if (tasks.isEmpty) return tasks;
    final map = await _tags.tagNamesForTasks(
      tasks.map((t) => t.id).toList(),
    );
    return [
      for (final t in tasks) t.copyWith(tags: map[t.id] ?? const []),
    ];
  }
}

/// Maps a database task row to the domain model. Shared with
/// [LinksRepository] so joined link queries can map the same way.
Task taskFromRow(db.Task row) => Task(
  id: row.id,
  day: DateTime.fromMillisecondsSinceEpoch(row.date),
  title: row.title,
  done: row.done != 0,
  sortOrder: row.sortOrder,
  dueDate: row.dueDate == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(row.dueDate!),
  startTimeMinutes: row.startTimeMinutes,
  endTimeMinutes: row.endTimeMinutes,
  notes: row.notes,
  workoutId: row.workoutId,
  workoutTemplateId: row.workoutTemplateId,
  tags: null,
  recurrence: decodeRecurrenceJson(row.recurrence),
  seriesId: row.seriesId,
  taskStatus: row.taskStatus == null
      ? null
      : TaskStatus.values[row.taskStatus!.clamp(
          0,
          TaskStatus.values.length - 1,
        )],
  carryOver: row.carryOver,
  createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
);

/// Decodes a JSON string[] tag column; shared across repositories.
List<String>? decodeTagList(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return null;
}

/// Decodes a JSON int[] column (template exclusion days); shared internally.
Set<int>? _decodeDays(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<int>().toSet();
  } catch (_) {}
  return null;
}

String? encodeRecurrenceJson(PlannerRecurrence? recurrence) {
  if (recurrence == null) return null;
  return jsonEncode(recurrence.toJson());
}

PlannerRecurrence? decodeRecurrenceJson(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    return PlannerRecurrence.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Creates a new [Task] with a fresh UUID v7, the current timestamp, and its
/// `day` normalized to start-of-day.
Task newTask({
  required DateTime day,
  required String title,
  int sortOrder = 0,
  DateTime? dueDate,
  int? startTimeMinutes,
  int? endTimeMinutes,
  String? notes,
  String? workoutId,
  String? workoutTemplateId,
  List<String>? tags,
  PlannerRecurrence? recurrence,
  String? seriesId,
  bool carryOver = true,
}) => Task(
  id: const Uuid().v7(),
  day: DateTime(day.year, day.month, day.day),
  title: title,
  done: false,
  taskStatus: TaskStatus.pending,
  carryOver: carryOver,
  sortOrder: sortOrder,
  dueDate: dueDate,
  startTimeMinutes: startTimeMinutes,
  endTimeMinutes: endTimeMinutes,
  notes: notes,
  workoutId: workoutId,
  workoutTemplateId: workoutTemplateId,
  tags: tags,
  recurrence: recurrence,
  seriesId: seriesId,
  createdAt: DateTime.now(),
);
