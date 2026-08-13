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
  });

  final String title;
  final String value;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;

  /// Optional extra content rendered below the subtitle (e.g. the hero card's
  /// P/C/F composition bars).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: FitFatTokens.spaceS),
            ],
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
