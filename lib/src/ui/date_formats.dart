import 'package:flutter/material.dart';

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

  /// Two-digit zero padding for locale-independent values (e.g. the `mm:ss`
  /// rest duration, which the background task isolate renders without a
  /// [BuildContext]).
  static String twoDigit(int value) => value.toString().padLeft(2, '0');
}
