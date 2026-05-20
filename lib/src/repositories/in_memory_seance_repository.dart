import 'dart:async';

import '../models/seance_models.dart';
import 'seance_repository.dart';

class InMemorySeanceRepository implements SeanceRepository {
  final List<SeanceTemplate> _templates = [];

  @override
  Future<SeanceTemplate> createTemplate(SeanceTemplate template) async {
    final created = template.copyWith(id: template.id.isNotEmpty ? template.id : _generateId());
    _templates.add(created);
    return created;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<SeanceTemplate>> listTemplates() async {
    return List.unmodifiable(_templates);
  }

  @override
  Future<SeanceTemplate> updateTemplate(SeanceTemplate template) async {
    final idx = _templates.indexWhere((t) => t.id == template.id);
    if (idx == -1) {
      throw StateError('Template not found');
    }
    _templates[idx] = template;
    return template;
  }

  @override
  Future<SeanceTemplate> cloneTemplate(String id, {DateTime? scheduledFor}) async {
    final src = _templates.firstWhere((t) => t.id == id);
    final cloned = SeanceTemplate(
      id: _generateId(),
      name: '${src.name} (copy)',
      scheduledFor: scheduledFor,
      exercises: src.exercises.map((e) => e.copyWith(id: _generateId())).toList(),
    );
    _templates.add(cloned);
    return cloned;
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
