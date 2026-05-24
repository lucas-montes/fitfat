import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/exercise.dart';
import '../providers/seance.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({required this.exercise, super.key});

  final ExerciseDefinition exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(seanceHistoryProvider);

    // Filter completed seances containing this exercise
    final relevant = history.where(
      (s) =>
          s.completedAt != null &&
          s.exercises.any((e) => e.exercise.name == exercise.name),
    );

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: relevant.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No history for ${exercise.name} yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a seance with this exercise to see it here',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: relevant.map((seance) {
                final entry = seance.exercises.firstWhere(
                  (e) => e.exercise.name == exercise.name,
                );
                final bestSet = entry.sets.fold<ExerciseSet?>(
                  null,
                  (best, s) =>
                      best == null || s.weight > best.weight ? s : best,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, MMM d, yyyy',
                          ).format(seance.startedAt),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${entry.sets.length} set${entry.sets.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        ...entry.sets.asMap().entries.map((e) {
                          final s = e.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'Set ${e.key + 1}: ${s.reps} reps × ${s.weight.toStringAsFixed(1)} kg',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }),
                        if (bestSet != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Best set: ${bestSet.reps} reps × ${bestSet.weight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
