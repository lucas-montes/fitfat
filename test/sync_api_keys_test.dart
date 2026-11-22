import 'dart:convert';

import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync keys live in secure storage. Older builds left them in plain
/// SharedPreferences, and loading must move them without losing any.
void main() {
  const secure = FlutterSecureStorage();
  late ProviderContainer container;
  late SharedPreferences prefs;

  Future<void> boot(
    Map<String, Object> initialPrefs, {
    Map<String, String> initialSecure = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    FlutterSecureStorage.setMockInitialValues({...initialSecure});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer();
    container
        .read(syncApiKeysProvider.notifier)
        .set(await SyncKeyStore.load(prefs));
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
  }

  bool prefsHoldKey(String key) =>
      prefs.getKeys().any((k) => '${prefs.get(k)}'.contains(key));

  tearDown(() => container.dispose());

  test('keys stored in the server list move to secure storage', () async {
    await boot({
      'settings_sync_servers': jsonEncode([
        {'id': 'a', 'url': 'http://a:3030', 'label': 'a', 'apiKey': 'key-a'},
        {'id': 'b', 'url': 'http://b:3030', 'label': 'b', 'apiKey': 'key-b'},
      ]),
      'settings_sync_active_id': 'b',
      'settings_remote_sync_api_key': 'key-b',
      'settings_remote_sync_base_url': 'http://b:3030',
    });

    final s = container.read(settingsProvider);
    expect(s.servers.map((e) => e.id), ['a', 'b']);
    expect(s.remoteSyncBaseUrl, 'http://b:3030');
    expect(s.remoteSyncApiKey, 'key-b');
    expect(await secure.read(key: 'sync_api_key_a'), 'key-a');
    expect(await secure.read(key: 'sync_api_key_b'), 'key-b');
    expect(prefsHoldKey('key-a'), isFalse);
    expect(prefsHoldKey('key-b'), isFalse);
  });

  test('the oldest scalar URL and key become one saved server', () async {
    await boot({
      'settings_remote_sync_base_url': 'http://old:3030',
      'settings_remote_sync_api_key': 'old-key',
    });

    final s = container.read(settingsProvider);
    expect(s.servers, hasLength(1));
    expect(s.remoteSyncBaseUrl, 'http://old:3030');
    expect(s.remoteSyncApiKey, 'old-key');
    expect(prefsHoldKey('old-key'), isFalse);

    // The id is persisted, so a second start finds the same server and key.
    final id = s.servers.single.id;
    container.dispose();
    container = ProviderContainer();
    container
        .read(syncApiKeysProvider.notifier)
        .set(await SyncKeyStore.load(prefs));
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
    expect(container.read(settingsProvider).servers.single.id, id);
    expect(container.read(settingsProvider).remoteSyncApiKey, 'old-key');
  });

  test('add, switch and delete keep keys out of prefs', () async {
    await boot({});
    final notifier = container.read(settingsProvider.notifier);

    await notifier.addServer('http://one:3030/', 'k1');
    await notifier.addServer('http://two:3030', 'k2');
    var s = container.read(settingsProvider);
    expect(s.remoteSyncBaseUrl, 'http://two:3030');
    expect(s.remoteSyncApiKey, 'k2');
    expect(prefsHoldKey('k1'), isFalse);
    expect(prefsHoldKey('k2'), isFalse);

    final one = s.servers.first.id;
    final two = s.servers.last.id;
    expect(notifier.apiKeyFor(one), 'k1');

    await notifier.setActiveServer(one);
    s = container.read(settingsProvider);
    expect(s.remoteSyncBaseUrl, 'http://one:3030');
    expect(s.remoteSyncApiKey, 'k1');

    await notifier.deleteServer(one);
    s = container.read(settingsProvider);
    expect(s.servers.map((e) => e.id), [two]);
    expect(s.remoteSyncApiKey, 'k2');
    expect(await secure.read(key: 'sync_api_key_$one'), isNull);
  });
}
