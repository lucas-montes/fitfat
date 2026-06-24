import 'package:flutter/material.dart';

import '../../../../models/workout.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Format a [DateTime] as "HH:mm" for display on set tiles.
String formatHHmm(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Build a subtitle widget showing an optional completed time and notes.
/// Time and notes are separated by " · " when both present.
/// Returns null when nothing to show (no time, no notes).
Widget? setSubtitle({DateTime? completedTime, String? notes}) {
  final parts = <String>[];
  if (completedTime != null) parts.add(formatHHmm(completedTime));
  if (notes != null && notes.isNotEmpty) parts.add(notes);
  if (parts.isEmpty) return null;
  return Text(parts.join(' · '), style: const TextStyle(fontSize: 12));
}

// ---------------------------------------------------------------------------
// Weight set tile
// ---------------------------------------------------------------------------

/// A single weight set row showing reps × weight, completion status,
/// completion time, and notes. Supports tap-to-copy, edit, delete, and
/// toggle-complete via the trailing popup menu.
class WeightSetTile extends StatelessWidget {
  final WeightSet set;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const WeightSetTile({
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: completed ? 0.6 : 1.0,
        child: ListTile(
          leading: InkWell(
            onTap: onToggleComplete,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              completed ? Icons.check_circle : Icons.check_circle_outline,
              color: completed ? Colors.green : null,
            ),
          ),
          title: Text('${set.effectiveReps} × ${set.effectiveWeightKg} kg'),
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
