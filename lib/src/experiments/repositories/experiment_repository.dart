import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/experiment.dart';
import '../../tags/repositories/tag_repository.dart';

/// Data access for experiments (schema v27: the standalone `experiments`
/// table, un-merged from planner items). Check-ins live here too.
final class ExperimentRepository {
  final db.AppDatabase _database;
  const ExperimentRepository(this._database);

  /// All alive experiments ordered by start date, newest first.
  Future<List<Experiment>> getAll() async {
    final rows =
        await (_database.select(_database.experiments)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startDate,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  Future<Experiment?> getById(String id) async {
    final row = await (_database.select(
      _database.experiments,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return null;
    return (await _attachTags([_toDomain(row)])).first;
  }

  /// Experiments whose [startDate .. endDate] span intersects the inclusive
  /// day range [start, end] (open-ended spans extend infinitely forward).
  /// Combined with the matching task query this powers the timeline union.
  Future<List<Experiment>> getByRange(DateTime start, DateTime end) async {
    final fromMs = _startOfDay(start).millisecondsSinceEpoch;
    final toMs = _startOfDay(end).millisecondsSinceEpoch;
    final rows =
        await (_database.select(_database.experiments)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.startDate.isSmallerOrEqualValue(toMs) &
                  // Open-ended experiments (end_date null) never end.
                  (t.endDate.isNull() | t.endDate.isBiggerOrEqualValue(fromMs)),
            ))
            .get();
    return _attachTags(rows.map(_toDomain).toList());
  }

  /// Experiments active on [day] (span contains it).
  Future<List<Experiment>> getByDay(DateTime day) => getByRange(day, day);

  /// Inserts a new experiment row or refreshes it in place (ids are stable).
  /// Upsert so re-writing an experiment whose tombstoned row still exists
  /// (the undo path of [delete]) revives it instead of tripping the primary
  /// key.
  Future<void> upsert(Experiment experiment) async {
    final companion = db.ExperimentsCompanion.insert(
      id: experiment.id,
      name: experiment.name,
      purpose: Value(experiment.purpose),
      startDate: _startOfDay(experiment.startDate).millisecondsSinceEpoch,
      endDate: Value(
        experiment.endDate == null
            ? null
            : _startOfDay(experiment.endDate!).millisecondsSinceEpoch,
      ),
      status: Value(experiment.status.storage),
      categories: Value(_encodeCategories(experiment.categories)),
      reminderEnabled: Value(experiment.reminderEnabled),
      reminderTimeMinutes: Value(experiment.reminderTimeMinutes),
      createdAt: experiment.createdAt.millisecondsSinceEpoch,
      deletedAt: const Value(null),
    );
    await _database
        .into(_database.experiments)
        .insert(companion, onConflict: DoUpdate((_) => companion));
    if (experiment.tags != null) {
      await TagRepository(
        _database,
      ).setExperimentTags(experiment.id, experiment.tags!);
    }
  }

  /// Tombstones an experiment, removing its check-ins and link-table rows
  /// physically. When [cascadeTasks] is true, also tombstones tasks linked
  /// via `task_experiments`.
  Future<void> delete(String id, {bool cascadeTasks = false}) async {
    await _database.transaction(() async {
      List<String> cascadeIds = const [];
      if (cascadeTasks) {
        final links = await (_database.select(
          _database.taskExperiments,
        )..where((t) => t.experimentId.equals(id))).get();
        cascadeIds = links.map((e) => e.taskId).toList();
        for (final taskId in cascadeIds) {
          final now = DateTime.now().millisecondsSinceEpoch;
          await (_database.update(
            _database.tasks,
          )..where((t) => t.id.equals(taskId))).write(
            db.TasksCompanion(deletedAt: Value(now)),
          );
          await (_database.delete(
            _database.taskExperiments,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.taskTags,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.taskGoals,
          )..where((t) => t.taskId.equals(taskId))).go();
          await (_database.delete(
            _database.taskNotes,
          )..where((t) => t.taskId.equals(taskId))).go();
        }
      }
      await (_database.delete(
        _database.experimentCheckins,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.taskExperiments,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.experimentGoals,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.experimentTags,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.experimentNotes,
      )..where((t) => t.experimentId.equals(id))).go();
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_database.update(
        _database.experiments,
      )..where((t) => t.id.equals(id))).write(
        db.ExperimentsCompanion(deletedAt: Value(now)),
      );
    });
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

  Experiment _toDomain(db.Experiment row) => experimentFromRow(row);

  ExperimentCheckin _toCheckin(db.ExperimentCheckin row) => ExperimentCheckin(
    id: row.id,
    experimentId: row.experimentId,
    day: DateTime.fromMillisecondsSinceEpoch(row.day),
    rating: row.rating,
    note: row.note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static String? _encodeCategories(List<ExperimentCategory>? values) {
    if (values == null || values.isEmpty) return null;
    return jsonEncode(values.map((c) => c.storage).toList());
  }

  /// Normalizes any [DateTime] to the start of its day so every day is a
  /// stable query key, matching how dates are stored.
  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);

  /// Tag (priority) access for this experiment table.
  TagRepository get _tags => TagRepository(_database);

  /// Populates [Experiment.tags] for a batch of experiments in one lookup.
  Future<List<Experiment>> _attachTags(List<Experiment> items) async {
    if (items.isEmpty) return items;
    final map = await _tags.tagNamesForExperiments(
      items.map((e) => e.id).toList(),
    );
    return [for (final e in items) e.copyWith(tags: map[e.id] ?? const [])];
  }
}

/// Maps a database experiment row to the domain model. Shared with
/// [LinksRepository] so joined link queries can map rows the same way.
Experiment experimentFromRow(db.Experiment row) => Experiment(
  id: row.id,
  name: row.name,
  purpose: row.purpose,
  startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
  endDate: row.endDate == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
  status: switch (row.status) {
    'active' => ExperimentStatus.active,
    'done' => ExperimentStatus.done,
    'aborted' => ExperimentStatus.aborted,
    _ => ExperimentStatus.planned,
  },
  categories: _decodeCategoriesTopLevel(row.categories),
  tags: null,
  reminderEnabled: row.reminderEnabled,
  reminderTimeMinutes: row.reminderTimeMinutes,
  createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
);

List<ExperimentCategory> _decodeCategoriesTopLevel(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      return switch (e as String) {
        'diet' => ExperimentCategory.diet,
        'body' => ExperimentCategory.body,
        'steps' => ExperimentCategory.steps,
        _ => ExperimentCategory.workout,
      };
    }).toList();
  } on Object {
    return const [];
  }
}
