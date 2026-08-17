import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/planner_item.dart';
import '../../models/planner_recurrence.dart';

final class PlannerRepository {
  final db.AppDatabase _database;
  const PlannerRepository(this._database);

  Future<List<PlannerItem>> getByDay(DateTime day) async {
    final startOfDay = _startOfDay(day);
    final rows =
        await (_database.select(_database.plannerItems)
              ..where((t) => t.date.equals(startOfDay.millisecondsSinceEpoch))
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
        .insert(
          db.PlannerItemsCompanion.insert(
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
            createdAt: item.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(PlannerItem item) async {
    await (_database.update(
      _database.plannerItems,
    )..where((t) => t.id.equals(item.id))).write(
      db.PlannerItemsCompanion(
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
      ),
    );
  }

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
                    t.done.equals(0),
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
              dueDate: Value(
                anchor.dueDate == null ? null : dMillis,
              ),
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
    final row = await (_database.select(_database.plannerItems)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// All occurrences (anchor + generated) of a recurring series.
  Future<List<PlannerItem>> getBySeriesId(String seriesId) async {
    final rows = await (_database.select(_database.plannerItems)
          ..where((t) => t.seriesId.equals(seriesId)))
        .get();
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

  Future<void> _setExclusion(String seriesId, DateTime day, {required bool add}) async {
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
}) => PlannerItem(
  id: const Uuid().v7(),
  day: DateTime(day.year, day.month, day.day),
  title: title,
  done: false,
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
