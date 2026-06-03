import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import '../../providers/exercises.dart';
import 'history/screen.dart';

class ExercisesListTab extends ConsumerStatefulWidget {
  const ExercisesListTab({super.key});

  @override
  ConsumerState<ExercisesListTab> createState() => _ExercisesListTabState();
}

class _ExercisesListTabState extends ConsumerState<ExercisesListTab> {
  final _searchController = TextEditingController();
  final Set<String> _selectedCategories = {};

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
    final allCategories = exercises.map((e) => e.category).toSet().toList()
      ..sort();

    final filtered = exercises.where((e) {
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
        return false;
      }
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(e.category)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
        if (allCategories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: allCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = allCategories[i];
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (isSelected) {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noExercisesFoundSimple,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.noExercisesFoundAction,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return Card(
                      child: ListTile(
                        title: Text(exercise.name),
                        subtitle: Text(exercise.category),
                        trailing: const Icon(Icons.info_outline),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseHistoryScreen(exercise: exercise),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
