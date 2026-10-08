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
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Editing a food already logged in a meal.
///
/// The rows inside an expanded meal were an inert `ListTile`, and the meal form
/// only offered a read-only summary plus a separate "Choose foods" button, so
/// changing a logged portion was possible but invisible. Tapping a row now opens
/// a small editor.
///
/// Every test closes the sheet before finishing. A left-open sheet strands
/// timers and the test framework reports them after teardown — a failure of the
/// test's own making.
void main() {
  late db.AppDatabase database;
  late MealRepository meals;
  late FoodRepository foods;
  late ProviderContainer container;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(database);
    foods = FoodRepository(database);

    final ingredients = IngredientRepository(database);
    final oats = newIngredient(
      name: 'Oats',
      caloriesPer100g: 400,
      proteinPer100g: 13,
      carbsPer100g: 60,
      fatPer100g: 7,
    );
    await ingredients.insert(oats);

    await meals.insert(
      MealEntry(
        id: 'meal-1',
        name: 'Breakfast',
        eatenAt: DateTime(2026, 10, 8, 8),
        createdAt: DateTime(2026, 10, 8, 8),
        items: [
          MealFood(
            id: 'row-1',
            mealId: 'meal-1',
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
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  Future<void> pumpList(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
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

  /// Expands the meal so its food rows exist, then opens the editor on the row
  /// titled [foodName].
  Future<void> openEditor(WidgetTester tester, String foodName) async {
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    expect(find.text(foodName), findsOneWidget);
    await tester.tap(find.text(foodName));
    await tester.pumpAndSettle();
  }

  /// Replaces the amount field's contents.
  Future<void> setAmount(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField), value);
    await tester.pumpAndSettle();
  }

  testWidgets('a food row opens an editor showing its current amount', (
    tester,
  ) async {
    await pumpList(tester);
    await openEditor(tester, 'Oats');

    expect(find.text('Oats'), findsWidgets);
    expect(find.widgetWithText(TextFormField, '100'), findsOneWidget);
    // The summary of what is currently stored, so the change is visible before
    // it is saved.
    expect(find.textContaining('400'), findsWidgets);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('changing the amount rescales the stored food', (tester) async {
    await pumpList(tester);
    await openEditor(tester, 'Oats');

    await setAmount(tester, '250');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final stored = (await meals.getAll()).single;
    expect(stored.items.single.amount, 250);
    // 400 kcal per 100g, so 250 g is 1000 kcal — scaled linearly, not snapped
    // to a fresh resolution.
    expect(stored.items.single.calories, closeTo(1000, 1e-9));
  });

  testWidgets('removing a food drops it from the meal', (tester) async {
    await pumpList(tester);
    await openEditor(tester, 'Oats');

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect((await meals.getAll()).single.items, isEmpty);
  });

  testWidgets('cancelling changes nothing', (tester) async {
    await pumpList(tester);
    await openEditor(tester, 'Oats');

    await setAmount(tester, '999');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await meals.getAll()).single.items.single.amount, 100);
  });

  testWidgets('a non-positive amount is refused', (tester) async {
    await pumpList(tester);
    await openEditor(tester, 'Oats');

    await setAmount(tester, '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The sheet stays open showing the error rather than saving a zero portion.
    expect(find.textContaining('greater than zero'), findsOneWidget);
    expect((await meals.getAll()).single.items.single.amount, 100);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('the row carries a trailing chevron affordance', (tester) async {
    await pumpList(tester);
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();

    // Without it the row is tappable but indistinguishable from static text,
    // which is what made this undiscoverable in the first place.
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Oats'), matching: find.byType(ListTile)),
    );
    expect(tile.onTap, isNotNull);
    expect(tile.trailing, isA<Icon>());
  });
}
