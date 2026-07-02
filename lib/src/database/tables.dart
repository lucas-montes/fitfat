import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Diet tables
// ---------------------------------------------------------------------------

@DataClass()
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get caloriesPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClass()
class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get eatenAt => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClass()
class MealIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(Meals, #id)();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get grams => real()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Exercise tables
// ---------------------------------------------------------------------------

@DataClass()
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get exerciseType => text()(); // 'weightlifting' | 'cardio'
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClass()
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get date => integer()();
  IntColumn? get startedAt => integer().nullable()();
  IntColumn? get completedAt => integer().nullable()();
  TextColumn? get notes => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClass()
class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClass()
class ExerciseSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn? get reps => integer().nullable()();
  RealColumn? get weightKg => real().nullable()();
  IntColumn? get actualReps => integer().nullable()();
  RealColumn? get actualWeightKg => real().nullable()();
  IntColumn? get durationMinutes => integer().nullable()();
  RealColumn? get distanceMeters => real().nullable()();
  TextColumn? get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
