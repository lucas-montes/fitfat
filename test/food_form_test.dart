import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/diet/providers/foods.dart';
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/screens/food_form.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for a crash that shipped: adding a part from the picker's
/// "+" button inserted it into the draft but never created its amount field
/// controller or error notifier, so the very next build hit a null check on
/// `_amountCtrls[id]!` and the whole form died with
/// "Null check operator used on a null value".
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
  });

  tearDown(() => database.close());

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: FoodFormScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adding a part renders its row without crashing', (tester) async {
    await pumpForm(tester);

    // Tap the "+" next to the only ingredient offered.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // The crash surfaced as a framework exception rather than a failed
    // expectation, so assert the error trap stayed empty.
    expect(tester.takeException(), isNull);
    expect(find.text('Oats'), findsOneWidget);
    // Its default amount is on screen.
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('saving with no parts is refused rather than throwing', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.ensureVisible(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Still on the form — nothing was written.
    expect(find.byType(FoodFormScreen), findsOneWidget);
    // Still only the ingredient's own derived food — the refused save wrote no
    // user-created recipe.
    expect(
      (await foods.getAllWithNutrition()).where((e) => !e.food.isDerived),
      isEmpty,
    );
  });

  testWidgets('a saved part becomes the composition of a new food', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Porridge');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save recipe'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final saved = (await foods.getAllWithNutrition())
        .where((e) => !e.food.isDerived)
        .toList();
    expect(saved, hasLength(1));
    expect(saved.single.food.name, 'Porridge');
    expect(saved.single.food.components.single.amount, 100);
  });
}
