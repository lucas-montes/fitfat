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
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

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
