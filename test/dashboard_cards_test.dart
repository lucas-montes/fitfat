import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/body/repositories/body_metrics_repository.dart';
import 'package:fitfat/src/dashboard/screens/dashboard.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/goals/repositories/goal_repository.dart';
import 'package:fitfat/src/models/goal.dart';
import 'package:fitfat/src/models/task.dart';
import 'package:fitfat/src/planner/repositories/task_repository.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Goal _goal(String id, {DateTime? start, DateTime? end}) => Goal(
  id: id,
  title: id,
  startDate: start ?? DateTime(2026, 1, 1),
  endDate: end,
  status: GoalStatus.active,
  targetType: GoalTargetType.numeric,
  targetValue: 10,
  baselineValue: 0,
  unit: 'km',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('goalPaceGap', () {
    final now = DateTime(2026, 7, 2);
    test('half the time gone, a quarter done: a quarter behind', () {
      final g = _goal(
        'g',
        start: DateTime(2026, 1, 1),
        end: DateTime(2027, 1, 1),
      );
      expect(goalPaceGap(g, 0.25, now), closeTo(0.25, 0.01));
    });
    test('no end date or no progress: no pace', () {
      expect(goalPaceGap(_goal('g'), 0.5, now), isNull);
      expect(goalPaceGap(_goal('g', end: DateTime(2027)), null, now), isNull);
    });
  });

  group('dashboard with data', () {
    late db.AppDatabase database;
    ProviderContainer? container;

    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({
        'settings_has_seen_wizard': true,
        'settings_base_currency': 'EUR',
      });
      FlutterSecureStorage.setMockInitialValues({});
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int ms(DateTime d) => d.millisecondsSinceEpoch;

      // A finished workout, one in progress and one planned for today.
      final past = today.subtract(const Duration(days: 2));
      for (final (id, name, day, started, completed) in [
        (
          'done',
          'Bench day',
          past,
          past.add(const Duration(hours: 18)),
          past.add(const Duration(hours: 19)),
        ),
        ('active', 'Running now', today, now, null),
        ('plan', 'Legs plan', today, null, null),
      ]) {
        await database
            .into(database.workouts)
            .insert(
              db.WorkoutsCompanion.insert(
                id: id,
                name: name,
                date: ms(day),
                startedAt: Value(started == null ? null : ms(started)),
                completedAt: Value(completed == null ? null : ms(completed)),
                createdAt: ms(day),
              ),
            );
      }

      final tasks = TaskRepository(database);
      Task task(String id, {bool done = false, int? start, int? end}) => Task(
        id: id,
        day: today,
        title: id,
        done: done,
        sortOrder: 0,
        startTimeMinutes: start,
        endTimeMinutes: end,
        taskStatus: done ? TaskStatus.done : TaskStatus.pending,
        createdAt: now,
      );
      await tasks.insert(task('Skate session', done: true, start: 0, end: 30));
      await tasks.insert(task('All day focus', start: 0, end: 24 * 60));
      await tasks.insert(task('Call Marta back'));

      final goals = GoalRepository(database);
      await goals.upsertGoal(
        _goal(
          'Run 10 km',
          start: today.subtract(const Duration(days: 100)),
          end: today.add(const Duration(days: 100)),
        ),
      );
      await goals.recordProgress(goalId: 'Run 10 km', day: now, value: 2);
      await goals.upsertGoal(_goal('Read 12 books'));

      final body = BodyMetricsRepository(database);
      await body.upsert(today.subtract(const Duration(days: 20)), weightKg: 79);
      await body.upsert(today, weightKg: 78.4);

      await database
          .into(database.accounts)
          .insert(
            db.AccountsCompanion.insert(
              id: 'bbva',
              name: 'BBVA',
              type: 'bank',
              createdAt: 0,
            ),
          );
      var n = 0;
      for (final (type, amount, category) in [
        ('income', 2150.0, 'Salary'),
        ('expense', 412.0, 'Groceries'),
        ('expense', 186.0, 'Eating out'),
        ('expense', 120.0, 'Shopping'),
        ('expense', 64.0, 'Transport'),
      ]) {
        await database
            .into(database.transactions)
            .insert(
              db.TransactionsCompanion.insert(
                id: 't${n++}',
                type: type,
                amount: amount,
                currencyCode: 'EUR',
                amountBase: amount,
                rateUsed: 1,
                accountId: const Value('bbva'),
                category: Value(category),
                date: ms(today),
                createdAt: n,
              ),
            );
      }
    });

    tearDown(() async {
      container?.dispose();
      container = null;
      await database.close();
    });

    testWidgets('every card renders at phone width without overflow', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      container = c;
      c.read(syncApiKeysProvider.notifier).set(await SyncKeyStore.load(prefs));
      c.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      c.read(startupGateProvider.notifier).complete();

      tester.view.physicalSize = const Size(360, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: FitFatTheme.dark,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Title on the app-bar line.
      expect(find.textContaining('Today'), findsWidgets);

      // Nutrition: all five nutrients as rows.
      for (final label in ['Protein', 'Carbs', 'Fat', 'Fiber', 'Sodium']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Tasks: the task on now is in the strip.
      expect(find.textContaining('Now · until'), findsOneWidget);
      expect(find.text('All day focus'), findsOneWidget);

      // Training: the planned workout with Start, never the one running.
      expect(find.text('Legs plan'), findsOneWidget);
      expect(find.text('Running now'), findsNothing);
      expect(find.text('Bench day'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('WORKOUTS'), findsOneWidget);
      expect(find.text('DAYS'), findsNothing);

      // Goals: the one with a date is featured with its pace.
      expect(find.textContaining('Behind pace'), findsOneWidget);

      // Money: categories named under the bar.
      expect(find.textContaining('Groceries'), findsOneWidget);
      expect(find.textContaining('+1 more'), findsOneWidget);
      // Amounts use the currency symbol, not the code.
      expect(find.textContaining('€'), findsWidgets);
      expect(find.textContaining('EUR'), findsNothing);
    });
  });
}
