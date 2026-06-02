import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../exercise/services/workout_services.dart';
import '../services/logger.dart';
import 'tables.dart';

part 'app_database.g.dart';

final _log = logger('app_database');

@DriftDatabase(
  tables: [
    Exercises,
    Ingredients,
    IngredientComponents,
    Meals,
    MealIngredients,
    Seances,
    ExerciseEntries,
    ExerciseSets,
    Templates,
    TemplateExercises,
    TemplateSets,
    Goals,
    UserProfile,
    BodyWeightEntries,
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
  int get schemaVersion => 3;

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
    },
  );

  Future<void> _seedExercises() async {
    // Use comprehensive bundle from ExerciseLibraryService
    final bundled = ExerciseLibraryService.getAllBundled();

    // Get existing exercise names to skip duplicates
    final existing = await select(exercises).get();
    final existingNames = existing.map((e) => e.name.toLowerCase()).toSet();

    for (final (name, category) in bundled) {
      if (existingNames.contains(name.toLowerCase())) continue;

      await into(exercises).insert(
        ExercisesCompanion.insert(
          id: const Uuid().v4(),
          name: name,
          category: category,
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
  // Seances
  // ---------------------------------------------------------------------------

  Stream<List<Seance>> watchSeances() => select(seances).watch();
  Stream<Seance?> watchActiveSeance() => (select(
    seances,
  )..where((t) => t.completedAt.isNull())).watchSingleOrNull();
  Future<void> insertSeance(SeancesCompanion entry) =>
      into(seances).insert(entry);
  Future<void> updateSeance(SeancesCompanion entry) =>
      update(seances).replace(entry);

  // ---------------------------------------------------------------------------
  // Exercise entries
  // ---------------------------------------------------------------------------

  Stream<List<ExerciseEntry>> watchExerciseEntries(String seanceId) => (select(
    exerciseEntries,
  )..where((t) => t.seanceId.equals(seanceId))).watch();
  Future<void> insertExerciseEntry(ExerciseEntriesCompanion entry) =>
      into(exerciseEntries).insert(entry);
  Future<void> deleteExerciseEntriesBySeance(String seanceId) =>
      (delete(exerciseEntries)..where((t) => t.seanceId.equals(seanceId))).go();

  // ---------------------------------------------------------------------------
  // Exercise sets
  // ---------------------------------------------------------------------------

  Stream<List<ExerciseSet>> watchExerciseSets(String entryId) =>
      (select(exerciseSets)..where((t) => t.entryId.equals(entryId))).watch();
  Future<void> insertExerciseSet(ExerciseSetsCompanion entry) =>
      into(exerciseSets).insert(entry);
  Future<void> deleteExerciseSetsByEntry(String entryId) =>
      (delete(exerciseSets)..where((t) => t.entryId.equals(entryId))).go();

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  Stream<List<Template>> watchTemplates() => select(templates).watch();
  Future<void> insertTemplate(TemplatesCompanion entry) =>
      into(templates).insert(entry);
  Future<void> updateTemplate(TemplatesCompanion entry) =>
      update(templates).replace(entry);
  Future<void> deleteTemplate(String id) =>
      (delete(templates)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // Template exercises
  // ---------------------------------------------------------------------------

  Stream<List<TemplateExercise>> watchTemplateExercises(String templateId) =>
      (select(
        templateExercises,
      )..where((t) => t.templateId.equals(templateId))).watch();
  Future<void> insertTemplateExercise(TemplateExercisesCompanion entry) =>
      into(templateExercises).insert(entry);
  Future<void> deleteTemplateExercisesByTemplate(String templateId) => (delete(
    templateExercises,
  )..where((t) => t.templateId.equals(templateId))).go();

  // ---------------------------------------------------------------------------
  // Template planned sets
  // ---------------------------------------------------------------------------

  Stream<List<TemplateSet>> watchTemplateSets(String templateExerciseId) =>
      (select(
        templateSets,
      )..where((t) => t.templateExerciseId.equals(templateExerciseId))).watch();
  Future<void> insertTemplateSet(TemplateSetsCompanion entry) =>
      into(templateSets).insert(entry);
  Future<void> deleteTemplateSetsByExercise(String templateExerciseId) =>
      (delete(
        templateSets,
      )..where((t) => t.templateExerciseId.equals(templateExerciseId))).go();

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
    // Debug: log the database file path so we can confirm where the DB is stored
    try {
      // Use print so it's visible in Flutter logs during development
      if (kDebugMode) {
        print('[DB] Opening database at: $dbPath');
      }
    } catch (e, st) {
      _log.warning('Failed to log database path', e, st);
    }
    return NativeDatabase(File(dbPath));
  });
}
