import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../services/logger.dart';
import 'tables.dart';

part 'app_database.g.dart';

final _log = logger('app_database');

@DriftDatabase(
  tables: [
    Exercises,
    ExerciseBodyParts,
    Workouts,
    WeightSets,
    CardioSets,
    Ingredients,
    IngredientComponents,
    Meals,
    MealIngredients,
    Goals,
    UserProfile,
    BodyWeightEntries,
    WaterConsumption,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  /// Public constructor that allows creating an `AppDatabase` with a
  /// custom [QueryExecutor]. This is useful for dev or non-production
  /// databases (e.g. a separate file-backed DB) without touching the
  /// default production connection.
  AppDatabase.open(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedExercises();
      await _seedIngredients();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new ingredient fields (nullable = safe for existing rows)
        await m.addColumn(ingredients, ingredients.creatorId);
        await m.addColumn(ingredients, ingredients.isArchived);
        await m.addColumn(ingredients, ingredients.sodiumPer100g);
        await m.addColumn(ingredients, ingredients.fiberPer100g);
        await m.addColumn(ingredients, ingredients.sugarsPer100g);
        await m.addColumn(ingredients, ingredients.saturatedFatPer100g);
        await m.addColumn(ingredients, ingredients.cholesterolPer100g);
        // Create junction table for composite ingredients
        await m.createTable(ingredientComponents);
      }
      if (from < 3) {
        // Add creatorId column to exercises table
        await m.addColumn(exercises, exercises.creatorId);
        // Seed comprehensive exercise bundle
        await _seedExercises();
      }
      if (from < 4) {
        // Rename sex column to gender in user_profile table
        await m.database.customStatement(
          'ALTER TABLE user_profile RENAME COLUMN sex TO gender',
        );
      }
      if (from < 5) {
        // Add completedAt column to exercise_sets table
        await m.database.customStatement(
          'ALTER TABLE exercise_sets ADD COLUMN completed_at TEXT',
        );
      }
      if (from < 6) {
        // Make seances.completed_at non-nullable — fill any null values first
        await m.database.customStatement(
          'UPDATE seances SET completed_at = started_at WHERE completed_at IS NULL',
        );
      }
      if (from < 7) {
        // Remove weight_kg from user_profile
        await m.database.customStatement(
          'ALTER TABLE user_profile DROP COLUMN weight_kg',
        );
      }
      if (from < 8) {
        // Add type and met columns to exercises table
        await m.database.customStatement(
          "ALTER TABLE exercises ADD COLUMN type TEXT NOT NULL DEFAULT 'weightlifting'",
        );
        await m.database.customStatement(
          'ALTER TABLE exercises ADD COLUMN met REAL NOT NULL DEFAULT 5.0',
        );
        await _seedExercises();
      }
      if (from < 9) {
        // Create old workout model tables (replaced by v12 schema)
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS workouts (id TEXT PRIMARY KEY, name TEXT NOT NULL, start_time TEXT NOT NULL, end_time TEXT, notes TEXT, source TEXT DEFAULT \'manual\', planned_workout_id TEXT, is_guided INTEGER DEFAULT 0)',
        );
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS workout_entries (id TEXT PRIMARY KEY, sort_order INTEGER NOT NULL, exercise_id TEXT NOT NULL REFERENCES exercises(id), workout_id TEXT NOT NULL REFERENCES workouts(id), note TEXT, effort INTEGER)',
        );
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS workout_sets (id TEXT PRIMARY KEY, entry_id TEXT NOT NULL REFERENCES workout_entries(id), reps INTEGER NOT NULL, weight_kg REAL NOT NULL, completed_at TEXT)',
        );
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS cardio_details (id TEXT PRIMARY KEY, entry_id TEXT NOT NULL UNIQUE REFERENCES workout_entries(id), duration_minutes INTEGER NOT NULL)',
        );
      }
      if (from < 10) {
        // Create planning tables (replaced by v12 schema)
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS planned_workouts (id TEXT PRIMARY KEY, scheduled_date TEXT NOT NULL, name TEXT NOT NULL, notes TEXT, source TEXT DEFAULT \'manual\', template_id TEXT, is_completed INTEGER DEFAULT 0, completed_workout_id TEXT REFERENCES workouts(id))',
        );
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS planned_entries (id TEXT PRIMARY KEY, planned_workout_id TEXT NOT NULL REFERENCES planned_workouts(id), exercise_id TEXT NOT NULL REFERENCES exercises(id), sort_order INTEGER NOT NULL, planned_reps INTEGER NOT NULL, planned_weight_kg REAL NOT NULL, planned_rest_seconds INTEGER, note TEXT, effort_target INTEGER)',
        );
        await m.database.customStatement(
          'CREATE TABLE IF NOT EXISTS planned_cardio (id TEXT PRIMARY KEY, planned_entry_id TEXT NOT NULL UNIQUE REFERENCES planned_entries(id), planned_duration_minutes INTEGER NOT NULL)',
        );
      }
      if (from < 11) {
        // One-time data migration: copy old seances to old workout tables.
        // This migration is now a no-op — v12 drops all old workout tables.
        // The old migration files (migrate_seances.dart, seance_converter.dart)
        // have been removed.
      }
      if (from < 12) {
        // -----------------------------------------------------------------
        // v12: Replace the entire workout/planning schema with unified
        // Workouts + WeightSets + CardioSets.
        // Clean slate — drop all old workout-related tables first.
        // -----------------------------------------------------------------

        // Drop old tables (child tables first to avoid FK issues)
        await m.deleteTable('planned_cardio');
        await m.deleteTable('planned_entries');
        await m.deleteTable('planned_workouts');
        await m.deleteTable('cardio_details');
        await m.deleteTable('workout_sets');
        await m.deleteTable('workout_entries');
        await m.deleteTable('workouts');

        // Also drop seance-era tables that are no longer needed
        await m.deleteTable('exercise_sets');
        await m.deleteTable('exercise_entries');
        await m.deleteTable('seances');
        await m.deleteTable('template_sets');
        await m.deleteTable('template_exercises');
        await m.deleteTable('templates');

        // Create new tables
        await m.createTable(exerciseBodyParts);
        await m.createTable(workouts);
        await m.createTable(weightSets);
        await m.createTable(cardioSets);

        // Update exercises table: add description, image_url; drop category
        await m.database.customStatement(
          "ALTER TABLE exercises ADD COLUMN description TEXT NOT NULL DEFAULT ''",
        );
        await m.database.customStatement(
          'ALTER TABLE exercises ADD COLUMN image_url TEXT',
        );
        await m.database.customStatement(
          'ALTER TABLE exercises DROP COLUMN category',
        );
      }
      if (from < 13) {
        // Add notes column to weight_sets and cardio_sets
        await m.database.customStatement(
          "ALTER TABLE weight_sets ADD COLUMN notes TEXT",
        );
        await m.database.customStatement(
          "ALTER TABLE cardio_sets ADD COLUMN notes TEXT",
        );
      }
    },
  );

  Future<void> _seedExercises() async {
    final bundled = _bundledExercises;

    final existing = await select(exercises).get();
    final existingNames = existing.map((e) => e.name.toLowerCase()).toSet();

    for (final (name, type, met) in bundled) {
      if (existingNames.contains(name.toLowerCase())) continue;

      await into(exercises).insert(
        ExercisesCompanion.insert(
          id: const Uuid().v4(),
          name: name,
          type: Value(type),
          met: Value(met),
          creatorId: const Value('__system__'),
        ),
      );
    }
  }

  Future<void> _seedIngredients() async {
    const seed = <(String, double, double, double, double)>[
      ('Chicken Breast', 165, 31, 0, 3.6),
      ('White Rice', 130, 2.7, 28, 0.3),
      ('Eggs', 155, 13, 1.1, 11),
      ('Milk', 42, 3.4, 5, 1),
      ('Whey Protein', 400, 80, 10, 5),
      ('Peanut Butter', 588, 25, 20, 50),
      ('Oats', 389, 17, 66, 7),
      ('Banana', 89, 1.1, 23, 0.3),
      ('Olive Oil', 884, 0, 0, 100),
      ('Broccoli', 34, 2.8, 7, 0.4),
      ('Sweet Potato', 86, 1.6, 20, 0.1),
      ('Salmon', 208, 20, 0, 13),
    ];
    for (final (name, cal, prot, carbs, fat) in seed) {
      await into(ingredients).insert(
        IngredientsCompanion.insert(
          id: const Uuid().v4(),
          name: name,
          caloriesPer100g: cal,
          proteinPer100g: prot,
          carbsPer100g: carbs,
          fatPer100g: fat,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Exercises
  // ---------------------------------------------------------------------------

  Stream<List<Exercise>> watchExercises() => select(exercises).watch();
  Future<List<Exercise>> getAllExercises() => select(exercises).get();
  Future<void> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);
  Future<void> upsertExercises(List<ExercisesCompanion> entries) => batch((b) {
    for (final e in entries) {
      b.insert(exercises, e, mode: InsertMode.insertOrReplace);
    }
  });

  // ---------------------------------------------------------------------------
  // Workouts
  // ---------------------------------------------------------------------------

  Stream<List<WorkoutRow>> watchWorkouts() => select(workouts).watch();
  Future<WorkoutRow?> getWorkoutById(String id) =>
      (select(workouts)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<List<WorkoutRow>> getWorkoutsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(workouts)..where(
          (t) =>
              t.scheduledDate.isBetweenValues(start, end) |
              t.startedAt.isBetweenValues(start, end),
        ))
        .get();
  }

  Future<List<WorkoutRow>> getActiveWorkouts() => (select(
    workouts,
  )..where((t) => t.startedAt.isNotNull() & t.completedAt.isNull())).get();

  Future<void> insertWorkout(WorkoutsCompanion entry) =>
      into(workouts).insert(entry);
  Future<void> updateWorkout(WorkoutsCompanion entry) =>
      update(workouts).replace(entry);
  Future<void> deleteWorkout(String id) =>
      (delete(workouts)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Weight sets
  // ---------------------------------------------------------------------------

  Stream<List<WeightSetRow>> watchWeightSets(String workoutId) =>
      (select(weightSets)..where((t) => t.workoutId.equals(workoutId))).watch();
  Future<List<WeightSetRow>> getWeightSets(String workoutId) =>
      (select(weightSets)..where((t) => t.workoutId.equals(workoutId))).get();
  Future<void> insertWeightSet(WeightSetsCompanion entry) =>
      into(weightSets).insert(entry);
  Future<void> updateWeightSet(WeightSetsCompanion entry) =>
      update(weightSets).replace(entry);
  Future<void> deleteWeightSetsByWorkout(String workoutId) =>
      (delete(weightSets)..where((t) => t.workoutId.equals(workoutId))).go();

  // ---------------------------------------------------------------------------
  // Cardio sets
  // ---------------------------------------------------------------------------

  Stream<List<CardioSetRow>> watchCardioSets(String workoutId) =>
      (select(cardioSets)..where((t) => t.workoutId.equals(workoutId))).watch();
  Future<List<CardioSetRow>> getCardioSets(String workoutId) =>
      (select(cardioSets)..where((t) => t.workoutId.equals(workoutId))).get();
  Future<void> insertCardioSet(CardioSetsCompanion entry) =>
      into(cardioSets).insert(entry);
  Future<void> updateCardioSet(CardioSetsCompanion entry) =>
      update(cardioSets).replace(entry);
  Future<void> deleteCardioSetsByWorkout(String workoutId) =>
      (delete(cardioSets)..where((t) => t.workoutId.equals(workoutId))).go();

  // ---------------------------------------------------------------------------
  // Exercise body parts
  // ---------------------------------------------------------------------------

  Future<List<ExerciseBodyPart>> getBodyParts(String exerciseId) => (select(
    exerciseBodyParts,
  )..where((t) => t.exerciseId.equals(exerciseId))).get();
  Future<void> insertBodyPart(ExerciseBodyPartsCompanion entry) =>
      into(exerciseBodyParts).insert(entry);
  Future<void> deleteBodyPartsByExercise(String exerciseId) => (delete(
    exerciseBodyParts,
  )..where((t) => t.exerciseId.equals(exerciseId))).go();

  // ---------------------------------------------------------------------------
  // Ingredients
  // ---------------------------------------------------------------------------

  Stream<List<Ingredient>> watchIngredients() => select(ingredients).watch();
  Stream<List<Ingredient>> watchNonArchivedIngredients() =>
      (select(ingredients)..where((t) => t.isArchived.equals(false))).watch();
  Future<List<Ingredient>> getAllIngredients() => select(ingredients).get();
  Future<List<Ingredient>> getNonArchivedIngredients() =>
      (select(ingredients)..where((t) => t.isArchived.equals(false))).get();
  Future<List<Ingredient>> getIngredientByIds(List<String> ids) =>
      (select(ingredients)..where((t) => t.id.isIn(ids))).get();
  Future<List<IngredientComponent>> getComponentsForIngredient(String id) =>
      (select(
        ingredientComponents,
      )..where((t) => t.ingredientId.equals(id))).get();
  Future<List<Ingredient>> getArchivedIngredients() =>
      (select(ingredients)..where((t) => t.isArchived.equals(true))).get();
  Future<void> insertIngredient(IngredientsCompanion entry) =>
      into(ingredients).insert(entry);
  Future<void> updateIngredient(IngredientsCompanion entry) =>
      update(ingredients).replace(entry);
  Future<void> archiveIngredient(String id) =>
      (update(ingredients)..where((t) => t.id.equals(id))).write(
        IngredientsCompanion(isArchived: Value(true)),
      );
  Future<void> unarchiveIngredient(String id) =>
      (update(ingredients)..where((t) => t.id.equals(id))).write(
        IngredientsCompanion(isArchived: Value(false)),
      );
  Future<void> deleteIngredient(String id) =>
      (delete(ingredients)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Meals
  // ---------------------------------------------------------------------------

  Stream<List<Meal>> watchMeals() => select(meals).watch();
  Future<List<Meal>> getMealsByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(
      meals,
    )..where((t) => t.eatenAt.isBetweenValues(start, end))).get();
  }

  Future<void> insertMeal(MealsCompanion entry) => into(meals).insert(entry);
  Future<void> deleteMeal(String id) =>
      (delete(meals)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Meal ingredients
  // ---------------------------------------------------------------------------

  Stream<List<MealIngredient>> watchMealIngredients(String mealId) =>
      (select(mealIngredients)..where((t) => t.mealId.equals(mealId))).watch();
  Future<void> insertMealIngredient(MealIngredientsCompanion entry) =>
      into(mealIngredients).insert(entry);
  Future<void> deleteMealIngredient(String id) =>
      (delete(mealIngredients)..where((t) => t.id.equals(id))).go();
  Future<void> deleteMealIngredientsByMeal(String mealId) =>
      (delete(mealIngredients)..where((t) => t.mealId.equals(mealId))).go();

  // ---------------------------------------------------------------------------
  // Goals
  // ---------------------------------------------------------------------------

  Stream<List<Goal>> watchGoals() => select(goals).watch();
  Future<void> insertGoal(GoalsCompanion entry) => into(goals).insert(entry);
  Future<void> updateGoal(GoalsCompanion entry) => update(goals).replace(entry);
  Future<void> deleteGoal(String id) =>
      (delete(goals)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // User profile
  // ---------------------------------------------------------------------------

  Stream<UserProfileData?> watchProfile() =>
      (select(userProfile)..limit(1)).watchSingleOrNull();
  Future<void> upsertProfile(UserProfileCompanion entry) =>
      into(userProfile).insert(entry, mode: InsertMode.insertOrReplace);

  // ---------------------------------------------------------------------------
  // Body weight entries
  // ---------------------------------------------------------------------------

  Stream<List<BodyWeightEntry>> watchBodyWeight() =>
      select(bodyWeightEntries).watch();
  Future<void> insertBodyWeight(BodyWeightEntriesCompanion entry) =>
      into(bodyWeightEntries).insert(entry);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'fitfat.db');
    try {
      if (kDebugMode) {
        print('[DB] Opening database at: $dbPath');
      }
    } catch (e, st) {
      _log.warning('Failed to log database path', e, st);
    }
    return NativeDatabase(File(dbPath));
  });
}

/// (name, type, met)
const _bundledExercises = <(String, String, double)>[
  // Cardio
  ('Running', 'cardio', 8.0),
  ('Walking', 'cardio', 3.5),
  ('Cycling', 'cardio', 7.5),
  ('Swimming', 'cardio', 6.0),
  ('Jump Rope', 'cardio', 10.0),
  ('Rowing', 'cardio', 6.0),
  ('Elliptical', 'cardio', 5.0),
  ('Stair Climber', 'cardio', 6.0),
  // Chest
  ('Bench Press', 'weightlifting', 5.5),
  ('Incline Bench Press', 'weightlifting', 5.5),
  ('Decline Bench Press', 'weightlifting', 5.5),
  ('Dumbbell Fly', 'weightlifting', 4.0),
  ('Cable Crossover', 'weightlifting', 4.0),
  ('Push Up', 'weightlifting', 3.5),
  ('Dumbbell Bench Press', 'weightlifting', 5.0),
  // Back
  ('Deadlift', 'weightlifting', 6.0),
  ('Barbell Row', 'weightlifting', 5.0),
  ('Pull Up', 'weightlifting', 5.0),
  ('Lat Pulldown', 'weightlifting', 4.5),
  ('Seated Cable Row', 'weightlifting', 4.5),
  ('T-Bar Row', 'weightlifting', 5.0),
  ('Face Pull', 'weightlifting', 3.0),
  ('Dumbbell Row', 'weightlifting', 5.0),
  // Shoulders
  ('Overhead Press', 'weightlifting', 5.0),
  ('Lateral Raise', 'weightlifting', 3.0),
  ('Front Raise', 'weightlifting', 3.0),
  ('Reverse Fly', 'weightlifting', 3.0),
  ('Arnold Press', 'weightlifting', 4.5),
  ('Shrug', 'weightlifting', 3.0),
  // Legs
  ('Squat', 'weightlifting', 6.0),
  ('Leg Press', 'weightlifting', 5.0),
  ('Leg Extension', 'weightlifting', 4.0),
  ('Leg Curl', 'weightlifting', 4.0),
  ('Romanian Deadlift', 'weightlifting', 5.0),
  ('Calf Raise', 'weightlifting', 3.0),
  ('Lunge', 'weightlifting', 4.5),
  ('Bulgarian Split Squat', 'weightlifting', 5.0),
  ('Hip Thrust', 'weightlifting', 4.5),
  // Arms
  ('Barbell Curl', 'weightlifting', 3.0),
  ('Dumbbell Curl', 'weightlifting', 3.0),
  ('Hammer Curl', 'weightlifting', 3.0),
  ('Triceps Pushdown', 'weightlifting', 3.0),
  ('Overhead Triceps Extension', 'weightlifting', 3.0),
  ('Skull Crusher', 'weightlifting', 3.0),
  ('Concentration Curl', 'weightlifting', 2.5),
  ('Preacher Curl', 'weightlifting', 3.0),
  // Core
  ('Crunch', 'weightlifting', 2.5),
  ('Russian Twist', 'weightlifting', 2.5),
  ('Plank', 'weightlifting', 2.5),
  ('Leg Raise', 'weightlifting', 2.5),
  ('Cable Woodchop', 'weightlifting', 3.0),
  ('Ab Wheel Rollout', 'weightlifting', 3.0),
];
