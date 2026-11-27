import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/screens/training_screen.dart';
import 'package:fitfat/src/exercise/screens/workout_history_screen.dart';
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
}
