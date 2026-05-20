import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/router/app_router.dart';

void _onForegroundTaskData(Object data) {
  if (data is Map<String, dynamic> && data['type'] == 'open_current_seance') {
    appRouter.go('/exercise');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  runApp(const ProviderScope(child: FitFatApp()));
}
