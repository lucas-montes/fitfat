import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/diet/repositories/food_repository.dart';
import 'package:fitfat/src/diet/repositories/ingredient_repository.dart';
import 'package:fitfat/src/diet/repositories/meal_repository.dart';
import 'package:fitfat/src/diet/screens/meal_form.dart';
import 'package:fitfat/src/diet/screens/meal_list.dart';
import 'package:fitfat/src/models/food.dart';
import 'package:fitfat/src/models/meal_entry.dart';
import 'package:fitfat/src/models/meal_food.dart';
import 'package:fitfat/src/ui/widgets/date_filter_chips.dart';
import 'package:fitfat/src/ui/widgets/macro_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late db.AppDatabase database;
  late MealRepository meals;
  late FoodRepository foods;
  late IngredientRepository ingredients;
  ProviderContainer? container;
  late String oats;
  late String banana;

  MealEntry entry(String id, DateTime at, List<MealFood> items) =>
      MealEntry(id: id, name: '', eatenAt: at, createdAt: at, items: items);

  Future<MealFood> item(String mealId, String foodId, double grams) async =>
      MealFood(
        id: '$mealId-$foodId',
        mealId: mealId,
        foodId: foodId,
        foodName: '',
        amount: grams,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        nutrition: await foods.resolveNutrition(foodId),
      );

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    meals = MealRepository(database);
    foods = FoodRepository(database);
    ingredients = IngredientRepository(database);
    final o = newIngredient(
      name: 'Rolled oats',
      caloriesPer100g: 400,
      proteinPer100g: 13,
      carbsPer100g: 60,
      fatPer100g: 7,
    );
    final b = newIngredient(
      name: 'Banana',
      caloriesPer100g: 90,
      proteinPer100g: 1,
      carbsPer100g: 23,
      fatPer100g: 0.3,
    );
    await ingredients.insert(o);
    await ingredients.insert(b);
    oats = derivedFoodId(o.id);
    banana = derivedFoodId(b.id);
  });

  tearDown(() async {
    container?.dispose();
    container = null;
    await database.close();
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    container?.dispose();
    final nav = GlobalKey<NavigatorState>();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    container!.read(startupGateProvider.notifier).complete();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container!,
        child: MaterialApp(
          navigatorKey: nav,
          theme: FitFatTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const Scaffold(),
        ),
      ),
    );
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => home));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  group('groupMealDays', () {
    MealEntry m(String id, DateTime at, [String food = 'Oats']) => MealEntry(
      id: id,
      name: '',
      eatenAt: at,
      createdAt: at,
      items: [
        MealFood(
          id: '$id-i',
          mealId: id,
          foodId: 'f',
          foodName: food,
          amount: 100,
          calories: 100,
          protein: 1,
          carbs: 1,
          fat: 1,
        ),
      ],
    );

    test('newest day first, meals in time order', () {
      final days = groupMealDays([
        m('a', DateTime(2026, 11, 26, 14)),
        m('b', DateTime(2026, 11, 27, 18)),
        m('c', DateTime(2026, 11, 27, 8)),
        m('d', DateTime(2026, 11, 26, 8)),
      ]);
      expect(days.map((d) => d.day), [
        DateTime(2026, 11, 27),
        DateTime(2026, 11, 26),
      ]);
      expect(days.first.meals.map((x) => x.id), ['c', 'b']);
      expect(days.last.meals.map((x) => x.id), ['d', 'a']);
    });

    test('filters by month and by food name', () {
      final all = [
        m('a', DateTime(2026, 10, 30, 8)),
        m('b', DateTime(2026, 11, 2, 8), 'Banana'),
        m('c', DateTime(2026, 11, 3, 8)),
      ];
      final nov = groupMealDays(
        all,
        filter: DateFilter(month: DateTime(2026, 11)),
      );
      expect(nov.expand((d) => d.meals).map((x) => x.id), ['c', 'b']);
      final q = groupMealDays(all, query: 'bana');
      expect(q.expand((d) => d.meals).map((x) => x.id), ['b']);
    });
  });

  test('segment widths keep a minimum and fill the bar', () {
    final w = segmentWidths([400, 0, 90, 10, 0], 300, minWidth: 24);
    expect(w.reduce((a, b) => a + b), closeTo(300, 0.001));
    expect(w.every((x) => x >= 24 - 1e-9), isTrue);
    expect(w[0], greaterThan(w[2]));
  });

  group('meal history', () {
    testWidgets('a day card lists meals; a row opens to its foods', (
      tester,
    ) async {
      final now = DateTime.now();
      final at = DateTime(now.year, now.month, now.day, 8, 10);
      await tester.runAsync(() async {
        await meals.insert(
          entry('m1', at, [
            await item('m1', oats, 50),
            await item('m1', banana, 100),
          ]),
        );
      });
      await pump(tester, const MealListScreen());

      expect(find.byType(MealDayCard), findsOneWidget);
      expect(find.text('290 kcal'), findsOneWidget); // 200 + 90
      expect(find.textContaining('2 foods'), findsOneWidget);
      expect(find.text('Rolled oats'), findsNothing);

      await tester.tap(find.byType(MealRow));
      await tester.pumpAndSettle();
      expect(find.text('Rolled oats'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Edit meal'), findsOneWidget);
    });

    testWidgets('↻ logs the same foods again now, and Undo removes it', (
      tester,
    ) async {
      final at = DateTime.now().subtract(const Duration(days: 1));
      await tester.runAsync(() async {
        await meals.insert(entry('m1', at, [await item('m1', oats, 50)]));
      });
      await pump(tester, const MealListScreen());

      await tester.tap(find.byTooltip('Log again now'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final all = (await tester.runAsync(meals.getAll))!;
      expect(all, hasLength(2));
      final copy = all.firstWhere((m) => m.id != 'm1');
      expect(copy.items.single.foodId, oats);
      expect(copy.items.single.amount, 50);
      expect(copy.totalCalories, closeTo(200, 0.01));
      expect(find.byType(MealDayCard), findsNWidgets(2));

      await tester.tap(find.text('Undo'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect((await tester.runAsync(meals.getAll))!, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('meal editor', () {
    testWidgets('has no name field; save is off until a food is added', (
      tester,
    ) async {
      await pump(tester, const MealFormScreen());
      expect(find.text('Name'), findsNothing);
      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('mealEditSearch')),
        'ban',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('suggest-$banana')));
      await tester.pumpAndSettle();
      expect(find.text('90 kcal'), findsOneWidget); // 100 g default
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final saved = (await tester.runAsync(meals.getAll))!.single;
      expect(saved.name, isEmpty);
      expect(saved.items.single.foodId, banana);
      expect(saved.items.single.amount, 100);
    });

    testWidgets('a food added again starts at the grams used last time', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await meals.insert(
          entry('m1', DateTime(2026, 11, 20, 8), [await item('m1', oats, 65)]),
        );
      });
      await pump(tester, const MealFormScreen());
      await tester.enterText(
        find.byKey(const ValueKey('mealEditSearch')),
        'oat',
      );
      await tester.pumpAndSettle();
      expect(find.text('last 65 g'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('suggest-$oats')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '65'), findsOneWidget);
    });

    testWidgets('editing grams persists the rescaled portion', (tester) async {
      await tester.runAsync(() async {
        await meals.insert(
          entry('m1', DateTime(2026, 11, 20, 8), [await item('m1', oats, 100)]),
        );
      });
      final existing = (await tester.runAsync(meals.getAll))!.single;
      await pump(tester, MealFormScreen(meal: existing));
      expect(find.text('Rolled oats'), findsOneWidget);
      expect(find.text('400'), findsWidgets); // total kcal

      await tester.enterText(find.widgetWithText(TextField, '100'), '150');
      await tester.pumpAndSettle();
      expect(find.text('600'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final updated = (await tester.runAsync(meals.getAll))!.single;
      expect(updated.items.single.amount, 150);
      expect(updated.totalCalories, closeTo(600, 0.01));
    });

    testWidgets('delete removes the meal, with Undo', (tester) async {
      await tester.runAsync(() async {
        await meals.insert(
          entry('m1', DateTime(2026, 11, 20, 8), [await item('m1', oats, 100)]),
        );
      });
      final existing = (await tester.runAsync(meals.getAll))!.single;
      await pump(tester, MealFormScreen(meal: existing));
      await tester.tap(find.text('Delete meal'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect((await tester.runAsync(meals.getAll))!, isEmpty);
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
