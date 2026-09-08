import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/app/router.dart';
import 'src/notifications/active_workout_notifier.dart';
import 'src/settings/providers/settings.dart';

Future<void> main() async {
  developer.Timeline.instantSync('startup.main.start');
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((r) {
    debugPrint('${r.level.name} ${r.loggerName}: ${r.message} ${r.error ?? ''} ${r.stackTrace ?? ''}');
    developer.log(r.message, name: r.loggerName, error: r.error, stackTrace: r.stackTrace, level: r.level.value);
  });
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  FlutterForegroundTask.initCommunicationPort();
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      developer.Timeline.instantSync(
        'startup.frame',
        arguments: {'frameNumber': t.toString()},
      );
    }
  });
  final container = ProviderContainer();
  unawaited(
    SharedPreferences.getInstance().then((prefs) {
      container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
    }),
  );
  FlutterForegroundTask.addTaskDataCallback((data) {
    if (data != 'active-workout') return;
    final prefs = container.read(sharedPreferencesHolderProvider);
    if (prefs == null) return;
    if (prefs.getString(activeWorkoutNameKey) == null) return;
    _openPlanTab('/active-workout');
  });
  runApp(
    UncontrolledProviderScope(container: container, child: const FitFatApp()),
  );
}

void _openPlanTab([String location = '/plan']) {
  if (appRouter.routerDelegate.navigatorKey.currentState != null) {
    appRouter.go(location);
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.go(location);
    });
  }
}
