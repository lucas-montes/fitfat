import 'package:flutter/material.dart';

import '../../../../models/workout.dart';
import 'weight_set_tile.dart';

/// A single cardio set row showing duration, completion status, and notes.
/// Same interaction pattern as [WeightSetTile] but for duration-based sets.
class CardioSetTile extends StatelessWidget {
  final CardioSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback? onToggleFailed;

  const CardioSetTile({
    super.key,
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
    this.onToggleFailed,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;
    final failed = set.isFailed;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Opacity(
        opacity: completed && !failed ? 0.6 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              failed
                  ? Icons.cancel
                  : (completed
                        ? Icons.check_circle
                        : Icons.check_circle_outline),
              color: failed ? Colors.red : (completed ? Colors.green : null),
            ),
          ),
          title: Text(
            '${set.effectiveDurationMinutes} min',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: failed ? Colors.red.shade700 : null,
              decoration: failed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: setSubtitle(
            completedTime: completed ? set.completedAt : null,
            notes: set.notes,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'toggleFailed') onToggleFailed?.call();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
              ),
              // Only show failed toggle for completed sets
              if (completed)
                PopupMenuItem(
                  value: 'toggleFailed',
                  child: Text(failed ? 'Unmark failed' : 'Mark as failed'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
