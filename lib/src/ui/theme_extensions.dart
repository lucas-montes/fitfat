import 'package:material_ui/material_ui.dart';

import 'palettes.dart';

/// Success and warning status colors, exposed as a `ThemeExtension`.
///
/// The app theme builds this from the active [ThemePalette]
/// ([FitFatColors.fromPalette]); danger lives in `ColorScheme.error`. The
/// [light]/[dark] constants are the legacy teal values, kept for tests.
@immutable
final class FitFatColors extends ThemeExtension<FitFatColors> {
  const FitFatColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  /// Light-brightness palette (dark greens/ambers that hold ≥ 4.5:1 on light
  /// surfaces).
  static const FitFatColors light = FitFatColors(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A4F00),
    onWarning: Color(0xFFFFFFFF),
  );

  /// Dark-brightness palette (light greens/ambers that hold ≥ 4.5:1 on the
  /// teal-tinted dark surfaces).
  static const FitFatColors dark = FitFatColors(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF10341B),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF3D2500),
  );

  /// Status colors taken from the active [ThemePalette]. Dark palettes use
  /// bright status colors, so their on-colors are the canvas; light palettes
  /// use deep status colors with white on top.
  factory FitFatColors.fromPalette(ThemePalette p) {
    final on = p.brightness == Brightness.dark ? p.bg : const Color(0xFFFFFFFF);
    return FitFatColors(
      success: p.success,
      onSuccess: on,
      warning: p.warning,
      onWarning: on,
    );
  }

  /// Status color for completed / saved states (e.g. "Completed" pill).
  final Color success;

  /// Foreground color guaranteed to contrast with [success].
  final Color onSuccess;

  /// Status color for in-progress / attention states (e.g. "Active" pill).
  final Color warning;

  /// Foreground color guaranteed to contrast with [warning].
  final Color onWarning;

  @override
  FitFatColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) {
    return FitFatColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  FitFatColors lerp(FitFatColors? other, double t) {
    if (other == null) return this;
    return FitFatColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }
}
