class MacroNutrients {
  const MacroNutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  static const zero = MacroNutrients(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
  );

  MacroNutrients operator +(MacroNutrients other) {
    return MacroNutrients(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }

  MacroNutrients scale(double factor) {
    return MacroNutrients(
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
    );
  }
}

class Ingredient {
  Ingredient({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.components = const [],
  });

  factory Ingredient.fromComponents({
    required String id,
    required String name,
    required List<IngredientPortion> components,
  }) {
    final totals = components.fold(
      MacroNutrients.zero,
      (sum, portion) => sum + portion.macros,
    );
    final totalGrams = components.fold(0.0, (sum, portion) => sum + portion.grams);
    final factor = totalGrams == 0 ? 0.0 : 100.0 / totalGrams;
    final per100g = totals.scale(factor);

    return Ingredient(
      id: id,
      name: name,
      caloriesPer100g: per100g.calories,
      proteinPer100g: per100g.protein,
      carbsPer100g: per100g.carbs,
      fatPer100g: per100g.fat,
      components: components,
    );
  }

  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final List<IngredientPortion> components;

  bool get isComposite => components.isNotEmpty;

  MacroNutrients macrosForGrams(double grams) {
    final factor = grams / 100;
    return MacroNutrients(
      calories: caloriesPer100g * factor,
      protein: proteinPer100g * factor,
      carbs: carbsPer100g * factor,
      fat: fatPer100g * factor,
    );
  }
}

class IngredientPortion {
  IngredientPortion({required this.ingredient, required this.grams});

  final Ingredient ingredient;
  final double grams;

  MacroNutrients get macros => ingredient.macrosForGrams(grams);
}

class MealEntry {
  MealEntry({
    required this.id,
    required this.eatenAt,
    required this.items,
    this.name,
  });

  final String id;
  final String? name;
  final DateTime eatenAt;
  final List<IngredientPortion> items;

  MacroNutrients get totalMacros {
    return items.fold(MacroNutrients.zero, (sum, item) => sum + item.macros);
  }

  double get totalGrams {
    return items.fold(0.0, (sum, item) => sum + item.grams);
  }
}
