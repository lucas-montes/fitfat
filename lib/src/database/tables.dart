import 'package:drift/drift.dart';

import '../models/enums.dart';

// ---------------------------------------------------------------------------
// Exercises list (seed data, can be synced from remote)
// ---------------------------------------------------------------------------

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get type => text().withDefault(const Constant('weightlifting'))();
  RealColumn get met => real().withDefault(const Constant(5.0))();
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

//NOTE: maybe completedAt is nullable because we save the values in the databae to be able to close the app and not lose progress, if it's the case maybe we could save it somewhere else in the meantime

class Seances extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
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
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Exercise entries (exercises within a seance)
// ---------------------------------------------------------------------------
// Exercise sets (individual sets within an exercise entry)
// ---------------------------------------------------------------------------

class ExerciseSets extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(ExerciseEntries, #id)();
  IntColumn get reps => integer()();
  RealColumn get weight => real()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// A predefined workout template

class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

//TODO: not sure about this one, maybe we need to link it with an actual exercise
class TemplateExercises extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(Templates, #id)();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class TemplateSets extends Table {
  TextColumn get id => text()();
  TextColumn get templateExerciseId =>
      text().references(TemplateExercises, #id)();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real()();
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
  TextColumn get gender => textEnum<Gender>()();
  RealColumn get heightCm => real()();
  TextColumn get activityLevel =>
      text()(); // 'sedentary' | 'light' | 'moderate' | 'active' | 'veryActive'

  @override
  Set<Column> get primaryKey => {id};
}

class BodyWeightEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weightKg => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class WaterConsumption extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get liters => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Workouts (new unified activity model — replaces Seances eventually)
// ---------------------------------------------------------------------------

class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get plannedWorkoutId => text().nullable()();
  BoolColumn get isGuided => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Workout entries (exercises within a workout)
// ---------------------------------------------------------------------------

class WorkoutEntries extends Table {
  TextColumn get id => text()();
  IntColumn get sortOrder => integer()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get note => text().nullable()();
  IntColumn get effort => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Workout sets (individual sets within a weightlifting entry)
// ---------------------------------------------------------------------------

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(WorkoutEntries, #id)();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Cardio details (duration-based entries within a workout)
// ---------------------------------------------------------------------------

class CardioDetails extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(WorkoutEntries, #id).unique()();
  IntColumn get durationMinutes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Planned workouts (scheduled workouts with prescribed weights)
// ---------------------------------------------------------------------------

class PlannedWorkouts extends Table {
  TextColumn get id => text()();
  DateTimeColumn get scheduledDate => dateTime()();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get templateId => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get completedWorkoutId =>
      text().references(Workouts, #id).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Planned entries (prescribed exercises within a planned workout)
// ---------------------------------------------------------------------------

class PlannedEntries extends Table {
  TextColumn get id => text()();
  TextColumn get plannedWorkoutId => text().references(PlannedWorkouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get plannedReps => integer()();
  RealColumn get plannedWeightKg => real()();
  IntColumn get plannedRestSeconds => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get effortTarget => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Planned cardio (duration-based prescribed entry within a planned workout)
// ---------------------------------------------------------------------------

class PlannedCardio extends Table {
  TextColumn get id => text()();
  TextColumn get plannedEntryId =>
      text().references(PlannedEntries, #id).unique()();
  IntColumn get plannedDurationMinutes => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
