import 'dart:async';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../ui/haptics.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../exercise_filter.dart';
import '../providers/exercises.dart';
import 'exercise_detail_screen.dart';
import 'exercise_form.dart';

final class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

final class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _types = {};
  final Set<String> _bodyParts = {};
  final Set<String> _equipments = {};
  final Set<String> _muscles = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _types.isNotEmpty ||
      _bodyParts.isNotEmpty ||
      _equipments.isNotEmpty ||
      _muscles.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _query = '';
      _types.clear();
      _bodyParts.clear();
      _equipments.clear();
      _muscles.clear();
    });
  }

  Future<void> _pickOptions({
    required String title,
    required List<String> options,
    required Set<String> selection,
    String Function(String)? display,
  }) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _FilterOptionsSheet(
        title: title,
        options: options,
        selected: selection,
        display: display,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        selection
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _openDetail(Exercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
      ),
    );
    if (mounted) ref.invalidate(exerciseListProvider);
  }

  /// Long-press opens the edit form; built-in exercises are locked and show a
  /// SnackBar instead.
  void _openEdit(BuildContext context, Exercise exercise) {
    if (exercise.isLocked) {
      final l10n = AppLocalizations.of(context)!;
      showTopBanner(context, message: l10n.exerciseLockedEdit);
      return;
    }
    _openForm(context, null, exercise);
  }

  Future<void> _openForm(
    BuildContext context,
    Exercise? existing,
    Exercise? _,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExerciseFormScreen(exercise: existing)),
    );
    if (saved == true && mounted) ref.invalidate(exerciseListProvider);
  }

  /// Blocks the dismiss (and the delete) when the exercise is locked or still
  /// part of a workout; otherwise passes through to the plain delete.
  Future<bool> _confirmDelete(Exercise exercise) async {
    if (exercise.isLocked) {
      final l10n = AppLocalizations.of(context)!;
      showTopBanner(context, message: l10n.exerciseLockedDelete);
      return false;
    }
    final count = await ref
        .read(exerciseRepositoryProvider)
        .usageCount(exercise.id);
    if (!mounted) return false;
    if (count > 0) {
      final l10n = AppLocalizations.of(context)!;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.exerciseUsedTitle),
          content: Text(l10n.exerciseUsedBody(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _deleteExercise(WidgetRef ref, Exercise exercise) async {
    unawaited(Haptics.mediumImpact());
    await ref.read(exerciseRepositoryProvider).delete(exercise.id);
    if (mounted) ref.invalidate(exerciseListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exercisesAsync = ref.watch(exerciseListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseListAppBar)),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (exercises) {
          if (exercises.isEmpty) {
            return EmptyState(
              icon: Icons.sports_gymnastics,
              title: l10n.emptyExercisesTitle,
              description: l10n.emptyExercisesBody,
              ctaLabel: l10n.emptyExercisesCta,
              onCtaPressed: () => _openForm(context, null, null),
            );
          }
          final options = exerciseFilterOptions(exercises);
          // First apply filters, then rank by relevance if there's a query
          final filtered = filterExercises(
            exercises,
            query: _query,
            types: _types,
            bodyParts: _bodyParts,
            equipments: _equipments,
            muscles: _muscles,
          );
          final visible = _query.trim().isNotEmpty
              ? const DefaultSearchRanker()
                    .rank(_query.trim(), filtered)
                    .map((se) => se.exercise)
                    .toList()
              : filtered;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.exerciseListSearchHint,
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.exerciseFilterClear,
                            onPressed: () =>
                                setState(() => _searchCtrl.clear()),
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (!options.isEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        label: _chipLabel(
                          l10n.exerciseFilterType,
                          _types.length,
                        ),
                        active: _types.isNotEmpty,
                        onTap: () => _pickOptions(
                          title: l10n.exerciseFilterType,
                          options: options.types,
                          selection: _types,
                          display: (v) => v == 'cardio'
                              ? l10n.exerciseTypeCardio
                              : l10n.exerciseTypeWeightlifting,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _chipLabel(
                          l10n.exerciseFilterBodyPart,
                          _bodyParts.length,
                        ),
                        active: _bodyParts.isNotEmpty,
                        onTap: () => _pickOptions(
                          title: l10n.exerciseFilterBodyPart,
                          options: options.bodyParts,
                          selection: _bodyParts,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _chipLabel(
                          l10n.exerciseFilterEquipment,
                          _equipments.length,
                        ),
                        active: _equipments.isNotEmpty,
                        onTap: () => _pickOptions(
                          title: l10n.exerciseFilterEquipment,
                          options: options.equipments,
                          selection: _equipments,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _chipLabel(
                          l10n.exerciseFilterMuscle,
                          _muscles.length,
                        ),
                        active: _muscles.isNotEmpty,
                        onTap: () => _pickOptions(
                          title: l10n.exerciseFilterMuscle,
                          options: options.muscles,
                          selection: _muscles,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_hasFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.exerciseFilterResults(visible.length),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(l10n.exerciseFilterClear),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: visible.isEmpty
                    ? _FilteredEmptyState(onClear: _clearFilters, l10n: l10n)
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, i) => _ExerciseTile(
                          exercise: visible[i],
                          l10n: l10n,
                          onTap: () => _openDetail(visible[i]),
                          onLongPress: () => _openEdit(context, visible[i]),
                          onConfirmDelete: () => _confirmDelete(visible[i]),
                          onDelete: () => _deleteExercise(ref, visible[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, null, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _chipLabel(String label, int count) =>
      count > 0 ? '$label ($count)' : label;

  Widget _buildFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Center(
      child: FilterChip(
        label: Text(label),
        selected: active,
        showCheckmark: active,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

final class _FilteredEmptyState extends StatelessWidget {
  final VoidCallback onClear;
  final AppLocalizations l10n;

  const _FilteredEmptyState({required this.onClear, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 12),
          Text(l10n.exerciseFilterNoResults),
          const SizedBox(height: 8),
          TextButton(onPressed: onClear, child: Text(l10n.exerciseFilterClear)),
        ],
      ),
    );
  }
}

/// Multi-select filter bottom sheet with its own search field (the muscle list
/// is long). Returns the updated selection via [Navigator.pop] (null = cancel).
final class _FilterOptionsSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final String Function(String)? display;

  const _FilterOptionsSheet({
    required this.title,
    required this.options,
    required this.selected,
    this.display,
  });

  @override
  State<_FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

final class _FilterOptionsSheetState extends State<_FilterOptionsSheet> {
  late final Set<String> _selected = {...widget.selected};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = _search.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.options
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.exerciseFilterSearchOptions,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in visible)
                      CheckboxListTile(
                        dense: true,
                        title: Text(widget.display?.call(option) ?? option),
                        value: _selected.contains(option),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(option);
                          } else {
                            _selected.remove(option);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text(l10n.exerciseFilterClear),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: Text(l10n.exerciseFilterApply),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDelete;

  const _ExerciseTile({
    required this.exercise,
    required this.l10n,
    required this.onTap,
    required this.onLongPress,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(exercise.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: _ExerciseThumbnail(exercise: exercise),
        title: Text(exercise.name),
        subtitle: Text(
          exercise.isWeightlifting
              ? l10n.exerciseTypeWeightlifting
              : l10n.exerciseTypeCardio,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

/// 48 px leading thumbnail for exercises with catalog media; falls back to the
/// type icon when there is no image (user-created rows) or the asset fails.
/// Always returns a 48x48 box for consistent alignment.
final class _ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseThumbnail({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = exercise.isWeightlifting
        ? Icons.fitness_center
        : Icons.directions_run;
    final fallback = Icon(
      icon,
      color: theme.colorScheme.onSurfaceVariant,
      size: 28,
    );
    final imagePath = exercise.imagePath;
    if (imagePath == null) {
      return SizedBox(width: 48, height: 48, child: Center(child: fallback));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(FitFatTokens.radiusM),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(child: fallback),
        ),
      ),
    );
  }
}
