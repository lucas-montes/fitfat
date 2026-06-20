import 'package:flutter/material.dart';
import 'package:fitfat/l10n/app_localizations.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.sessionsCount,
    required this.totalVolume,
  });

  final int sessionsCount;
  final double totalVolume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: l10n.sessions, value: '$sessionsCount'),
            _Stat(
              label: l10n.volume,
              value: '${totalVolume.toStringAsFixed(0)} kg',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
