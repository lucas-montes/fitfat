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
          compact ? FitFatTokens.spaceM : FitFatTokens.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 16 : 20, color: scheme.primary),
              const SizedBox(height: FitFatTokens.spaceS),
            ],
            Text(
              title,
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
                    child: Text(
                      value,
                      key: ValueKey(value),
                      style:
                          (compact
                                  ? theme.textTheme.titleLarge
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.bold),
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
