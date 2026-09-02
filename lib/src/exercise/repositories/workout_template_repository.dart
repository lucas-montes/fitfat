import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart' as db;
import '../../models/planner_recurrence.dart';
import '../../models/workout_template.dart';

/// Data access for workout templates (schema v28): CRUD for the blueprint
/// plus occurrence-exclusion bookkeeping for the scheduler.
final class WorkoutTemplateRepository {
  final db.AppDatabase _database;
  const WorkoutTemplateRepository(this._database);

  /// All templates, alphabetical.
  Future<List<WorkoutTemplate>> getAll() async {
    final rows =
        await (_database.select(_database.workoutTemplates)..orderBy([
              (t) => OrderingTerm(expression: t.name.collate(Collate.noCase)),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<WorkoutTemplate?> getById(String id) async {
    final row = await (_database.select(
      _database.workoutTemplates,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// A template with its full blueprint (blocks ordered, sets numbered).
  Future<WorkoutTemplateDetails?> getWithDetails(String id) async {
    final template = await getById(id);
    if (template == null) return null;
    final exerciseRows = await (_database.select(
      _database.workoutTemplateExercises,
    )..where((t) => t.templateId.equals(id))).get();
    exerciseRows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final blocks = <TemplateBlock>[];
    for (final ex in exerciseRows) {
      final setRows = await (_database.select(
        _database.workoutTemplateSets,
      )..where((t) => t.templateExerciseId.equals(ex.id))).get();
      setRows.sort((a, b) => a.setNumber.compareTo(b.setNumber));
      blocks.add(
        TemplateBlock(
          exercise: WorkoutTemplateExercise(
            id: ex.id,
            templateId: ex.templateId,
            exerciseId: ex.exerciseId,
            sortOrder: ex.sortOrder,
            notes: ex.notes,
          ),
          sets: [
            for (final s in setRows)
              WorkoutTemplateSet(
                id: s.id,
                templateExerciseId: s.templateExerciseId,
                setNumber: s.setNumber,
                reps: s.reps,
                weightKg: s.weightKg,
                restSeconds: s.restSeconds,
                durationMinutes: s.durationMinutes,
                distanceMeters: s.distanceMeters,
              ),
          ],
        ),
      );
    }
    return WorkoutTemplateDetails(template: template, blocks: blocks);
  }

  /// Inserts or updates the blueprint header row.
  Future<void> upsert(WorkoutTemplate template) async {
    final companion = db.WorkoutTemplatesCompanion.insert(
      id: template.id,
      name: template.name,
      notes: Value(template.notes),
      startDate: _startOfDay(template.startDate).millisecondsSinceEpoch,
      recurrence: Value(_encodeRecurrence(template.recurrence)),
      excludedDates: Value(_encodeDays(template.excludedDates)),
      sourceRoutineId: Value(template.sourceRoutineId),
      createdAt: template.createdAt.millisecondsSinceEpoch,
      updatedAt: template.updatedAt.millisecondsSinceEpoch,
    );
    final existing = await (_database.select(
      _database.workoutTemplates,
    )..where((t) => t.id.equals(template.id))).getSingleOrNull();
    if (existing == null) {
      await _database.into(_database.workoutTemplates).insert(companion);
    } else {
      await (_database.update(
        _database.workoutTemplates,
      )..where((t) => t.id.equals(template.id))).write(companion);
    }
  }

  /// Replaces the whole blueprint (exercises + sets) in one transaction —
  /// the same replace-style contract as the session editor.
  Future<void> replaceBlueprint(
    String templateId,
    List<TemplateBlock> blocks,
  ) async {
    await _database.transaction(() async {
      final oldExerciseIds = await (_database.select(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(templateId))).get();
      for (final ex in oldExerciseIds) {
        await (_database.delete(
          _database.workoutTemplateSets,
        )..where((t) => t.templateExerciseId.equals(ex.id))).go();
      }
      await (_database.delete(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(templateId))).go();

      for (final (i, block) in blocks.indexed) {
        final exerciseId = const Uuid().v7();
        await _database
            .into(_database.workoutTemplateExercises)
            .insert(
              db.WorkoutTemplateExercisesCompanion.insert(
                id: exerciseId,
                templateId: templateId,
                exerciseId: block.exercise.exerciseId,
                sortOrder: i,
                notes: Value(block.exercise.notes),
              ),
            );
        for (final (j, set) in block.sets.indexed) {
          await _database
              .into(_database.workoutTemplateSets)
              .insert(
                db.WorkoutTemplateSetsCompanion.insert(
                  id: const Uuid().v7(),
                  templateExerciseId: exerciseId,
                  setNumber: j + 1,
                  reps: Value(set.reps),
                  weightKg: Value(set.weightKg),
                  restSeconds: Value(set.restSeconds),
                  durationMinutes: Value(set.durationMinutes),
                  distanceMeters: Value(set.distanceMeters),
                ),
              );
        }
      }
      await (_database.update(
        _database.workoutTemplates,
      )..where((t) => t.id.equals(templateId))).write(
        db.WorkoutTemplatesCompanion(
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  /// Duplicates a template blueprint-only (new id, name "(Copy)", no schedule).
  Future<WorkoutTemplate> duplicate(String id) async {
    final details = await getWithDetails(id);
    if (details == null) throw StateError('Template not found');
    final orig = details.template;
    final newId = const Uuid().v7();
    final now = DateTime.now();
    final copy = WorkoutTemplate(
      id: newId,
      name: '${orig.name} (Copy)',
      notes: orig.notes,
      startDate: now,
      recurrence: null,
      excludedDates: null,
      sourceRoutineId: null,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(copy);
    await replaceBlueprint(newId, details.blocks);
    return copy;
  }

  /// Deletes a template and its blueprint. Sessions instantiated from it are
  /// left untouched (they only lose their provenance pointer's target).
  Future<void> delete(String id) async {
    await _database.transaction(() async {
      final exercises = await (_database.select(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(id))).get();
      for (final ex in exercises) {
        await (_database.delete(
          _database.workoutTemplateSets,
        )..where((t) => t.templateExerciseId.equals(ex.id))).go();
      }
      await (_database.delete(
        _database.workoutTemplateExercises,
      )..where((t) => t.templateId.equals(id))).go();
      await (_database.delete(
        _database.workoutTemplates,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Scheduler bookkeeping
  // ---------------------------------------------------------------------------

  /// Records [day] as an excluded occurrence of [templateId]'s rule so the
  /// materializer stops regenerating a deleted scheduled task.
  Future<void> excludeOccurrence(String templateId, DateTime day) async {
    await _toggleExclusion(templateId, day, add: true);
  }

  /// Undo counterpart of [excludeOccurrence]: re-includes [day] so the
  /// occurrence regenerates again.
  Future<void> restoreOccurrence(String templateId, DateTime day) async {
    await _toggleExclusion(templateId, day, add: false);
  }

  Future<void> _toggleExclusion(
    String templateId,
    DateTime day, {
    required bool add,
  }) async {
    final template = await getById(templateId);
    if (template == null) return;
    final dayMs = _startOfDay(day).millisecondsSinceEpoch;
    final set = <int>{...(template.excludedDates ?? const {})};
    final changed = add ? set.add(dayMs) : set.remove(dayMs);
    if (!changed) return;
    await (_database.update(
      _database.workoutTemplates,
    )..where((t) => t.id.equals(templateId))).write(
      db.WorkoutTemplatesCompanion(
        excludedDates: Value(_encodeDays(set)),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Row mapping
  // ---------------------------------------------------------------------------

  WorkoutTemplate _toDomain(db.WorkoutTemplate row) => WorkoutTemplate(
    id: row.id,
    name: row.name,
    notes: row.notes,
    startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate),
    recurrence: _decodeRecurrence(row.recurrence),
    excludedDates: _decodeDays(row.excludedDates),
    sourceRoutineId: row.sourceRoutineId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static String? _encodeRecurrence(PlannerRecurrence? r) =>
      r == null ? null : jsonEncode(r.toJson());

  static PlannerRecurrence? _decodeRecurrence(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return PlannerRecurrence.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _encodeDays(Set<int>? days) {
    if (days == null || days.isEmpty) return null;
    return jsonEncode(days.toList()..sort());
  }

  static Set<int>? _decodeDays(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<int>().toSet();
    } catch (_) {}
    return null;
  }
}
