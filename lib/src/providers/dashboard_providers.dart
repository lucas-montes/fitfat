import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_models.dart';
import '../models/food_models.dart';
import 'food_providers.dart';

final chartPeriodProvider = NotifierProvider<ChartPeriodNotifier, ChartPeriod>(
  ChartPeriodNotifier.new,
);

class ChartPeriodNotifier extends Notifier<ChartPeriod> {
  @override
  ChartPeriod build() => ChartPeriod.thirtyDays;
}


final goalProvider = NotifierProvider<GoalNotifier, NutritionGoal>(
  GoalNotifier.new,
);

final dailyNutritionProvider = Provider<MacroNutrients>((ref) {
  final meals = ref.watch(mealLogProvider);
  final today = DateTime.now();

  return meals
      .where((meal) =>
          meal.eatenAt.year == today.year &&
          meal.eatenAt.month == today.month &&
          meal.eatenAt.day == today.day)
      .fold(
        MacroNutrients.zero,
        (sum, meal) => sum + meal.totalMacros,
      );
});

final monthlyNutritionProvider = Provider<MacroNutrients>((ref) {
  final meals = ref.watch(mealLogProvider);
  final now = DateTime.now();

  final mealsThisMonth = meals.where((meal) =>
      meal.eatenAt.year == now.year && meal.eatenAt.month == now.month);

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

final strengthTrendProvider =
    Provider<List<StrengthDataPoint>>((ref) {
  return _seedStrengthData();
});

final weightTrendProvider =
    Provider<List<WeightDataPoint>>((ref) {
  return _seedWeightData();
});

class GoalNotifier extends Notifier<NutritionGoal> {
  @override
  NutritionGoal build() => _defaultGoal();

  void updateGoal({
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
    double? targetWeight,
  }) {
    state = NutritionGoal(
      dailyCalories: dailyCalories ?? state.dailyCalories,
      dailyProtein: dailyProtein ?? state.dailyProtein,
      dailyCarbs: dailyCarbs ?? state.dailyCarbs,
      dailyFat: dailyFat ?? state.dailyFat,
      targetWeight: targetWeight ?? state.targetWeight,
    );
  }
}

NutritionGoal _defaultGoal() {
  return const NutritionGoal(
    dailyCalories: 2000,
    dailyProtein: 150,
    dailyCarbs: 200,
    dailyFat: 65,
    targetWeight: 80,
  );
}

List<StrengthDataPoint> _seedStrengthData() {
  final now = DateTime.now();
  final data = <StrengthDataPoint>[];

  for (int i = 90; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));

    // Bench Press trend
    data.add(StrengthDataPoint(
      date: date,
      exercise: 'Bench Press',
      maxWeight: 100 + (90 - i) * 0.3 + (i % 5) * 2,
    ));

    // Deadlift trend
    data.add(StrengthDataPoint(
      date: date,
      exercise: 'Deadlift',
      maxWeight: 150 + (90 - i) * 0.5 + (i % 7) * 2,
    ));

    // Squat trend
    data.add(StrengthDataPoint(
      date: date,
      exercise: 'Squat',
      maxWeight: 120 + (90 - i) * 0.4 + (i % 6) * 1.5,
    ));
  }

  return data;
}

List<WeightDataPoint> _seedWeightData() {
  final now = DateTime.now();
  final data = <WeightDataPoint>[];

  for (int i = 90; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    data.add(WeightDataPoint(
      date: date,
      weight: 85 - (90 - i) * 0.15 + (i % 10) * 0.2,
    ));
  }

  return data;
}
