import 'package:flutter/material.dart';

import '../tokens.dart';

/// Shared status pill used across workout list / detail (and later the
/// dashboard). Renders [label] on a translucent tint of [color] and animates
/// the color flip when the status changes.
final class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  /// Localized status label (e.g. "Completed", "Active", "Pending").
  final String label;

  /// Status color from `FitFatColors` (or the M3-neutral for "Pending").
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FitFatTokens.motionFast,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: FitFatTokens.spaceS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(FitFatTokens.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
