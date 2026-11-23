import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/exercise/screens/exercise_form.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Custom exercises (skating) have no catalogue MET, so the form lets the
/// user set one, by hand or from a preset.
void main() {
  late db.AppDatabase database;
  late ExerciseRepository repo;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseRepository(database);
  });
  tearDown(() => database.close());

  Future<void> openForm(WidgetTester tester, {Exercise? exercise}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<Object?>(
                  builder: (_) => ExerciseFormScreen(exercise: exercise),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('a new cardio exercise takes a preset MET', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Skating');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cardio').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skating · 7'));
    await tester.pumpAndSettle();
    await save(tester);

    final saved = (await repo.getAll()).single;
    expect(saved.name, 'Skating');
    expect(saved.met, 7.0);
  });

  testWidgets('an existing exercise can be re-rated, comma decimal', (
    tester,
  ) async {
    final skate = newExercise(
      name: 'Skating',
      exerciseType: 'cardio',
    ).copyWith(met: 7.0);
    await repo.insert(skate);
    await openForm(tester, exercise: skate);

    expect(find.widgetWithText(TextFormField, '7'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('exercise-met')), '7,5');
    await save(tester);
    expect((await repo.getById(skate.id))!.met, 7.5);
  });

  testWidgets('out-of-range values are rejected', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Odd');
    await tester.enterText(find.byKey(const Key('exercise-met')), '40');
    await save(tester);
    expect(find.text('Enter a number from 1 to 25'), findsOneWidget);
    expect(await repo.getAll(), isEmpty);
  });

  testWidgets('catalogue exercises keep their curated MET', (tester) async {
    final walking = Exercise(
      id: 'walking',
      name: 'Walking',
      exerciseType: 'cardio',
      bodyPart: 'Cardio',
      met: 3.5,
      createdAt: DateTime(2026),
    );
    await repo.insert(walking);
    await openForm(tester, exercise: walking);
    expect(find.byKey(const Key('exercise-met')), findsNothing);
    await save(tester);
    expect((await repo.getById('walking'))!.met, 3.5);
  });
}
