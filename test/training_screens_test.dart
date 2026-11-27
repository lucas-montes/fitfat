import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/screens/training_screen.dart';
import 'package:fitfat/src/exercise/screens/workout_history_screen.dart';
import 'package:fitfat/src/exercise/screens/workout_templates_screen.dart';
import 'package:fitfat/src/exercise/screens/workout_summary_screen.dart';
import 'package:fitfat/src/exercise/screens/exercise_list.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  var n = 0;

  Future<void> workout(
    String id,
    String name,
    DateTime day, {
    String? routineId,
    bool active = false,
  }) async {
    await database
        .into(database.workouts)
        .insert(
          db.WorkoutsCompanion.insert(
            id: id,
            name: name,
            date: day.millisecondsSinceEpoch,
            startedAt: Value(
              day.subtract(const Duration(minutes: 50)).millisecondsSinceEpoch,
            ),
            completedAt: active
                ? const Value.absent()
                : Value(day.millisecondsSinceEpoch),
            routineId: Value(routineId),
            createdAt: day.millisecondsSinceEpoch,
          ),
        );
    if (active) return;
    await database
        .into(database.exercises)
        .insertOnConflictUpdate(
          db.ExercisesCompanion.insert(
            id: 'bench',
            name: 'Bench press',
            exerciseType: 'weightlifting',
            createdAt: 0,
          ),
        );
    await database
        .into(database.workoutExercises)
        .insert(
          db.WorkoutExercisesCompanion.insert(
            id: 'we-$id',
            workoutId: id,
            exerciseId: 'bench',
            sortOrder: 0,
          ),
        );
    await database
        .into(database.exerciseSets)
        .insert(
          db.ExerciseSetsCompanion.insert(
            id: 's${n++}',
            workoutExerciseId: 'we-$id',
            setNumber: 1,
            actualReps: const Value(8),
            actualWeightKg: const Value(80),
          ),
        );
  }

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    container
        .read(syncApiKeysProvider.notifier)
        .set(await SyncKeyStore.load(prefs));
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
    container.read(startupGateProvider.notifier).complete();
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FitFatTheme.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('home: one recent card per routine, active strip on top', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      await workout(
        'a',
        'Bench day',
        now.subtract(const Duration(days: 9)),
        routineId: 'r',
      );
      await workout(
        'b',
        'Bench day',
        now.subtract(const Duration(days: 2)),
        routineId: 'r',
      );
      await workout('c', 'Skate', now.subtract(const Duration(days: 1)));
      await workout('x', 'Legs', now, active: true);
    });
    await pump(tester, const TrainingScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Bench day'), findsOneWidget);
    expect(find.text('Skate'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('×2'), findsOneWidget);
    expect(find.text('Start'), findsNWidgets(2));
  });

  testWidgets('history: week cards with rows; month chip filters', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await workout('a', 'Bench day', DateTime(2026, 10, 14, 19));
      await workout('b', 'Skate', DateTime(2026, 11, 21, 19));
      await workout('c', 'Pull', DateTime(2026, 11, 22, 19));
    });
    await pump(tester, const WorkoutHistoryScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Bench day'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
    expect(find.text('Nov 16–22'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nov'));
    await tester.pumpAndSettle();
    expect(find.text('Bench day'), findsNothing);
    expect(find.text('Skate'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsNWidgets(2));
  });

  testWidgets('templates: card lists exercises with targets and Start', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await workout('a', 'Bench day', DateTime(2026, 10, 14, 19));
      final now = DateTime.now().millisecondsSinceEpoch;
      await database
          .into(database.workoutTemplates)
          .insert(
            db.WorkoutTemplatesCompanion.insert(
              id: 't',
              name: 'Bench 85 block',
              startDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.workoutTemplateExercises)
          .insert(
            db.WorkoutTemplateExercisesCompanion.insert(
              id: 'te',
              templateId: 't',
              exerciseId: 'bench',
              sortOrder: 0,
            ),
          );
      for (var i = 1; i <= 4; i++) {
        await database
            .into(database.workoutTemplateSets)
            .insert(
              db.WorkoutTemplateSetsCompanion.insert(
                id: 'ts$i',
                templateExerciseId: 'te',
                setNumber: i,
                reps: const Value(5),
                weightKg: const Value(85),
              ),
            );
      }
    });
    await pump(tester, const WorkoutTemplatesScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Bench 85 block'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('4 × 5 · 85.0 kg'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('workout detail: summary, set bars with rest, PR, danger row', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // Earlier session: 80 x 8 (sets the bar to beat).
      await workout('old', 'Bench day', DateTime(2026, 11, 12, 19));
      final day = DateTime(2026, 11, 24, 19);
      await database
          .into(database.workouts)
          .insert(
            db.WorkoutsCompanion.insert(
              id: 'w',
              name: 'Bench day',
              date: day.millisecondsSinceEpoch,
              startedAt: Value(
                day
                    .subtract(const Duration(minutes: 54))
                    .millisecondsSinceEpoch,
              ),
              completedAt: Value(day.millisecondsSinceEpoch),
              createdAt: day.millisecondsSinceEpoch,
            ),
          );
      await database
          .into(database.workoutExercises)
          .insert(
            db.WorkoutExercisesCompanion.insert(
              id: 'we-w',
              workoutId: 'w',
              exerciseId: 'bench',
              sortOrder: 0,
            ),
          );
      for (final (i, reps, actual, kg, rest) in [
        (1, 8, 8, 80.0, 130),
        (2, 8, 7, 80.0, 165),
        (3, 5, 5, 85.0, null),
      ]) {
        await database
            .into(database.exerciseSets)
            .insert(
              db.ExerciseSetsCompanion.insert(
                id: 'w-s$i',
                workoutExerciseId: 'we-w',
                setNumber: i,
                reps: Value(reps),
                weightKg: Value(kg),
                actualReps: Value(actual),
                actualWeightKg: Value(kg),
                actualRestSeconds: Value(rest),
              ),
            );
      }
    });
    await pump(tester, const WorkoutSummaryScreen(workoutId: 'w'));
    expect(tester.takeException(), isNull);
    expect(find.text('80.0 kg × 7'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget);
    expect(find.text('85.0 kg × 5 · PR'), findsOneWidget);
    expect(find.text('02:10'), findsOneWidget);
    expect(find.text('02:28'), findsOneWidget); // average rest
    expect(
      find.textContaining('1 PR · Bench press 85.0 kg × 5'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Delete workout'), 200);
    expect(find.text('Also removes 3 logged sets'), findsOneWidget);
  });

  testWidgets(
    'exercises: grid when browsing, facet dropdown with live count, rows with last set',
    (tester) async {
      await tester.runAsync(() async {
        await workout('a', 'Bench day', DateTime(2026, 11, 24, 19));
        await (database.update(
          database.exercises,
        )..where((e) => e.id.equals('bench'))).write(
          const db.ExercisesCompanion(
            bodyPart: Value('Chest'),
            equipment: Value('Barbell'),
          ),
        );
        await database
            .into(database.exercises)
            .insert(
              db.ExercisesCompanion.insert(
                id: 'squat',
                name: 'Squat',
                exerciseType: 'weightlifting',
                createdAt: 0,
                bodyPart: const Value('Legs'),
              ),
            );
      });
      await pump(tester, const ExerciseListScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('Chest · Barbell'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.text('Body part'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Chest'));
      await tester.pumpAndSettle();
      expect(find.text('Show 1 exercise'), findsOneWidget);
      await tester.tap(find.text('Show 1 exercise'));
      await tester.pumpAndSettle();

      expect(find.text('Body part: Chest'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      expect(find.text('Squat'), findsNothing);
      expect(find.text('80 kg × 8'), findsOneWidget);
    },
  );
}
