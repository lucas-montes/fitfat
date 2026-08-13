import 'package:flutter/services.dart';

/// Centralized haptic feedback helpers (T04). Each wraps a `HapticFeedback`
/// call so call sites read as intent ("selection", "destructive", "confirm"),
/// and degrades to a no-op on platforms without haptic support.
abstract final class Haptics {
  /// Light selection feedback — e.g., planner checkbox toggles.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Medium impact for destructive actions — e.g., list deletes.
  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  /// Light impact for confirmations — e.g., saving set actuals.
  static Future<void> lightImpact() => HapticFeedback.lightImpact();
}
