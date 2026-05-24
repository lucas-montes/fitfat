import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../exercise/repository/seance.dart';
import '../../models/seance.dart';

class DriftSeanceRepository implements SeanceRepository {
  DriftSeanceRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<List<SeanceTemplate>> listTemplates() async {
    final templates = await _db.select(_db.templates).get();
    final result = <SeanceTemplate>[];
    for (final template in templates) {
      result.add(await _assembleTemplate(template));
    }
    return result;
  }

  @override
  Future<SeanceTemplate> createTemplate(SeanceTemplate template) async {
    final templateId = template.id.isNotEmpty ? template.id : _uuid.v4();
    await _db.into(_db.templates).insert(
      TemplatesCompanion.insert(id: templateId, name: template.name),
    );
    for (final exercise in template.exercises) {
      final exerciseId = exercise.id.isNotEmpty ? exercise.id : _uuid.v4();
      await _db.into(_db.templateExercises).insert(
        TemplateExercisesCompanion.insert(
          id: exerciseId,
          templateId: templateId,
          name: exercise.name,
        ),
      );
      for (final plannedSet in exercise.plannedSets) {
        await _db.into(_db.templateSets).insert(
          TemplateSetsCompanion.insert(
            id: _uuid.v4(),
            templateExerciseId: exerciseId,
            reps: plannedSet.reps,
            weightKg: Value(plannedSet.weightKg),
            restSeconds: Value(plannedSet.restSeconds),
          ),
        );
      }
    }
    return template.copyWith(id: templateId);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final exercises = await (
      _db.select(_db.templateExercises)
        ..where((table) => table.templateId.equals(id))
    ).get();
    for (final exercise in exercises) {
      await (_db.delete(_db.templateSets)
            ..where((table) => table.templateExerciseId.equals(exercise.id)))
          .go();
    }
    await (_db.delete(_db.templateExercises)
          ..where((table) => table.templateId.equals(id)))
        .go();
    await (_db.delete(_db.templates)..where((table) => table.id.equals(id))).go();
  }

  @override
  Future<SeanceTemplate> updateTemplate(SeanceTemplate template) async {
    await _db.update(_db.templates).replace(
      TemplatesCompanion(
        id: Value(template.id),
        name: Value(template.name),
      ),
    );
    final oldExercises = await (
      _db.select(_db.templateExercises)
        ..where((table) => table.templateId.equals(template.id))
    ).get();
    for (final exercise in oldExercises) {
      await (_db.delete(_db.templateSets)
            ..where((table) => table.templateExerciseId.equals(exercise.id)))
          .go();
    }
    await (_db.delete(_db.templateExercises)
          ..where((table) => table.templateId.equals(template.id)))
        .go();
    for (final exercise in template.exercises) {
      final exerciseId = _uuid.v4();
      await _db.into(_db.templateExercises).insert(
        TemplateExercisesCompanion.insert(
          id: exerciseId,
          templateId: template.id,
          name: exercise.name,
        ),
      );
      for (final plannedSet in exercise.plannedSets) {
        await _db.into(_db.templateSets).insert(
          TemplateSetsCompanion.insert(
            id: _uuid.v4(),
            templateExerciseId: exerciseId,
            reps: plannedSet.reps,
            weightKg: Value(plannedSet.weightKg),
            restSeconds: Value(plannedSet.restSeconds),
          ),
        );
      }
    }
    return template;
  }

  @override
  Future<SeanceTemplate> cloneTemplate(
    String id, {
    DateTime? scheduledFor,
  }) async {
    final original = await _assembleTemplate(
      await (_db.select(_db.templates)..where((table) => table.id.equals(id)))
          .getSingle(),
    );
    final cloned = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} (copy)',
      scheduledFor: scheduledFor,
      exercises: original.exercises
          .map((exercise) => exercise.copyWith(id: _uuid.v4()))
          .toList(),
    );
    return createTemplate(cloned);
  }

  Future<SeanceTemplate> _assembleTemplate(Template template) async {
    final exerciseRows = await (
      _db.select(_db.templateExercises)
        ..where((table) => table.templateId.equals(template.id))
    ).get();
    final exercises = <ExerciseTemplate>[];
    for (final exerciseRow in exerciseRows) {
      final setRows = await (
        _db.select(_db.templateSets)
          ..where((table) => table.templateExerciseId.equals(exerciseRow.id))
      ).get();
      exercises.add(
        ExerciseTemplate(
          id: exerciseRow.id,
          name: exerciseRow.name,
          plannedSets: setRows
              .map(
                (setRow) => PlannedSet(
                  reps: setRow.reps,
                  weightKg: setRow.weightKg,
                  restSeconds: setRow.restSeconds,
                ),
              )
              .toList(),
        ),
      );
    }
    return SeanceTemplate(id: template.id, name: template.name, exercises: exercises);
  }
}
