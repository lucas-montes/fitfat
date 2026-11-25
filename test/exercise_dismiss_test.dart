import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/repositories/exercise_repository.dart';
import 'package:fitfat/src/exercise/providers/exercises.dart';
import 'package:fitfat/src/exercise/screens/exercise_list.dart';
import 'package:fitfat/src/models/exercise.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression cover for "A dismissed Dismissible widget is still part of the
/// tree" on the exercise list: the swipe-delete awaited a catalog lookup
/// before the row left the list, so the next rebuild asserted.
void main() {
  late db.AppDatabase database;
  late ExerciseRepository repo;
  late ProviderContainer container;
  var slowRefetch = false;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseRepository(database);
    for (final name in ['Squat', 'Bench']) {
      await repo.insert(
        Exercise(
          id: name,
          name: name,
          exerciseType: 'weightlifting',
          createdAt: DateTime(2026, 1, 1),
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
      overrides: [
        databaseProvider.overrideWithValue(database),
        // On a phone the refetch after a delete takes longer than a frame, so
        // the list rebuilds once with the stale rows first. Reproduce that.
        exerciseListProvider.overrideWith((ref) async {
          final rows = await ExerciseRepository(database).getAll();
          if (slowRefetch) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          return rows;
        }),
      ],
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
          home: const ExerciseListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swiping an exercise away does not throw', (tester) async {
    await pumpList(tester);
    expect(find.text('Squat'), findsOneWidget);
    slowRefetch = true;

    await tester.drag(find.text('Squat'), const Offset(-600, 0));
    // Frame by frame through the dismiss animation and the slow refetch: the
    // window in which a still-listed dismissed row asserts.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Squat'), findsNothing);
    expect(find.text('Bench'), findsOneWidget);
    expect((await repo.getAll()).map((e) => e.id), ['Bench']);
  });
}
