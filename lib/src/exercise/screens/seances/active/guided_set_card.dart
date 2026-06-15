import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../../../models/workout.dart' as domain;

class GuidedSetCard extends StatelessWidget {
  const GuidedSetCard({
    super.key,
    required this.set,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    this.onPrefill,
    this.isPr = false,
  });

  final domain.WeightSet set;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onPrefill;
  final bool isPr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final card = Card(
      color: set.isCompleted ? Colors.green.withAlpha(20) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: set.isCompleted ? Colors.green : null,
                  border: Border.all(
                    color: set.isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: set.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.set} ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: set.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: set.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${set.reps} reps × ${set.weightKg.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        fontSize: 13,
                        color: set.isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (set.isCompleted)
                Text(
                  DateFormat('HH:mm').format(set.completedAt!),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                )
              else
                Text(
                  l10n.tapToComplete,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              if (onPrefill != null)
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 18),
                  onPressed: onPrefill,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Prefill form',
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

    if (!set.isCompleted) {
      return Dismissible(
        key: ValueKey('guided-set-$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => onTap(),
        child: card,
      );
    }

    return card;
  }
}
