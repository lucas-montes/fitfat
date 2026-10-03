import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/diet/screens/meal_list.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A meal name is optional, so the list has to render something meaningful for a
/// blank one. The column is NOT NULL, so the blank is stored as an empty string
/// and this fallback is the only thing standing between the user and a blank
/// title line.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  Future<void> pumpList(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    // The meal list returns nothing until startup completes. Flipping the real
    // gate through a container rather than overriding it keeps the ordering
    // explicit — the provider must not be read before this.
    container.read(startupGateProvider.notifier).complete();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: MealListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed(String id, String name) async {
    await database
        .into(database.meals)
        .insert(
          db.MealsCompanion.insert(
            id: id,
            name: name,
            eatenAt: DateTime(2026, 3, 12, 14, 30).millisecondsSinceEpoch,
            createdAt: DateTime(2026, 3, 12, 14, 30).millisecondsSinceEpoch,
          ),
        );
  }

  testWidgets('a named meal shows its name', (tester) async {
    await seed('m1', 'Breakfast');
    await pumpList(tester);
    expect(find.text('Breakfast'), findsOneWidget);
  });

  testWidgets('an unnamed meal falls back to a dated label, not a blank', (
    tester,
  ) async {
    await seed('m2', '');
    await pumpList(tester);

    expect(find.text('Breakfast'), findsNothing);
    // A generic label that still identifies the meal.
    expect(
      find.textContaining('Meal ·'),
      findsOneWidget,
      reason: 'a blank name must still render a title',
    );
    // And it is a real title, not an empty Text.
    final title = tester.widget<Text>(find.textContaining('Meal ·'));
    expect(title.data, isNotEmpty);
  });

  testWidgets('a whitespace-only name is treated as no name', (tester) async {
    // `name.trim()` — a stray space should not produce a blank-looking title.
    await seed('m3', '   ');
    await pumpList(tester);
    expect(find.textContaining('Meal ·'), findsOneWidget);
  });
}
