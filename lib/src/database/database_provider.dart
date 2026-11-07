import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart' as db;

final databaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(database.close);
  return database;
});
