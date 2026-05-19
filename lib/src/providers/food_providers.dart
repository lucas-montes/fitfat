import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/food_models.dart';

final ingredientListProvider =
    NotifierProvider<IngredientListNotifier, List<Ingredient>>(
  IngredientListNotifier.new,
);

final mealLogProvider = NotifierProvider<MealLogNotifier, List<MealEntry>>(
  MealLogNotifier.new,
);

class IngredientListNotifier extends Notifier<List<Ingredient>> {
  @override
  List<Ingredient> build() => _seedIngredients();

  void addIngredient(Ingredient ingredient) {
    state = [...state, ingredient];
  }

  void updateIngredient(Ingredient ingredient) {
    state = [
      for (final existing in state)
        if (existing.id == ingredient.id) ingredient else existing,
    ];
    ref.read(mealLogProvider.notifier).replaceIngredient(ingredient);
  }

  void removeIngredient(String id) {
    state = state.where((ingredient) => ingredient.id != id).toList();
    // Also remove the ingredient from any meals that reference it.
    ref.read(mealLogProvider.notifier).removeIngredient(id);
  }
}

class MealLogNotifier extends Notifier<List<MealEntry>> {
  @override
  List<MealEntry> build() {
    final ingredients = ref.read(ingredientListProvider);
    return _seedMeals(ingredients);
  }

  void addMeal(MealEntry meal) {
    state = [...state, meal];
  }

  void updateMeal(MealEntry meal) {
    state = [
      for (final existing in state)
        if (existing.id == meal.id) meal else existing,
    ];
  }

  void removeMeal(String id) {
    state = state.where((meal) => meal.id != id).toList();
  }

  void replaceIngredient(Ingredient ingredient) {
    state = [
      for (final meal in state)
        MealEntry(
          id: meal.id,
          name: meal.name,
          eatenAt: meal.eatenAt,
          items: [
            for (final item in meal.items)
              if (item.ingredient.id == ingredient.id)
                IngredientPortion(ingredient: ingredient, grams: item.grams)
              else
                item,
          ],
        ),
    ];
  }

  void removeIngredient(String id) {
    state = [
      for (final meal in state)
        MealEntry(
          id: meal.id,
          name: meal.name,
          eatenAt: meal.eatenAt,
          items: [for (final item in meal.items) if (item.ingredient.id != id) item],
        ),
    ].where((meal) => meal.items.isNotEmpty).toList();
  }
}

final _uuid = Uuid();

List<Ingredient> _seedIngredients() {
  final flour = Ingredient(
    id: _uuid.v4(),
    name: 'Flour',
    caloriesPer100g: 364,
    proteinPer100g: 10,
    carbsPer100g: 76,
    fatPer100g: 1,
  );
  final tomato = Ingredient(
    id: _uuid.v4(),
    name: 'Tomato Sauce',
    caloriesPer100g: 32,
    proteinPer100g: 2,
    carbsPer100g: 7,
    fatPer100g: 0.4,
  );
  final cheese = Ingredient(
    id: _uuid.v4(),
    name: 'Mozzarella',
    caloriesPer100g: 280,
    proteinPer100g: 20,
    carbsPer100g: 3,
    fatPer100g: 20,
  );
  final oliveOil = Ingredient(
    id: _uuid.v4(),
    name: 'Olive Oil',
    caloriesPer100g: 884,
    proteinPer100g: 0,
    carbsPer100g: 0,
    fatPer100g: 100,
  );
  final donut = Ingredient(
    id: _uuid.v4(),
    name: 'Donut',
    caloriesPer100g: 403,
    proteinPer100g: 5,
    carbsPer100g: 50,
    fatPer100g: 20,
  );
  final cola = Ingredient(
    id: _uuid.v4(),
    name: 'Cola',
    caloriesPer100g: 42,
    proteinPer100g: 0,
    carbsPer100g: 10.6,
    fatPer100g: 0,
  );

  final pizza = Ingredient.fromComponents(
    id: _uuid.v4(),
    name: 'Homemade Pizza',
    components: [
      IngredientPortion(ingredient: flour, grams: 200),
      IngredientPortion(ingredient: tomato, grams: 120),
      IngredientPortion(ingredient: cheese, grams: 150),
      IngredientPortion(ingredient: oliveOil, grams: 15),
    ],
  );

  return [flour, tomato, cheese, oliveOil, donut, cola, pizza];
}

List<MealEntry> _seedMeals(List<Ingredient> ingredients) {
  final now = DateTime.now();
  final donut = ingredients.firstWhere((item) => item.name == 'Donut');
  final cola = ingredients.firstWhere((item) => item.name == 'Cola');
  final pizza = ingredients.firstWhere((item) => item.name == 'Homemade Pizza');

  return [
    MealEntry(
      id: _uuid.v4(),
      name: 'Snack',
      eatenAt: DateTime(now.year, now.month, now.day, 10, 30),
      items: [
        IngredientPortion(ingredient: donut, grams: 80),
        IngredientPortion(ingredient: cola, grams: 250),
      ],
    ),
    MealEntry(
      id: _uuid.v4(),
      name: 'Homemade Pizza',
      eatenAt: DateTime(now.year, now.month, now.day, 13, 15),
      items: [
        IngredientPortion(ingredient: pizza, grams: 180),
      ],
    ),
  ];
}
