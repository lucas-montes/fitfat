import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/goal.dart';
import '../../tags/repositories/tag_repository.dart';

final class GoalRepository {
  final db.AppDatabase _database;
  const GoalRepository(this._database);

  /// All goals, most recently started first.
  Future<List<Goal>> getGoals() async {
    final rows =
        await (_database.select(_database.goals)..orderBy([
              (t) => OrderingTerm(
                expression: t.startDate,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  Future<Goal?> getGoalById(String id) async {
    final row = await (_database.select(
      _database.goals,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([_toDomain(row)])).first;
  }

  Future<void> upsertGoal(Goal goal) async {
    final companion = db.GoalsCompanion.insert(
      id: goal.id,
      title: goal.title,
      description: Value(goal.description),
      startDate: _startOfDay(goal.startDate).millisecondsSinceEpoch,
      endDate: Value(
        goal.endDate == null
            ? null
            : _startOfDay(goal.endDate!).millisecondsSinceEpoch,
      ),
      status: Value(goal.status.storage),
      targetType: Value(goal.targetType.storage),
      targetValue: Value(goal.targetValue),
      baselineValue: Value(goal.baselineValue),
      unit: Value(goal.unit),
      reminderEnabled: Value(goal.reminderEnabled),
      reminderTimeMinutes: Value(goal.reminderTimeMinutes),
      createdAt: goal.createdAt.millisecondsSinceEpoch,
      updatedAt: goal.updatedAt.millisecondsSinceEpoch,
    );
    final existing = await (_database.select(
      _database.goals,
    )..where((t) => t.id.equals(goal.id))).getSingleOrNull();
    if (existing == null) {
      await _database.into(_database.goals).insert(companion);
    } else {
      await (_database.update(
        _database.goals,
      )..where((t) => t.id.equals(goal.id))).write(companion);
    }
    if (goal.tags != null) {
      await TagRepository(_database).setGoalTags(goal.id, goal.tags!);
    }
  }

  Future<void> setGoalStatus(String id, GoalStatus status) async {
    await (_database.update(
      _database.goals,
    )..where((t) => t.id.equals(id))).write(
      db.GoalsCompanion(
        status: Value(status.storage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Deletes a goal plus its progress entries and link-table rows.
  /// When [cascadeTasks] is true, also deletes tasks linked via `task_goals`.
  Future<void> deleteGoal(String id, {bool cascadeTasks = false}) async {
    await _database.transaction(() async {
      if (cascadeTasks) {
        final links = await (_database.select(
          _database.taskGoals,
        )..where((t) => t.goalId.equals(id))).get();
        for (final link in links) {
          final taskId = link.taskId;
          await (_database.delete(
            _database.taskTags,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.taskExperiments,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.taskNotes,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.tasks,
          )..where((t) => t.id.equals(taskId))).go();
        }
      }
      await (_database.delete(
        _database.goalProgressEntries,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.taskGoals,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.experimentGoals,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.goalTags,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.goalNotes,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.goalWorkouts,
      )..where((t) => t.goalId.equals(id))).go();
      await (_database.delete(
        _database.goals,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  /// Progress log for a goal, newest day first.
  Future<List<GoalProgress>> getProgressLog(String goalId) async {
    final rows =
        await (_database.select(_database.goalProgressEntries)
              ..where((t) => t.goalId.equals(goalId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.recordedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map(_toProgress).toList();
  }

  /// Most recent recorded value for a goal, or null when nothing recorded.
  Future<double?> getLatestProgressValue(String goalId) async {
    final row =
        await (_database.select(_database.goalProgressEntries)
              ..where((t) => t.goalId.equals(goalId))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.recordedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.value;
  }

  /// Records a progress measurement; re-recording on the same day overwrites
  /// (unique per goal per day, same convention as experiment check-ins).
  Future<void> recordProgress({
    required String goalId,
    required DateTime day,
    required double value,
    String? note,
  }) async {
    final dayKey = _startOfDay(day).millisecondsSinceEpoch;
    final existing =
        await (_database.select(_database.goalProgressEntries)..where(
              (t) => t.goalId.equals(goalId) & t.recordedAt.equals(dayKey),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await _database
          .into(_database.goalProgressEntries)
          .insert(
            db.GoalProgressEntriesCompanion.insert(
              id: const Uuid().v7(),
              goalId: goalId,
              recordedAt: dayKey,
              value: value,
              note: Value(note),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } else {
      await (_database.update(
        _database.goalProgressEntries,
      )..where((t) => t.id.equals(existing.id))).write(
        db.GoalProgressEntriesCompanion(value: Value(value), note: Value(note)),
      );
    }
  }

  Future<void> deleteProgress(String id) async {
    await (_database.delete(
      _database.goalProgressEntries,
    )..where((t) => t.id.equals(id))).go();
  }

  Goal _toDomain(db.Goal row) => Goal(
    id: row.id,
    title: row.title,
    description: row.description,
    tags: null,
    startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
    endDate: row.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
    status: GoalStatusStorage.parse(row.status),
    targetType: GoalTargetTypeStorage.parse(row.targetType),
    targetValue: row.targetValue,
    baselineValue: row.baselineValue,
    unit: row.unit,
    reminderEnabled: row.reminderEnabled,
    reminderTimeMinutes: row.reminderTimeMinutes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  GoalProgress _toProgress(db.GoalProgressEntry row) => GoalProgress(
    id: row.id,
    goalId: row.goalId,
    day: DateTime.fromMillisecondsSinceEpoch(row.recordedAt),
    value: row.value,
    note: row.note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tag (priority) access for this goal table.
  TagRepository get _tags => TagRepository(_database);

  /// Populates [Goal.tags] for a batch of goals in one lookup.
  Future<List<Goal>> _attachTags(List<Goal> items) async {
    if (items.isEmpty) return items;
    final map = await _tags.tagNamesForGoals(items.map((g) => g.id).toList());
    return [for (final g in items) g.copyWith(tags: map[g.id] ?? const [])];
  }
}
