import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/app/router.dart';
import 'src/notifications/active_workout_notifier.dart';
import 'src/settings/providers/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opt into edge-to-edge rendering on Android (enforced by default on
  // API 35+; this makes older devices match). Status bar icons are handled
  // per-brightness via AppBarTheme.systemOverlayStyle (T10).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // The communication port must be opened before runApp so cold-start taps
  // on the ongoing-workout notification are delivered. Everything heavier
  // (foreground-task init, timezone DB, notifications, catalog import) is
  // deferred to the post-first-frame BackgroundStartup so the first frame
  // renders instantly.
  FlutterForegroundTask.initCommunicationPort();
  final prefs = await SharedPreferences.getInstance();
  // T06: tapping the ongoing workout notification opens the active-workout
  // view. The signal arrives from the background task handler; gate on an
  // active session and defer until the router's navigator is mounted (cold
  // start can deliver the signal before the first frame).
  FlutterForegroundTask.addTaskDataCallback((data) {
    if (data != 'active-workout') return;
    if (prefs.getString(activeWorkoutNameKey) == null) return;
    _openPlanTab('/active-workout');
  });
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const FitFatApp(),
    ),
  );
}

/// Navigates to [location] once the router's navigator is mounted. Used by
/// notification-tap handlers (cold starts deliver the tap before the first
/// frame, so the navigation is deferred to a post-frame callback).
void _openPlanTab([String location = '/plan']) {
  if (appRouter.routerDelegate.navigatorKey.currentState != null) {
    appRouter.go(location);
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.go(location);
    });
  }
}
