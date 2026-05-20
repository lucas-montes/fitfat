import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/seance_models.dart';
import '../../providers/seance_providers.dart';

class CreateSeanceScreen extends ConsumerStatefulWidget {
  const CreateSeanceScreen({this.template, super.key});

  final SeanceTemplate? template;

  @override
  ConsumerState<CreateSeanceScreen> createState() => _CreateSeanceScreenState();
}

class _CreateSeanceScreenState extends ConsumerState<CreateSeanceScreen> {
  final _nameController = TextEditingController();
  final _exerciseNameController = TextEditingController();
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
    _exerciseNameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    final name = _exerciseNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _exercises = [
        ..._exercises,
        ExerciseTemplate(
          id: const Uuid().v4(),
          name: name,
          sets: 3,
          reps: 8,
          plannedWeightKg: null,
          restSeconds: 60,
        )
      ];
      _exerciseNameController.clear();
    });
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.template == null ? 'Create Template' : 'Edit Template')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(label: Text('Template name')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _exerciseNameController,
                    decoration: const InputDecoration(label: Text('Exercise name')),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addExercise,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _exercises.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final e = _exercises[index];
                  return Card(
                    child: ListTile(
                      title: Text(e.name),
                      subtitle: Text('${e.sets}×${e.reps} • rest ${e.restSeconds}s'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _exercises = List.from(_exercises)..removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            FilledButton.tonal(
              onPressed: _save,
              child: const Text('Save Template'),
            ),
          ],
        ),
      ),
    );
  }
}
