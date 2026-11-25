import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:fitfat/src/sync/screens/sync_hub_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The status-first sync screen at phone size: hero with "Sync now", the
/// collapsed data list that expands, and a per-type sheet that offers only
/// the directions that type supports.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;

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
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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
          home: const SyncHubScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the hero and a collapsed data list', (tester) async {
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('No server yet'), findsOneWidget);
    expect(find.text('Workouts · 0'), findsOneWidget);
    expect(find.text('Receipts · 0'), findsNothing);

    await tester.ensureVisible(find.text('Show all 15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show all 15'));
    await tester.pumpAndSettle();
    expect(find.text('Show less', skipOffstage: false), findsOneWidget);
    expect(find.text('Receipts · 0', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pull-only type has only the get button', (tester) async {
    await pump(tester);

    expect(find.byTooltip('Pull Transactions'), findsOneWidget);
    expect(find.byTooltip('Push Transactions'), findsNothing);
  });

  testWidgets('a two-way type has both buttons, one tap each', (tester) async {
    await pump(tester);

    expect(find.byTooltip('Push Workouts'), findsOneWidget);
    expect(find.byTooltip('Pull Workouts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
