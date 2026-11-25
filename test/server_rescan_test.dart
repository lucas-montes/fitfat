import 'dart:convert';

import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/providers/sync_api_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rescanning a server QR code updates the server in use instead of piling up
/// a new entry every time the computer's address or key changes.
void main() {
  const secure = FlutterSecureStorage();
  late ProviderContainer container;

  Future<void> boot(Map<String, Object> initialPrefs) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer();
    container
        .read(syncApiKeysProvider.notifier)
        .set(await SyncKeyStore.load(prefs));
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
  }

  Map<String, Object> twoServers() => {
    'settings_sync_servers': jsonEncode([
      {
        'id': 'a',
        'url': 'http://10.0.0.5:3030',
        'label': '10.0.0.5',
        'apiKey': 'ka',
      },
      {'id': 'b', 'url': 'http://b:3030', 'label': 'Laptop', 'apiKey': 'kb'},
    ]),
    'settings_sync_active_id': 'a',
  };

  tearDown(() => container.dispose());

  test('a new address repoints the active server, same entry', () async {
    await boot(twoServers());
    final notifier = container.read(settingsProvider.notifier);

    await notifier.rescanServer('http://10.0.0.9:3030/', 'new-key');

    final s = container.read(settingsProvider);
    expect(s.servers.map((e) => e.id), ['a', 'b']);
    final a = s.servers.first;
    expect(a.url, 'http://10.0.0.9:3030');
    expect(a.label, '10.0.0.9', reason: 'an address-derived label follows');
    expect(s.activeServerId, 'a');
    expect(s.remoteSyncBaseUrl, 'http://10.0.0.9:3030');
    expect(s.remoteSyncApiKey, 'new-key');
    expect(await secure.read(key: 'sync_api_key_a'), 'new-key');
  });

  test('a label the user typed is kept', () async {
    await boot({...twoServers(), 'settings_sync_active_id': 'b'});

    await container
        .read(settingsProvider.notifier)
        .rescanServer('http://laptop2:3030', 'k2');

    final b = container.read(settingsProvider).servers.last;
    expect(b.url, 'http://laptop2:3030');
    expect(b.label, 'Laptop');
  });

  test('a known address switches to that server with the new key', () async {
    await boot(twoServers());

    await container
        .read(settingsProvider.notifier)
        .rescanServer('http://b:3030', 'kb2');

    final s = container.read(settingsProvider);
    expect(s.servers, hasLength(2));
    expect(s.servers.first.url, 'http://10.0.0.5:3030', reason: 'untouched');
    expect(s.activeServerId, 'b');
    expect(s.remoteSyncApiKey, 'kb2');
  });

  test('with no servers it adds one', () async {
    await boot({});

    await container
        .read(settingsProvider.notifier)
        .rescanServer('http://pc:3030', 'k');

    final s = container.read(settingsProvider);
    expect(s.servers.single.url, 'http://pc:3030');
    expect(s.remoteSyncApiKey, 'k');
  });
}
