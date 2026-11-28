import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/exercise/providers/training.dart';
import 'package:fitfat/src/exercise/repositories/training_summaries.dart';
import 'package:fitfat/src/exercise/screens/workout_templates_screen.dart';
import 'package:fitfat/src/settings/providers/appearance.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:fitfat/src/settings/screens/custom_palette_screen.dart';
import 'package:fitfat/src/ui/palettes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nixBlock = '''
{
  base00 = "000000"; #background default (black): 282936
  base01 = "333547"; #background secondary (dark grey): 3a3c4e
  base02 = "44475a"; #background tertiary (grey less dark): 44475a
  base03 = "6272a4"; #backgroud (light grey)
  base04 = "62d6e8"; #light foreground (blue): 62d6e8
  base05 = "f8f8f2"; #foreground (white)
  base06 = "f1f2f8"; #light background (white a little dirty)
  base07 = "f3f981"; #yellow og: f7f7f7b
  base08 = "ea51b2"; #pinker
  base09 = "d95bff"; #purple
  base0A = "3ff0a9"; #green-blue og: 00f769
  base0B = "ebff87"; #yellow
  base0C = "a1efe4"; #cyan
  base0D = "51d6f4"; #blue og: 62d6e8
  base0E = "ff2fb3"; #pink og: b45bcf
  base0F = "00f769"; #green
}
''';

void main() {
  test('the defaults are exactly the base16 block, and it parses back', () {
    final parsed = parseBase16(_nixBlock);
    expect(parsed.length, 16);
    for (var i = 0; i < 16; i++) {
      expect(
        parsed[i],
        defaultBase16[i],
        reason: 'base0${i.toRadixString(16)}',
      );
    }
  });

  test('hex helpers round-trip and reject junk', () {
    expect(colorToHex(const Color(0xFFD95BFF)), 'D95BFF');
    expect(colorFromHex('#d95bff'), const Color(0xFFD95BFF));
    expect(colorFromHex('d95bf'), isNull);
    expect(colorFromHex('zz5bff'), isNull);
  });

  test('dark mapping reads base16 as written', () {
    final p = paletteFromBase16(defaultBase16, Brightness.dark);
    expect(p.bg, const Color(0xFF000000));
    expect(p.surface, const Color(0xFF333547));
    expect(p.fg, const Color(0xFFF8F8F2));
    expect(p.accent, const Color(0xFFD95BFF));
    expect(p.success, const Color(0xFF00F769));
    final light = paletteFromBase16(defaultBase16, Brightness.light);
    expect(light.bg, const Color(0xFFF1F2F8));
    expect(light.fg, const Color(0xFF000000));
  });

  group('with prefs', () {
    late ProviderContainer c;
    late db.AppDatabase database;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      c.read(syncApiKeysProvider.notifier).set(await SyncKeyStore.load(prefs));
      c.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      c.read(startupGateProvider.notifier).complete();
    });

    tearDown(() async {
      c.dispose();
      await database.close();
    });

    test(
      'editing the custom palette in use changes the theme and persists',
      () async {
        final n = c.read(appearanceProvider.notifier);
        await n.setPalette(
          c.read(appearanceProvider).customPalette(Brightness.dark),
        );
        await n.setCustomColors(Brightness.dark, {0: const Color(0xFF282936)});
        expect(c.read(appearanceProvider).dark.bg, const Color(0xFF282936));
        // Light keeps its own colors.
        expect(c.read(appearanceProvider).customLight[0], defaultBase16[0]);

        final prefs = await SharedPreferences.getInstance();
        final c2 = ProviderContainer();
        addTearDown(c2.dispose);
        c2.read(sharedPreferencesHolderProvider.notifier).set(prefs);
        final s = c2.read(appearanceProvider);
        expect(s.dark.id, customPaletteId);
        expect(s.dark.bg, const Color(0xFF282936));

        await c.read(appearanceProvider.notifier).resetCustom(Brightness.dark);
        expect(c.read(appearanceProvider).dark.bg, defaultBase16[0]);
      },
    );

    Future<void> pump(WidgetTester tester, Widget home, {Size? size}) async {
      tester.view.physicalSize = size ?? const Size(360, 2000);
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
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('editor: 16 slots, typing a hex applies it', (tester) async {
      await pump(
        tester,
        const CustomPaletteScreen(brightness: Brightness.dark),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('base00'), findsOneWidget);
      expect(find.text('base0F'), findsOneWidget);
      expect(find.text('Not used yet'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, '282936');
      await tester.pumpAndSettle();
      expect(c.read(appearanceProvider).customDark[0], const Color(0xFF282936));
    });

    testWidgets('template cards: the menu sits in the same corner on each', (
      tester,
    ) async {
      TemplateCard card(String id, String name, {DateTime? created}) =>
          TemplateCard(
            id: id,
            name: name,
            createdAt: created ?? DateTime(2020),
            lastDone: DateTime(2026, 11, 20),
            exercises: const [
              (
                name: 'Bench press',
                sets: 4,
                reps: 5,
                weightKg: 85,
                durationMinutes: null,
                distanceMeters: null,
              ),
            ],
          );
      final override = ProviderContainer(
        parent: c,
        overrides: [
          templateCardsProvider.overrideWith(
            (ref) async => [
              card('a', 'Push'),
              card(
                'b',
                'A very long template name that will not fit on one line',
              ),
            ],
          ),
        ],
      );
      addTearDown(override.dispose);
      c = override;
      await pump(tester, const WorkoutTemplatesScreen());
      expect(tester.takeException(), isNull);
      final menus = find.byType(PopupMenuButton<VoidCallback>);
      expect(menus, findsNWidgets(2));
      final cards = find.byType(Card);
      for (var i = 0; i < 2; i++) {
        final m = tester.getRect(menus.at(i));
        final k = tester.getRect(
          find.ancestor(of: menus.at(i), matching: cards).first,
        );
        expect(k.right - m.right, 0, reason: 'flush right, card $i');
        expect(m.top - k.top, 0, reason: 'flush top, card $i');
      }
    });
  });
}
