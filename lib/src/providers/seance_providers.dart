import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/seance_models.dart';
import '../repositories/seance_repository.dart';
import '../repositories/drift/drift_seance_repository.dart' as drift;
import 'database_providers.dart';
import 'exercise_providers.dart';

final seanceRepositoryProvider = Provider<SeanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return drift.DriftSeanceRepository(db);
});

final templateListProvider =
    NotifierProvider<TemplateListNotifier, List<SeanceTemplate>>(
      TemplateListNotifier.new,
    );

class TemplateListNotifier extends Notifier<List<SeanceTemplate>> {
  late final SeanceRepository _repo;

  @override
  List<SeanceTemplate> build() {
    _repo = ref.read(seanceRepositoryProvider);
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final list = await _repo.listTemplates();
      if (list.isNotEmpty) state = list;
    } catch (_) {}
  }

  Future<void> loadTemplates() async {
    final list = await _repo.listTemplates();
    state = list;
  }

  Future<void> createTemplate(SeanceTemplate template) async {
    final created = await _repo.createTemplate(template);
    state = [...state, created];
  }

  Future<void> updateTemplate(SeanceTemplate template) async {
    final updated = await _repo.updateTemplate(template);
    state = state.map((t) => t.id == updated.id ? updated : t).toList();
  }

  Future<void> deleteTemplate(String id) async {
    await _repo.deleteTemplate(id);
    state = state.where((t) => t.id != id).toList();
  }

  Future<SeanceTemplate> cloneTemplate(
    String id, {
    DateTime? scheduledFor,
  }) async {
    final cloned = await _repo.cloneTemplate(id, scheduledFor: scheduledFor);
    state = [...state, cloned];
    return cloned;
  }
}

/// Active seance plan mapping: maps active seance exercise entry id -> planned exercise template
final activeSeancePlanProvider =
    NotifierProvider<ActiveSeancePlanNotifier, Map<String, ExerciseTemplate>>(
      ActiveSeancePlanNotifier.new,
    );

class ActiveSeancePlanNotifier extends Notifier<Map<String, ExerciseTemplate>> {
  @override
  Map<String, ExerciseTemplate> build() => {};

  void setPlanForEntry(String entryId, ExerciseTemplate plan) {
    state = {...state, entryId: plan};
  }

  void clear() {
    state = {};
  }

  /// Populate plan entries by aligning the active seance exercises sequence with the
  /// provided template's exercises (positional mapping). This assumes the caller
  /// started a seance and added exercises in the same order as the template.
  void populateFromTemplate(SeanceTemplate template) {
    final seance = ref.read(activeSeanceProvider);
    if (seance == null) return;
    final Map<String, ExerciseTemplate> map = {};
    for (
      var i = 0;
      i < template.exercises.length && i < seance.exercises.length;
      i++
    ) {
      map[seance.exercises[i].id] = template.exercises[i];
    }
    state = map;
  }
}
