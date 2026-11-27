import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// The one group label used across the app: a small-caps label on the left
/// and an optional total on the right (e.g. "WED 25 NOV ····· +2,084.42 €").
///
/// Used for day groups (transactions, meals), weeks (workouts), status
/// groups (receipts) and settings sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.label, {
    super.key,
    this.trailing,
    this.trailingWidget,
    this.padding = const EdgeInsets.only(
      top: FitFatTokens.spaceM,
      bottom: FitFatTokens.spaceXs,
    ),
  });

  final String label;

  /// Right-aligned text in the same style, e.g. a day's net total.
  final String? trailing;

  /// Right-aligned widget; takes precedence over [trailing].
  final Widget? trailingWidget;
  final EdgeInsetsGeometry padding;

  /// The shared small-caps style, for callers that need it inline.
  static TextStyle? styleOf(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.9,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = styleOf(context);
    final right =
        trailingWidget ??
        (trailing == null ? null : Text(trailing!.toUpperCase(), style: style));
    return Semantics(
      header: true,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?right,
          ],
        ),
      ),
    );
  }
}
