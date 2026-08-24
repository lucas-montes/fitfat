import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/experiment.dart';
import '../../models/planner_item.dart';
import '../../models/planner_recurrence.dart';

final class PlannerRepository {
  final db.AppDatabase _database;
  const PlannerRepository(this._database);

  Future<List<PlannerItem>> getByDay(DateTime day) async {
    final startOfDay = _startOfDay(day);
    final rows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) =>
                    t.date.equals(startOfDay.millisecondsSinceEpoch) &
                    t.kind.equals(_kindStorage(PlannerItemKind.task)),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Pending tasks with a start time, on or after [from] (inclusive), ordered
  /// by day then start time. Used by the dashboard's upcoming timed-tasks card.
  Future<List<PlannerItem>> getUpcomingWithStartTime(DateTime from) async {
    final fromStart = _startOfDay(from);
    final rows =
        await (_database.select(_database.plannerItems)
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
    return rows.map(_toDomain).toList();
  }

  Future<void> insert(PlannerItem item) async {
    await _database
        .into(_database.plannerItems)
        .insert(_companionFor(item, createdAt: item.createdAt));
  }

  Future<void> update(PlannerItem item) async {
    await (_database.update(
      _database.plannerItems,
    )..where((t) => t.id.equals(item.id))).write(
      db.PlannerItemsCompanion(
        // `date` (the item's day) is written too: setting a due date on edit
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
        tags: Value(_encode(item.tags)),
        recurrence: Value(_encodeRecurrence(item.recurrence)),
        seriesId: Value(item.seriesId),
        taskStatus: Value(item.taskStatus?.storage),
        carryOver: Value(item.carryOver),
        kind: Value(_kindStorage(item.kind)),
        endDate: Value(
          item.endDate == null
              ? null
              : _startOfDay(item.endDate!).millisecondsSinceEpoch,
        ),
        purpose: Value(item.purpose),
        status: Value(item.status?.storage),
        categories: Value(_encodeCategories(item.categories)),
        reminderEnabled: Value(item.reminderEnabled),
        reminderTimeMinutes: Value(item.reminderTimeMinutes),
        experimentId: Value(item.experimentId),
      ),
    );
  }

  /// Full insert companion for any planner item (task or experiment).
  db.PlannerItemsCompanion _companionFor(
    PlannerItem item, {
    required DateTime createdAt,
  }) => db.PlannerItemsCompanion.insert(
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
    tags: Value(_encode(item.tags)),
    recurrence: Value(_encodeRecurrence(item.recurrence)),
    seriesId: Value(item.seriesId),
    taskStatus: Value(item.taskStatus?.storage),
    carryOver: Value(item.carryOver),
    kind: Value(_kindStorage(item.kind)),
    endDate: Value(
      item.endDate == null
          ? null
          : _startOfDay(item.endDate!).millisecondsSinceEpoch,
    ),
    purpose: Value(item.purpose),
    status: Value(item.status?.storage),
    categories: Value(_encodeCategories(item.categories)),
    reminderEnabled: Value(item.reminderEnabled),
    reminderTimeMinutes: Value(item.reminderTimeMinutes),
    experimentId: Value(item.experimentId),
    createdAt: createdAt.millisecondsSinceEpoch,
  );

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.plannerItems,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Re-inserts a previously deleted [item] with its original id — the undo
  /// path for delete. Shares the create path so both stay consistent.
  Future<void> restore(PlannerItem item) => insert(item);

  Future<void> updateSortOrder(String id, int sortOrder) async {
    await (_database.update(_database.plannerItems)
          ..where((t) => t.id.equals(id)))
        .write(db.PlannerItemsCompanion(sortOrder: Value(sortOrder)));
  }

  Future<int> copyFromPreviousDay(DateTime day) async {
    final targetDay = _startOfDay(day);
    final previousDay = _startOfDay(
      targetDay.subtract(const Duration(days: 1)),
    );
    final pendingRows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) =>
                    t.date.equals(previousDay.millisecondsSinceEpoch) &
                    t.done.equals(0) &
                    // Cancelled tasks were explicitly dropped; don't revive.
                    (t.taskStatus.isNull() |
                        t.taskStatus.isNotIn([TaskStatus.cancelled.storage])) &
                    // Only plain tasks are copied; experiments are ranges,
                    // not repeatable day entries.
                    t.kind.equals(_kindStorage(PlannerItemKind.task)),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    if (pendingRows.isEmpty) return 0;

    final now = DateTime.now();
    await _database.transaction(() async {
      for (final row in pendingRows) {
        await _database
            .into(_database.plannerItems)
            .insert(
              db.PlannerItemsCompanion.insert(
                id: const Uuid().v7(),
                date: targetDay.millisecondsSinceEpoch,
                title: row.title,
                done: 0,
                sortOrder: row.sortOrder,
                dueDate: Value(row.dueDate),
                startTimeMinutes: Value(row.startTimeMinutes),
                endTimeMinutes: Value(row.endTimeMinutes),
                notes: Value(row.notes),
                workoutId: Value(row.workoutId),
                tags: Value(row.tags),
                recurrence: Value(row.recurrence),
                seriesId: Value(row.seriesId),
                createdAt: now.millisecondsSinceEpoch,
              ),
            );
      }
    });
    return pendingRows.length;
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
        await (_database.select(_database.plannerItems)..where(
              (t) =>
                  t.kind.equals(_kindStorage(PlannerItemKind.task)) &
                  t.seriesId.isNull() &
                  t.date.isSmallerThanValue(today.millisecondsSinceEpoch) &
                  t.done.equals(0) &
                  (t.taskStatus.isNull() |
                      t.taskStatus.equals(TaskStatus.pending.storage)),
            ))
            .get();
    for (final row in rows) {
      final item = _toDomain(row);
      await update(
        item.carryOver
            ? item.copyWith(day: today)
            : item.withTaskStatus(TaskStatus.cancelled),
      );
    }
    return rows.length;
  }

  PlannerItem _toDomain(db.PlannerItem row) => PlannerItem(
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
    tags: _decode(row.tags),
    recurrence: _decodeRecurrence(row.recurrence),
    seriesId: row.seriesId,
    taskStatus: row.taskStatus == null
        ? null
        : _taskStatusFromStorage(row.taskStatus!),
    carryOver: row.carryOver,
    kind: _kindFromStorage(row.kind),
    endDate: row.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
    purpose: row.purpose,
    status: row.status == null ? null : _statusFromStorage(row.status!),
    categories: _decodeCategories(row.categories),
    reminderEnabled: row.reminderEnabled,
    reminderTimeMinutes: row.reminderTimeMinutes,
    experimentId: row.experimentId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  /// All distinct tags across every planner task, sorted. Powers the
  /// autocomplete suggestions in the add/edit dialog.
  Future<List<String>> distinctTags() async {
    final rows = await (_database.select(_database.plannerItems)).get();
    final result = <String>{};
    for (final row in rows) {
      final tags = _decode(row.tags);
      if (tags != null) result.addAll(tags);
    }
    return (result.toList()..sort());
  }

  /// Recurring "anchor" tasks (those carrying a rule) whose series can still
  /// produce occurrences on or before [upTo]. Used to materialize occurrences.
  Future<List<PlannerItem>> getRecurringAnchors(DateTime upTo) async {
    final rows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) =>
                    t.recurrence.isNotNull() &
                    t.date.isSmallerOrEqualValue(
                      _startOfDay(upTo).millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([(t) => OrderingTerm(expression: t.date)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Ensures every occurrence of every series that falls on [day] exists as a
  /// concrete task row. Idempotent: existing occurrences are left untouched.
  Future<void> materializeForDay(DateTime day) async {
    final d = _startOfDay(day);
    final anchors = await getRecurringAnchors(d);
    await _materializeDay(anchors, d);
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

  Future<void> _materializeDay(List<PlannerItem> anchors, DateTime d) async {
    final dMillis = d.millisecondsSinceEpoch;
    for (final anchor in anchors) {
      final rule = anchor.recurrence;
      if (rule == null || anchor.seriesId == null) continue;
      // Respect explicitly deleted occurrences so they are not regenerated.
      if (rule.excludedDates?.contains(dMillis) ?? false) continue;
      if (!rule.isOccurrenceOn(anchor.day, d)) continue;
      final existing =
          await (_database.select(_database.plannerItems)..where(
                (t) =>
                    t.date.equals(dMillis) &
                    t.seriesId.equals(anchor.seriesId!),
              ))
              .get();
      if (existing.isNotEmpty) continue;
      await _database
          .into(_database.plannerItems)
          .insert(
            db.PlannerItemsCompanion.insert(
              id: const Uuid().v7(),
              date: dMillis,
              title: anchor.title,
              done: 0,
              sortOrder: anchor.sortOrder,
              dueDate: Value(anchor.dueDate == null ? null : dMillis),
              startTimeMinutes: Value(anchor.startTimeMinutes),
              endTimeMinutes: Value(anchor.endTimeMinutes),
              notes: Value(anchor.notes),
              workoutId: Value(anchor.workoutId),
              tags: Value(_encode(anchor.tags)),
              seriesId: Value(anchor.seriesId),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }
  }

  /// Loads a single planner item by id (used to read/update the anchor of a
  /// recurring series, whose id equals its `seriesId`).
  Future<PlannerItem?> getById(String id) async {
    final row = await (_database.select(
      _database.plannerItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// All occurrences (anchor + generated) of a recurring series.
  Future<List<PlannerItem>> getBySeriesId(String seriesId) async {
    final rows = await (_database.select(
      _database.plannerItems,
    )..where((t) => t.seriesId.equals(seriesId))).get();
    return rows.map(_toDomain).toList();
  }

  /// Deletes one generated occurrence of a series and records its day as an
  /// excluded date on the anchor, so the materializer won't recreate it.
  Future<void> deleteOccurrence({
    required String id,
    required String seriesId,
    required DateTime day,
  }) async {
    await (_database.delete(
      _database.plannerItems,
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
      _database.plannerItems,
    )..where((t) => t.seriesId.equals(seriesId))).go();
  }

  /// Deletes future (strictly after [from]) generated occurrences of a series,
  /// leaving the anchor and past occurrences intact. Used when an anchor's
  /// rule changes so stale future instances are dropped before re-materializing.
  Future<void> deleteFutureOccurrences(String seriesId, DateTime from) async {
    await (_database.delete(_database.plannerItems)..where(
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
    List<String>? tags,
  }) async {
    final fromStart = _startOfDay(from).millisecondsSinceEpoch;
    await (_database.update(_database.plannerItems)..where(
          (t) =>
              t.seriesId.equals(seriesId) &
              t.id.isNotValue(seriesId) &
              t.date.isBiggerOrEqualValue(fromStart),
        ))
        .write(
          db.PlannerItemsCompanion(
            title: Value(title),
            startTimeMinutes: Value(startTimeMinutes),
            endTimeMinutes: Value(endTimeMinutes),
            notes: Value(notes),
            workoutId: Value(workoutId),
            tags: Value(_encode(tags)),
          ),
        );
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
      await (_database.delete(_database.plannerItems)..where(
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

  // ---------------------------------------------------------------------------
  // Experiments (planner items with kind='experiment').
  //
  // Since v24 an experiment IS a planner item: day = start date, endDate =
  // required end date, plus purpose/status/categories/reminder columns.
  // Check-ins live in experiment_checkins keyed by the item's id.
  // ---------------------------------------------------------------------------

  /// All experiments ordered by start date, newest first.
  Future<List<Experiment>> getExperiments() async {
    final rows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) => t.kind.equals(_kindStorage(PlannerItemKind.experiment)),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ]))
            .get();
    return rows.map(_toExperiment).toList();
  }

  Future<Experiment?> getExperimentById(String id) async {
    final row = await (_database.select(
      _database.plannerItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null ||
        _kindFromStorage(row.kind) != PlannerItemKind.experiment) {
      return null;
    }
    return _toExperiment(row);
  }

  /// Inserts a new experiment row or refreshes it in place (server of truth is
  /// local here; ids are stable).
  Future<void> upsertExperiment(Experiment experiment) async {
    final existing = await getById(experiment.id);
    final companion = db.PlannerItemsCompanion.insert(
      id: experiment.id,
      date: _startOfDay(experiment.startDate).millisecondsSinceEpoch,
      title: experiment.name,
      done: experiment.status == ExperimentStatus.done ? 1 : 0,
      sortOrder: 0,
      kind: const Value('experiment'),
      endDate: Value(
        experiment.endDate == null
            ? null
            : _startOfDay(experiment.endDate!).millisecondsSinceEpoch,
      ),
      purpose: Value(experiment.purpose),
      status: Value(experiment.status.storage),
      categories: Value(_encodeCategories(experiment.categories)),
      reminderEnabled: Value(experiment.reminderEnabled),
      reminderTimeMinutes: Value(experiment.reminderTimeMinutes),
      createdAt: experiment.createdAt.millisecondsSinceEpoch,
    );
    if (existing == null) {
      await _database.into(_database.plannerItems).insert(companion);
    } else {
      await (_database.update(
        _database.plannerItems,
      )..where((t) => t.id.equals(experiment.id))).write(companion);
    }
  }

  /// Deletes an experiment plus its check-ins in one transaction and detaches
  /// any child tasks linked via [PlannerItem.experimentId].
  Future<void> deleteExperiment(String id) async {
    await _database.transaction(() async {
      await (_database.update(_database.plannerItems)
            ..where((t) => t.experimentId.equals(id)))
          .write(db.PlannerItemsCompanion(experimentId: const Value(null)));
      await (_database.delete(
        _database.experimentCheckins,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.plannerItems,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  /// Tasks linked to an experiment ([PlannerItem.experimentId] == [id]),
  /// ordered by day then sort order.
  Future<List<PlannerItem>> getLinkedTasks(String id) async {
    final rows =
        await (_database.select(_database.plannerItems)
              ..where((t) => t.experimentId.equals(id))
              ..orderBy([
                (t) => OrderingTerm(expression: t.date),
                (t) => OrderingTerm(expression: t.sortOrder),
              ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Links [taskId] to an experiment, or unlinks it when [experimentId] is
  /// null.
  Future<void> setTaskExperiment(String taskId, String? experimentId) async {
    await (_database.update(_database.plannerItems)
          ..where((t) => t.id.equals(taskId)))
        .write(db.PlannerItemsCompanion(experimentId: Value(experimentId)));
  }

  /// Plain tasks whose title contains [query] (case-insensitive), newest
  /// first. Powers the link-a-task picker on the experiment detail screen.
  Future<List<PlannerItem>> searchTasks(String query, {int limit = 50}) async {
    final pattern = '%${query.trim()}%';
    final rows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) =>
                    t.kind.equals(_kindStorage(PlannerItemKind.task)) &
                    t.title.like(pattern),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// All planner items (any kind) with `date` within [start, end]
  /// (start-of-day bounds, inclusive). Powers calendar month markers.
  Future<List<PlannerItem>> getByRange(DateTime start, DateTime end) async {
    final fromMs = _startOfDay(start).millisecondsSinceEpoch;
    final toMs = _startOfDay(end).millisecondsSinceEpoch;
    final rows =
        await (_database.select(_database.plannerItems)..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(fromMs) &
                  t.date.isSmallerOrEqualValue(toMs),
            ))
            .get();
    return rows.map(_toDomain).toList();
  }

  /// Replaces the check-in for ([experimentId], [day]); the unique key on
  /// (experiment_id, day) guarantees one per day.
  Future<void> upsertCheckin({
    required String experimentId,
    required DateTime day,
    required int rating,
    String? note,
  }) async {
    final startOfDay = _startOfDay(day);
    final existing =
        await (_database.select(_database.experimentCheckins)..where(
              (t) =>
                  t.experimentId.equals(experimentId) &
                  t.day.equals(startOfDay.millisecondsSinceEpoch),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.experimentCheckins)
          .insert(
            db.ExperimentCheckinsCompanion.insert(
              id: const Uuid().v7(),
              experimentId: experimentId,
              day: startOfDay.millisecondsSinceEpoch,
              rating: rating,
              note: Value(note),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      return;
    }

    await (_database.update(
      _database.experimentCheckins,
    )..where((t) => t.id.equals(existing.id))).write(
      db.ExperimentCheckinsCompanion(
        rating: Value(rating),
        note: note == null ? const Value(null) : Value(note),
      ),
    );
  }

  Future<List<ExperimentCheckin>> getCheckins(String experimentId) async {
    final rows =
        await (_database.select(_database.experimentCheckins)
              ..where((t) => t.experimentId.equals(experimentId))
              ..orderBy([(t) => OrderingTerm(expression: t.day)]))
            .get();
    return rows.map(_toCheckin).toList();
  }

  Experiment _toExperiment(db.PlannerItem row) => Experiment(
    id: row.id,
    name: row.title,
    purpose: row.purpose,
    startDate: DateTime.fromMillisecondsSinceEpoch(row.date),
    endDate: row.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
    status: row.status == null
        ? ExperimentStatus.planned
        : _statusFromStorage(row.status!),
    categories: _decodeCategories(row.categories),
    reminderEnabled: row.reminderEnabled,
    reminderTimeMinutes: row.reminderTimeMinutes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  ExperimentCheckin _toCheckin(db.ExperimentCheckin row) => ExperimentCheckin(
    id: row.id,
    experimentId: row.experimentId,
    day: DateTime.fromMillisecondsSinceEpoch(row.day),
    rating: row.rating,
    note: row.note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static String _kindStorage(PlannerItemKind kind) => switch (kind) {
    PlannerItemKind.task => 'task',
    PlannerItemKind.experiment => 'experiment',
  };

  static PlannerItemKind _kindFromStorage(String value) =>
      value == 'experiment' ? PlannerItemKind.experiment : PlannerItemKind.task;

  static TaskStatus _taskStatusFromStorage(int value) =>
      TaskStatus.values[value.clamp(0, TaskStatus.values.length - 1)];

  static ExperimentStatus _statusFromStorage(String value) => switch (value) {
    'active' => ExperimentStatus.active,
    'done' => ExperimentStatus.done,
    'aborted' => ExperimentStatus.aborted,
    _ => ExperimentStatus.planned,
  };

  static String? _encodeCategories(List<ExperimentCategory>? values) {
    if (values == null || values.isEmpty) return null;
    return jsonEncode(values.map((c) => c.storage).toList());
  }

  static List<ExperimentCategory> _decodeCategories(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => _categoryFromStorage(e as String)).toList();
    } on Object {
      return const [];
    }
  }

  static ExperimentCategory _categoryFromStorage(String value) =>
      switch (value) {
        'diet' => ExperimentCategory.diet,
        'body' => ExperimentCategory.body,
        'steps' => ExperimentCategory.steps,
        _ => ExperimentCategory.workout,
      };

  /// Normalizes any [DateTime] to the start of its day so every day is a
  /// stable query key, matching how `date` is stored.
  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  static String? _encode(List<String>? values) {
    if (values == null || values.isEmpty) return null;
    return jsonEncode(values);
  }

  static List<String>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return null;
  }

  static String? _encodeRecurrence(PlannerRecurrence? recurrence) {
    if (recurrence == null) return null;
    return jsonEncode(recurrence.toJson());
  }

  static PlannerRecurrence? _decodeRecurrence(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return PlannerRecurrence.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Creates a new [PlannerItem] with a fresh UUID v7, the current timestamp,
/// and its `day` normalized to start-of-day.
PlannerItem newPlannerItem({
  required DateTime day,
  required String title,
  int sortOrder = 0,
  DateTime? dueDate,
  int? startTimeMinutes,
  int? endTimeMinutes,
  String? notes,
  String? workoutId,
  List<String>? tags,
  PlannerRecurrence? recurrence,
  String? seriesId,
  bool carryOver = true,
}) => PlannerItem(
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
  tags: tags,
  recurrence: recurrence,
  seriesId: seriesId,
  createdAt: DateTime.now(),
);
