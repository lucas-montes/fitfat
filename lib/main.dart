import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/app.dart';
import 'src/app/app_restart.dart';
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

/// Owns the [ProviderContainer] and rebuilds the whole tree when
/// [appRestartSignal] fires.
///
/// A whole-database import swaps the file under the app, so every provider
/// (and the closed database handle) is stale. Bumping the signal tears the
/// old container down and starts a fresh one against the imported file.
final class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

final class _AppRootState extends State<_AppRoot> {
  ProviderContainer? _container;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    appRestartSignal.addListener(_restart);
    _container = _createContainer();
  }

  @override
  void dispose() {
    appRestartSignal.removeListener(_restart);
    _container?.dispose();
    super.dispose();
  }

  ProviderContainer _createContainer([SharedPreferences? prefs]) {
    final container = ProviderContainer();
    _activeContainer = container;
    if (prefs != null) {
      // A restart happens while the user may be on a screen that reads prefs
      // synchronously; hand the new container the already-loaded instance so
      // that first frame cannot race the async load.
      container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
      return container;
    }
    unawaited(
      SharedPreferences.getInstance().then((loaded) {
        try {
          container.read(sharedPreferencesHolderProvider.notifier).set(loaded);
        } catch (_) {
          // The container was disposed by a restart before prefs resolved.
        }
      }),
    );
    return container;
  }

  void _restart() {
    final old = _container;
    final prefs = old?.read(sharedPreferencesHolderProvider);
    setState(() {
      _generation++;
      _container = _createContainer(prefs);
    });
    // The old tree is still on screen for this frame; dispose it once the new
    // one has been built so no in-flight provider read hits a closed handle.
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      key: ValueKey(_generation),
      container: _container!,
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
