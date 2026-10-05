import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/widgets/food_picker_sheet.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for a bug that shipped: the amount field's `enabled` state
/// was derived from the *parsed* amount, so backspacing `100` down to `00` parsed
/// to zero, disabled the field being typed into, dropped the keyboard and read as
/// the sheet closing — while also dropping the food from the meal.
///
/// Every test closes the sheet before finishing. A left-open sheet strands the
/// focused field's cursor-blink timer, which the test framework reports as a
/// pending timer after teardown — a failure of the test's own making.
void main() {
  late db.AppDatabase database;
  late FoodRepository foods;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    foods = FoodRepository(database);
    final ingredients = IngredientRepository(database);
    await ingredients.insert(
      newIngredient(
        name: 'Oats',
        caloriesPer100g: 400,
        proteinPer100g: 13,
        carbsPer100g: 60,
        fatPer100g: 7,
      ),
    );
    await ingredients.insert(
      newIngredient(
        name: 'Honey',
        caloriesPer100g: 300,
        proteinPer100g: 0,
        carbsPer100g: 80,
        fatPer100g: 0,
      ),
    );
  });

  tearDown(() => database.close());

  /// Opens the sheet over a trivial host and returns a future for its result.
  Future<Future<Map<String, double>?>> openSheet(
    WidgetTester tester, {
    Map<String, double> initial = const {},
  }) async {
    final completer = Completer<Map<String, double>?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: FitFatTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  completer.complete(
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
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return completer.future;
  }

  Finder _rowFor(String foodName) =>
      find.ancestor(of: find.text(foodName), matching: find.byType(ListTile));

  Finder amountFieldFor(String foodName) =>
      find.descendant(of: _rowFor(foodName), matching: find.byType(TextField));

  Future<void> tick(WidgetTester tester, String foodName) async {
    await tester.tap(
      find.descendant(of: _rowFor(foodName), matching: find.byType(Checkbox)),
    );
    await tester.pumpAndSettle();
  }

  /// Types into an amount field. Uses explicit pumps rather than
  /// [WidgetTester.pumpAndSettle], which never converges while a focused field
  /// blinks its cursor.
  Future<void> type(WidgetTester tester, String foodName, String value) async {
    await tester.enterText(amountFieldFor(foodName), value);
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Unticks everything so Done can close, used to end a test that deliberately
  /// left a blocking error on screen.
  Future<void> closeSheet(WidgetTester tester) async {
    for (final name in ['Oats', 'Honey']) {
      final cb = tester.widget<Checkbox>(
        find.descendant(of: _rowFor(name), matching: find.byType(Checkbox)),
      );
      if (cb.value == true) await tick(tester, name);
    }
    await confirm(tester);
  }

  group('no default amount', () {
    testWidgets('ticking a food leaves its amount empty', (tester) async {
      await openSheet(tester);
      await tick(tester, 'Oats');

      expect(
        tester.widget<TextField>(amountFieldFor('Oats')).controller!.text,
        isEmpty,
        reason: 'ticking must not invent a portion the user never chose',
      );

      await closeSheet(tester);
    });
  });

  group('the field never disables itself', () {
    testWidgets('deleting the leading digit keeps the sheet open and ticked', (
      tester,
    ) async {
      await openSheet(tester);
      await tick(tester, 'Oats');

      await type(tester, 'Oats', '100');
      // The reported repro: delete the first digit.
      await type(tester, 'Oats', '00');

      // Still open.
      expect(find.text('Done'), findsOneWidget);
      // Still ticked, so the food is not silently lost.
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: _rowFor('Oats'),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isTrue,
      );
      // The text is left exactly as typed, so the caret survives and the user can
      // carry on rather than starting again.
      expect(
        tester.widget<TextField>(amountFieldFor('Oats')).controller!.text,
        '00',
      );

      await closeSheet(tester);
    });

    testWidgets('a value passing through zero leaves the field usable', (
      tester,
    ) async {
      await openSheet(tester);
      await tick(tester, 'Oats');

      // Every partial numeric input that used to disable the field.
      for (final raw in ['0', '0.', '00', '0.0', '8', '80', '80.']) {
        await type(tester, 'Oats', raw);
        expect(
          tester.widget<TextField>(amountFieldFor('Oats')).enabled,
          isTrue,
          reason: 'the field disabled itself at "$raw"',
        );
      }

      await closeSheet(tester);
    });
  });

  group('Done validates', () {
    testWidgets('blocks and names a ticked food with no amount', (
      tester,
    ) async {
      await openSheet(tester);
      await tick(tester, 'Oats');
      await confirm(tester);

      expect(find.textContaining('Oats needs an amount'), findsOneWidget);
      // The sheet is still up, which is the point.
      expect(find.text('Done'), findsOneWidget);

      await closeSheet(tester);
    });

    testWidgets('clears the error once an amount is typed', (tester) async {
      await openSheet(tester);
      await tick(tester, 'Oats');
      await confirm(tester);
      expect(find.textContaining('needs an amount'), findsOneWidget);

      await type(tester, 'Oats', '75');
      expect(find.textContaining('needs an amount'), findsNothing);

      await confirm(tester);
    });

    testWidgets('succeeds once every ticked food has an amount', (
      tester,
    ) async {
      final future = await openSheet(tester);
      await tick(tester, 'Oats');
      await tick(tester, 'Honey');
      await type(tester, 'Oats', '80');
      await type(tester, 'Honey', '20');

      await confirm(tester);
      expect(await future, hasLength(2));
    });

    testWidgets('unticking a food clears its blocking error', (tester) async {
      final future = await openSheet(tester);
      await tick(tester, 'Oats');
      await confirm(tester);
      expect(find.textContaining('needs an amount'), findsOneWidget);

      await tick(tester, 'Oats');
      await confirm(tester);
      // Nothing ticked, nothing missing, so it closes with an empty result.
      expect(await future, isEmpty);
    });
  });

  group('existing selection', () {
    testWidgets('a reopened sheet restores amounts and ticked boxes', (
      tester,
    ) async {
      final resolved = await foods.getAllWithNutrition();
      final oatsFood = resolved.firstWhere((e) => e.food.name == 'Oats');

      final future = await openSheet(tester, initial: {oatsFood.food.id: 150});
      expect(
        tester.widget<TextField>(amountFieldFor('Oats')).controller!.text,
        '150',
      );

      await type(tester, 'Oats', '175');
      await confirm(tester);
      expect((await future)?[oatsFood.food.id], 175);
    });
  });
}
