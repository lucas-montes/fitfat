import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Global singleton instance to ensure database persists across app lifetime.
AppDatabase? _dbInstance;

/// Singleton provider for the Drift database (production/local default).
final databaseProvider = Provider<AppDatabase>((ref) {
  if (_dbInstance != null) {
    return _dbInstance!;
  }
  final db = AppDatabase();
  _dbInstance = db;
  return db;
});

/// Development/test database provider that uses a separate file-backed
/// SQLite database so tests and dev runs don't touch the production DB.
final devDatabaseProvider = Provider<AppDatabase>((ref) {
  final executor = LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'fitfat_dev.db');
    return NativeDatabase(File(dbPath));
  });

  final db = AppDatabase.open(executor);
  ref.onDispose(() => db.close());
  return db;
});
