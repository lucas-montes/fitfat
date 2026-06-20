import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/exercises.dart';
import '../../../models/workout.dart';

/// A bottom-sheet widget that shows the exercise library with search.
///
/// Returns the selected [ExerciseDefinition] via [Navigator.pop].
class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exerciseListProvider);
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();

    final filtered = exercises.where((e) {
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchExercisesHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
              ),
            ),
            // Exercise list or empty state
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noExercisesFoundSimple,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.noExercisesFoundAction,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final isWeightlifting =
                            exercise.type == ExerciseType.weightlifting;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isWeightlifting
                                  ? Icons.fitness_center
                                  : Icons.directions_run,
                            ),
                            title: Text(exercise.name),
                            subtitle: Text(
                              isWeightlifting
                                  ? l10n.weightlifting
                                  : l10n.cardio,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, exercise),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
