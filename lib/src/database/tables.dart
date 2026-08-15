import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Diet tables
// ---------------------------------------------------------------------------

class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get caloriesPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  // Optional extra nutriments per 100g (v3). Ingredient-only; not propagated to meals.
  RealColumn? get sodiumPer100g => real().nullable()(); // mg
  RealColumn? get fiberPer100g => real().nullable()(); // g
  RealColumn? get sugarPer100g => real().nullable()(); // g
  // Soft-delete flag (v4). Archived ingredients are hidden from list and
  // picker but their rows stay so past meals keep rendering names/macros.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get eatenAt => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

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

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get exerciseType => text()(); // 'weightlifting' | 'cardio'
  // Seeded/built-in exercises are locked (v8): cannot be edited or deleted.
  // User-created exercises default to 0.
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  // Catalog metadata (v8), populated for seeded exercises. Nullable so
  // user-created rows stay lean. instructions/tips/keywords store JSON arrays.
  TextColumn? get bodyPart => text().nullable()();
  TextColumn? get equipment => text().nullable()();
  TextColumn? get primaryMuscle => text().nullable()();
  TextColumn? get secondaryMuscle => text().nullable()();
  TextColumn? get instructions => text().nullable()(); // JSON string[]
  TextColumn? get tips => text().nullable()(); // JSON string[]
  TextColumn? get faqs => text().nullable()();
  TextColumn? get keywords => text().nullable()(); // JSON string[]
  TextColumn? get imagePath => text().nullable()(); // asset path
  TextColumn? get videoPath => text().nullable()(); // asset path
  // Canonicalization fields (v10): mark one exercise as canonical per group,
  // link variants via similarTo, and allow user tags.
  TextColumn? get similarTo => text().nullable()();
  TextColumn? get tags => text().nullable()(); // JSON string[]
  BoolColumn get isCanonical => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

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

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn? get reps => integer().nullable()();
  RealColumn? get weightKg => real().nullable()();
  // Planned rest between sets in seconds (v5). Required at the form level;
  // nullable in the DB so legacy rows and pre-v5 snapshots round-trip.
  IntColumn? get restSeconds => integer().nullable()();
  IntColumn? get actualReps => integer().nullable()();
  RealColumn? get actualWeightKg => real().nullable()();
  // Actual rest taken between sets in seconds (v5); recorded when the rest
  // period ends/cancels. Null until a rest is started and finished.
  IntColumn? get actualRestSeconds => integer().nullable()();
  // Time the set's actuals were saved (v7), epoch millis. Stamped whenever
  // updateSetActuals writes any actual; null for planned-only sets.
  IntColumn? get completedAt => integer().nullable()();
  IntColumn? get durationMinutes => integer().nullable()();
  RealColumn? get distanceMeters => real().nullable()();
  TextColumn? get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Planner tables
// ---------------------------------------------------------------------------

class PlannerItems extends Table {
  TextColumn get id => text()();
  IntColumn get date => integer()(); // start-of-day epoch milliseconds
  TextColumn get title => text()();
  IntColumn get done => integer()(); // 0 | 1
  IntColumn get sortOrder => integer()();
  IntColumn? get dueDate =>
      integer().nullable()(); // optional due date, epoch milliseconds
  // Optional due time-of-day (v8), minutes since midnight. Null = no time.
  IntColumn? get dueTimeMinutes => integer().nullable()();
  // Optional free-text note (v6).
  TextColumn? get notes => text().nullable()();
  // Optional linked workout (v11).
  TextColumn? get workoutId => text().nullable()();
  // Optional free-form tags as a JSON string[] (v12).
  TextColumn? get tags => text().nullable()();
  // Optional repeat rule as a JSON object (v13).
  TextColumn? get recurrence => text().nullable()();
  // Groups occurrences of one recurring series (v13).
  TextColumn? get seriesId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Notes tables
// ---------------------------------------------------------------------------

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  IntColumn get updatedAt => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Budget tables (schema v14)
// ---------------------------------------------------------------------------

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // Account kind: 'savings' | 'investment' | 'cash' | 'bank' | 'credit' | 'other'
  TextColumn get type => text()();
  // Opening balance expressed in the base currency (see Settings.baseCurrency).
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  TextColumn? get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  // 'income' | 'expense' | 'transfer'
  TextColumn get type => text()();
  // Amount in the transaction's own currency (currencyCode).
  RealColumn get amount => real()();
  // ISO-4217-ish currency code, e.g. 'USD'.
  TextColumn get currencyCode => text()();
  // amount converted to the base currency at save time (rateUsed).
  RealColumn get amountBase => real()();
  // rate used to convert currencyCode -> base (1.0 when currencyCode == base).
  RealColumn get rateUsed => real()();
  // Source account (for income/expense/transfer). Null while a transaction is
  // still a draft pending account selection.
  @ReferenceName('sourceTransactions')
  TextColumn? get accountId => text().references(Accounts, #id).nullable()();
  // Destination account, only for transfers.
  @ReferenceName('destinationTransactions')
  TextColumn? get toAccountId => text().references(Accounts, #id).nullable()();
  TextColumn? get category => text().nullable()();
  IntColumn get date => integer()(); // epoch milliseconds
  TextColumn? get note => text().nullable()();
  TextColumn? get receiptId => text().references(Receipts, #id).nullable()();
  // Draft transactions are pre-filled from a parsed receipt but not yet
  // confirmed / linked to an account by the user.
  BoolColumn get isDraft => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Receipts extends Table {
  TextColumn get id => text()();
  // Local filesystem path of the saved image.
  TextColumn get localPath => text()();
  // Remote path/identifier once uploaded; null until uploaded.
  TextColumn? get remotePath => text().nullable()();
  // 0 local | 1 uploading | 2 uploaded | 3 error
  IntColumn get uploadStatus => integer().withDefault(const Constant(0))();
  BoolColumn get parsed => boolean().withDefault(const Constant(false))();
  // Raw parsed JSON returned by the remote OCR service.
  TextColumn? get parsedJson => text().nullable()();
  // Draft or real transaction created from this receipt. Plain column (no FK)
  // to avoid a circular reference with `transactions.receiptId`.
  TextColumn? get transactionId => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class FxRates extends Table {
  // Non-base currency code, e.g. 'EUR'.
  TextColumn get code => text()();
  // Rate to convert 1 unit of `code` into the base currency.
  RealColumn get rateToBase => real()();
  // The base currency this rate is expressed against.
  TextColumn get baseCode => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

// ---------------------------------------------------------------------------
// Body metrics tables
// ---------------------------------------------------------------------------

class BodyMetrics extends Table {
  TextColumn get id => text()();
  IntColumn get date => integer()(); // start-of-day epoch milliseconds
  RealColumn? get weightKg => real().nullable()();
  RealColumn? get heightCm => real().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
