import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workout.dart';
import '../providers/workouts.dart';
import 'exercise_list.dart';
import 'workout_detail.dart';
import 'workout_form.dart';

final class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            tooltip: 'Manage Exercises',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseListScreen()),
            ),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (workouts) => workouts.isEmpty
            ? const Center(child: Text('No workouts yet. Tap + to add one.'))
            : ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (_, i) => _WorkoutTile(
                  workout: workouts[i],
                  onTap: () => _openDetail(context, ref, workouts[i]),
                  onDelete: () => _deleteWorkout(ref, workouts[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const WorkoutFormScreen()));
    if (saved == true) ref.invalidate(workoutListProvider);
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
      ),
    );
    ref.invalidate(workoutListProvider);
  }

  Future<void> _deleteWorkout(WidgetRef ref, Workout workout) async {
    await ref.read(workoutRepositoryProvider).delete(workout.id);
    ref.invalidate(workoutListProvider);
  }
}

final class _WorkoutTile extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkoutTile({
    required this.workout,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = workout.isCompleted
        ? Colors.green
        : workout.isActive
        ? Colors.orange
        : Colors.grey;
    final statusLabel = workout.isCompleted
        ? 'Completed'
        : workout.isActive
        ? 'Active'
        : 'Pending';

    final dateStr =
        '${workout.date.day.toString().padLeft(2, '0')}.'
        '${workout.date.month.toString().padLeft(2, '0')}.'
        '${workout.date.year}';

    return Dismissible(
      key: ValueKey(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete workout?'),
          content: Text('Remove "${workout.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ).then((r) => r ?? false),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(workout.name),
        subtitle: Text(dateStr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
