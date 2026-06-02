import '../../models/food.dart';

/// Pure Dart service for macro calculations and meal grouping.
/// No Flutter, no DB, no UI dependencies — fully testable.
class MacroCalculationService {
  /// Aggregate a list of component portions into per-100g macro values.
  /// Returns a [MacroNutrients] where each value is the weighted average
  /// of the components scaled to per-100g of the composite ingredient.
  MacroNutrients computePer100g(List<IngredientPortion> components) {
    if (components.isEmpty) return MacroNutrients.zero;

    final totalGrams = components.fold<double>(0, (sum, c) => sum + c.grams);
    if (totalGrams <= 0) return MacroNutrients.zero;

    double calories = 0, protein = 0, carbs = 0, fat = 0;

    for (final component in components) {
      final ratio = component.grams / totalGrams;
      calories += component.ingredient.caloriesPer100g * ratio;
      protein += component.ingredient.proteinPer100g * ratio;
      carbs += component.ingredient.carbsPer100g * ratio;
      fat += component.ingredient.fatPer100g * ratio;
    }

    return MacroNutrients(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Calculate the sum of macros across all meals in a list.
  MacroNutrients dailyTotals(List<MealEntry> meals) {
    return meals.fold<MacroNutrients>(
      MacroNutrients.zero,
      (sum, meal) => sum + meal.totalMacros,
    );
  }

  /// Group meals by calendar day (date only, ignoring time), sorted descending.
  Map<DateTime, List<MealEntry>> groupMealsByDay(
    List<MealEntry> meals,
  ) {
    final grouped = <DateTime, List<MealEntry>>{};

    for (final meal in meals) {
      final day = DateTime(
        meal.eatenAt.year,
        meal.eatenAt.month,
        meal.eatenAt.day,
      );
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(meal);
    }

    // Sort days descending, and meals within each day by eatenAt ascending
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final result = <DateTime, List<MealEntry>>{};
    for (final key in sortedKeys) {
      final mealsForDay = grouped[key]!;
      mealsForDay.sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
      result[key] = mealsForDay;
    }

    return result;
  }

  /// Validate ingredient creation inputs.
  /// Returns null if valid, or an error message string if invalid.
  String? validateIngredient(
    String name,
    List<IngredientPortion> components,
    double calories,
    double protein,
    double carbs,
    double fat,
  ) {
    if (name.trim().isEmpty) {
      return 'Ingredient name is required';
    }

    // For composite ingredients, require at least one component
    if (components.isNotEmpty) {
      // Components handle the macros, no further validation needed
      return null;
    }

    // For atomic ingredients, require at least one non-zero macro
    if (calories <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) {
      return 'At least one macro value must be greater than 0';
    }

    return null;
  }

  /// Format macros into a display string, optionally filtering by preferences.
  String formatMacros(
    MacroNutrients macros, {
    bool showCalories = true,
    bool showProtein = true,
    bool showCarbs = true,
    bool showFat = true,
  }) {
    final parts = <String>[];

    if (showCalories) parts.add('${macros.calories.toStringAsFixed(0)} kcal');
    if (showProtein) parts.add('P ${macros.protein.toStringAsFixed(1)}g');
    if (showCarbs) parts.add('C ${macros.carbs.toStringAsFixed(1)}g');
    if (showFat) parts.add('F ${macros.fat.toStringAsFixed(1)}g');

    return parts.join(' · ');
  }

  /// Format per-100g display string.
  String formatPer100g(
    MacroNutrients macros, {
    bool showCalories = true,
    bool showProtein = true,
    bool showCarbs = true,
    bool showFat = true,
  }) {
    return 'Per 100g: ${formatMacros(macros, showCalories: showCalories, showProtein: showProtein, showCarbs: showCarbs, showFat: showFat)}';
  }

  /// Check if an ingredient can be permanently deleted (not referenced by meals).
  Future<bool> canDeleteIngredient(
    String ingredientId,
    Future<bool> Function(String) checkMealRefs,
  ) async {
    final isReferenced = await checkMealRefs(ingredientId);
    return !isReferenced;
  }
}
