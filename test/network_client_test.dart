import 'package:fitfat/src/budget/services/remote_fx.dart';
import 'package:fitfat/src/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FxRateRemoteService', () {
    test('parses rates returned by a scripted MockApiClient', () async {
      final mock = MockApiClient(
        onRequest: (method, path, body) async {
          expect(method, 'GET');
          expect(path, '/rates');
          return {
            'base': 'USD',
            'rates': {'EUR': 0.92, 'GBP': 0.79},
          };
        },
      );
      final service = FxRateRemoteService(
        mock,
        baseUrl: 'https://example.test',
      );
      final rates = await service.fetchRates('USD');
      expect(rates, {'EUR': 0.92, 'GBP': 0.79});
    });

    test('fails clearly while the endpoint is not configured', () async {
      final service = FxRateRemoteService(MockApiClient(), baseUrl: '');
      await expectLater(service.fetchRates('USD'), throwsStateError);
    });
  });

  group('MockApiClient', () {
    test('returns null when no handler is set', () async {
      final mock = MockApiClient();
      expect(await mock.getJson('/x'), isNull);
      expect(await mock.postJson('/x', body: {'a': 1}), isNull);
      expect(await mock.deleteJson('/x'), isNull);
    });
  });
}