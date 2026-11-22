import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// The API keys of the saved sync servers, by server id.
///
/// The keys live in [FlutterSecureStorage] (the Android keystore), never in
/// SharedPreferences. They are read once at startup by [loadSyncApiKeys] and
/// held here, so the many synchronous readers of
/// `SettingsState.remoteSyncApiKey` never wait on the keystore.
final class SyncApiKeys extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void set(Map<String, String> keys) => state = Map.unmodifiable(keys);

  void put(String id, String key) => set({...state, id: key});

  void remove(String id) => set({...state}..remove(id));
}

final syncApiKeysProvider = NotifierProvider<SyncApiKeys, Map<String, String>>(
  SyncApiKeys.new,
);

/// Reads and writes the per-server keys in secure storage.
abstract final class SyncKeyStore {
  static const _storage = FlutterSecureStorage();

  static const serversPrefKey = 'settings_sync_servers';
  static const activeServerIdPrefKey = 'settings_sync_active_id';
  static const _legacyBaseUrlPrefKey = 'settings_remote_sync_base_url';
  static const _legacyApiKeyPrefKey = 'settings_remote_sync_api_key';

  static String _secureKey(String id) => 'sync_api_key_$id';

  static Future<void> write(String id, String key) =>
      _storage.write(key: _secureKey(id), value: key);

  static Future<void> delete(String id) => _storage.delete(key: _secureKey(id));

  /// Loads every server's key, first moving any key still held in plain
  /// SharedPreferences into secure storage.
  ///
  /// Older builds kept the key as an `apiKey` field of each server entry and
  /// as the scalar `settings_remote_sync_api_key`; the oldest had only the
  /// scalar URL and key and no server list. A plain-text copy is removed only
  /// after its secure write succeeds. If the keystore cannot be reached, the
  /// plain-text keys are returned as they are, so sync keeps working.
  static Future<Map<String, String>> load(SharedPreferences prefs) async {
    final entries = await _entries(prefs);
    final legacyKey = prefs.getString(_legacyApiKeyPrefKey)?.trim() ?? '';
    final plain = <String, String>{
      for (final e in entries)
        if ((e['apiKey'] as String? ?? '').trim().isNotEmpty)
          e['id'] as String: (e['apiKey'] as String).trim(),
    };
    final activeId = prefs.getString(activeServerIdPrefKey);
    if (legacyKey.isNotEmpty && activeId != null) {
      plain.putIfAbsent(activeId, () => legacyKey);
    }

    try {
      for (final MapEntry(:key, :value) in plain.entries) {
        await write(key, value);
      }
      if (entries.any((e) => e.containsKey('apiKey'))) {
        await prefs.setString(
          serversPrefKey,
          jsonEncode([
            for (final e in entries) {...e}..remove('apiKey'),
          ]),
        );
      }
      await prefs.remove(_legacyApiKeyPrefKey);
      await prefs.remove(_legacyBaseUrlPrefKey);

      final keys = <String, String>{};
      for (final e in entries) {
        final id = e['id'] as String;
        final key = await _storage.read(key: _secureKey(id));
        if (key != null && key.isNotEmpty) keys[id] = key;
      }
      return keys;
    } catch (_) {
      return plain;
    }
  }

  /// The stored server entries, after turning the oldest scalar URL + key
  /// into a one-entry list with a persisted id.
  static Future<List<Map<String, dynamic>>> _entries(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(serversPrefKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      } catch (_) {
        return const [];
      }
    }
    final base = prefs.getString(_legacyBaseUrlPrefKey)?.trim() ?? '';
    if (base.isEmpty) return const [];
    final id = const Uuid().v7();
    final host = Uri.tryParse(base)?.host ?? '';
    final entry = <String, dynamic>{
      'id': id,
      'url': base,
      'label': host.isEmpty ? base : host,
    };
    await prefs.setString(serversPrefKey, jsonEncode([entry]));
    await prefs.setString(activeServerIdPrefKey, id);
    return [entry];
  }
}
