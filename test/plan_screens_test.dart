import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/goals/notifications/goal_reminder.dart';
import 'package:fitfat/src/goals/providers/goals.dart';
import 'package:fitfat/src/goals/repositories/goal_repository.dart';
import 'package:fitfat/src/goals/services/goal_tracking.dart';
import 'package:fitfat/src/models/goal.dart';
import 'package:fitfat/src/planner/repositories/task_repository.dart';
import 'package:fitfat/src/planner/screens/planner_screen.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Goal goal(
  String id, {
  String? source,
  String? param,
  double target = 100,
  double? baseline,
  GoalStatus status = GoalStatus.active,
}) => Goal(
  id: id,
  title: id,
  startDate: DateTime(2026, 1, 1),
  status: status,
  targetType: GoalTargetType.numeric,
  targetValue: target,
  baselineValue: baseline,
  trackSource: source,
  trackParam: param,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late db.AppDatabase database;
  late GoalRepository goals;
  ProviderContainer? container;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    goals = GoalRepository(database);
    SharedPreferences.setMockInitialValues({'settings_has_seen_wizard': true});
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    container?.dispose();
    container = null;
    await database.close();
  });

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    c.read(syncApiKeysProvider.notifier).set(await SyncKeyStore.load(prefs));
    c.read(sharedPreferencesHolderProvider.notifier).set(prefs);
    c.read(startupGateProvider.notifier).complete();
    container = c;
    return c;
  }

  Future<void> workoutSet(String id, DateTime day, double kg) async {
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
        .into(database.workouts)
        .insert(
          db.WorkoutsCompanion.insert(
            id: id,
            name: 'Bench day',
            date: day.millisecondsSinceEpoch,
            completedAt: Value(day.millisecondsSinceEpoch),
            createdAt: day.millisecondsSinceEpoch,
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
            id: 's-$id',
            workoutExerciseId: 'we-$id',
            setNumber: 1,
            actualReps: const Value(5),
            actualWeightKg: Value(kg),
          ),
        );
  }

  group('goal tracking', () {
    test('best set: a running best from finished workouts', () async {
      await workoutSet('w1', DateTime(2026, 10, 1), 80);
      await workoutSet('w2', DateTime(2026, 10, 8), 85);
      await workoutSet('w3', DateTime(2026, 10, 15), 82.5);
      await goals.upsertGoal(
        goal('g', source: 'exercise_best', param: 'bench', baseline: 80),
      );
      final c = await makeContainer();
      final s = await c.read(goalStatusProvider('g').future);
      expect(s.points.map((p) => p.value), [80, 85, 85]);
      expect(s.current, 85);
      expect(s.progress, closeTo(0.25, 1e-9));
      expect(s.source, TrackSource.exerciseBest);
    });

    test('body weight: the latest weigh-in', () async {
      for (final (d, kg) in [(1, 80.0), (8, 79.2), (15, 78.6)]) {
        await database
            .into(database.bodyMetrics)
            .insert(
              db.BodyMetricsCompanion.insert(
                id: 'b$d',
                date: DateTime(2026, 11, d).millisecondsSinceEpoch,
                weightKg: Value(kg),
                createdAt: 0,
              ),
            );
      }
      await goals.upsertGoal(
        goal('w', source: 'body_weight', target: 75, baseline: 80),
      );
      final c = await makeContainer();
      final s = await c.read(goalStatusProvider('w').future);
      expect(s.current, 78.6);
      expect(s.progress, closeTo(0.28, 1e-9));
    });

    test('manual: the progress log', () async {
      await goals.upsertGoal(goal('m', target: 12));
      await goals.recordProgress(
        goalId: 'm',
        day: DateTime(2026, 11, 1),
        value: 4,
      );
      await goals.recordProgress(
        goalId: 'm',
        day: DateTime(2026, 11, 20),
        value: 5,
      );
      final c = await makeContainer();
      final s = await c.read(goalStatusProvider('m').future);
      expect(s.points.map((p) => p.value), [4, 5]);
      expect(s.source, isNull);
    });

    test('tracking survives a round trip through the repository', () async {
      await goals.upsertGoal(goal('t', source: 'account_balance', param: 'a1'));
      final g = (await goals.getGoalById('t'))!;
      expect(g.trackSource, 'account_balance');
      expect(g.trackParam, 'a1');
      expect(g.isManual, isFalse);
    });
  });

  test('a notification reply is queued, then recorded', () async {
    await goals.upsertGoal(goal('books', target: 12));
    final queued = await queueGoalReply(
      const NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction,
        actionId: goalReplyActionId,
        input: '6',
        payload: '$goalReminderPayload:books',
      ),
    );
    expect(queued, isTrue);
    expect(await goals.getLatestProgressValue('books'), isNull);
    expect(await drainGoalReplies(goals), 1);
    expect(await goals.getLatestProgressValue('books'), 6);
    // The queue is empty afterwards.
    expect(await drainGoalReplies(goals), 0);
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester) async {
      final c = await tester.runAsync(makeContainer);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c!,
          child: MaterialApp(
            theme: FitFatTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const PlannerScreen(),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Today lists timed tasks with times, then anytime ones', (
      tester,
    ) async {
      final today = DateTime.now();
      await tester.runAsync(() async {
        final repo = TaskRepository(database);
        await repo.insert(
          newTask(
            day: today,
            title: 'Deep work',
            startTimeMinutes: 9 * 60,
            endTimeMinutes: 11 * 60,
          ),
        );
        await repo.insert(newTask(day: today, title: 'Pay rent', sortOrder: 1));
      });
      await pump(tester);
      expect(find.text('Deep work'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
      expect(find.text('ANYTIME'), findsOneWidget);
      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.textContaining('0 of 2 done'), findsOneWidget);
    });

    testWidgets('quick add keeps the sheet open for the next task', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('quickAddTitle')),
        'Call the bank',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quickAddSubmit')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      // Still open, ready for the next one.
      expect(find.byKey(const ValueKey('quickAddTitle')), findsOneWidget);
      final today = DateTime.now();
      final tasks = (await tester.runAsync(
        () => TaskRepository(
          database,
        ).getByDay(DateTime(today.year, today.month, today.day)),
      ))!;
      expect(tasks.map((t) => t.title), ['Call the bank']);
    });

    testWidgets('a manual goal steps +1 from its card', (tester) async {
      await tester.runAsync(() async {
        await goals.upsertGoal(goal('Read 12 books', target: 12));
        await goals.recordProgress(
          goalId: 'Read 12 books',
          day: DateTime.now().subtract(const Duration(days: 3)),
          value: 5,
        );
      });
      await pump(tester);
      await tester.tap(find.text('Goals'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 / 12'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('goalStep-Read 12 books')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () => goals.getLatestProgressValue('Read 12 books'),
        ),
        6,
      );
      expect(find.text('6 / 12'), findsOneWidget);
      container!.invalidate(goalListProvider);
    });
  });
}
