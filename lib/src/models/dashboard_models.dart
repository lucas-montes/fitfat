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
  const WeightDataPoint({
    required this.date,
    required this.weight,
  });

  final DateTime date;
  final double weight;
}

enum ChartPeriod {
  sevenDays,
  thirtyDays,
  ninetyDays,
}

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
