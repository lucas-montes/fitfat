import 'dart:convert';

import 'package:drift/drift.dart';

import '../../database/app_database.dart' as db;
import '../../models/experiment.dart';
import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/task.dart';
import '../../models/workout.dart';
import '../../experiments/repositories/experiment_repository.dart'
    show experimentFromRow;
import 'task_repository.dart' show taskFromRow;

/// One end of a link: the linked entity plus the optional relationship label.
typedef LabeledTask = ({Task item, String? label});
typedef LabeledExperiment = ({Experiment item, String? label});
typedef LabeledGoal = ({Goal item, String? label});
typedef LabeledNote = ({Note item, String? label});
typedef LabeledWorkout = ({Workout item, String? label});

/// Data access for the v27 link (junction) tables: typed many-to-many
/// associations between tasks, experiments, goals, notes and workouts.
///
/// Every association has list helpers in both directions plus idempotent
/// link/unlink operations; links are keyed by their pair, so re-linking with
/// a new label updates it in place. The queries are written out per table on
/// purpose: Drift's generated table classes share no common typed interface
/// for "the column pointing at X", so explicit code keeps everything checked.
final class LinksRepository {
  final db.AppDatabase _database;
  const LinksRepository(this._database);

  // ---------------------------------------------------------------------------
  // task ↔ experiment
  // ---------------------------------------------------------------------------

  Future<List<LabeledTask>> tasksForExperiment(String experimentId) async {
    final query =
        _database.select(_database.taskExperiments).join([
            innerJoin(
              _database.tasks,
              _database.tasks.id.equalsExp(_database.taskExperiments.taskId),
            ),
          ])
          ..where(_database.taskExperiments.experimentId.equals(experimentId))
          ..orderBy([
            OrderingTerm.asc(_database.tasks.date),
            OrderingTerm.asc(_database.tasks.sortOrder),
          ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: taskFromRow(row.readTable(_database.tasks)),
          label: row.readTable(_database.taskExperiments).label,
        ),
    ];
  }

  Future<List<LabeledExperiment>> experimentsForTask(String taskId) async {
    final query =
        _database.select(_database.taskExperiments).join([
            innerJoin(
              _database.experiments,
              _database.experiments.id.equalsExp(
                _database.taskExperiments.experimentId,
              ),
            ),
          ])
          ..where(_database.taskExperiments.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(_database.experiments.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: experimentFromRow(row.readTable(_database.experiments)),
          label: row.readTable(_database.taskExperiments).label,
        ),
    ];
  }

  Future<void> linkTaskExperiment(
    String taskId,
    String experimentId, {
    String? label,
  }) {
    return _database
        .into(_database.taskExperiments)
        .insert(
          db.TaskExperimentsCompanion.insert(
            taskId: taskId,
            experimentId: experimentId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.TaskExperimentsCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkTaskExperiment(String taskId, String experimentId) {
    return (_database.delete(_database.taskExperiments)..where(
          (t) => t.taskId.equals(taskId) & t.experimentId.equals(experimentId),
        ))
        .go();
  }

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
          ..where(_database.taskGoals.goalId.equals(goalId))
          ..orderBy([
            OrderingTerm.asc(_database.tasks.date),
            OrderingTerm.asc(_database.tasks.sortOrder),
          ]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: taskFromRow(row.readTable(_database.tasks)),
          label: row.readTable(_database.taskGoals).label,
        ),
    ];
  }

  Future<List<LabeledGoal>> goalsForTask(String taskId) async {
    final query =
        _database.select(_database.taskGoals).join([
            innerJoin(
              _database.goals,
              _database.goals.id.equalsExp(_database.taskGoals.goalId),
            ),
          ])
          ..where(_database.taskGoals.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(_database.goals.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _goalFrom(row.readTable(_database.goals)),
          label: row.readTable(_database.taskGoals).label,
        ),
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
  // experiment ↔ goal
  // ---------------------------------------------------------------------------

  Future<List<LabeledExperiment>> experimentsForGoal(String goalId) async {
    final query =
        _database.select(_database.experimentGoals).join([
            innerJoin(
              _database.experiments,
              _database.experiments.id.equalsExp(
                _database.experimentGoals.experimentId,
              ),
            ),
          ])
          ..where(_database.experimentGoals.goalId.equals(goalId))
          ..orderBy([OrderingTerm.asc(_database.experiments.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: experimentFromRow(row.readTable(_database.experiments)),
          label: row.readTable(_database.experimentGoals).label,
        ),
    ];
  }

  Future<List<LabeledGoal>> goalsForExperiment(String experimentId) async {
    final query =
        _database.select(_database.experimentGoals).join([
            innerJoin(
              _database.goals,
              _database.goals.id.equalsExp(_database.experimentGoals.goalId),
            ),
          ])
          ..where(_database.experimentGoals.experimentId.equals(experimentId))
          ..orderBy([OrderingTerm.asc(_database.goals.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _goalFrom(row.readTable(_database.goals)),
          label: row.readTable(_database.experimentGoals).label,
        ),
    ];
  }

  Future<void> linkExperimentGoal(
    String experimentId,
    String goalId, {
    String? label,
  }) {
    return _database
        .into(_database.experimentGoals)
        .insert(
          db.ExperimentGoalsCompanion.insert(
            experimentId: experimentId,
            goalId: goalId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.ExperimentGoalsCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkExperimentGoal(String experimentId, String goalId) {
    return (_database.delete(_database.experimentGoals)..where(
          (t) => t.experimentId.equals(experimentId) & t.goalId.equals(goalId),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // task ↔ note
  // ---------------------------------------------------------------------------

  Future<List<LabeledNote>> notesForTask(String taskId) async {
    final query =
        _database.select(_database.taskNotes).join([
            innerJoin(
              _database.notes,
              _database.notes.id.equalsExp(_database.taskNotes.noteId),
            ),
          ])
          ..where(_database.taskNotes.taskId.equals(taskId))
          ..orderBy([OrderingTerm.desc(_database.notes.updatedAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _noteFrom(row.readTable(_database.notes)),
          label: row.readTable(_database.taskNotes).label,
        ),
    ];
  }

  Future<List<LabeledTask>> tasksForNote(String noteId) async {
    final query =
        _database.select(_database.taskNotes).join([
            innerJoin(
              _database.tasks,
              _database.tasks.id.equalsExp(_database.taskNotes.taskId),
            ),
          ])
          ..where(_database.taskNotes.noteId.equals(noteId))
          ..orderBy([OrderingTerm.desc(_database.tasks.date)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: taskFromRow(row.readTable(_database.tasks)),
          label: row.readTable(_database.taskNotes).label,
        ),
    ];
  }

  Future<void> linkTaskNote(String taskId, String noteId, {String? label}) {
    return _database
        .into(_database.taskNotes)
        .insert(
          db.TaskNotesCompanion.insert(
            taskId: taskId,
            noteId: noteId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.TaskNotesCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkTaskNote(String taskId, String noteId) {
    return (_database.delete(
      _database.taskNotes,
    )..where((t) => t.taskId.equals(taskId) & t.noteId.equals(noteId))).go();
  }

  // ---------------------------------------------------------------------------
  // experiment ↔ note
  // ---------------------------------------------------------------------------

  Future<List<LabeledNote>> notesForExperiment(String experimentId) async {
    final query =
        _database.select(_database.experimentNotes).join([
            innerJoin(
              _database.notes,
              _database.notes.id.equalsExp(_database.experimentNotes.noteId),
            ),
          ])
          ..where(_database.experimentNotes.experimentId.equals(experimentId))
          ..orderBy([OrderingTerm.desc(_database.notes.updatedAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _noteFrom(row.readTable(_database.notes)),
          label: row.readTable(_database.experimentNotes).label,
        ),
    ];
  }

  Future<List<LabeledExperiment>> experimentsForNote(String noteId) async {
    final query =
        _database.select(_database.experimentNotes).join([
            innerJoin(
              _database.experiments,
              _database.experiments.id.equalsExp(
                _database.experimentNotes.experimentId,
              ),
            ),
          ])
          ..where(_database.experimentNotes.noteId.equals(noteId))
          ..orderBy([OrderingTerm.asc(_database.experiments.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: experimentFromRow(row.readTable(_database.experiments)),
          label: row.readTable(_database.experimentNotes).label,
        ),
    ];
  }

  Future<void> linkExperimentNote(
    String experimentId,
    String noteId, {
    String? label,
  }) {
    return _database
        .into(_database.experimentNotes)
        .insert(
          db.ExperimentNotesCompanion.insert(
            experimentId: experimentId,
            noteId: noteId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.ExperimentNotesCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkExperimentNote(String experimentId, String noteId) {
    return (_database.delete(_database.experimentNotes)..where(
          (t) => t.experimentId.equals(experimentId) & t.noteId.equals(noteId),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // goal ↔ note
  // ---------------------------------------------------------------------------

  Future<List<LabeledNote>> notesForGoal(String goalId) async {
    final query =
        _database.select(_database.goalNotes).join([
            innerJoin(
              _database.notes,
              _database.notes.id.equalsExp(_database.goalNotes.noteId),
            ),
          ])
          ..where(_database.goalNotes.goalId.equals(goalId))
          ..orderBy([OrderingTerm.desc(_database.notes.updatedAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _noteFrom(row.readTable(_database.notes)),
          label: row.readTable(_database.goalNotes).label,
        ),
    ];
  }

  Future<List<LabeledGoal>> goalsForNote(String noteId) async {
    final query =
        _database.select(_database.goalNotes).join([
            innerJoin(
              _database.goals,
              _database.goals.id.equalsExp(_database.goalNotes.goalId),
            ),
          ])
          ..where(_database.goalNotes.noteId.equals(noteId))
          ..orderBy([OrderingTerm.asc(_database.goals.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _goalFrom(row.readTable(_database.goals)),
          label: row.readTable(_database.goalNotes).label,
        ),
    ];
  }

  Future<void> linkGoalNote(String goalId, String noteId, {String? label}) {
    return _database
        .into(_database.goalNotes)
        .insert(
          db.GoalNotesCompanion.insert(
            goalId: goalId,
            noteId: noteId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.GoalNotesCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkGoalNote(String goalId, String noteId) {
    return (_database.delete(
      _database.goalNotes,
    )..where((t) => t.goalId.equals(goalId) & t.noteId.equals(noteId))).go();
  }

  // ---------------------------------------------------------------------------
  // goal ↔ workout
  // ---------------------------------------------------------------------------

  Future<List<LabeledWorkout>> workoutsForGoal(String goalId) async {
    final query =
        _database.select(_database.goalWorkouts).join([
            innerJoin(
              _database.workouts,
              _database.workouts.id.equalsExp(_database.goalWorkouts.workoutId),
            ),
          ])
          ..where(_database.goalWorkouts.goalId.equals(goalId))
          ..orderBy([OrderingTerm.desc(_database.workouts.date)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _workoutFrom(row.readTable(_database.workouts)),
          label: row.readTable(_database.goalWorkouts).label,
        ),
    ];
  }

  Future<List<LabeledGoal>> goalsForWorkout(String workoutId) async {
    final query =
        _database.select(_database.goalWorkouts).join([
            innerJoin(
              _database.goals,
              _database.goals.id.equalsExp(_database.goalWorkouts.goalId),
            ),
          ])
          ..where(_database.goalWorkouts.workoutId.equals(workoutId))
          ..orderBy([OrderingTerm.asc(_database.goals.startDate)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _goalFrom(row.readTable(_database.goals)),
          label: row.readTable(_database.goalWorkouts).label,
        ),
    ];
  }

  Future<void> linkGoalWorkout(
    String goalId,
    String workoutId, {
    String? label,
  }) {
    return _database
        .into(_database.goalWorkouts)
        .insert(
          db.GoalWorkoutsCompanion.insert(
            goalId: goalId,
            workoutId: workoutId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.GoalWorkoutsCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkGoalWorkout(String goalId, String workoutId) {
    return (_database.delete(_database.goalWorkouts)..where(
          (t) => t.goalId.equals(goalId) & t.workoutId.equals(workoutId),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // note ↔ workout
  // ---------------------------------------------------------------------------

  Future<List<LabeledWorkout>> workoutsForNote(String noteId) async {
    final query =
        _database.select(_database.noteWorkouts).join([
            innerJoin(
              _database.workouts,
              _database.workouts.id.equalsExp(_database.noteWorkouts.workoutId),
            ),
          ])
          ..where(_database.noteWorkouts.noteId.equals(noteId))
          ..orderBy([OrderingTerm.desc(_database.workouts.date)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _workoutFrom(row.readTable(_database.workouts)),
          label: row.readTable(_database.noteWorkouts).label,
        ),
    ];
  }

  Future<List<LabeledNote>> notesForWorkout(String workoutId) async {
    final query =
        _database.select(_database.noteWorkouts).join([
            innerJoin(
              _database.notes,
              _database.notes.id.equalsExp(_database.noteWorkouts.noteId),
            ),
          ])
          ..where(_database.noteWorkouts.workoutId.equals(workoutId))
          ..orderBy([OrderingTerm.desc(_database.notes.updatedAt)]);
    final rows = await query.get();
    return [
      for (final row in rows)
        (
          item: _noteFrom(row.readTable(_database.notes)),
          label: row.readTable(_database.noteWorkouts).label,
        ),
    ];
  }

  Future<void> linkNoteWorkout(
    String noteId,
    String workoutId, {
    String? label,
  }) {
    return _database
        .into(_database.noteWorkouts)
        .insert(
          db.NoteWorkoutsCompanion.insert(
            noteId: noteId,
            workoutId: workoutId,
            label: Value(label),
          ),
          onConflict: DoUpdate(
            (_) => db.NoteWorkoutsCompanion(label: Value(label)),
          ),
        );
  }

  Future<void> unlinkNoteWorkout(String noteId, String workoutId) {
    return (_database.delete(_database.noteWorkouts)..where(
          (t) => t.noteId.equals(noteId) & t.workoutId.equals(workoutId),
        ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Cascade detach helpers — called from entity delete flows so no dangling
  // link rows survive their target.
  // ---------------------------------------------------------------------------

  /// Removes every link row referencing [taskId].
  Future<void> detachTask(String taskId) async {
    await (_database.delete(
      _database.taskExperiments,
    )..where((t) => t.taskId.equals(taskId))).go();
    await (_database.delete(
      _database.taskGoals,
    )..where((t) => t.taskId.equals(taskId))).go();
    await (_database.delete(
      _database.taskNotes,
    )..where((t) => t.taskId.equals(taskId))).go();
  }

  /// Removes every link row referencing [experimentId].
  Future<void> detachExperiment(String experimentId) async {
    await (_database.delete(
      _database.taskExperiments,
    )..where((t) => t.experimentId.equals(experimentId))).go();
    await (_database.delete(
      _database.experimentGoals,
    )..where((t) => t.experimentId.equals(experimentId))).go();
    await (_database.delete(
      _database.experimentNotes,
    )..where((t) => t.experimentId.equals(experimentId))).go();
  }

  /// Removes every link row referencing [goalId].
  Future<void> detachGoal(String goalId) async {
    await (_database.delete(
      _database.taskGoals,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_database.delete(
      _database.experimentGoals,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_database.delete(
      _database.goalNotes,
    )..where((t) => t.goalId.equals(goalId))).go();
    await (_database.delete(
      _database.goalWorkouts,
    )..where((t) => t.goalId.equals(goalId))).go();
  }

  /// Removes every link row referencing [noteId].
  Future<void> detachNote(String noteId) async {
    await (_database.delete(
      _database.taskNotes,
    )..where((t) => t.noteId.equals(noteId))).go();
    await (_database.delete(
      _database.experimentNotes,
    )..where((t) => t.noteId.equals(noteId))).go();
    await (_database.delete(
      _database.goalNotes,
    )..where((t) => t.noteId.equals(noteId))).go();
    await (_database.delete(
      _database.noteWorkouts,
    )..where((t) => t.noteId.equals(noteId))).go();
  }

  /// Removes every link row referencing [workoutId].
  Future<void> detachWorkout(String workoutId) async {
    await (_database.delete(
      _database.goalWorkouts,
    )..where((t) => t.workoutId.equals(workoutId))).go();
    await (_database.delete(
      _database.noteWorkouts,
    )..where((t) => t.workoutId.equals(workoutId))).go();
  }

  // ---------------------------------------------------------------------------
  // Row mappers (kept local so joined rows map identically everywhere).
  // ---------------------------------------------------------------------------

  Goal _goalFrom(db.Goal row) => Goal(
    id: row.id,
    title: row.title,
    description: row.description,
    tags: _decodeTags(row.tags),
    startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
    endDate: row.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
    status: GoalStatusStorage.parse(row.status),
    targetType: GoalTargetTypeStorage.parse(row.targetType),
    targetValue: row.targetValue,
    unit: row.unit,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  Note _noteFrom(db.Note row) => Note(
    id: row.id,
    title: row.title,
    body: row.body,
    tags: _decodeTags(row.tags),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  Workout _workoutFrom(db.Workout row) => Workout(
    id: row.id,
    name: row.name,
    date: DateTime.fromMillisecondsSinceEpoch(row.date),
    startedAt: row.startedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.startedAt!)
        : null,
    completedAt: row.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.completedAt!)
        : null,
    notes: row.notes,
    routineId: row.routineId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

List<String>? _decodeTags(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return null;
}
