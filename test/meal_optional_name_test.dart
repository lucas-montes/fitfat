import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/diet/widgets/food_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cover for two changes that are easy to regress because neither has an
/// obvious failure: a meal name became optional, and the food picker moved into
/// a debounced sheet.
void main() {
  late db.AppDatabase database;
  late IngredientRepository ingredients;
  late FoodRepository foods;
  late MealRepository meals;
  late FoodIngredient oats;
  late FoodIngredient honey;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    ingredients = IngredientRepository(database);
    foods = FoodRepository(database);
    meals = MealRepository(database);

    Future<FoodIngredient> oat({
      String name = 'Oats',
      double calories = 400,
    }) async {
      final ing = newIngredient(
        name: name,
        caloriesPer100g: calories,
        proteinPer100g: 13,
        carbsPer100g: 60,
        fatPer100g: 7,
      );
      await ingredients.insert(ing);
      return FoodIngredient(
        foodId: '',
        ingredientId: ing.id,
        ingredientName: name,
        amount: 100,
      );
    }

    oats = await oat();
    honey = await oat(name: 'Honey', calories: 300);
  });

  tearDown(() => database.close());

  Widget host(Widget child) => ProviderScope(
    overrides: [databaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: child),
    ),
  );

  /// Opens the sheet over a trivial host and returns a future for its result.
  ///
  /// The future is returned rather than the value because the sheet is modal:
  /// the caller has to drive the confirm/dismiss itself before the future
  /// settles.
  Future<Future<Map<String, double>?>> openSheet(
    WidgetTester tester, {
    required Map<String, double> initial,
  }) async {
    final result = Completer<Map<String, double>?>();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.complete(
                await showFoodPickerSheet(
                  context,
                  foods: await foods.getAllWithNutrition(),
                  initialAmounts: initial,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result.future;
  }

  group('meal name is optional', () {
    test('an unnamed meal persists with an empty name', () async {
      await meals.insert(
        MealEntry(
          id: 'm1',
          name: '',
          eatenAt: DateTime(2026, 3, 12, 14, 30),
          createdAt: DateTime(2026, 3, 12, 14, 30),
          items: const [],
        ),
      );

      final loaded = await meals.getAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.name, isEmpty);
    });

    test('a named meal still round-trips', () async {
      await meals.insert(
        MealEntry(
          id: 'm2',
          name: 'Breakfast',
          eatenAt: DateTime(2026, 3, 12, 8),
          createdAt: DateTime(2026, 3, 12, 8),
          items: const [],
        ),
      );
      expect((await meals.getAll()).single.name, 'Breakfast');
    });
  });

  group('food picker sheet', () {
    testWidgets('offers single ingredients, not just recipes', (tester) async {
      // A user-created recipe.
      await foods.insert(newFood(name: 'Granola'), [
        FoodIngredient(
          foodId: '',
          ingredientId: oats.ingredientId,
          ingredientName: 'Oats',
          amount: 80,
        ),
      ]);

      await openSheet(tester, initial: {});

      // Both sections present: without the derived 1:1 foods a plain ingredient
      // could not be logged at all.
      expect(find.text('RECIPES'), findsOneWidget);
      expect(find.text('SINGLE INGREDIENTS'), findsOneWidget);
      expect(find.text('Granola'), findsOneWidget);
      expect(find.text('Oats'), findsOneWidget);
    });

    testWidgets('selecting returns the amount keyed by food id', (
      tester,
    ) async {
      final resolved = await foods.getAllWithNutrition();
      final oatsFood = resolved.firstWhere((e) => e.food.isDerived);

      final result = await openSheet(tester, initial: {oatsFood.food.id: 150});

      // Confirm, then read what the sheet handed back.
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final chosen = await result;

      expect(chosen, isNotNull);
      expect(chosen![oatsFood.food.id], 150);
    });

    testWidgets('a dismissed sheet leaves the selection untouched', (
      tester,
    ) async {
      final resolved = await foods.getAllWithNutrition();
      final oatsFood = resolved.first;

      final result = await openSheet(tester, initial: {oatsFood.food.id: 120});

      // Back out without confirming.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Nothing was returned, so the caller keeps its existing map.
      expect(await result, isNull);
    });

    // Covers the filtering, not the debounce itself: a timer delay is a
    // performance property that would need timing assertions to pin down, and
    // `pumpAndSettle` flushes it either way. What matters is that the sheet
    // returns only matching rows.
    testWidgets('search narrows the list to matches', (tester) async {
      await foods.insert(newFood(name: 'Granola'), [
        FoodIngredient(
          foodId: '',
          ingredientId: oats.ingredientId,
          ingredientName: 'Oats',
          amount: 80,
        ),
      ]);
      await openSheet(tester, initial: {});

      expect(find.text('Granola'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'gran');
      await tester.pump();
      // Past the sheet's 250ms debounce, then settle the resulting rebuild.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Granola'), findsOneWidget);
      expect(find.text('Honey'), findsNothing);
      expect(find.text('Oats'), findsNothing);
    });
  });
}
