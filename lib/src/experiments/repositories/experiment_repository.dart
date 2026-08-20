import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/experiment.dart';

final class ExperimentRepository {
  final db.AppDatabase _database;
  const ExperimentRepository(this._database);

  /// All experiments ordered by start date, newest first.
  Future<List<Experiment>> getAll() async {
    final rows =
        await (_database.select(_database.experiments)..orderBy([
              (t) => OrderingTerm(
                expression: t.startDate,
                mode: OrderingMode.desc,
              ),
            ]))
            .get();
    return rows.map(_toExperiment).toList();
  }

  Future<Experiment?> getById(String id) async {
    final row = await (_database.select(
      _database.experiments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toExperiment(row);
  }

  Future<void> insert(Experiment experiment) async {
    await _database
        .into(_database.experiments)
        .insert(_companionFor(experiment));
  }

  Future<void> update(Experiment experiment) async {
    await (_database.update(_database.experiments)
          ..where((t) => t.id.equals(experiment.id)))
        .write(_companionFor(experiment));
  }

  /// Deletes the experiment and its check-ins in a single transaction.
  Future<void> delete(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.experimentCheckins,
      )..where((t) => t.experimentId.equals(id))).go();
      await (_database.delete(
        _database.experiments,
      )..where((t) => t.id.equals(id))).go();
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

  db.ExperimentsCompanion _companionFor(Experiment experiment) =>
      db.ExperimentsCompanion(
        id: Value(experiment.id),
        name: Value(experiment.name),
        purpose: Value(experiment.purpose),
        startDate: Value(
          _startOfDay(experiment.startDate).millisecondsSinceEpoch,
        ),
        endDate: Value(experiment.endDate?.millisecondsSinceEpoch),
        status: Value(experiment.status.storage),
        categories: Value(
          jsonEncode(experiment.categories.map((c) => c.storage).toList()),
        ),
        reminderEnabled: Value(experiment.reminderEnabled),
        reminderTimeMinutes: Value(experiment.reminderTimeMinutes),
        createdAt: Value(experiment.createdAt.millisecondsSinceEpoch),
      );

  Experiment _toExperiment(db.Experiment row) => Experiment(
    id: row.id,
    name: row.name,
    purpose: row.purpose,
    startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
    endDate: row.endDate == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endDate!),
    status: _statusFromStorage(row.status),
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

  List<ExperimentCategory> _decodeCategories(String encoded) {
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list.map((e) => _categoryFromStorage(e as String)).toList();
    } on Object {
      return const [];
    }
  }

  DateTime _startOfDay(DateTime day) => DateTime(day.year, day.month, day.day);
}

ExperimentStatus _statusFromStorage(String value) => switch (value) {
  'active' => ExperimentStatus.active,
  'done' => ExperimentStatus.done,
  'aborted' => ExperimentStatus.aborted,
  _ => ExperimentStatus.planned,
};

ExperimentCategory _categoryFromStorage(String value) => switch (value) {
  'diet' => ExperimentCategory.diet,
  'body' => ExperimentCategory.body,
  'steps' => ExperimentCategory.steps,
  _ => ExperimentCategory.workout,
};

extension on ExperimentStatus {
  String get storage => switch (this) {
    ExperimentStatus.planned => 'planned',
    ExperimentStatus.active => 'active',
    ExperimentStatus.done => 'done',
    ExperimentStatus.aborted => 'aborted',
  };
}

extension on ExperimentCategory {
  String get storage => switch (this) {
    ExperimentCategory.workout => 'workout',
    ExperimentCategory.diet => 'diet',
    ExperimentCategory.body => 'body',
    ExperimentCategory.steps => 'steps',
  };
}
