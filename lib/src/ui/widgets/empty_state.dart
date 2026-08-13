import 'package:flutter/material.dart';

import '../tokens.dart';

/// Reusable empty state: tonal-circle icon, title, description, and an
/// optional primary CTA. Replaces plain-text empty messages across the app
/// (consumed in T03 for every empty list).
final class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCtaPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasCta = ctaLabel != null && onCtaPressed != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FitFatTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: scheme.onSecondaryContainer),
            ),
            const SizedBox(height: FitFatTokens.spaceL),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: FitFatTokens.spaceS),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (hasCta) ...[
              const SizedBox(height: FitFatTokens.spaceL),
              FilledButton(onPressed: onCtaPressed, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
