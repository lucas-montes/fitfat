import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Ingredients,
    Meals,
    MealIngredients,
    Exercises,
    Workouts,
    WorkoutExercises,
    ExerciseSets,
    PlannerItems,
    BodyMetrics,
    Notes,
    Accounts,
    Transactions,
    Receipts,
    FxRates,
    Experiments,
    ExperimentCheckins,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(plannerItems);
      }
      if (from < 3) {
        // v3: optional ingredient nutriments, planner due date, body_metrics.
        await m.addColumn(ingredients, ingredients.sodiumPer100g);
        await m.addColumn(ingredients, ingredients.fiberPer100g);
        await m.addColumn(ingredients, ingredients.sugarPer100g);
        await m.addColumn(plannerItems, plannerItems.dueDate);
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
        await m.addColumn(plannerItems, plannerItems.notes);
      }
      if (from < 7) {
        // v7: set completion timestamp (epoch millis), stamped when actuals
        // are saved. Null for planned-only sets.
        await m.addColumn(exerciseSets, exerciseSets.completedAt);
      }
      if (from < 8) {
        // v8: exercise catalog metadata + is_locked; planner due time.
        await m.addColumn(exercises, exercises.isLocked);
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
        await m.addColumn(plannerItems, plannerItems.dueTimeMinutes);
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
        await m.addColumn(plannerItems, plannerItems.workoutId);
      }
      if (from < 12) {
        // v12: free-form planner task tags (JSON string[]).
        await m.addColumn(plannerItems, plannerItems.tags);
      }
      if (from < 13) {
        // v13: recurring task rule + series grouping.
        await m.addColumn(plannerItems, plannerItems.recurrence);
        await m.addColumn(plannerItems, plannerItems.seriesId);
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
        await m.addColumn(plannerItems, plannerItems.startTimeMinutes);
        await m.addColumn(plannerItems, plannerItems.endTimeMinutes);
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
        // v18: experiments + daily check-ins.
        await m.createTable(experiments);
        await m.createTable(experimentCheckins);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fitfat.sqlite'));
    return NativeDatabase(file);
  });
}
