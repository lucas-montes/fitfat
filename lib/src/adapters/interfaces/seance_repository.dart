import '../../models/seance.dart' as model;

/// Abstract interface for seance/template data access.
abstract class SeanceRepository {
  /// Returns all templates.
  Future<List<model.SeanceTemplate>> listTemplates();

  /// Creates a new template.
  Future<model.SeanceTemplate> createTemplate(model.SeanceTemplate template);

  /// Updates an existing template.
  Future<model.SeanceTemplate> updateTemplate(model.SeanceTemplate template);

  /// Deletes a template by ID.
  Future<void> deleteTemplate(String id);

  /// Clones a template, optionally scheduling it.
  Future<model.SeanceTemplate> cloneTemplate(
    String id, {
    DateTime? scheduledFor,
  });
}
