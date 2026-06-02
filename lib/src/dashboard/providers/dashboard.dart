import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../diet/providers/meals.dart';
import '../../models/dashboard.dart';
import '../../models/exercise.dart';
import '../../models/food.dart';
import '../../database/app_database.dart' hide Goal, Seance;
import '../../database/providers.dart';
import '../../adapters/drift/goals.dart';
import '../../adapters/drift/profile.dart';
import '../../exercise/providers/seance.dart';
import '../../services/logger.dart';

final _log = logger('dashboard_providers');

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
    } catch (e, st) {
      _log.warning('Failed to load profile from database', e, st);
    }
  }

  Future<void> _persist(UserProfile profile) async {
    try {
      final db = ref.read(databaseProvider);
      final repo = DriftProfileRepository(db);
      await repo.upsert(profile);
    } catch (e, st) {
      _log.warning('Failed to persist profile to database', e, st);
    }
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
    } catch (e, st) {
      _log.warning('Failed to load goals from database', e, st);
    }
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
    } catch (e, st) {
      _log.warning('Failed to persist data into the database', e, st);
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
  final entries = ref.watch(bodyWeightEntriesProvider);
  return entries.maybeWhen(
    data: (rows) =>
        rows
            .map(
              (entry) =>
                  WeightDataPoint(date: entry.date, weight: entry.weightKg),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
    orElse: () => const [],
  );
});

final bodyWeightEntriesProvider = StreamProvider<List<BodyWeightEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchBodyWeight();
});

final bodyWeightTrackerProvider = Provider<BodyWeightTrackerController>((ref) {
  return BodyWeightTrackerController(ref);
});

class BodyWeightTrackerController {
  BodyWeightTrackerController(this._ref);

  final Ref _ref;

  Future<void> addEntry(double weightKg, {DateTime? date}) async {
    final db = _ref.read(databaseProvider);
    await db.insertBodyWeight(
      BodyWeightEntriesCompanion.insert(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: date ?? DateTime.now(),
        weightKg: weightKg,
      ),
    );
  }
}

@immutable
class WorkoutDaySummary {
  const WorkoutDaySummary({
    required this.date,
    required this.seances,
    required this.volume,
    required this.duration,
  });

  final DateTime date;
  final List<Seance> seances;
  final double volume;
  final Duration duration;

  bool get hasWorkout => seances.isNotEmpty;
}

@immutable
class WorkoutDashboardStats {
  const WorkoutDashboardStats({
    required this.weekSessions,
    required this.monthSessions,
    required this.monthVolume,
    required this.monthDuration,
    required this.todaySummary,
    required this.lastWorkout,
  });

  final int weekSessions;
  final int monthSessions;
  final double monthVolume;
  final Duration monthDuration;
  final WorkoutDaySummary? todaySummary;
  final Seance? lastWorkout;
}

final workoutDaySummariesProvider = Provider<List<WorkoutDaySummary>>((ref) {
  final history = ref.watch(seanceHistoryProvider);
  final now = DateTime.now();
  final startDate = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 83));

  final days = <WorkoutDaySummary>[];
  for (var index = 0; index < 84; index++) {
    final date = startDate.add(Duration(days: index));
    final sessions =
        history
            .where(
              (seance) =>
                  _dayKey(seance.completedAt ?? seance.startedAt) ==
                  _dayKey(date),
            )
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.startedAt).compareTo(
              a.completedAt ?? a.startedAt,
            ),
          );

    days.add(
      WorkoutDaySummary(
        date: date,
        seances: sessions,
        volume: sessions.fold(
          0.0,
          (sum, seance) => sum + _seanceVolume(seance),
        ),
        duration: sessions.fold(
          Duration.zero,
          (sum, seance) => sum + seance.duration,
        ),
      ),
    );
  }

  return days;
});

final workoutDashboardStatsProvider = Provider<WorkoutDashboardStats>((ref) {
  final history = ref.watch(seanceHistoryProvider);
  final days = ref.watch(workoutDaySummariesProvider);
  final now = DateTime.now();
  final todayKey = _dayKey(now);
  final monthStart = DateTime(now.year, now.month, 1);
  final weekStart = _startOfWeek(now);

  final weekSessions = history.where((seance) {
    return _completedOnOrAfter(seance, weekStart);
  }).length;

  final monthWorkouts = history.where((seance) {
    return _completedOnOrAfter(seance, monthStart);
  }).toList();

  final todaySummary = days.firstWhere(
    (day) => _dayKey(day.date) == todayKey,
    orElse: () => WorkoutDaySummary(
      date: todayKey,
      seances: const [],
      volume: 0,
      duration: Duration.zero,
    ),
  );

  return WorkoutDashboardStats(
    weekSessions: weekSessions,
    monthSessions: monthWorkouts.length,
    monthVolume: monthWorkouts.fold(
      0.0,
      (sum, seance) => sum + _seanceVolume(seance),
    ),
    monthDuration: monthWorkouts.fold(
      Duration.zero,
      (sum, seance) => sum + seance.duration,
    ),
    todaySummary: todaySummary.hasWorkout ? todaySummary : null,
    lastWorkout: history.isEmpty ? null : history.first,
  );
});

DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

bool _completedOnOrAfter(Seance seance, DateTime threshold) {
  final completedAt = seance.completedAt ?? seance.startedAt;
  return !completedAt.isBefore(threshold);
}

DateTime _startOfWeek(DateTime date) {
  final dayStart = _dayKey(date);
  return dayStart.subtract(Duration(days: dayStart.weekday - DateTime.monday));
}

double _seanceVolume(Seance seance) {
  return seance.exercises.fold(0.0, (sum, entry) {
    return sum +
        entry.sets.fold(0.0, (setSum, set) {
          if (!set.isCompleted) return setSum;
          return setSum + (set.reps * set.weight);
        });
  });
}

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

// ---------------------------------------------------------------------------
// Water tracker
// ---------------------------------------------------------------------------

const _waterTrackerKey = 'water_tracker_data';
const _waterDailyGoalKey = 'water_daily_goal_ml';
const _defaultWaterGoalMl = 2500; // 2.5L

/// Provider for water tracker state (current day's water intake + history)
final waterTrackerProvider =
    NotifierProvider<WaterTrackerNotifier, WaterTrackerState>(
  WaterTrackerNotifier.new,
);

class WaterTrackerState {
  final Map<String, int> dailyTotals; // "YYYY-MM-DD" -> ml
  final int dailyGoalMl;

  WaterTrackerState({
    required this.dailyTotals,
    required this.dailyGoalMl,
  });

  int getTodayMl() {
    final today = _formatDate(DateTime.now());
    return dailyTotals[today] ?? 0;
  }

  List<MapEntry<String, int>> getLastNDays(int days) {
    final today = DateTime.now();
    final entries = <MapEntry<String, int>>[];

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      final ml = dailyTotals[dateStr] ?? 0;
      entries.add(MapEntry(dateStr, ml));
    }

    return entries;
  }
}

class WaterTrackerNotifier extends Notifier<WaterTrackerState> {
  @override
  WaterTrackerState build() {
    _load();
    return WaterTrackerState(
      dailyTotals: {},
      dailyGoalMl: _defaultWaterGoalMl,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily totals
      final dataStr = prefs.getString(_waterTrackerKey);
      final dailyTotals = <String, int>{};
      if (dataStr != null) {
        final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          dailyTotals[entry.key] = entry.value as int;
        }
      }

      // Load daily goal
      final goalMl = prefs.getInt(_waterDailyGoalKey) ?? _defaultWaterGoalMl;

      state = WaterTrackerState(
        dailyTotals: dailyTotals,
        dailyGoalMl: goalMl,
      );
    } catch (e) {
      if (kDebugMode) print('Failed to load water tracker: $e');
      state = WaterTrackerState(
        dailyTotals: {},
        dailyGoalMl: _defaultWaterGoalMl,
      );
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _waterTrackerKey,
        jsonEncode(state.dailyTotals),
      );
      await prefs.setInt(_waterDailyGoalKey, state.dailyGoalMl);
    } catch (e) {
      if (kDebugMode) print('Failed to save water tracker: $e');
    }
  }

  Future<void> addWater(int ml) async {
    final today = _formatDate(DateTime.now());
    final currentMl = state.dailyTotals[today] ?? 0;

    final newTotals = Map<String, int>.from(state.dailyTotals);
    newTotals[today] = currentMl + ml;

    state = WaterTrackerState(
      dailyTotals: newTotals,
      dailyGoalMl: state.dailyGoalMl,
    );

    await _save();
  }

  Future<void> setDailyGoal(int ml) async {
    state = WaterTrackerState(
      dailyTotals: state.dailyTotals,
      dailyGoalMl: ml,
    );
    await _save();
  }

  Future<void> resetToday() async {
    final today = _formatDate(DateTime.now());
    final newTotals = Map<String, int>.from(state.dailyTotals);
    newTotals.remove(today);

    state = WaterTrackerState(
      dailyTotals: newTotals,
      dailyGoalMl: state.dailyGoalMl,
    );

    await _save();
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
