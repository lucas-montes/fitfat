import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Exercises list (seed data, can be synced from remote)
// ---------------------------------------------------------------------------

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get creatorId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Ingredients (food database)
// ---------------------------------------------------------------------------

class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get creatorId => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  RealColumn get caloriesPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  RealColumn get sodiumPer100g => real().nullable()();
  RealColumn get fiberPer100g => real().nullable()();
  RealColumn get sugarsPer100g => real().nullable()();
  RealColumn get saturatedFatPer100g => real().nullable()();
  RealColumn get cholesterolPer100g => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Ingredient components (composite/recipe ingredients)
// ---------------------------------------------------------------------------

class IngredientComponents extends Table {
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  TextColumn get componentId => text().references(Ingredients, #id)();
  RealColumn get grams => real()();

  @override
  Set<Column> get primaryKey => {ingredientId, componentId};
}

// ---------------------------------------------------------------------------
// Meals
// ---------------------------------------------------------------------------

class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Meal ingredients (junction table)
// ---------------------------------------------------------------------------

class MealIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(Meals, #id)();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get grams => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Seances
// ---------------------------------------------------------------------------

class Seances extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get restBetweenSetsMillis =>
      integer().withDefault(const Constant(60000))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Exercise entries (exercises within a seance)
// ---------------------------------------------------------------------------

class ExerciseEntries extends Table {
  TextColumn get id => text()();
  TextColumn get seanceId => text().references(Seances, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Exercise sets (individual sets within an exercise entry)
// ---------------------------------------------------------------------------

class ExerciseSets extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(ExerciseEntries, #id)();
  IntColumn get reps => integer()();
  RealColumn get weight => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Template exercises (exercises added to a template)
// ---------------------------------------------------------------------------

class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(Templates, #id)();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Template planned sets (planned sets within a template exercise)
// ---------------------------------------------------------------------------

class TemplateSets extends Table {
  TextColumn get id => text()();
  TextColumn get templateExerciseId =>
      text().references(TemplateExercises, #id)();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'strength' | 'bodyweight'
  TextColumn get exerciseName => text().nullable()();
  RealColumn get targetWeightKg => real()();
  TextColumn get direction => text()
      .nullable()(); // 'gain' | 'lose' | 'maintain' (nullable for strength)
  DateTimeColumn get targetDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// User profile (singleton — one row)
// ---------------------------------------------------------------------------

class UserProfile extends Table {
  TextColumn get id => text()();
  DateTimeColumn get birthDate => dateTime()();
  TextColumn get sex => text()(); // 'male' | 'female'
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get activityLevel =>
      text()(); // 'sedentary' | 'light' | 'moderate' | 'active' | 'veryActive'

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Body weight entries (track weight over time)
// ---------------------------------------------------------------------------

class BodyWeightEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();

  @override
  Set<Column> get primaryKey => {id};
}
