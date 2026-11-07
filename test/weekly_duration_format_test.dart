import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/dashboard/screens/dashboard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The weekly Time tile once rendered 45 minutes as `0.9 h`, which had to be
/// read back into minutes to be understood. Whole units only.
///
/// The formatter takes `AppLocalizations` because the unit suffixes are
/// translated, so the delegate is loaded directly rather than through a widget.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  String format(int minutes) => formatWeeklyDuration(l10n, minutes);

  test('under an hour is whole minutes', () {
    expect(format(0), '0 m');
    expect(format(1), '1 m');
    expect(format(45), '45 m');
    expect(format(59), '59 m');
  });

  test('a whole hour drops the minutes', () {
    expect(format(60), '1 h');
    expect(format(120), '2 h');
    expect(format(600), '10 h');
  });

  test('hours and minutes together', () {
    expect(format(61), '1 h 1 m');
    expect(format(90), '1 h 30 m');
    expect(format(135), '2 h 15 m');
    expect(format(605), '10 h 5 m');
    expect(format(630), '10 h 30 m');
  });

  test('never renders a fraction of an hour', () {
    // The regression itself, across the range where the old formatter produced
    // decimals: everything under 60 minutes.
    for (var minutes = 0; minutes < 60; minutes++) {
      final rendered = format(minutes);
      expect(
        rendered.contains('.'),
        isFalse,
        reason: '$minutes minutes rendered as $rendered',
      );
    }
  });

  test('minutes past an hour are the remainder, not a total', () {
    // 135 must not read as 2 h 135 m.
    expect(format(135), isNot(contains('135')));
    expect(format(135), contains('15'));
  });
}
