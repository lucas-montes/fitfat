import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../providers/exercises.dart';
import 'exercise_form.dart';

/// Opens a modal bottom sheet to pick one or more exercises for a workout.
/// Returns the set of selected exercise ids, or null if the user cancelled.
Future<Set<String>?> showExercisePickerSheet(
  BuildContext context, {
  required Set<String> initialSelected,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _ExercisePickerContent(initialSelected: initialSelected),
  );
}

final class _ExercisePickerContent extends ConsumerStatefulWidget {
  final Set<String> initialSelected;
  const _ExercisePickerContent({required this.initialSelected});

  @override
  ConsumerState<_ExercisePickerContent> createState() =>
      _ExercisePickerContentState();
}

final class _ExercisePickerContentState
    extends ConsumerState<_ExercisePickerContent> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = v);
    });
  }

  Future<void> _createExercise(String query) async {
    final created = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseFormScreen(initialName: query.trim()),
      ),
    );
    if (created == null || !mounted) return;
    ref.invalidate(exerciseListProvider);
    final reloaded = await ref.read(exerciseListProvider.future);
    if (!mounted) return;
    Exercise? match;
    for (final ex in reloaded) {
      if (ex.id == created.id) {
        match = ex;
        break;
      }
    }
    if (match != null && mounted) setState(() => _selected.add(match!.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercisesAsync = ref.watch(exerciseListProvider);
    final q = _query.trim().toLowerCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.workoutFormAddExercise,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonCancel,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.workoutFormSearchHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(l10n.errorWithMessage('$e'))),
                data: (exercises) {
                  final visible = q.isEmpty
                      ? exercises
                      : exercises
                            .where((ex) => ex.name.toLowerCase().contains(q))
                            .toList();
                  final hasExact = visible.any(
                    (ex) => ex.name.toLowerCase() == q,
                  );
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      if (q.isNotEmpty && !hasExact)
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(l10n.workoutFormCreateExercise(q)),
                          onTap: () => _createExercise(q),
                        ),
                      for (final ex in visible)
                        ListTile(
                          leading: Icon(
                            ex.isWeightlifting
                                ? Icons.fitness_center
                                : Icons.directions_run,
                            size: 20,
                          ),
                          title: Text(ex.name),
                          trailing: _selected.contains(ex.id)
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const Icon(Icons.add_circle_outline),
                          onTap: () => setState(() {
                            if (_selected.contains(ex.id)) {
                              _selected.remove(ex.id);
                            } else {
                              _selected.add(ex.id);
                            }
                          }),
                        ),
                      if (visible.isEmpty && q.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.workoutFormNoExercises,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(_selected),
                  child: Text(l10n.workoutFormAddExercise),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
