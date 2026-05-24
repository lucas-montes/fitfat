import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// User profile
// ---------------------------------------------------------------------------

enum Sex { male, female }

extension SexLabel on Sex {
  String get label => switch (this) {
    Sex.male => 'Male',
    Sex.female => 'Female',
  };
}

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  final double factor;
  const ActivityLevel(this.factor);

  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sedentary',
    ActivityLevel.light => 'Light',
    ActivityLevel.moderate => 'Moderate',
    ActivityLevel.active => 'Active',
    ActivityLevel.veryActive => 'Very Active',
  };
}

@immutable
class UserProfile {
  const UserProfile({
    required this.birthDate,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
  });

  final DateTime birthDate;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

// ---------------------------------------------------------------------------
// Goal types
// ---------------------------------------------------------------------------

enum BodyWeightDirection { gain, lose, maintain }

extension BodyWeightDirectionLabel on BodyWeightDirection {
  String get label => switch (this) {
    BodyWeightDirection.gain => 'Gain',
    BodyWeightDirection.lose => 'Lose',
    BodyWeightDirection.maintain => 'Maintain',
  };
}

sealed class Goal {
  const Goal();
}

class StrengthGoal extends Goal {
  const StrengthGoal({
    required this.exerciseName,
    required this.targetWeightKg,
    this.targetDate,
  });

  final String exerciseName;
  final double targetWeightKg;
  final DateTime? targetDate;
}

class BodyWeightGoal extends Goal {
  const BodyWeightGoal({
    required this.targetWeightKg,
    required this.direction,
    this.targetDate,
  });

  final double targetWeightKg;
  final BodyWeightDirection direction;
  final DateTime? targetDate;
}

/// Holds all user goals: at most one bodyweight goal + N strength goals
/// (one per exercise).
@immutable
class GoalsData {
  const GoalsData({this.bodyWeightGoal, this.strengthGoals = const []});

  final BodyWeightGoal? bodyWeightGoal;
  final List<StrengthGoal> strengthGoals;
}

// ---------------------------------------------------------------------------
// Computed macros derived from goal + profile
// ---------------------------------------------------------------------------

@immutable
class ComputedMacros {
  const ComputedMacros({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
  });

  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;

  static const zero = ComputedMacros(
    dailyCalories: 0,
    dailyProtein: 0,
    dailyCarbs: 0,
    dailyFat: 0,
  );
}

// ---------------------------------------------------------------------------
// Old NutritionGoal retained for backward compat until T08/T09 migration
// ---------------------------------------------------------------------------

class NutritionGoal {
  const NutritionGoal({
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFat,
    required this.targetWeight,
  });

  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFat;
  final double targetWeight;
}

// ---------------------------------------------------------------------------
// Chart data points
// ---------------------------------------------------------------------------

class StrengthDataPoint {
  const StrengthDataPoint({
    required this.date,
    required this.exercise,
    required this.maxWeight,
  });

  final DateTime date;
  final String exercise;
  final double maxWeight;
}

class WeightDataPoint {
  const WeightDataPoint({required this.date, required this.weight});

  final DateTime date;
  final double weight;
}

// ---------------------------------------------------------------------------
// Chart period
// ---------------------------------------------------------------------------

enum ChartPeriod { sevenDays, thirtyDays, ninetyDays }

String periodLabel(ChartPeriod period) {
  switch (period) {
    case ChartPeriod.sevenDays:
      return '7 Days';
    case ChartPeriod.thirtyDays:
      return '30 Days';
    case ChartPeriod.ninetyDays:
      return '3 Months';
  }
}

int periodDays(ChartPeriod period) {
  switch (period) {
    case ChartPeriod.sevenDays:
      return 7;
    case ChartPeriod.thirtyDays:
      return 30;
    case ChartPeriod.ninetyDays:
      return 90;
  }
}
