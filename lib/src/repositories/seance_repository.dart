import '../models/seance_models.dart';

abstract class SeanceRepository {
  Future<List<SeanceTemplate>> listTemplates();
  Future<SeanceTemplate> createTemplate(SeanceTemplate template);
  Future<void> deleteTemplate(String id);
  Future<SeanceTemplate> updateTemplate(SeanceTemplate template);
  Future<SeanceTemplate> cloneTemplate(String id, {DateTime? scheduledFor});
}
