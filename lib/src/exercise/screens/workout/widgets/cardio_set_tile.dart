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

  const CardioSetTile({
    super.key,
    required this.set,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = set.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text(
            '${set.effectiveDurationMinutes} min',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: setSubtitle(
            completedTime: completed ? set.completedAt : null,
            notes: set.notes,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggleComplete();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(completed ? 'Mark incomplete' : 'Mark complete'),
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
