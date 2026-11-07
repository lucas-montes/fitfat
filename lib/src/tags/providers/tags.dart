import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import '../../models/tag.dart';
import '../repositories/tag_repository.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(databaseProvider));
});

/// The registered "priorities" vocabulary, ordered by manual priority.
final tagListProvider = FutureProvider<List<Tag>>((ref) {
  return ref.watch(tagRepositoryProvider).listTags();
});

/// Every known tag name (vocabulary + free-form references), for autocomplete.
final tagNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(tagRepositoryProvider).distinctTagNames();
});

/// Usage count per tag name across planner items, notes and goals.
final tagUsageCountsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(tagRepositoryProvider).usageCounts();
});
