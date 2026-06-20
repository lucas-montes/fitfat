import 'package:drift/drift.dart';

import '../models/enums.dart';

// ---------------------------------------------------------------------------
// Exercises (seed data, can be synced from remote)
// ---------------------------------------------------------------------------

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('weightlifting'))();
  RealColumn get met => real().withDefault(const Constant(5.0))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get creatorId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Exercise body parts (join table)
// ---------------------------------------------------------------------------

class ExerciseBodyParts extends Table {
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get bodyPart => text()();

  @override
  Set<Column> get primaryKey => {exerciseId, bodyPart};
}

// ---------------------------------------------------------------------------
// Workouts (unified model — free-form or scheduled)
// ---------------------------------------------------------------------------

@DataClassName('WorkoutRow')
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Weight sets (individual weightlifting sets within a workout)
// ---------------------------------------------------------------------------

@DataClassName('WeightSetRow')
class WeightSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get plannedReps => integer()();
  RealColumn get plannedWeightKg => real()();
  IntColumn get plannedRestSeconds => integer().nullable()();
  IntColumn get actualReps => integer().nullable()();
  RealColumn get actualWeightKg => real().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Cardio sets (individual cardio/duration sets within a workout)
// ---------------------------------------------------------------------------

@DataClassName('CardioSetRow')
class CardioSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get plannedDurationMinutes => integer()();
  IntColumn get actualDurationMinutes => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();

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
  TextColumn get gender => textEnum<Gender>()();
  RealColumn get heightCm => real()();
  TextColumn get activityLevel =>
      text()(); // 'sedentary' | 'light' | 'moderate' | 'active' | 'veryActive'

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Body weight entries
// ---------------------------------------------------------------------------

class BodyWeightEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Water consumption
// ---------------------------------------------------------------------------

class WaterConsumption extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get liters => real()();

  @override
  Set<Column> get primaryKey => {id};
}
