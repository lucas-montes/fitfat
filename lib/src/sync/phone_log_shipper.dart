import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../network/api_client.dart';

/// Buffers this device's `package:logging` records and ships them to the sync
/// server's `/phone-logs` endpoint, which traces each line to its stdout.
///
/// This makes remote debugging possible without `adb logcat`: whenever the
/// phone performs a sync or push, its recent log history (including the error
/// that just happened) lands in the computer's console.
final class PhoneLogShipper {
  PhoneLogShipper._();

  static final PhoneLogShipper instance = PhoneLogShipper._();

  static bool _installed = false;
  static const int maxLines = 200;

  final List<String> _buffer = <String>[];
  http.Client? _client;

  /// Subscribes to every log record produced anywhere in the app. Call once
  /// from `main()`.
  static void install() {
    if (_installed) return;
    _installed = true;
    Logger.root.onRecord.listen((r) {
      final error = r.error == null ? '' : ' — ${r.error}';
      instance._append(
        '${r.time.toIso8601String()} ${r.level.name} ${r.loggerName}: ${r.message}$error',
      );
    });
  }

  void _append(String line) {
    if (line.isEmpty) return;
    if (_buffer.length >= maxLines) _buffer.removeAt(0);
    _buffer.add(line);
  }

  /// Post the buffered lines to the server. Fire-and-forget at the call site:
  /// diagnostics must never fail the operation that is being diagnosed.
  ///
  /// [debugPrint]s problems instead of throwing so the Flutter console still
  /// reflects shipping failures.
  Future<void> ship({required String baseUrl, required String apiKey}) async {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return;
    if (_buffer.isEmpty) return;
    // Snapshot + clear: records logged while shipping are kept for the next
    // attempt, and on failure the snapshot is put back so no history is lost.
    final lines = List<String>.from(_buffer);
    _buffer.clear();
    final client = _client ??= http.Client();
    final api = HttpApiClient(
      client,
      baseUrl: base,
      timeout: const Duration(seconds: 5),
    );
    try {
      await api.postJson(
        '/phone-logs',
        body: {'lines': lines},
        headers: authHeaders(apiKey),
      );
    } catch (e) {
      _buffer.insertAll(0, lines.take(maxLines - _buffer.length));
      debugPrint('PhoneLogShipper: could not ship ${lines.length} lines — $e');
    }
  }
}
