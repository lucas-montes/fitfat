import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/planner/screens/planner_screen.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late db.AppDatabase database;
  ProviderContainer? container;
  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({'settings_has_seen_wizard': true});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() async {
    container?.dispose();
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

  Future<void> pump(WidgetTester tester) async {
    final c = await tester.runAsync(makeContainer);
    tester.view.physicalSize = const Size(1280, 2772);
    tester.view.devicePixelRatio = 3.25;
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

  // A real phone geometry (1280x2772 @ 3.25): its 393.846…dp width is
  // fractional, which used to trip the pagers' fixed-extent assertion; the
  // month view used to throw "No Material widget found" from TableCalendar's
  // header. The test binding fails on any such framework error.
  testWidgets('day, month and week views lay out on a fractional-width phone', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Day, week or month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Month view'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final title = DateFormat.yMMMM('en').format(DateTime(now.year, now.month));
    expect(find.text(title), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    final next = DateFormat.yMMMM(
      'en',
    ).format(DateTime(now.year, now.month + 1));
    expect(find.text(next), findsOneWidget);

    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Day, week or month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week view'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
  });
}
