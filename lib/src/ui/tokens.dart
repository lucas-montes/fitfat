/// Central design tokens for FitFat: spacing, radii, motion, and layout
/// constants shared by the theme and widgets in `lib/src/ui/`.
abstract final class FitFatTokens {
  /// 4dp base spacing unit.
  static const double spaceXs = 4;

  /// 8dp spacing (symmetric pill padding, gap between small elements).
  static const double spaceS = 8;

  /// 12dp spacing (gap between label and value in cards).
  static const double spaceM = 12;

  /// 16dp standard screen / card padding.
  static const double spaceL = 16;

  /// 24dp section spacing.
  static const double spaceXl = 24;

  /// 32dp large section spacing.
  static const double spaceXxl = 32;

  /// Small corner radius (chips, small surfaces).
  static const double radiusS = 8;

  /// Medium corner radius (cards, buttons, text fields, dialogs).
  static const double radiusM = 12;

  /// Large corner radius (hero cards, bottom sheets).
  static const double radiusL = 16;

  /// Fully rounded (pills, dots).
  static const double radiusFull = 999;

  /// Fast motion (micro-interactions, color flips).
  static const Duration motionFast = Duration(milliseconds: 150);

  /// Standard motion (cross-fades, switches).
  static const Duration motionNormal = Duration(milliseconds: 250);

  /// Slow motion (emphasis, hero transitions).
  static const Duration motionSlow = Duration(milliseconds: 350);

  /// Maximum content width for large screens; wider layouts center the
  /// content (dashboard uses a `ConstrainedBox` with this value).
  static const double kContentMaxWidth = 600;
}
