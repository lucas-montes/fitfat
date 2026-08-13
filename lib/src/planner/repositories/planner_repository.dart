import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/planner_item.dart';

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

  /// Pending tasks with a due time, due on or after [from] (inclusive),
  /// ordered by due date then due time. Used by the dashboard's upcoming
  /// timed-tasks card.
  Future<List<PlannerItem>> getUpcomingWithDueTime(DateTime from) async {
    final fromStart = _startOfDay(from);
    final rows =
        await (_database.select(_database.plannerItems)
              ..where(
                (t) =>
                    t.done.equals(0) &
                    t.dueTimeMinutes.isNotNull() &
                    t.dueDate.isNotNull() &
                    t.dueDate.isBiggerOrEqualValue(
                      fromStart.millisecondsSinceEpoch,
                    ),
              )
              ..orderBy([
                (t) => OrderingTerm(expression: t.dueDate),
                (t) => OrderingTerm(expression: t.dueTimeMinutes),
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
            dueTimeMinutes: Value(item.dueTimeMinutes),
            notes: Value(item.notes),
            workoutId: Value(item.workoutId),
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
        dueTimeMinutes: Value(item.dueTimeMinutes),
        notes: Value(item.notes),
        workoutId: Value(item.workoutId),
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
                dueTimeMinutes: Value(row.dueTimeMinutes),
                notes: Value(row.notes),
                workoutId: Value(row.workoutId),
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
    dueTimeMinutes: row.dueTimeMinutes,
    notes: row.notes,
    workoutId: row.workoutId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  /// Normalizes any [DateTime] to the start of its day so every day is a
  /// stable query key, matching how `date` is stored.
  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);
}

/// Creates a new [PlannerItem] with a fresh UUID v7, the current timestamp,
/// and its `day` normalized to start-of-day.
PlannerItem newPlannerItem({
  required DateTime day,
  required String title,
  int sortOrder = 0,
  DateTime? dueDate,
  int? dueTimeMinutes,
  String? notes,
  String? workoutId,
}) => PlannerItem(
  id: const Uuid().v7(),
  day: DateTime(day.year, day.month, day.day),
  title: title,
  done: false,
  sortOrder: sortOrder,
  dueDate: dueDate,
  dueTimeMinutes: dueTimeMinutes,
  notes: notes,
  workoutId: workoutId,
  createdAt: DateTime.now(),
);
