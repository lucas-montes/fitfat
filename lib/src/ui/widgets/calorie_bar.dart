import 'package:flutter/material.dart';

import '../theme_extensions.dart';
import '../tokens.dart';
import '../../../l10n/app_localizations.dart';

/// Horizontal calorie progress with a fixed target marker.
///
/// The track always reserves a fixed headroom and puts the target tick at
/// [_targetMarkFraction] of its width, so the line never moves as the day
/// fills. That is what makes the bar readable: the empty space to the right of
/// the tick is always "room left", and anything drawn past it is overage, shown
/// spatially rather than only as a number.
///
/// Past [_severeOverFactor] of the target the overfill turns red. Past
/// [_maxOverFraction] it fills the whole headroom zone and stops growing — the
/// layout has a fixed width, and by then the colour already says "well over".
final class CalorieBar extends StatelessWidget {
  const CalorieBar({required this.consumed, required this.target});

  final double consumed;
  final double target;

  /// Where the target tick sits, as a fraction of the track width. The
  /// remainder is headroom reserved for overage.
  static const _targetMarkFraction = 0.8;

  /// Overage beyond this multiple of the target is shown as severe.
  static const _severeOverFactor = 1.1;

  /// The most the overfill grows, as a multiple of the target. Past this the
  /// headroom zone is simply full.
  static const _maxOverFraction = 0.25;

  /// Where the target line sits, as a fraction of the track width.
  static const double targetMarkFraction = _targetMarkFraction;

  /// The segment layout for [consumed] against [target], as fractions of the
  /// track width.
  ///
  /// Split out from [build] because this arithmetic *is* the bar's behaviour —
  /// everything else is decoration. Testing it directly avoids asserting on
  /// theme colours, which shift with the seed and would make the test describe
  /// the palette rather than the logic.
  ///
  /// [severe] is separate from [over] on purpose: it is the escalation from
  /// amber to red at 110%, and it must stay true even when [over] has saturated
  /// at full width, so a 200% overage still reads as severe.
  static ({double fill, double over, bool severe}) geometryFor(
    double consumed,
    double target,
  ) {
    // A zero or negative target has no meaningful progress; the empty track is
    // the honest rendering rather than a division by zero.
    if (target <= 0) {
      return (fill: 0, over: 0, severe: false);
    }
    final excessRatio = (consumed - target) / target;
    return (
      fill: (consumed.clamp(0.0, target) / target) * _targetMarkFraction,
      over: excessRatio <= 0
          ? 0
          : (excessRatio.clamp(0.0, _maxOverFraction) / _maxOverFraction) *
                (1.0 - _targetMarkFraction),
      severe: excessRatio > _severeOverFactor - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.extension<FitFatColors>()!;
    final g = geometryFor(consumed, target);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardConsumedOfTarget(
            consumed.toStringAsFixed(0),
            target.toStringAsFixed(0),
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceS),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Track.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          FitFatTokens.radiusFull,
                        ),
                      ),
                    ),
                  ),
                  if (g.fill > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * g.fill,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(
                            FitFatTokens.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  if (g.over > 0)
                    Positioned(
                      left: w * _targetMarkFraction,
                      top: 0,
                      bottom: 0,
                      width: w * g.over,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: g.severe ? scheme.error : colors.warning,
                          borderRadius: BorderRadius.circular(
                            FitFatTokens.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  // The target line itself. Drawn last so it stays legible
                  // over both segments.
                  Positioned(
                    left: w * _targetMarkFraction - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: ColoredBox(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
