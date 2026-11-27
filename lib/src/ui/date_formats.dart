import 'package:material_ui/material_ui.dart';

/// Locale-aware date and time formatting for FitFat.
///
/// Every helper builds on [MaterialLocalizations] (the app registers
/// `GlobalMaterialLocalizations.delegate`, see `lib/src/app/app.dart`), so
/// dates and times render per the active locale (en/fr/es) without `intl`
/// initialization. Mirrors the planner's proven `formatMediumDate` usage.
abstract final class DateFormats {
  /// Medium-length locale-aware date, e.g. "Aug 6, 2026" / "6 août 2026".
  static String formatDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  /// Short locale-aware date, e.g. "8/6/26" / "06/08/2026".
  static String formatShortDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatShortDate(date);

  /// Locale-aware clock time, e.g. "2:30 PM" / "14:30".
  static String formatTime(BuildContext context, TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  /// One-letter weekday names Monday → Sunday in the active locale
  /// ("M T W T F S S" / "L M M J V S D").
  static List<String> narrowWeekdays(BuildContext context) {
    final names = MaterialLocalizations.of(context).narrowWeekdays;
    // MaterialLocalizations lists Sunday first.
    return [...names.skip(1), names.first];
  }

  /// Full locale-aware date with weekday, e.g. "Thursday, November 26".
  static String formatFullDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatFullDate(date);

  /// Two-digit zero padding for locale-independent values (e.g. the `mm:ss`
  /// rest duration, which the background task isolate renders without a
  /// [BuildContext]).
  static String twoDigit(int value) => value.toString().padLeft(2, '0');
}
