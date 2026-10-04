import 'package:fitfat/src/ui/tokens.dart';
import 'package:fitfat/src/ui/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The compact variant exists because three tiles in a row on a phone overflowed
/// and read as misaligned. Both are layout failures, so both are asserted rather
/// than eyeballed: Flutter reports overflow as a caught exception, and centring is
/// checked against the tile's own centre.
void main() {
  /// A realistic worst case: a three-tile row on a narrow phone, with a value
  /// long enough to overflow at the default metric size.
  Future<void> pumpRow(
    WidgetTester tester, {
    required String days,
    required String time,
    required String volume,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    compact: true,
                    icon: Icons.event_available_outlined,
                    title: 'Days',
                    value: days,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    compact: true,
                    icon: Icons.timer_outlined,
                    title: 'Time',
                    value: time,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    compact: true,
                    icon: Icons.calculate_outlined,
                    title: 'Volume',
                    value: volume,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('three compact tiles do not overflow on a narrow phone', (
    tester,
  ) async {
    await pumpRow(tester, days: '3/7', time: '2 h 15 m', volume: '999.9 kg');

    // A RenderFlex overflow surfaces as an exception; none means it fits.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long value is scaled down instead of wrapping', (
    tester,
  ) async {
    await pumpRow(tester, days: '7/7', time: '12 h 30 m', volume: '48210.3 kg');
    expect(tester.takeException(), isNull);

    // Still fully readable — scaleDown shrinks to fit rather than truncating.
    expect(find.text('48210.3 kg'), findsOneWidget);

    // `Text` would wrap rather than overflow, so the failure mode being guarded
    // against is a second line, not an error. Assert the single line directly:
    // without the FittedBox this value wraps and the three tiles end up ragged.
    expect(tester.widget<Text>(find.text('48210.3 kg')).maxLines, 1);
    expect(
      find.ancestor(
        of: find.text('48210.3 kg'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a long value stays on one line at 2x text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      compact: true,
                      icon: Icons.calculate_outlined,
                      title: 'Volume',
                      value: '999.9 kg',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text('999.9 kg')).maxLines, 1);
  });

  testWidgets('a title longer than the tile is ellipsised, not wrapped', (
    tester,
  ) async {
    await pumpRow(tester, days: '3/7', time: '2 h', volume: '48.2 t');
    final title = tester.widget<Text>(
      find.descendant(
        of: find.byType(MetricCard).first,
        matching: find.text('Days'),
      ),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(title.textAlign, TextAlign.center);
  });

  testWidgets('icon and value share the tile centre line', (tester) async {
    await pumpRow(tester, days: '3/7', time: '2 h', volume: '48.2 t');

    final cardCenter = tester.getCenter(find.byType(MetricCard).first).dx;
    final iconCenter = tester
        .getCenter(
          find.descendant(
            of: find.byType(MetricCard).first,
            matching: find.byIcon(Icons.event_available_outlined),
          ),
        )
        .dx;

    expect(
      (iconCenter - cardCenter).abs(),
      lessThan(1.0),
      reason: 'the icon should sit on the tile centre line',
    );
  });

  testWidgets('the default variant is untouched and still left-aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MetricCard(icon: Icons.timer, title: 'Time', value: '2 h 15 m'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Time'));
    expect(title.textAlign, isNot(TextAlign.center));
    expect(title.maxLines, isNull);
    // Hero-sized figure preserved for the one-or-two-tile case.
    expect(
      find.byType(FittedBox),
      findsNothing,
      reason: 'only compact tiles scale their value down',
    );
  });

  test('compact padding is tighter than the default', () {
    expect(FitFatTokens.spaceS, lessThan(FitFatTokens.spaceM));
    expect(FitFatTokens.spaceM, lessThan(FitFatTokens.spaceL));
  });
}
