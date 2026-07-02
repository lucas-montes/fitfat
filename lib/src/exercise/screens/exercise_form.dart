import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise.dart';
import '../providers/exercises.dart';
import '../repositories/exercise_repository.dart';

final class ExerciseFormScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;
  const ExerciseFormScreen({super.key, this.exercise});

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

final class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _exerciseType;
  bool _saving = false;

  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _exerciseType = ex?.exerciseType ?? 'weightlifting';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Exercise' : 'New Exercise'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Bench Press',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _exerciseType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'weightlifting',
                  child: Text('Weightlifting'),
                ),
                DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _exerciseType = v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(exerciseRepositoryProvider);
      final name = _nameCtrl.text.trim();

      if (_isEditing) {
        await repo.update(
          widget.exercise!.copyWith(name: name, exerciseType: _exerciseType),
        );
      } else {
        await repo.insert(newExercise(name: name, exerciseType: _exerciseType));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
