import 'dart:async';
import 'dart:developer' as developer;

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
import 'src/sync/phone_log_shipper.dart';

/// The container backing the currently mounted tree. The foreground-task
/// callback outlives a restart, so it must read through this instead of
/// capturing one container.
ProviderContainer? _activeContainer;

Future<void> main() async {
  developer.Timeline.instantSync('startup.main.start');
  Logger.root.level = Level.ALL;
  PhoneLogShipper.install();
  Logger.root.onRecord.listen((r) {
    debugPrint(
      '${r.level.name} ${r.loggerName}: ${r.message} ${r.error ?? ''} ${r.stackTrace ?? ''}',
    );
    developer.log(
      r.message,
      name: r.loggerName,
      error: r.error,
      stackTrace: r.stackTrace,
      level: r.level.value,
    );
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
  FlutterForegroundTask.addTaskDataCallback((data) {
    if (data != 'active-workout') return;
    final prefs = _activeContainer?.read(sharedPreferencesHolderProvider);
    if (prefs == null) return;
    if (prefs.getString(activeWorkoutNameKey) == null) return;
    _openPlanTab('/active-workout');
  });
  runApp(const _AppRoot());
}

/// Owns the app-wide [ProviderContainer] so the foreground-task callback (which
/// outlives the widget tree) can read through [_activeContainer].
final class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

final class _AppRootState extends State<_AppRoot> {
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = _createContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  ProviderContainer _createContainer() {
    final container = ProviderContainer();
    _activeContainer = container;
    unawaited(
      SharedPreferences.getInstance().then((loaded) {
        try {
          container.read(sharedPreferencesHolderProvider.notifier).set(loaded);
        } catch (_) {
          // The container was disposed before prefs resolved.
        }
      }),
    );
    return container;
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _container,
      child: const FitFatApp(),
    );
  }
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
