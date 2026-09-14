import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../planner/repositories/task_repository.dart' show decodeTagList;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Ingredients,
    Stores,
    IngredientPictures,
    IngredientPrices,
    Meals,
    MealIngredients,
    Exercises,
    Workouts,
    WorkoutExercises,
    ExerciseSets,
    WorkoutTemplates,
    WorkoutTemplateExercises,
    WorkoutTemplateSets,
    Tasks,
    Experiments,
    BodyMetrics,
    Notes,
    Accounts,
    Transactions,
    Receipts,
    FxRates,
    ExperimentCheckins,
    Tags,
    Goals,
    GoalProgressEntries,
    TaskExperiments,
    TaskGoals,
    ExperimentGoals,
    TaskNotes,
    ExperimentNotes,
    GoalNotes,
    GoalWorkouts,
    NoteWorkouts,
    TaskTags,
    ExperimentTags,
    GoalTags,
    NoteTags,
    NoteAudio,
    ExerciseCatalog,
    IngredientCatalog,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 32;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Barcode lookup index (v20). Created idempotently here so fresh
      // installs and every upgrade path end up with the same index without
      // per-version migration steps.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_barcode '
        'ON ingredients (barcode)',
      );
      // Replay-lineage lookup index (v21) — same idempotent pattern.
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_workouts_routine '
        'ON workouts (routine_id)',
      );
      // Link-table reverse-lookup indexes (v27). The composite primary keys
      // already serve lookups on the leading column; these cover queries that
      // start from the second column (e.g. goals for a task, tasks for a goal).
      const linkIndexes = [
        (
          'idx_task_experiments_experiment',
          'task_experiments',
          'experiment_id',
        ),
        ('idx_task_goals_goal', 'task_goals', 'goal_id'),
        ('idx_experiment_goals_goal', 'experiment_goals', 'goal_id'),
        ('idx_task_notes_note', 'task_notes', 'note_id'),
        ('idx_experiment_notes_note', 'experiment_notes', 'note_id'),
        ('idx_goal_notes_note', 'goal_notes', 'note_id'),
        ('idx_goal_workouts_workout', 'goal_workouts', 'workout_id'),
        ('idx_note_workouts_workout', 'note_workouts', 'workout_id'),
        ('idx_task_tags_task', 'task_tags', 'task_id'),
        ('idx_experiment_tags_experiment', 'experiment_tags', 'experiment_id'),
        ('idx_goal_tags_goal', 'goal_tags', 'goal_id'),
        ('idx_note_tags_note', 'note_tags', 'note_id'),
      ];
      for (final (name, table, column) in linkIndexes) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS $name ON $table ($column)',
        );
      }
    },
    onUpgrade: (m, from, to) async {
      // Historical planner_items steps are frozen raw SQL: the table has since
      // been renamed to `tasks` (v27) and its Dart class no longer exists, but
      // upgrades from very old schemas still need the original statements.
      if (from < 2) {
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS planner_items ('
          'id TEXT NOT NULL PRIMARY KEY, '
          'date INTEGER NOT NULL, '
          'title TEXT NOT NULL, '
          'done INTEGER NOT NULL, '
          'sort_order INTEGER NOT NULL, '
          'created_at INTEGER NOT NULL)',
        );
      }
      if (from < 3) {
        // v3: optional ingredient nutriments, planner due date, body_metrics.
        await m.addColumn(ingredients, ingredients.sodiumPer100g);
        await m.addColumn(ingredients, ingredients.fiberPer100g);
        await m.addColumn(ingredients, ingredients.sugarPer100g);
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN due_date INTEGER NULL',
        );
        await m.createTable(bodyMetrics);
        // Clean up orphaned meal_ingredients rows left by the pre-T02
        // new-meal bug (rows whose meal_id points at no meals row).
        await m.database.customStatement(
          'DELETE FROM meal_ingredients WHERE meal_id NOT IN (SELECT id FROM meals)',
        );
      }
      if (from < 4) {
        // v4: ingredient soft-archive flag (default false).
        await m.addColumn(ingredients, ingredients.isArchived);
      }
      if (from < 5) {
        // v5: planned + actual rest per exercise set (seconds).
        await m.addColumn(exerciseSets, exerciseSets.restSeconds);
        await m.addColumn(exerciseSets, exerciseSets.actualRestSeconds);
      }
      if (from < 6) {
        // v6: optional free-text note per planner task.
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN notes TEXT NULL',
        );
      }
      if (from < 7) {
        // v7: set completion timestamp (epoch millis), stamped when actuals
        // are saved. Null for planned-only sets.
        await m.addColumn(exerciseSets, exerciseSets.completedAt);
      }
      if (from < 8) {
        // v8: exercise catalog metadata columns; planner due time.
        // (is_locked was also added here once; dropped again in v23.)
        await m.addColumn(exercises, exercises.bodyPart);
        await m.addColumn(exercises, exercises.equipment);
        await m.addColumn(exercises, exercises.primaryMuscle);
        await m.addColumn(exercises, exercises.secondaryMuscle);
        await m.addColumn(exercises, exercises.instructions);
        await m.addColumn(exercises, exercises.tips);
        await m.addColumn(exercises, exercises.faqs);
        await m.addColumn(exercises, exercises.keywords);
        await m.addColumn(exercises, exercises.imagePath);
        await m.addColumn(exercises, exercises.videoPath);
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN due_time_minutes INTEGER NULL',
        );
      }
      if (from < 9) {
        // v9: free-form notes (Notes tab).
        await m.createTable(notes);
      }
      if (from < 10) {
        // v10: exercise canonicalization fields.
        await m.addColumn(exercises, exercises.similarTo);
        await m.addColumn(exercises, exercises.tags);
        await m.addColumn(exercises, exercises.isCanonical);
      }
      if (from < 11) {
        // v11: planner workout linking.
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN workout_id TEXT NULL',
        );
      }
      if (from < 12) {
        // v12: free-form planner task tags (JSON string[]).
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN tags TEXT NULL',
        );
      }
      if (from < 13) {
        // v13: recurring task rule + series grouping.
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN recurrence TEXT NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN series_id TEXT NULL',
        );
      }
      if (from < 14) {
        // v14: budget section — accounts, transactions, receipts, fx_rates.
        await m.createTable(accounts);
        await m.createTable(transactions);
        await m.createTable(receipts);
        await m.createTable(fxRates);
      }
      if (from < 15) {
        // v15: planner task start/end time (replaces the single due time).
        // Existing due_time_minutes is carried over into start_time_minutes.
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN start_time_minutes INTEGER NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN end_time_minutes INTEGER NULL',
        );
        await m.database.customStatement(
          'UPDATE planner_items SET start_time_minutes = due_time_minutes '
          'WHERE due_time_minutes IS NOT NULL',
        );
      }
      if (from < 16) {
        // v16: logged cardio actuals. Exercise sets used to overwrite the
        // planned duration/distance columns when a cardio set was saved, which
        // made it impossible to tell "done" from "planned". Old rows had their
        // effective value (planned if never logged) in those columns, so carry
        // them into the new actual columns to preserve existing data.
        await m.addColumn(exerciseSets, exerciseSets.actualDurationMinutes);
        await m.addColumn(exerciseSets, exerciseSets.actualDistanceMeters);
        await m.database.customStatement(
          'UPDATE exercise_sets SET actual_duration_minutes = duration_minutes, '
          'actual_distance_meters = distance_meters',
        );
      }
      if (from < 17) {
        // v17: exercise-level free-text note on workout_exercises.
        await m.addColumn(workoutExercises, workoutExercises.notes);
      }
      if (from < 18) {
        // v18: experiments + daily check-ins. The standalone experiments
        // table is raw-SQL-created (its Dart class is gone since v24) so the
        // sequential v24 migration can copy rows out of it before dropping.
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS experiments ('
          'id TEXT NOT NULL PRIMARY KEY, '
          'name TEXT NOT NULL, '
          'purpose TEXT NULL, '
          'start_date INTEGER NOT NULL, '
          'end_date INTEGER NULL, '
          'status TEXT NOT NULL, '
          'categories TEXT NOT NULL, '
          'reminder_enabled INTEGER NOT NULL DEFAULT 1, '
          'reminder_time_minutes INTEGER NOT NULL DEFAULT 1200, '
          'created_at INTEGER NOT NULL)',
        );
        await m.createTable(experimentCheckins);
      }
      if (from < 19) {
        // v19: fx_rates.manual — marks hand-edited rates so a refresh can
        // distinguish them from fetched ones.
        await m.addColumn(fxRates, fxRates.manual);
      }
      if (from < 20) {
        // v20: ingredient shopping metadata — brand + barcode columns and the
        // stores / ingredient_pictures / ingredient_prices tables.
        await m.addColumn(ingredients, ingredients.brand);
        await m.addColumn(ingredients, ingredients.barcode);
        await m.createTable(stores);
        await m.createTable(ingredientPictures);
        await m.createTable(ingredientPrices);
      }
      if (from < 21) {
        // v21: workouts.routine_id — replay lineage shared by all occurrences
        // of the same routine (workout-replay T01). The lookup index is
        // created idempotently in beforeOpen.
        await m.addColumn(workouts, workouts.routineId);
      }
      if (from < 22) {
        // v22: fx_rates gains a daily-snapshot dimension (rate_date) and a
        // composite PK (code, base_code, rate_date). The old table was keyed
        // only by code, so rebuild it: rename, recreate with the new schema,
        // and backfill existing rows as a single '0001-01-01' snapshot.
        await m.database.customStatement(
          'ALTER TABLE fx_rates RENAME TO fx_rates_old',
        );
        await m.createTable(fxRates);
        await m.database.customStatement(
          'INSERT INTO fx_rates '
          '(code, rate_to_base, base_code, updated_at, manual, rate_date) '
          "SELECT code, rate_to_base, base_code, updated_at, manual, '0001-01-01' "
          'FROM fx_rates_old',
        );
        await m.database.customStatement('DROP TABLE fx_rates_old');
      }
      if (from < 23) {
        // v23: drop exercises.is_locked. The bundled catalog and its locked
        // exercises are no longer imported (data now arrives via the sync
        // client), so the edit/delete guard column is dead. Drift cannot drop a
        // column in place, so rebuild: rename, recreate without the column,
        // backfill, then drop the old table.
        await m.database.customStatement(
          'ALTER TABLE exercises RENAME TO exercises_old',
        );
        await m.createTable(exercises);
        await m.database.customStatement(
          'INSERT INTO exercises '
          '(id, name, exercise_type, body_part, equipment, primary_muscle, '
          'secondary_muscle, instructions, tips, faqs, keywords, image_path, '
          'video_path, similar_to, tags, is_canonical, created_at) '
          'SELECT id, name, exercise_type, body_part, equipment, primary_muscle, '
          'secondary_muscle, instructions, tips, faqs, keywords, image_path, '
          'video_path, similar_to, tags, is_canonical, created_at '
          'FROM exercises_old',
        );
        await m.database.customStatement('DROP TABLE exercises_old');
      }
      if (from < 24) {
        // v24: experiments fold into planner_items as kind='experiment' rows
        // (day = start date, end_date = required end, plus purpose/status/
        // categories/reminder columns and a child-task experiment_id link).
        // Check-ins re-point at planner ids (ids are preserved by the copy),
        // losing their FK to the standalone table, which is then dropped.
        await m.database.customStatement(
          "ALTER TABLE planner_items ADD COLUMN kind TEXT NOT NULL DEFAULT 'task'",
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN end_date INTEGER NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN purpose TEXT NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN status TEXT NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN categories TEXT NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items '
          'ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items '
          'ADD COLUMN reminder_time_minutes INTEGER NOT NULL DEFAULT 1200',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN experiment_id TEXT NULL',
        );
        await m.database.customStatement(
          'INSERT INTO planner_items '
          '(id, date, title, done, sort_order, end_date, purpose, status, '
          'categories, reminder_enabled, reminder_time_minutes, created_at) '
          'SELECT id, start_date, name, '
          "CASE WHEN status = 'done' THEN 1 ELSE 0 END, 0, "
          // Open-ended experiments get a concrete end one week out so the
          // new required-end rule holds for migrated rows.
          'COALESCE(end_date, start_date + 604800000), purpose, status, '
          'categories, reminder_enabled, reminder_time_minutes, created_at '
          'FROM experiments',
        );
        await m.database.customStatement(
          'ALTER TABLE experiment_checkins RENAME TO experiment_checkins_old',
        );
        await m.createTable(experimentCheckins);
        await m.database.customStatement(
          'INSERT INTO experiment_checkins '
          '(id, experiment_id, day, rating, note, created_at) '
          'SELECT id, experiment_id, day, rating, note, created_at '
          'FROM experiment_checkins_old',
        );
        await m.database.customStatement('DROP TABLE experiment_checkins_old');
        await m.database.customStatement('DROP TABLE IF EXISTS experiments');
      }
      if (from < 25) {
        // v25: task lifecycle + carry-over. task_status distinguishes
        // pending/done/cancelled for plain tasks (experiments stay null and
        // keep using status); done stays the source of truth for "completed"
        // and is kept in sync (done == task_status == 1).
        await m.database.customStatement(
          'ALTER TABLE planner_items ADD COLUMN task_status INTEGER NULL',
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items '
          'ADD COLUMN carry_over INTEGER NOT NULL DEFAULT 1',
        );
        await m.database.customStatement(
          "UPDATE planner_items SET task_status = CASE WHEN done = 1 "
          "THEN 1 ELSE 0 END WHERE kind = 'task'",
        );
      }
      if (from < 26) {
        // v26: goals & priorities. `tags` is the shared vocabulary behind the
        // Priorities feature; notes gain tag support and goals link to tags
        // by name via their own JSON string[] column. Progress entries are
        // unique per goal per day.
        await m.createTable(tags);
        // `notes` gains a JSON `tags` string[] column (removed in v29 in favor
        // of a dedicated tag link table; this only matters for the v26→v29
        // upgrade path, where the column still physically exists on old DBs).
        await m.database.customStatement(
          'ALTER TABLE notes ADD COLUMN tags TEXT',
        );
        await m.createTable(goals);
        await m.createTable(goalProgressEntries);
      }
      if (from < 27) {
        // v27: un-merge the v24 experiment fold and introduce link tables.
        //
        // 1. Experiments move back into a standalone `experiments` table
        //    (ids preserved so experiment_checkins keep resolving).
        // 2. `planner_items` is rebuilt as `tasks` without the
        //    experiment-only columns (kind, end_date, purpose, status,
        //    categories, reminder_*, experiment_id).
        // 3. Child-task → experiment back-references become rows in the
        //    `task_experiments` link table; further junction tables are
        //    created empty.
        // 4. Goals gain reminder + baseline columns.
        await m.createTable(experiments);
        await m.database.customStatement(
          'INSERT INTO experiments '
          '(id, name, purpose, start_date, end_date, status, categories, '
          'reminder_enabled, reminder_time_minutes, created_at) '
          'SELECT id, title, purpose, date, end_date, '
          "COALESCE(status, 'planned'), categories, reminder_enabled, "
          'reminder_time_minutes, created_at '
          "FROM planner_items WHERE kind = 'experiment'",
        );
        await m.database.customStatement(
          'ALTER TABLE planner_items RENAME TO planner_items_old',
        );
        await m.createTable(tasks);
        await m.database.customStatement(
          'INSERT INTO tasks '
          '(id, date, title, done, task_status, carry_over, sort_order, '
          'due_date, due_time_minutes, start_time_minutes, end_time_minutes, '
          'notes, workout_id, recurrence, series_id, created_at) '
          'SELECT id, date, title, done, task_status, carry_over, sort_order, '
          'due_date, due_time_minutes, start_time_minutes, end_time_minutes, '
          'notes, workout_id, recurrence, series_id, created_at '
          "FROM planner_items_old WHERE kind = 'task'",
        );
        await m.createTable(taskExperiments);
        await m.database.customStatement(
          'INSERT INTO task_experiments (task_id, experiment_id) '
          'SELECT id, experiment_id FROM planner_items_old '
          "WHERE kind = 'task' AND experiment_id IS NOT NULL",
        );
        await m.database.customStatement('DROP TABLE planner_items_old');
        await m.createTable(taskGoals);
        await m.createTable(experimentGoals);
        await m.createTable(taskNotes);
        await m.createTable(experimentNotes);
        await m.createTable(goalNotes);
        await m.createTable(goalWorkouts);
        await m.createTable(noteWorkouts);
        await m.addColumn(goals, goals.reminderEnabled);
        await m.addColumn(goals, goals.reminderTimeMinutes);
        await m.addColumn(goals, goals.baselineValue);
      }
      if (from < 28) {
        // v28: workout templates + priorities backfill.
        //
        // 1. Template tables (blueprint exercises + planned sets) plus
        //    provenance columns on workouts / tasks.
        // 2. Every distinct replay lineage (routine_id) is auto-promoted to
        //    a template seeded from its latest occurrence's planned sets;
        //    that lineage's sessions get stamped with the template id.
        // 3. Free-form tag references across tasks/experiments/notes/goals
        //    are normalized and registered in the shared `tags` vocabulary.
        await m.createTable(workoutTemplates);
        await m.createTable(workoutTemplateExercises);
        await m.createTable(workoutTemplateSets);
        await m.addColumn(workouts, workouts.templateId);
        await m.addColumn(tasks, tasks.workoutTemplateId);

        final uuid = const Uuid();
        String baseName(String raw) {
          final stripped = raw.replaceAll(RegExp(r' (#\d+|\(Copy\))+$'), '');
          return stripped.trim().isEmpty ? raw.trim() : stripped.trim();
        }

        // --- Auto-promote routine lineages -------------------------------
        final lineageRows = await (select(
          workouts,
        )..where((t) => t.routineId.isNotNull())).get();
        final byLineage = <String, List<Workout>>{};
        for (final row in lineageRows) {
          byLineage.putIfAbsent(row.routineId!, () => []).add(row);
        }
        for (final entry in byLineage.entries) {
          final lineage = entry.value;
          // Prefer the most recently completed occurrence; fall back to the
          // newest one so never-completed routines still promote.
          int rank(Workout w) =>
              (w.completedAt ?? 0) * 2 + (w.date > 0 ? 1 : 0);
          lineage.sort((a, b) => rank(b).compareTo(rank(a)));
          final source = lineage.first;

          final templateId = uuid.v7();
          final now = DateTime.now().millisecondsSinceEpoch;
          await into(workoutTemplates).insert(
            WorkoutTemplatesCompanion.insert(
              id: templateId,
              name: baseName(source.name),
              startDate: source.date,
              sourceRoutineId: Value(entry.key),
              createdAt: now,
              updatedAt: now,
            ),
          );

          final blocks = await (select(
            workoutExercises,
          )..where((t) => t.workoutId.equals(source.id))).get();
          blocks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          for (final block in blocks) {
            final templateExerciseId = uuid.v7();
            await into(workoutTemplateExercises).insert(
              WorkoutTemplateExercisesCompanion.insert(
                id: templateExerciseId,
                templateId: templateId,
                exerciseId: block.exerciseId,
                sortOrder: block.sortOrder,
                notes: Value(block.notes),
              ),
            );
            final sets = await (select(
              exerciseSets,
            )..where((t) => t.workoutExerciseId.equals(block.id))).get();
            sets.sort((a, b) => a.setNumber.compareTo(b.setNumber));
            for (final set in sets) {
              await into(workoutTemplateSets).insert(
                WorkoutTemplateSetsCompanion.insert(
                  id: uuid.v7(),
                  templateExerciseId: templateExerciseId,
                  setNumber: set.setNumber,
                  reps: Value(set.reps),
                  weightKg: Value(set.weightKg),
                  restSeconds: Value(set.restSeconds),
                  durationMinutes: Value(set.durationMinutes),
                  distanceMeters: Value(set.distanceMeters),
                ),
              );
            }
          }
          // Stamp provenance onto every session of this lineage.
          await (update(workouts)..where((t) => t.routineId.equals(entry.key)))
              .write(WorkoutsCompanion(templateId: Value(templateId)));
        }

        // --- Priorities vocabulary backfill ------------------------------
        Future<void> registerRefs(List<String>? refs) async {
          for (final ref in refs ?? const <String>[]) {
            final clean = ref.trim().replaceAll(RegExp(r'\s+'), ' ');
            if (clean.isEmpty) continue;
            final existing = await (select(
              tags,
            )..where((t) => t.name.equals(clean))).getSingleOrNull();
            if (existing != null) continue;
            final maxOrderExp = tags.sortOrder.max();
            final orderRow = await (selectOnly(
              tags,
            )..addColumns([maxOrderExp])).getSingleOrNull();
            final now = DateTime.now().millisecondsSinceEpoch;
            await into(tags).insert(
              TagsCompanion.insert(
                id: uuid.v7(),
                name: clean,
                sortOrder: Value((orderRow?.read(maxOrderExp) ?? -1) + 1),
                createdAt: now,
                updatedAt: now,
              ),
            );
          }
        }

        Future<void> readRefs(String table) async {
          try {
            final rows = await m.database
                .customSelect('SELECT id, tags FROM $table')
                .get();
            for (final row in rows) {
              await registerRefs(decodeTagList(row.read<String?>('tags')));
            }
          } on Exception {
            // The `tags` column may be absent on this table (e.g. when a
            // cross-version upgrade created it from a model that no longer
            // carries the JSON column). Nothing to backfill here.
          }
        }

        await readRefs('tasks');
        await readRefs('experiments');
        await readRefs('notes');
        await readRefs('goals');
      }
      if (from < 29) {
        // v29: tags become a real many-to-many. Each tagged entity now links
        // to the shared `tags` (Priorities) vocabulary by id via a dedicated
        // junction table, replacing the per-entity JSON name arrays.
        //
        // 1. Create the four junction tables.
        // 2. Backfill links from the existing JSON columns (still present).
        //    Every referenced name was already registered into `tags` by the
        //    v28 backfill, but we still upsert defensively in case any slipped
        //    through.
        // 3. Drop the now-redundant JSON `tags` columns.
        await m.createTable(taskTags);
        await m.createTable(experimentTags);
        await m.createTable(goalTags);
        await m.createTable(noteTags);

        String normalize(String raw) =>
            raw.trim().replaceAll(RegExp(r'\s+'), ' ');

        Future<String> ensureTag(String rawName) async {
          final clean = normalize(rawName);
          if (clean.isEmpty) throw ArgumentError('Blank tag name');
          final existing = await (select(
            tags,
          )..where((t) => t.name.equals(clean))).getSingleOrNull();
          if (existing != null) return existing.id;
          final maxOrderExp = tags.sortOrder.max();
          final orderRow = await (selectOnly(
            tags,
          )..addColumns([maxOrderExp])).getSingleOrNull();
          final now = DateTime.now().millisecondsSinceEpoch;
          final id = const Uuid().v7();
          await into(tags).insert(
            TagsCompanion.insert(
              id: id,
              name: clean,
              sortOrder: Value((orderRow?.read(maxOrderExp) ?? -1) + 1),
              createdAt: now,
              updatedAt: now,
            ),
          );
          return id;
        }

        Future<void> linkRows(
          String table,
          Future<void> Function(String id, List<String> names) insertLinks,
        ) async {
          List<QueryRow> rows;
          try {
            rows = await m.database.customSelect(
              'SELECT id, id AS entity_id, tags FROM $table',
            ).get();
          } on Exception {
            // The `tags` column is absent on this table (cross-version
            // upgrade from a schema that never carried JSON tags here):
            // there is nothing to link, so skip it.
            return;
          }
          for (final row in rows) {
            final id = row.read<String>('id');
            final names = decodeTagList(row.read<String?>('tags'));
            if (names == null || names.isEmpty) continue;
            await insertLinks(id, names);
          }
        }

        await linkRows('tasks', (id, names) async {
          for (final name in names) {
            final tagId = await ensureTag(name);
            await into(taskTags).insert(
              TaskTagsCompanion.insert(tagId: tagId, taskId: id),
              onConflict: DoNothing(),
            );
          }
        });
        await linkRows('experiments', (id, names) async {
          for (final name in names) {
            final tagId = await ensureTag(name);
            await into(experimentTags).insert(
              ExperimentTagsCompanion.insert(tagId: tagId, experimentId: id),
              onConflict: DoNothing(),
            );
          }
        });
        await linkRows('notes', (id, names) async {
          for (final name in names) {
            final tagId = await ensureTag(name);
            await into(noteTags).insert(
              NoteTagsCompanion.insert(tagId: tagId, noteId: id),
              onConflict: DoNothing(),
            );
          }
        });
        await linkRows('goals', (id, names) async {
          for (final name in names) {
            final tagId = await ensureTag(name);
            await into(goalTags).insert(
              GoalTagsCompanion.insert(tagId: tagId, goalId: id),
              onConflict: DoNothing(),
            );
          }
        });

        // Dropping the JSON columns is best-effort: SQLite < 3.35 lacks
        // DROP COLUMN, in which case the unused column harmlessly lingers.
        for (final table in ['tasks', 'experiments', 'notes', 'goals']) {
          try {
            await m.database.customStatement(
              'ALTER TABLE $table DROP COLUMN tags',
            );
          } catch (_) {
            // Leave the dead column in place on unsupported runtimes.
          }
        }
      }

      if (from < 30) {
        // v30: voice clips attached to notes (one audio file per clip).
        await m.createTable(noteAudio);
      }

      if (from < 31) {
        // v31: selective-sync catalog index (no FK, no media stored here).
        await m.createTable(exerciseCatalog);
        await m.createTable(ingredientCatalog);
      }

      if (from < 32) {
        // v32: `has_image` hint on the exercise catalog so the picker can
        // skip thumbnail fetches for imageless rows (default false).
        await m.addColumn(exerciseCatalog, exerciseCatalog.hasImage);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitfat.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
