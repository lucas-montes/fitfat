import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/exercise.dart';

final class ExerciseRepository {
  final db.AppDatabase _database;
  const ExerciseRepository(this._database);

  Future<List<Exercise>> getAll() async {
    final rows =
        await (_database.select(_database.exercises)..orderBy([
              (t) => OrderingTerm(expression: t.name, mode: OrderingMode.asc),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<Exercise?> getById(String id) async {
    final row = await (_database.select(
      _database.exercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  Future<void> insert(Exercise exercise) async {
    await _database
        .into(_database.exercises)
        .insert(
          db.ExercisesCompanion.insert(
            id: exercise.id,
            name: exercise.name,
            exerciseType: exercise.exerciseType,
            createdAt: exercise.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(Exercise exercise) async {
    await (_database.update(
      _database.exercises,
    )..where((t) => t.id.equals(exercise.id))).write(
      db.ExercisesCompanion(
        name: Value(exercise.name),
        exerciseType: Value(exercise.exerciseType),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.exercises,
    )..where((t) => t.id.equals(id))).go();
  }

  Exercise _toDomain(db.Exercise row) => Exercise(
    id: row.id,
    name: row.name,
    exerciseType: row.exerciseType,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );
}

/// Creates a new [Exercise] with a fresh UUID v7 and the current timestamp.
Exercise newExercise({required String name, required String exerciseType}) =>
    Exercise(
      id: const Uuid().v7(),
      name: name,
      exerciseType: exerciseType,
      createdAt: DateTime.now(),
    );
