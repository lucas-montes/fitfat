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
import 'package:fitfat/src/diet/screens/meal_form.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The meal edit form, for a meal that already has foods logged.
///
/// Two things this pins. The form showed raw food ids (`i:<uuid>`) for every
/// logged food, because the name map was only ever populated by opening the
/// picker — so the name assertion is the regression itself. And the food rows
/// were read-only text with no affordance, which is why editing a portion was
/// possible but invisible.
///
/// Every test closes the editor sheet before finishing: a left-open sheet
/// strands timers the framework reports after teardown.
void main() {
  late db.AppDatabase database;
  late MealRepository meals;
  late FoodRepository foods;
  late ProviderContainer container;
  late String oatsFoodId;

  const eatenAt = 'eaten';

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(database);
    foods = FoodRepository(database);

    final ingredients = IngredientRepository(database);
    final oats = newIngredient(
      name: 'Rolled Oats',
      caloriesPer100g: 400,
      proteinPer100g: 13,
      carbsPer100g: 60,
      fatPer100g: 7,
    );
    await ingredients.insert(oats);
    oatsFoodId = derivedFoodId(oats.id);

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
            foodId: oatsFoodId,
            foodName: '',
            amount: 100,
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            nutrition: await foods.resolveNutrition(oatsFoodId),
          ),
        ],
      ),
    );
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  /// Opens the edit form for the logged meal.
  Future<void> pumpForm(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    container.read(startupGateProvider.notifier).complete();

    final existing = (await meals.getAll()).single;
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
          home: MealFormScreen(meal: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The sheet's amount field. A bare byType(TextFormField) also matches the
  /// form's own name field, which makes enterText throw on two candidates.
  Finder amountField() => find.widgetWithText(TextFormField, 'Amount');

  /// The sheet's Save: applies the change to the form's draft only.
  Finder sheetSave() =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text('Save'));

  /// The app bar's Save: persists the meal and pops the form.
  Finder appBarSave() =>
      find.descendant(of: find.byType(AppBar), matching: find.text('Save'));

  Future<void> closeSheet(WidgetTester tester) async {
    if (find.text('Cancel').evaluate().isNotEmpty) {
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('shows the food name, never the id', (tester) async {
    await pumpForm(tester);

    expect(find.text('Rolled Oats'), findsOneWidget);
    expect(
      find.text(oatsFoodId),
      findsNothing,
      reason: 'the raw food id must never be the label',
    );
  });

  testWidgets('a food row opens the editor with its current amount',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Rolled Oats'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('100')), findsOneWidget);

    await closeSheet(tester);
  });

  testWidgets('changing the amount updates the draft and persists on save',
      (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Rolled Oats'));
    await tester.pumpAndSettle();
    await tester.enterText(amountField(), '250');
    await tester.pumpAndSettle();
    await tester.tap(sheetSave());
    await tester.pumpAndSettle();

    // The draft changed but nothing is written until the form is saved.
    expect(find.textContaining('250 g'), findsOneWidget);
    expect((await meals.getAll()).single.items.single.amount, 100);

    await tester.tap(appBarSave());
    await tester.pumpAndSettle();

    final stored = (await meals.getAll()).single;
    expect(stored.items.single.amount, 250);
    // 400 kcal per 100g, so 250 g is 1000 kcal.
    expect(stored.items.single.calories, closeTo(1000, 1e-9));
  });

  testWidgets('removing the food drops it from the draft', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Rolled Oats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Rolled Oats'), findsNothing);
  });

  testWidgets('removing the only food leaves nothing to save', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Rolled Oats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Save is still offered but must refuse an empty meal rather than write one.
    await tester.tap(appBarSave());
    await tester.pumpAndSettle();

    expect((await meals.getAll()).single.items, hasLength(1));
  });

  testWidgets('cancelling the editor leaves the draft alone', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Rolled Oats'));
    await tester.pumpAndSettle();
    await tester.enterText(amountField(), '999');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('100 g'), findsOneWidget);
  });

  testWidgets('the row carries a chevron affordance', (tester) async {
    await pumpForm(tester);

    final row = find.ancestor(
      of: find.text('Rolled Oats'),
      matching: find.byType(InkWell),
    );
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.chevron_right)),
      findsOneWidget,
    );
  });

  testWidgets('the meal total sits above the choose-foods button',
      (tester) async {
    await pumpForm(tester);

    final totalsY = tester.getTopLeft(find.text('Meal total')).dy;
    final chooseY = tester
        .getTopLeft(find.widgetWithText(OutlinedButton, 'Choose foods'))
        .dy;

    expect(
      totalsY,
      lessThan(chooseY),
      reason: 'the running total must be readable before the food list',
    );
  });

  testWidgets('save lives in the app bar, not below the food list',
      (tester) async {
    await pumpForm(tester);

    final save = find.text('Save');
    expect(save, findsOneWidget);
    expect(appBarSave(), findsOneWidget);
    expect(save, findsOneWidget, reason: 'and only once');
  });

  testWidgets('the form is still titled as an edit', (tester) async {
    await pumpForm(tester);
    expect(find.text('Edit Meal'), findsOneWidget);
  });
}
