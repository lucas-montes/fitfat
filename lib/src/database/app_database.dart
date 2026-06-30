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
    ExerciseTranslations,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedExercises();
      await _seedIngredients();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Fresh start: drop all existing tables and recreate from scratch.
      // Data loss is intentional — old schema versions are incompatible with
      // the current clean-slate schema (v1).
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
      }
      await m.createAll();
      await _seedExercises();
      await _seedIngredients();
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
  // Exercise translations
  // ---------------------------------------------------------------------------

  Future<List<ExerciseTranslation>> getTranslations(String locale) => (select(
    exerciseTranslations,
  )..where((t) => t.locale.equals(locale))).get();

  Future<ExerciseTranslation?> getTranslation(
    String exerciseId,
    String locale,
  ) =>
      (select(exerciseTranslations)..where(
            (t) => t.exerciseId.equals(exerciseId) & t.locale.equals(locale),
          ))
          .getSingleOrNull();

  Future<void> insertTranslation(ExerciseTranslationsCompanion entry) =>
      into(exerciseTranslations).insert(entry);

  Future<void> upsertTranslations(
    List<ExerciseTranslationsCompanion> entries,
  ) => batch((b) {
    for (final e in entries) {
      b.insert(exerciseTranslations, e, mode: InsertMode.insertOrReplace);
    }
  });

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
