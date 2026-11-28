import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/dashboard/providers/dashboard_layout.dart';
import 'package:fitfat/src/dashboard/screens/dashboard.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:fitfat/src/settings/screens/settings_screen.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DashboardLayout', () {
    test('parseOrder keeps saved order, drops unknown, appends new cards', () {
      expect(
        DashboardLayoutNotifier.parseOrder([
          'money',
          'bogus',
          'tasks',
          'money',
        ]),
        [
          DashboardCard.money,
          DashboardCard.tasks,
          DashboardCard.nutrition,
          DashboardCard.training,
          DashboardCard.weight,
          DashboardCard.goals,
        ],
      );
      expect(DashboardLayoutNotifier.parseOrder(null), DashboardCard.values);
    });

    test('defaults put nutrition and tasks first', () {
      expect(DashboardLayout.defaults.visible.take(2), [
        DashboardCard.nutrition,
        DashboardCard.tasks,
      ]);
    });

    test('reorder and hide persist', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      final n = c.read(dashboardLayoutProvider.notifier);

      await n.reorder(5, 0); // money to the top
      await n.setVisible(DashboardCard.weight, false);
      final layout = c.read(dashboardLayoutProvider);
      expect(layout.order.first, DashboardCard.money);
      expect(layout.visible, isNot(contains(DashboardCard.weight)));

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      expect(c2.read(dashboardLayoutProvider).order.first, DashboardCard.money);
      expect(
        c2.read(dashboardLayoutProvider).hidden,
        contains(DashboardCard.weight),
      );
    });
  });

  group('screens', () {
    late db.AppDatabase database;
    late ProviderContainer container;

    setUp(() async {
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      SharedPreferences.setMockInitialValues({
        // Skip the onboarding wizard.
        'settings_has_seen_wizard': true,
      });
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
      tester.view.physicalSize = const Size(390, 1600);
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

    testWidgets('dashboard: cards in order, empty ones offer a start action', (
      tester,
    ) async {
      await pump(tester, const DashboardScreen());
      expect(tester.takeException(), isNull);

      final nutrition = tester.getTopLeft(find.text('Nutrition')).dy;
      final tasks = tester.getTopLeft(find.text('Tasks')).dy;
      expect(nutrition, lessThan(tasks));
      expect(find.text('Log meal'), findsOneWidget);
      expect(find.text('Add task'), findsOneWidget);
      expect(find.text('Set a goal', skipOffstage: false), findsOneWidget);

      await container
          .read(dashboardLayoutProvider.notifier)
          .setVisible(DashboardCard.tasks, false);
      await tester.pumpAndSettle();
      expect(find.text('Tasks'), findsNothing);
    });

    testWidgets('settings hub: inline controls and search', (tester) async {
      await pump(tester, const SettingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('Dark'), findsOneWidget); // theme segment, inline
      expect(find.text('Rest alarm sound'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'rest');
      await tester.pumpAndSettle();
      expect(find.text('Rest alarm sound'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No settings match'), findsOneWidget);
    });
  });
}
