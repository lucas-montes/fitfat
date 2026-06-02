import 'package:flutter_riverpod/flutter_riverpod.dart';

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
