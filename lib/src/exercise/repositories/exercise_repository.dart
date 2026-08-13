import 'dart:convert';

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
            isLocked: Value(exercise.isLocked),
            bodyPart: Value(exercise.bodyPart),
            equipment: Value(exercise.equipment),
            primaryMuscle: Value(exercise.primaryMuscle),
            secondaryMuscle: Value(exercise.secondaryMuscle),
            instructions: Value(_encode(exercise.instructions)),
            tips: Value(_encode(exercise.tips)),
            faqs: Value(exercise.faqs),
            keywords: Value(_encode(exercise.keywords)),
            imagePath: Value(exercise.imagePath),
            videoPath: Value(exercise.videoPath),
            similarTo: Value(exercise.similarTo),
            tags: Value(_encode(exercise.tags)),
            isCanonical: Value(exercise.isCanonical),
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

  /// Refreshes a catalog (locked) row in place with all of its metadata
  /// columns. Used by [CatalogImporter] to update already-imported locked rows
  /// when the bundled catalog changes; never called for user-created rows.
  Future<void> updateCatalog(Exercise exercise) async {
    await (_database.update(
      _database.exercises,
    )..where((t) => t.id.equals(exercise.id))).write(
      db.ExercisesCompanion(
        name: Value(exercise.name),
        exerciseType: Value(exercise.exerciseType),
        isLocked: Value(exercise.isLocked),
        bodyPart: Value(exercise.bodyPart),
        equipment: Value(exercise.equipment),
        primaryMuscle: Value(exercise.primaryMuscle),
        secondaryMuscle: Value(exercise.secondaryMuscle),
        instructions: Value(_encode(exercise.instructions)),
        tips: Value(_encode(exercise.tips)),
        faqs: Value(exercise.faqs),
        keywords: Value(_encode(exercise.keywords)),
        imagePath: Value(exercise.imagePath),
        videoPath: Value(exercise.videoPath),
        similarTo: Value(exercise.similarTo),
        tags: Value(_encode(exercise.tags)),
        isCanonical: Value(exercise.isCanonical),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_database.delete(
      _database.exercises,
    )..where((t) => t.id.equals(id))).go();
  }

  /// Number of `workout_exercises` rows referencing this exercise — used to
  /// block deletion of exercises that are still part of a workout.
  Future<int> usageCount(String id) async {
    final countColumn = _database.workoutExercises.id.count();
    final row =
        await (_database.selectOnly(_database.workoutExercises)
              ..addColumns([countColumn])
              ..where(_database.workoutExercises.exerciseId.equals(id)))
            .getSingle();
    return row.read(countColumn) ?? 0;
  }

  Exercise _toDomain(db.Exercise row) => Exercise(
    id: row.id,
    name: row.name,
    exerciseType: row.exerciseType,
    isLocked: row.isLocked,
    bodyPart: row.bodyPart,
    equipment: row.equipment,
    primaryMuscle: row.primaryMuscle,
    secondaryMuscle: row.secondaryMuscle,
    instructions: _decode(row.instructions),
    tips: _decode(row.tips),
    faqs: row.faqs,
    keywords: _decode(row.keywords),
    imagePath: row.imagePath,
    videoPath: row.videoPath,
    similarTo: row.similarTo,
    tags: _decode(row.tags),
    isCanonical: row.isCanonical,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

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
}

/// Creates a new [Exercise] with a fresh UUID v7 and the current timestamp.
Exercise newExercise({required String name, required String exerciseType}) =>
    Exercise(
      id: const Uuid().v7(),
      name: name,
      exerciseType: exerciseType,
      createdAt: DateTime.now(),
    );
