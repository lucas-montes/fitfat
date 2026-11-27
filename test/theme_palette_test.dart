import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/settings/providers/appearance.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/ui/palettes.dart';
import 'package:fitfat/src/ui/widgets/confirm_delete.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('palettes', () {
    test('defaults are Dracula (dark) and Alucard (light)', () {
      expect(defaultDarkPalette.name, 'Dracula');
      expect(defaultLightPalette.name, 'Alucard');
      expect(paletteById(null, Brightness.dark).id, 'dracula');
      expect(paletteById('gone', Brightness.light).id, 'alucard');
    });

    test('ids are unique per brightness and brightness matches the list', () {
      for (final list in [darkPalettes, lightPalettes]) {
        expect(list.map((p) => p.id).toSet().length, list.length);
        expect(list.map((p) => p.brightness).toSet().length, 1);
      }
    });

    for (final p in [...darkPalettes, ...lightPalettes]) {
      test('${p.name} (${p.brightness.name}) keeps text readable', () {
        expect(_contrast(p.fg, p.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.fg, p.surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.muted, p.bg), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.onAccent, p.accent), greaterThanOrEqualTo(3));
      });
    }

    test('theme maps palette roles onto the color scheme', () {
      final p = defaultDarkPalette;
      final t = FitFatTheme.fromPalette(p);
      expect(t.colorScheme.primary, p.accent);
      expect(t.colorScheme.error, p.danger);
      expect(t.scaffoldBackgroundColor, p.bg);
      expect(t.cardTheme.color, p.surface);
      expect(identical(t, FitFatTheme.fromPalette(p)), isTrue);
    });
  });

  group('appearance setting', () {
    test('palette choice persists per brightness', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sharedPreferencesHolderProvider.notifier).set(prefs);

      expect(c.read(appearanceProvider).dark.id, 'dracula');
      final nord = darkPalettes.firstWhere((p) => p.id == 'nord');
      await c.read(appearanceProvider.notifier).setPalette(nord);
      expect(c.read(appearanceProvider).dark.id, 'nord');
      expect(c.read(appearanceProvider).light.id, 'alucard');
      expect(prefs.getString(AppearanceNotifier.darkPaletteKey), 'nord');

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      expect(c2.read(appearanceProvider).dark.id, 'nord');
    });
  });

  group('confirmDelete', () {
    Future<BuildContext> pump(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: FitFatTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return ctx;
    }

    testWidgets('no cascade: deletes at once and offers Undo', (tester) async {
      final ctx = await pump(tester);
      var deleted = false, undone = false;
      final f = confirmDelete(
        ctx,
        itemName: 'Banana',
        delete: () async => deleted = true,
        undo: () async => undone = true,
      );
      await tester.pump();
      expect(await f, isTrue);
      expect(deleted, isTrue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Banana deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(undone, isTrue);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('cascade: lists what goes and waits for confirmation', (
      tester,
    ) async {
      final ctx = await pump(tester);
      var deleted = false;
      final f = confirmDelete(
        ctx,
        itemName: 'Push day',
        delete: () async => deleted = true,
        cascade: const [
          (label: 'Sets', count: 18),
          (label: 'Voice notes', count: 0),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete Push day?'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Voice notes'), findsNothing);
      expect(deleted, isFalse);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await f, isFalse);
      expect(deleted, isFalse);
    });
  });
}
