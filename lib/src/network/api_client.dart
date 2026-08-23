import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../settings/providers/settings.dart';

/// Low-level HTTP abstraction returning decoded JSON. Implementations:
/// [HttpApiClient] (real `package:http`) and [MockApiClient] (scripted, for
/// tests). Higher-level services (FX rates, future sync) depend on this so
/// they can be unit-tested without a socket; swap it in `ProviderScope` via
/// [apiClientProvider].
abstract class ApiClient {
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  });

  Future<Object?> deleteJson(String path, {Map<String, String>? query});
}

/// Thrown for any non-2xx response surfaced by [HttpApiClient].
final class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Production [ApiClient] backed by `package:http`. Requests are joined onto
/// [baseUrl] and time out after [timeout]; responses are decoded as UTF-8
/// JSON.
final class HttpApiClient implements ApiClient {
  HttpApiClient(
    this._client, {
    required this.baseUrl,
    this.timeout = defaultTimeout,
  });

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'FitFat/1.0',
  };

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Uri _uri(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Map<String, String>? headers,
  }) async {
    final response = await request().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(statusCode: response.statusCode, body: response.body);
    }
    return response;
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _send(
      () => _client.get(
        _uri(path, query: query),
        headers: {..._headers, ...?headers},
      ),
      headers: headers,
    );
    return _decode(response);
  }

  @override
  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri(path, query: query),
        headers: {..._headers, ...?headers},
        body: _encodeBody(body),
      ),
      headers: headers,
    );
    return _decode(response);
  }

  @override
  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri(path, query: query),
        headers: {..._headers, ...?headers},
        body: _encodeBody(body),
      ),
      headers: headers,
    );
    return _decode(response);
  }

  @override
  Future<Object?> deleteJson(String path, {Map<String, String>? query}) async {
    final response = await _send(
      () => _client.delete(_uri(path, query: query), headers: _headers),
    );
    return _decode(response);
  }

  String? _encodeBody(Object? body) => body == null ? null : jsonEncode(body);
}

/// Scripted [ApiClient] for tests. [onRequest] receives `(method, path, body)`
/// and returns the decoded-JSON response (or throws to simulate an HTTP
/// failure); no handler yields `null`.
final class MockApiClient implements ApiClient {
  MockApiClient({this.onRequest});

  final Future<Object?> Function(String method, String path, Object? body)?
  onRequest;

  Future<Object?> _handle(String method, String path, Object? body) {
    final handler = onRequest;
    if (handler == null) return Future<Object?>.value(null);
    return handler(method, path, body);
  }

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _handle('GET', path, null);

  @override
  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _handle('POST', path, body);

  @override
  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) => _handle('PUT', path, body);

  @override
  Future<Object?> deleteJson(String path, {Map<String, String>? query}) =>
      _handle('DELETE', path, null);
}

/// Overridable network client. Tests inject [MockApiClient] via
/// `apiClientProvider.overrideWithValue(...)`; the default hits [baseUrl]
/// (compile-time `API_BASE_URL`, empty until a real endpoint is configured).
final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final timeout = Duration(
    seconds: ref.watch(settingsProvider).apiTimeoutSeconds,
  );
  return HttpApiClient(http.Client(), baseUrl: baseUrl, timeout: timeout);
});
