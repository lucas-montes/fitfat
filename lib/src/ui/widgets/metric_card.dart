import 'package:flutter/material.dart';

import '../tokens.dart';

/// Shared stat-card shell for dashboard metric cards (hero calories card,
/// body-metrics summary, latest workout). Consumed from T09.
final class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
    this.trailing,
    this.child,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;

  /// Optional extra content rendered below the subtitle (e.g. the hero card's
  /// P/C/F composition bars).
  final Widget? child;

  /// Tightens the type and padding for a row of three or more cards, where the
  /// default `headlineSmall` value overflows a third of the width. Opt-in so the
  /// hero cards that render one or two keep their full-size figures.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          compact ? FitFatTokens.spaceS : FitFatTokens.spaceL,
        ),
        child: Column(
          // Compact tiles centre their contents: three of them in a row read as
          // a set, and a left-aligned icon with centred text beside it looks
          // misaligned.
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 14 : 20, color: scheme.primary),
              const SizedBox(height: FitFatTokens.spaceXs),
            ],
            Text(
              title,
              textAlign: compact ? TextAlign.center : TextAlign.start,
              // Only compact tiles are narrow enough to need clipping; the
              // default ones wrap as they always have.
              maxLines: compact ? 1 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style:
                  (compact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.labelMedium)
                      ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: FitFatTokens.spaceXs),
            Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: FitFatTokens.motionNormal,
                    child: compact
                        // A third-width tile cannot hold a headline figure:
                        // "999.9 kg" at titleLarge overflows. ScaleDown keeps
                        // the whole value legible rather than ellipsing it, and
                        // only shrinks when it has to.
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value,
                              key: ValueKey(value),
                              maxLines: 1,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            value,
                            key: ValueKey(value),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: FitFatTokens.spaceXs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: FitFatTokens.spaceM),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
