import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../database/app_database.dart';
import '../../models/seance_models.dart';
import '../seance_repository.dart';

class DriftSeanceRepository implements SeanceRepository {
  DriftSeanceRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<List<SeanceTemplate>> listTemplates() async {
    final templates = await _db.select(_db.templates).get();
    final result = <SeanceTemplate>[];
    for (final t in templates) {
      result.add(await _assembleTemplate(t));
    }
    return result;
  }

  @override
  Future<SeanceTemplate> createTemplate(SeanceTemplate template) async {
    final templateId = template.id.isNotEmpty ? template.id : _uuid.v4();
    await _db
        .into(_db.templates)
        .insert(TemplatesCompanion.insert(id: templateId, name: template.name));
    for (final ex in template.exercises) {
      final exerciseId = ex.id.isNotEmpty ? ex.id : _uuid.v4();
      await _db
          .into(_db.templateExercises)
          .insert(
            TemplateExercisesCompanion.insert(
              id: exerciseId,
              templateId: templateId,
              name: ex.name,
            ),
          );
      for (final ps in ex.plannedSets) {
        await _db
            .into(_db.templateSets)
            .insert(
              TemplateSetsCompanion.insert(
                id: _uuid.v4(),
                templateExerciseId: exerciseId,
                reps: ps.reps,
                weightKg: Value(ps.weightKg),
                restSeconds: Value(ps.restSeconds),
              ),
            );
      }
    }
    return template.copyWith(id: templateId);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final exercises = await (_db.select(
      _db.templateExercises,
    )..where((t) => t.templateId.equals(id))).get();
    for (final ex in exercises) {
      await (_db.delete(
        _db.templateSets,
      )..where((t) => t.templateExerciseId.equals(ex.id))).go();
    }
    await (_db.delete(
      _db.templateExercises,
    )..where((t) => t.templateId.equals(id))).go();
    await (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<SeanceTemplate> updateTemplate(SeanceTemplate template) async {
    await _db
        .update(_db.templates)
        .replace(
          TemplatesCompanion(
            id: Value(template.id),
            name: Value(template.name),
          ),
        );
    final oldExercises = await (_db.select(
      _db.templateExercises,
    )..where((t) => t.templateId.equals(template.id))).get();
    for (final ex in oldExercises) {
      await (_db.delete(
        _db.templateSets,
      )..where((t) => t.templateExerciseId.equals(ex.id))).go();
    }
    await (_db.delete(
      _db.templateExercises,
    )..where((t) => t.templateId.equals(template.id))).go();
    for (final ex in template.exercises) {
      final exerciseId = _uuid.v4();
      await _db
          .into(_db.templateExercises)
          .insert(
            TemplateExercisesCompanion.insert(
              id: exerciseId,
              templateId: template.id,
              name: ex.name,
            ),
          );
      for (final ps in ex.plannedSets) {
        await _db
            .into(_db.templateSets)
            .insert(
              TemplateSetsCompanion.insert(
                id: _uuid.v4(),
                templateExerciseId: exerciseId,
                reps: ps.reps,
                weightKg: Value(ps.weightKg),
                restSeconds: Value(ps.restSeconds),
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
      await (_db.select(
        _db.templates,
      )..where((t) => t.id.equals(id))).getSingle(),
    );
    final cloned = original.copyWith(
      id: _uuid.v4(),
      name: '${original.name} (copy)',
      scheduledFor: scheduledFor,
      exercises: original.exercises
          .map((e) => e.copyWith(id: _uuid.v4()))
          .toList(),
    );
    return createTemplate(cloned);
  }

  Future<SeanceTemplate> _assembleTemplate(Template t) async {
    final exRows = await (_db.select(
      _db.templateExercises,
    )..where((te) => te.templateId.equals(t.id))).get();
    final exercises = <ExerciseTemplate>[];
    for (final ex in exRows) {
      final setRows = await (_db.select(
        _db.templateSets,
      )..where((ts) => ts.templateExerciseId.equals(ex.id))).get();
      exercises.add(
        ExerciseTemplate(
          id: ex.id,
          name: ex.name,
          plannedSets: setRows
              .map(
                (s) => PlannedSet(
                  reps: s.reps,
                  weightKg: s.weightKg,
                  restSeconds: s.restSeconds,
                ),
              )
              .toList(),
        ),
      );
    }
    return SeanceTemplate(id: t.id, name: t.name, exercises: exercises);
  }
}
