import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/src/providers/food_providers.dart';
import 'package:fitfat/src/models/food_models.dart';

void main() {
  test('updateIngredient propagates into meals', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ingredients = container.read(ingredientListProvider);
    final donut = ingredients.firstWhere((i) => i.name == 'Donut');

    final updated = Ingredient(
      id: donut.id,
      name: donut.name,
      caloriesPer100g: donut.caloriesPer100g + 100,
      proteinPer100g: donut.proteinPer100g,
      carbsPer100g: donut.carbsPer100g,
      fatPer100g: donut.fatPer100g,
      components: donut.components,
    );

    container.read(ingredientListProvider.notifier).updateIngredient(updated);

    final meals = container.read(mealLogProvider);

    final found = meals.any((meal) =>
        meal.items.any((item) =>
            item.ingredient.id == donut.id &&
            item.ingredient.caloriesPer100g == updated.caloriesPer100g));

    expect(found, isTrue);
  });

  test('removeIngredient removes portions and empty meals', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ingredients = container.read(ingredientListProvider);
    final pizza = ingredients.firstWhere((i) => i.name == 'Homemade Pizza');

    // Ensure meals are seeded (mealLogProvider built) before we remove the
    // ingredient, otherwise MealLogNotifier.build may attempt to reference the
    // removed ingredient while seeding meals.
    container.read(mealLogProvider);
    container.read(ingredientListProvider.notifier).removeIngredient(pizza.id);

    final ingredientsAfter = container.read(ingredientListProvider);
    expect(ingredientsAfter.any((i) => i.id == pizza.id), isFalse);

    final meals = container.read(mealLogProvider);
    // The seeded data had two meals; removing the pizza ingredient should
    // remove the pizza-only meal and leave the Snack meal intact.
    expect(meals.length, 1);
    expect(meals.first.name, 'Snack');

    final anyPizza = meals.any((meal) =>
        meal.items.any((item) => item.ingredient.id == pizza.id));
    expect(anyPizza, isFalse);
  });
}
