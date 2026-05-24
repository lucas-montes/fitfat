import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/src/adapters/in_memory/in_memory_meal_repository.dart';
import 'package:fitfat/src/providers/repositories.dart';
import 'package:fitfat/src/providers/meal_controller_provider.dart';
import 'package:fitfat/src/models/food_models.dart';

void main() {
  test('MealListController loads meals and reacts to additions', () async {
    // For tests we use the in-memory repository to avoid native sqlite
    // dependencies in the test environment. This keeps tests fast and
    // isolated while exercising the controller logic.
    final repo = InMemoryMealRepository();
    final container = ProviderContainer(
      overrides: [mealRepositoryProvider.overrideWithValue(repo)],
    );

    addTearDown(() async {
      container.dispose();
    });

    final month = DateTime(2026, 5, 1);

    final controller = container.read(mealControllerProvider.notifier);

    // initial load should succeed (empty data)
    try {
      await controller.loadMonth(month);
    } catch (e, st) {
      print('controller.loadMonth threw: $e\n$st');
    }
    final state = container.read(mealControllerProvider);
    if (state.status == MealListStatus.error) {
      print('Initial load error: ${state.errorMessage}');
    }
    expect(state.status, MealListStatus.data);
    expect(state.meals, isEmpty);

    // add a meal with no ingredient items (allowed)
    final meal = MealEntry(
      id: const Uuid().v4(),
      name: 'Apple',
      eatenAt: month.add(const Duration(hours: 12)),
      items: [],
    );
    // sanity-check: try repository upsert directly to see low-level errors
    try {
      await repo.upsert(meal);
    } catch (e, st) {
      print('repo.upsert threw: $e\n$st');
    }

    await controller.addMeal(meal);

    final updated = container.read(mealControllerProvider);
    if (updated.status == MealListStatus.error) {
      // show error message for debugging
      print('Controller error: ${updated.errorMessage}');
    }
    expect(updated.status, MealListStatus.data);
    expect(updated.meals.any((m) => m.name == 'Apple'), isTrue);
  });
}
