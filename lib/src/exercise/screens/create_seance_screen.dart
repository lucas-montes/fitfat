import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fitfat/l10n/app_localizations.dart';
import '../../models/exercise.dart';
import '../../models/seance.dart';
import '../providers/seance.dart';
import '../providers/exercises.dart';

class CreateSeanceScreen extends ConsumerStatefulWidget {
  const CreateSeanceScreen({this.template, super.key});

  final SeanceTemplate? template;

  @override
  ConsumerState<CreateSeanceScreen> createState() => _CreateSeanceScreenState();
}

class _CreateSeanceScreenState extends ConsumerState<CreateSeanceScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  List<ExerciseTemplate> _exercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _exercises = widget.template!.exercises;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addExerciseFromPreset(ExerciseDefinition exercise) {
    setState(() {
      _exercises = [
        ..._exercises,
        ExerciseTemplate(
          id: const Uuid().v4(),
          name: exercise.name,
          plannedSets: [],
        ),
      ];
    });
    _searchController.clear();
  }

  void _addCustomExercise(String name) {
    setState(() {
      _exercises = [
        ..._exercises,
        ExerciseTemplate(id: const Uuid().v4(), name: name, plannedSets: []),
      ];
    });
    _searchController.clear();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final id = widget.template?.id ?? const Uuid().v4();
    final template = SeanceTemplate(id: id, name: name, exercises: _exercises);
    if (widget.template == null) {
      await ref.read(templateListProvider.notifier).createTemplate(template);
    } else {
      await ref.read(templateListProvider.notifier).updateTemplate(template);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allExercises = ref.watch(exerciseListProvider);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? allExercises
        : allExercises
              .where((e) => e.name.toLowerCase().contains(query))
              .toList();
    final existingNames = _exercises.map((e) => e.name).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.template == null ? l10n.createTemplate : l10n.editTemplate,
        ),
        actions: [
          if (_exercises.isNotEmpty && _nameController.text.trim().isNotEmpty)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.save),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  label: Text(l10n.templateNameLabel),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  label: Text(l10n.addExercise),
                  hintText: l10n.searchExercises,
                  border: const OutlineInputBorder(),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.add_circle),
                          tooltip: l10n.addCustom,
                          onPressed: () {
                            _addCustomExercise(query);
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (query.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.searchAboveHint,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: filtered
                      .where((e) => !existingNames.contains(e.name))
                      .map(
                        (e) => ListTile(
                          dense: true,
                          title: Text(e.name),
                          trailing: const Icon(Icons.add, size: 18),
                          onTap: () => _addExerciseFromPreset(e),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _exercises.isEmpty
                ? Center(child: Text(l10n.noExercisesAdded))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _exercises.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _ExerciseTile(
                      exercise: _exercises[index],
                      onChanged: (updated) {
                        setState(() {
                          _exercises = [
                            for (int i = 0; i < _exercises.length; i++)
                              if (i == index) updated else _exercises[i],
                          ];
                        });
                      },
                      onRemove: () {
                        setState(() {
                          _exercises = List.from(_exercises)..removeAt(index);
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise tile — shows name + set count, tap to open sets editor
// ---------------------------------------------------------------------------

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
  });

  final ExerciseTemplate exercise;
  final ValueChanged<ExerciseTemplate> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(exercise.name),
        subtitle: exercise.plannedSets.isEmpty
            ? Text(l10n.noSetsConfigured)
            : Text(l10n.setsCount(exercise.totalSets)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _openEditor(context),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
        onTap: () => _openEditor(context),
      ),
    );
  }

  void _openEditor(BuildContext context) async {
    // NOTE: Opens a full-screen page (not a dialog) so the user has more room
    // to see and edit all planned sets.
    final result = await Navigator.of(context).push<List<PlannedSet>>(
      MaterialPageRoute(
        builder: (_) => _SetsEditorPage(plannedSets: exercise.plannedSets),
        fullscreenDialog: true,
      ),
    );
    if (result != null && context.mounted) {
      onChanged(
        ExerciseTemplate(
          id: exercise.id,
          name: exercise.name,
          plannedSets: result,
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Sets editor full-screen page — spacious view for editing planned sets
// ---------------------------------------------------------------------------

class _SetsEditorPage extends StatefulWidget {
  const _SetsEditorPage({required this.plannedSets});

  final List<PlannedSet> plannedSets;

  @override
  State<_SetsEditorPage> createState() => _SetsEditorPageState();
}

class _SetsEditorPageState extends State<_SetsEditorPage> {
  late List<_SetRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.plannedSets.isNotEmpty
        ? widget.plannedSets
              .map(
                (s) => _SetRow(
                  reps: TextEditingController(text: s.reps.toString()),
                  weight: TextEditingController(
                    text: s.weightKg?.toString() ?? '',
                  ),
                  rest: TextEditingController(text: s.restSeconds.toString()),
                ),
              )
              .toList()
        : [_newRow()];
  }

  _SetRow _newRow() => _SetRow(
    reps: TextEditingController(text: '8'),
    weight: TextEditingController(),
    rest: TextEditingController(text: '60'),
  );

  @override
  void dispose() {
    for (final r in _rows) {
      r.reps.dispose();
      r.weight.dispose();
      r.rest.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    setState(() => _rows.add(_newRow()));
  }

  void _removeSet(int index) {
    setState(() {
      _rows[index].reps.dispose();
      _rows[index].weight.dispose();
      _rows[index].rest.dispose();
      _rows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.sets} (${_rows.length})'),
        actions: [
          TextButton(
            onPressed: () {
              final planned = _rows
                  .map(
                    (r) => PlannedSet(
                      reps: int.tryParse(r.reps.text) ?? 8,
                      weightKg: double.tryParse(r.weight.text),
                      restSeconds: int.tryParse(r.rest.text) ?? 60,
                    ),
                  )
                  .toList();
              Navigator.pop(context, planned);
            },
            child: Text(l10n.done),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${l10n.set} ${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_rows.length > 1)
                          TextButton.icon(
                            icon: const Icon(Icons.remove_circle_outline),
                            label: Text(l10n.remove),
                            onPressed: () => _removeSet(i),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: r.reps,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(l10n.reps),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: r.weight,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(l10n.weightKg),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: r.rest,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              label: Text(l10n.restSeconds),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.addSet),
            onPressed: _addSet,
          ),
        ],
      ),
    );
  }
}

class _SetRow {
  _SetRow({required this.reps, required this.weight, required this.rest});
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController rest;
}
