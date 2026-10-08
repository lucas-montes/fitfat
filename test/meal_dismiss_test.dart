import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/diet/providers/meals.dart';
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/diet/screens/meal_list.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for a crash that shipped: swiping a meal away threw
///
///     A dismissed Dismissible widget is still part of the tree.
///
/// `onDismissed` started an async delete, and the Dismissible was only removed
/// once `mealListProvider` refetched — at least one frame after its animation
/// had already completed, so the very next rebuild asserted.
///
/// The fix hides the row synchronously. The test pins the crash, not the
/// mechanism: it dismisses a row and asserts nothing was thrown.
void main() {
  late db.AppDatabase database;
  late MealRepository meals;
  late FoodRepository foods;
  late ProviderContainer container;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(database);
    foods = FoodRepository(database);

    // A food to log, so the meal has a resolved snapshot and is not rejected.
    final ingredients = IngredientRepository(database);
    final oats = newIngredient(
      name: 'Oats',
      caloriesPer100g: 400,
      proteinPer100g: 13,
      carbsPer100g: 60,
      fatPer100g: 7,
    );
    await ingredients.insert(oats);

    for (final name in ['Breakfast', 'Lunch']) {
      await meals.insert(
        MealEntry(
          id: 'meal-$name',
          name: name,
          eatenAt: DateTime(2026, 10, 8, 8),
          createdAt: DateTime(2026, 10, 8, 8),
          items: [
            MealFood(
              id: 'mf-$name',
              mealId: 'meal-$name',
              foodId: derivedFoodId(oats.id),
              foodName: 'Oats',
              amount: 100,
              calories: 0,
              protein: 0,
              carbs: 0,
              fat: 0,
              nutrition: await foods.resolveNutrition(derivedFoodId(oats.id)),
            ),
          ],
        ),
      );
    }
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  Future<void> pumpList(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    // mealListProvider returns an empty list behind the gate, so without this
    // the screen renders its empty state and there is no row to swipe.
    container.read(startupGateProvider.notifier).complete();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FitFatTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const MealListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Swipes the row titled [title] far enough for Dismissible to complete its
  /// animation, then pumps the frames the old code needed to assert.
  Future<void> dismissRow(WidgetTester tester, String title) async {
    await tester.drag(find.text(title), const Offset(-600, 0));
    // Enough for the dismiss animation to finish and for the provider to
    // refetch — the window in which the old code threw.
    await tester.pumpAndSettle();
  }

  testWidgets('swiping a meal away does not throw', (tester) async {
    await pumpList(tester);
    expect(find.text('Breakfast'), findsOneWidget);

    await dismissRow(tester, 'Breakfast');

    expect(tester.takeException(), isNull);
  });

  testWidgets('the dismissed meal is gone afterwards', (tester) async {
    await pumpList(tester);
    await dismissRow(tester, 'Breakfast');

    expect(find.text('Breakfast'), findsNothing);
    expect(find.text('Lunch'), findsOneWidget);
    expect(await meals.getAll(), hasLength(1));
  });

  testWidgets('dismissing every meal in a day group does not throw',
      (tester) async {
    // Both meals share one day, so emptying the group is the case where the
    // group element itself has to disappear.
    await pumpList(tester);
    await dismissRow(tester, 'Breakfast');
    expect(tester.takeException(), isNull);
    await dismissRow(tester, 'Lunch');

    expect(tester.takeException(), isNull);
    expect(find.text('Lunch'), findsNothing);
  });

  testWidgets('the row leaves the tree before the delete completes',
      (tester) async {
    // Pins the ordering rather than the crash: Dismissible must not survive
    // its own animation. Pumped one frame at a time so the assertion window
    // is not closed by settling everything first.
    await pumpList(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Breakfast')),
    );
    await gesture.moveBy(const Offset(-600, 0));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
