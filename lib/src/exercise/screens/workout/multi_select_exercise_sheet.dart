import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';

import '../../providers/exercises.dart';
import '../../../models/workout.dart';

/// A bottom-sheet widget that shows the exercise library with search and
/// multi-select via checkboxes.
///
/// Returns the selected [List<ExerciseDefinition>] via [Navigator.pop].
class MultiSelectExerciseSheet extends ConsumerStatefulWidget {
  /// Pre-selected exercise IDs (for editing existing selections).
  final Set<String> initialSelection;

  const MultiSelectExerciseSheet({super.key, this.initialSelection = const {}});

  @override
  ConsumerState<MultiSelectExerciseSheet> createState() =>
      _MultiSelectExerciseSheetState();
}

class _MultiSelectExerciseSheetState
    extends ConsumerState<MultiSelectExerciseSheet> {
  final _searchController = TextEditingController();
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelection);
  }

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
      if (query.isEmpty) return true;
      if (e.name.toLowerCase().contains(query)) return true;
      if (e.localizedName != null &&
          e.localizedName!.toLowerCase().contains(query)) {
        return true;
      }
      return false;
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
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final isSelected = _selectedIds.contains(exercise.id);
                        final isWeightlifting =
                            exercise.type == ExerciseType.weightlifting;
                        return Card(
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedIds.add(exercise.id);
                                } else {
                                  _selectedIds.remove(exercise.id);
                                }
                              });
                            },
                            secondary: Icon(
                              isWeightlifting
                                  ? Icons.fitness_center
                                  : Icons.directions_run,
                            ),
                            title: Text(
                              exercise.localizedName ?? exercise.name,
                            ),
                            subtitle: Text(
                              isWeightlifting
                                  ? l10n.weightlifting
                                  : l10n.cardio,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final selected = exercises
                        .where((e) => _selectedIds.contains(e.id))
                        .toList();
                    Navigator.pop(context, selected);
                  },
                  child: Text('${l10n.done} (${_selectedIds.length})'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
