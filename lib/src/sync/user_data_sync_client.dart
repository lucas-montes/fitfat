import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'data_push_service.dart';
import 'sync_models.dart';

final class UserDataSyncClient {
  final ApiClient client;
  const UserDataSyncClient(this.client);

  Future<SyncResult> pushSelected(WidgetRef ref, String baseUrl, String apiKey, Set<String> entities) async {
    final failures = <String>[];
    for (final e in entities) {
      final res = await pushDataType(ref, e);
      if (!res.ok) failures.add('$e: ${res.error}');
    }
    if (failures.isNotEmpty) return SyncResult(error: failures.join('\n'));
    return const SyncResult(updated: 1, serverTime: 0);
  }

  Future<SyncResult> pullSelected(WidgetRef ref, String baseUrl, String apiKey, Set<String> entities) async {
    // Placeholder: personal pull would mirror global pull with per-entity cursors
    return const SyncResult(updated: 0, serverTime: 0);
  }
}
