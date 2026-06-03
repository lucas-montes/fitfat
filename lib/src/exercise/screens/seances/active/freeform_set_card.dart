import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/exercise.dart';

class FreeformSetCard extends StatelessWidget {
  const FreeformSetCard({
    super.key,
    required this.set,
    required this.index,
    required this.onLongPress,
    this.onPrefill,
    this.isPr = false,
  });

  final ExerciseSet set;
  final int index;
  final VoidCallback onLongPress;
  final VoidCallback? onPrefill;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPrefill,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.set} ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${set.reps} reps × ${set.weight.toStringAsFixed(1)}kg',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                set.completedAt != null
                    ? DateFormat('HH:mm').format(set.completedAt!)
                    : '—',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (isPr)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.emoji_events,
                    size: 16,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
