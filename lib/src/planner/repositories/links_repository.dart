import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../../models/task.dart';
import '../../tags/repositories/tag_repository.dart';
import 'task_repository.dart' show taskFromRow;

/// One end of a link: the linked entity plus the optional relationship label.
typedef LabeledTask = ({Task item, String? label});

/// Data access for the v27 link (junction) tables: typed many-to-many
/// associations between tasks, goals, notes and workouts.
///
/// Only task ↔ goal links are used by the app so far; the other junction tables
/// stay in the schema, where backups and entity deletes still handle them.
/// Link/unlink are idempotent; links are keyed by their pair, so re-linking
/// with a new label updates it in place. The queries are written out per table on
/// purpose: Drift's generated table classes share no common typed interface
/// for "the column pointing at X", so explicit code keeps everything checked.
final class LinksRepository {
  final db.AppDatabase _database;
  const LinksRepository(this._database);

  // ---------------------------------------------------------------------------
  // task ↔ goal
  // ---------------------------------------------------------------------------

  Future<List<LabeledTask>> tasksForGoal(String goalId) async {
    final query =
        _database.select(_database.taskGoals).join([
            innerJoin(
              _database.tasks,
              _database.tasks.id.equalsExp(_database.taskGoals.taskId),
            ),
          ])
          ..where(
            _database.taskGoals.goalId.equals(goalId) &
                _database.tasks.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(_database.tasks.date),
            OrderingTerm.asc(_database.tasks.sortOrder),
          ]);
    final rows = await query.get();
    final items = await _attachTasks(
      rows.map((r) => taskFromRow(r.readTable(_database.tasks))).toList(),
    );
    return [
      for (var i = 0; i < items.length; i++)
        (item: items[i], label: rows[i].readTable(_database.taskGoals).label),
    ];
  }

  Future<void> linkTaskGoal(String taskId, String goalId, {String? label}) {
    return _database
        .into(_database.taskGoals)
        .insert(
          db.TaskGoalsCompanion.insert(
            taskId: taskId,
            goalId: goalId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.TaskGoalsCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkTaskGoal(String taskId, String goalId) {
    return (_database.delete(
      _database.taskGoals,
    )..where((t) => t.taskId.equals(taskId) & t.goalId.equals(goalId))).go();
  }

  // ---------------------------------------------------------------------------
  // Cascade detach helper — called from entity delete flows so no dangling
  // link rows survive their target.
  // ---------------------------------------------------------------------------

  /// Removes every link row referencing [taskId].
  Future<void> detachTask(String taskId) async {
    await (_database.delete(
      _database.taskGoals,
    )..where((t) => t.taskId.equals(taskId))).go();
    await (_database.delete(
      _database.taskNotes,
    )..where((t) => t.taskId.equals(taskId))).go();
  }

  // ---------------------------------------------------------------------------
  // Row mappers (kept local so joined rows map identically everywhere).
  // ---------------------------------------------------------------------------

  /// Populates [Task.tags] for a batch of tasks in a single lookup.
  Future<List<Task>> _attachTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return tasks;
    final map = await TagRepository(
      _database,
    ).tagNamesForTasks(tasks.map((t) => t.id).toList());
    return [for (final t in tasks) t.copyWith(tags: map[t.id] ?? const [])];
  }
}
