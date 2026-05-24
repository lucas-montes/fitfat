import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/main.dart';
import 'src/app/router.dart';
import 'src/services/logger.dart' show initLogging;

void _onForegroundTaskData(Object data) {
  if (data is Map<String, dynamic> && data['type'] == 'open_current_seance') {
    appRouter.go('/current-seance');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  runApp(const ProviderScope(child: FitFatApp()));
}
