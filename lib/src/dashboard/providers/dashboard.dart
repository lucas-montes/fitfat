import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../diet/providers/meals.dart';
import '../../models/dashboard.dart';
import '../../models/food.dart';
import '../../database/providers.dart';
import '../../adapters/drift/goals.dart';
import '../../adapters/drift/profile.dart';

// ---------------------------------------------------------------------------
// Chart period
// ---------------------------------------------------------------------------

final chartPeriodProvider = NotifierProvider<ChartPeriodNotifier, ChartPeriod>(
  ChartPeriodNotifier.new,
);

class ChartPeriodNotifier extends Notifier<ChartPeriod> {
  @override
  ChartPeriod build() => ChartPeriod.thirtyDays;

  void updatePeriod(ChartPeriod period) {
    state = period;
  }
}

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    _loadFromDb();
    return null;
  }

  void setProfile(UserProfile profile) {
    state = profile;
    _persist(profile);
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final repo = DriftProfileRepository(db);
      final saved = await repo.get();
      if (saved != null) state = saved;
    } catch (_) {}
  }

  Future<void> _persist(UserProfile profile) async {
    try {
      final db = ref.read(databaseProvider);
      final repo = DriftProfileRepository(db);
      await repo.upsert(profile);
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------------
// Goals (bodyweight + N strength goals)
// ---------------------------------------------------------------------------

final goalsProvider = NotifierProvider<GoalsNotifier, GoalsData>(
  GoalsNotifier.new,
);

class GoalsNotifier extends Notifier<GoalsData> {
  @override
  GoalsData build() {
    _loadFromDb();
    return const GoalsData();
  }

  Future<void> _loadFromDb() async {
    try {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      final saved = await repo.loadAll();
      final hasAnyGoal =
          saved.bodyWeightGoal != null || saved.strengthGoals.isNotEmpty;
      if (hasAnyGoal) state = saved;
    } catch (_) {}
  }

  void setBodyWeightGoal(BodyWeightGoal goal) {
    state = GoalsData(bodyWeightGoal: goal, strengthGoals: state.strengthGoals);
    _persist(() async {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      await repo.upsertBodyWeight(goal);
    });
  }

  void clearBodyWeightGoal() {
    state = GoalsData(bodyWeightGoal: null, strengthGoals: state.strengthGoals);
    _persist(() async {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      await repo.clearBodyWeight();
    });
  }

  void addStrengthGoal(StrengthGoal goal) {
    state = GoalsData(
      bodyWeightGoal: state.bodyWeightGoal,
      strengthGoals: [
        for (final g in state.strengthGoals)
          if (g.exerciseName != goal.exerciseName) g,
        goal,
      ],
    );
    _persist(() async {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      await repo.addStrength(goal);
    });
  }

  void updateStrengthGoal(String exerciseName, StrengthGoal updated) {
    state = GoalsData(
      bodyWeightGoal: state.bodyWeightGoal,
      strengthGoals: [
        for (final g in state.strengthGoals)
          if (g.exerciseName == exerciseName) updated else g,
      ],
    );
    _persist(() async {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      await repo.updateStrength(exerciseName, updated);
    });
  }

  void removeStrengthGoal(String exerciseName) {
    state = GoalsData(
      bodyWeightGoal: state.bodyWeightGoal,
      strengthGoals: state.strengthGoals
          .where((g) => g.exerciseName != exerciseName)
          .toList(),
    );
    _persist(() async {
      final db = ref.read(databaseProvider);
      final repo = DriftGoalRepository(db);
      await repo.removeStrength(exerciseName);
    });
  }

  Future<void> _persist(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      // Silently handle DB errors — state is already updated in-memory
    }
  }
}

// ---------------------------------------------------------------------------
// TDEE computation
// ---------------------------------------------------------------------------

/// Computes Basal Metabolic Rate using Mifflin-St Jeor equation.
double _bmr(UserProfile profile) {
  final base =
      10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age;
  return switch (profile.sex) {
    Sex.male => base + 5,
    Sex.female => base - 161,
  };
}

/// Computes Total Daily Energy Expenditure.
double _tdee(UserProfile profile) {
  return _bmr(profile) * profile.activityLevel.factor;
}

/// Returns the caloric target per day for the given goal and TDEE.
double _caloricTarget(Goal goal, double tdee) {
  return switch (goal) {
    StrengthGoal() => tdee,
    BodyWeightGoal(direction: BodyWeightDirection.gain) => tdee + 300,
    BodyWeightGoal(direction: BodyWeightDirection.lose) => tdee - 500,
    BodyWeightGoal(direction: BodyWeightDirection.maintain) => tdee,
  };
}

/// Returns the protein grams-per-kg-bodyweight factor for the given goal.
double _proteinFactor(Goal goal) {
  return switch (goal) {
    StrengthGoal() => 2.2,
    BodyWeightGoal(direction: BodyWeightDirection.gain) => 2.0,
    BodyWeightGoal(direction: BodyWeightDirection.lose) => 2.4,
    BodyWeightGoal(direction: BodyWeightDirection.maintain) => 1.8,
  };
}

// ---------------------------------------------------------------------------
// Computed macros — derived from profile + goal
// ---------------------------------------------------------------------------

final computedMacrosProvider = Provider<ComputedMacros>((ref) {
  final profile = ref.watch(userProfileProvider);
  final goalsData = ref.watch(goalsProvider);

  if (profile == null) {
    return ComputedMacros.zero;
  }

  final tdee = _tdee(profile);
  final goal = goalsData.bodyWeightGoal;

  if (goal == null) {
    // Maintenance mode: no goal set, show TDEE maintenance macros
    return _computeMacros(profile, tdee, 1.8); // 1.8g/kg maintain protein
  }

  final targetCalories = _caloricTarget(
    goal,
    tdee,
  ).clamp(1200, double.infinity);

  final proteinFactor = _proteinFactor(goal);
  final proteinGrams = (proteinFactor * profile.weightKg).roundToDouble();
  final fatGrams = ((targetCalories * 0.25) / 9).roundToDouble();

  final proteinCalories = proteinGrams * 4;
  final fatCalories = fatGrams * 9;
  final carbCalories = (targetCalories - proteinCalories - fatCalories).clamp(
    0,
    double.infinity,
  );
  final carbGrams = (carbCalories / 4).roundToDouble();

  return ComputedMacros(
    dailyCalories: targetCalories.roundToDouble(),
    dailyProtein: proteinGrams,
    dailyCarbs: carbGrams,
    dailyFat: fatGrams,
  );
});

/// Computes maintenance macros from TDEE with the given protein factor.
ComputedMacros _computeMacros(
  UserProfile profile,
  double tdee,
  double proteinFactor,
) {
  final targetCalories = tdee.clamp(1200, double.infinity);
  final proteinGrams = (proteinFactor * profile.weightKg).roundToDouble();
  final fatGrams = ((targetCalories * 0.25) / 9).roundToDouble();

  final proteinCalories = proteinGrams * 4;
  final fatCalories = fatGrams * 9;
  final carbCalories = (targetCalories - proteinCalories - fatCalories).clamp(
    0,
    double.infinity,
  );
  final carbGrams = (carbCalories / 4).roundToDouble();

  return ComputedMacros(
    dailyCalories: targetCalories.roundToDouble(),
    dailyProtein: proteinGrams,
    dailyCarbs: carbGrams,
    dailyFat: fatGrams,
  );
}

// ---------------------------------------------------------------------------
// Legacy NutritionGoal provider — wraps computedMacros into old shape
// for any remaining consumers (will be removed in T08/T09)
// ---------------------------------------------------------------------------

final legacyNutritionGoalProvider = Provider<NutritionGoal>((ref) {
  final macros = ref.watch(computedMacrosProvider);
  final goalsData = ref.watch(goalsProvider);

  final targetWeight = switch (goalsData.bodyWeightGoal) {
    BodyWeightGoal(:final targetWeightKg) => targetWeightKg,
    null => 80.0,
  };

  return NutritionGoal(
    dailyCalories: macros.dailyCalories,
    dailyProtein: macros.dailyProtein,
    dailyCarbs: macros.dailyCarbs,
    dailyFat: macros.dailyFat,
    targetWeight: targetWeight,
  );
});

// ---------------------------------------------------------------------------
// Daily / monthly nutrition (unchanged)
// ---------------------------------------------------------------------------

final dailyNutritionProvider = Provider<MacroNutrients>((ref) {
  final meals = ref.watch(mealsProvider).meals;
  final today = DateTime.now();

  return meals
      .where(
        (meal) =>
            meal.eatenAt.year == today.year &&
            meal.eatenAt.month == today.month &&
            meal.eatenAt.day == today.day,
      )
      .fold(MacroNutrients.zero, (sum, meal) => sum + meal.totalMacros);
});

final monthlyNutritionProvider = Provider<MacroNutrients>((ref) {
  final meals = ref.watch(mealsProvider).meals;
  final now = DateTime.now();

  final mealsThisMonth = meals.where(
    (meal) => meal.eatenAt.year == now.year && meal.eatenAt.month == now.month,
  );

  if (mealsThisMonth.isEmpty) return MacroNutrients.zero;

  final total = mealsThisMonth.fold(
    MacroNutrients.zero,
    (sum, meal) => sum + meal.totalMacros,
  );

  // Return daily average
  final daysInMonth = now.month == 12
      ? 31
      : DateTime(now.year, now.month + 1, 0).day;
  return total.scale(1.0 / daysInMonth);
});

// ---------------------------------------------------------------------------
// Trend data (unchanged, still seed data until T08/T09)
// ---------------------------------------------------------------------------

final strengthTrendProvider = Provider<List<StrengthDataPoint>>((ref) {
  return _seedStrengthData();
});

final weightTrendProvider = Provider<List<WeightDataPoint>>((ref) {
  return _seedWeightData();
});

List<StrengthDataPoint> _seedStrengthData() {
  final now = DateTime.now();
  final data = <StrengthDataPoint>[];

  for (int i = 90; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));

    // Bench Press trend
    data.add(
      StrengthDataPoint(
        date: date,
        exercise: 'Bench Press',
        maxWeight: 100 + (90 - i) * 0.3 + (i % 5) * 2,
      ),
    );

    // Deadlift trend
    data.add(
      StrengthDataPoint(
        date: date,
        exercise: 'Deadlift',
        maxWeight: 150 + (90 - i) * 0.5 + (i % 7) * 2,
      ),
    );

    // Squat trend
    data.add(
      StrengthDataPoint(
        date: date,
        exercise: 'Squat',
        maxWeight: 120 + (90 - i) * 0.4 + (i % 6) * 1.5,
      ),
    );
  }

  return data;
}

List<WeightDataPoint> _seedWeightData() {
  final now = DateTime.now();
  final data = <WeightDataPoint>[];

  for (int i = 90; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    data.add(
      WeightDataPoint(
        date: date,
        weight: 85 - (90 - i) * 0.15 + (i % 10) * 0.2,
      ),
    );
  }

  return data;
}
