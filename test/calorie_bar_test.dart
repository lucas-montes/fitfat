import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/theme.dart';
import 'package:fitfat/src/ui/widgets/calorie_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bar's whole job is geometry: where the fill stops, where the target line
/// sits, and how far the overage spills past it. That arithmetic is exposed as
/// [CalorieBar.geometryFor] and tested here directly — asserting on rendered
/// colours instead would describe the theme seed, not the behaviour.
void main() {
  const mark = CalorieBar.targetMarkFraction;

  group('target mark', () {
    test('is fixed, and does not move with progress', () {
      expect(mark, 0.8);
      final low = CalorieBar.geometryFor(600, 3000);
      final high = CalorieBar.geometryFor(3900, 3000);
      // Nothing in the return value depends on progress for the mark itself,
      // but the invariant is that fill can never reach or pass it.
      expect(low.fill, lessThan(mark));
      expect(high.fill, closeTo(mark, 1e-9));
    });
  });

  group('fill', () {
    test('is proportional to progress up to the target', () {
      // Halfway to target fills half of the 80% reserved for it.
      expect(CalorieBar.geometryFor(1500, 3000).fill, closeTo(0.4, 1e-9));
      expect(CalorieBar.geometryFor(300, 3000).fill, closeTo(0.08, 1e-9));
      expect(CalorieBar.geometryFor(0, 3000).fill, 0);
    });

    test('stops at the mark however much is eaten', () {
      expect(CalorieBar.geometryFor(99999, 3000).fill, closeTo(mark, 1e-9));
    });

    test('is not negative for a negative intake', () {
      expect(CalorieBar.geometryFor(-200, 3000).fill, 0);
    });
  });

  group('overfill', () {
    test('is absent at or below the target', () {
      expect(CalorieBar.geometryFor(0, 3000).over, 0);
      expect(CalorieBar.geometryFor(2999, 3000).over, 0);
      expect(CalorieBar.geometryFor(3000, 3000).over, 0);
    });

    test('starts at the target mark and grows rightwards', () {
      final g = CalorieBar.geometryFor(3150, 3000);
      // 5% over fills a fifth of the 20% headroom zone.
      expect(g.fill, closeTo(mark, 1e-9));
      expect(g.over, closeTo(0.2 * 0.2, 1e-9));
    });

    test('clamps to the headroom zone so it cannot overflow the layout', () {
      // 200% over is far past the 125% cap.
      final g = CalorieBar.geometryFor(9000, 3000);
      expect(g.fill, closeTo(mark, 1e-9));
      expect(g.over, closeTo(1.0 - mark, 1e-9));
    });
  });

  group('severity', () {
    test('escalates past 110% of the target', () {
      expect(CalorieBar.geometryFor(3000, 3000).severe, isFalse);
      expect(CalorieBar.geometryFor(3299, 3000).severe, isFalse);
      expect(CalorieBar.geometryFor(3300, 3000).severe, isFalse);
      expect(CalorieBar.geometryFor(3301, 3000).severe, isTrue);
    });

    test('stays severe once the overfill has saturated', () {
      // Colour escalation must not be lost when the bar stops growing.
      final g = CalorieBar.geometryFor(9000, 3000);
      expect(g.over, closeTo(1.0 - mark, 1e-9));
      expect(g.severe, isTrue);
    });
  });

  group('degenerate target', () {
    test('zero target does not divide by zero', () {
      final g = CalorieBar.geometryFor(500, 0);
      expect(g.fill, 0);
      expect(g.over, 0);
      expect(g.severe, isFalse);
    });

    test('negative target renders the empty track', () {
      final g = CalorieBar.geometryFor(100, -50);
      expect(g.fill, 0);
      expect(g.over, 0);
      expect(g.severe, isFalse);
    });
  });

  group('widget', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required double consumed,
      required double target,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FitFatTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CalorieBar(consumed: consumed, target: target),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('headline states consumed against target', (tester) async {
      await pumpBar(tester, consumed: 3240, target: 3000);
      expect(find.text('3240 / 3000 kcal'), findsOneWidget);
    });

    testWidgets('renders at every stage without overflowing', (tester) async {
      for (final consumed in [0.0, 1500.0, 3000.0, 3300.0, 9000.0]) {
        await pumpBar(tester, consumed: consumed, target: 3000);
        expect(
          tester.takeException(),
          isNull,
          reason: 'overage state at $consumed kcal overflowed or threw',
        );
      }
    });

    testWidgets('a degenerate target still renders', (tester) async {
      await pumpBar(tester, consumed: 500, target: 0);
      expect(tester.takeException(), isNull);
    });
  });
}
