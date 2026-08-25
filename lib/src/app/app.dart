import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../dashboard/providers/dashboard.dart';
import '../notifications/notification_plugin.dart';
import '../notifications/rest_alarm.dart';
import '../notifications/task_reminders.dart';
import '../planner/providers/planner.dart';
import '../settings/providers/settings.dart';
import 'router.dart';
import 'theme.dart';

final class FitFatApp extends ConsumerWidget {
  const FitFatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'FitFat',
      debugShowCheckedModeBanner: false,
      theme: FitFatTheme.light,
      darkTheme: FitFatTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      routerConfig: appRouter,
      builder: (context, child) => _BackgroundStartup(child: child),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
    );
  }
}

/// Runs one-time background startup after the first frame so `runApp` returns
/// instantly. Rendered via `MaterialApp.builder` so it sits under
/// `Localizations` and can resolve the app locale for notification bodies.
///
/// Deferred work, in order:
///  1. Catalog import — idempotent (one-time prefs flag), no-op on later
///     launches; kicked off first and unawaited so the exercise list fills
///     in while the rest of startup continues.
///  2. Foreground-service channel config (only needed when a workout starts).
///  3. Timezone DB + device zone (only needed when scheduling reminders).
///  4. Notification scheduler init + cold-start tap replay.
///  4. Notification scheduler init + cold-start tap replay.
///  5. Planner reminder (re)schedule for pending future timed tasks — covers
///     cold starts; a no-op when the app-wide toggle is off.
///  6. Day rollover — past pending carry-over tasks move to today, others
///     become cancelled; re-runs on every app resume.
final class _BackgroundStartup extends ConsumerStatefulWidget {
  final Widget? child;

  const _BackgroundStartup({this.child});

  @override
  ConsumerState<_BackgroundStartup> createState() => _BackgroundStartupState();
}

final class _BackgroundStartupState extends ConsumerState<_BackgroundStartup>
    with WidgetsBindingObserver {
  bool _ran = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Moves past pending carry-over tasks to today (others become cancelled)
  /// and refreshes the affected providers. Runs on cold start and on every
  /// resume so a day that passes while the app sits in the background is
  /// still rolled over.
  Future<void> _rollover() async {
    try {
      final moved = await ref.read(taskRepositoryProvider).rolloverPastTasks();
      if (moved == 0 || !mounted) return;
    } catch (_) {
      return; // Rollover must never block startup.
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    ref.invalidate(dayEntriesProvider(today));
    ref.invalidate(monthEntriesProvider(today));
    invalidateDashboard(ref);
  }

  Future<void> _run() async {
    if (_ran || !mounted) return;
    _ran = true;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final prefs = ref.read(sharedPreferencesProvider);

    // Native plugin init (independent — run concurrently). The foreground-task
    // channel is HIGH priority + public visibility so the ongoing-workout
    // notification alerts on a locked screen; the notification plugin init
    // wires the tap handlers.
    await Future.wait([
      Future(
        () => FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'active_workout',
            channelName: 'Active Workout',
            channelDescription:
                'Shows workout duration and rest timer while a workout is active.',
            onlyAlertOnce: true,
            channelImportance: NotificationChannelImportance.HIGH,
            priority: NotificationPriority.HIGH,
            visibility: NotificationVisibility.VISIBILITY_PUBLIC,
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: false,
            playSound: false,
          ),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(1000),
            autoRunOnBoot: false,
            autoRunOnMyPackageReplaced: false,
            allowWakeLock: true,
            allowWifiLock: false,
          ),
        ),
      ),
      initializeNotifications(
        plugin: ref.read(flutterLocalNotificationsProvider),
        onTapPlan: () => appRouter.go('/plan'),
        onTapActiveWorkout: () => appRouter.go('/active-workout'),
        // Experiments now live inside the Planner tab.
        onTapExperiments: () => appRouter.go('/plan'),
      ),
    ]);

    // Cache the localized rest-alarm text for the scheduler (it schedules from
    // contexts without `AppLocalizations`, e.g. the rest-timer notifier).
    await prefs.setString(restAlarmTitleKey, l10n.restAlarmTitle);
    await prefs.setString(restAlarmBodyKey, l10n.restAlarmBody);
    // Template with {duration} placeholder for the scheduler to fill in
    await prefs.setString(
      'rest_alarm_body_with_duration',
      l10n.restAlarmBodyWithDuration('{duration}'),
    );

    // Planner reminders for pending future timed tasks (no-op when off).
    // Timezone data is initialized lazily here — only when we actually
    // schedule — so it no longer blocks every cold start.
    if (ref.read(settingsProvider).plannerNotifications) {
      await _initTimeZone();
      await ref
          .read(taskReminderSchedulerProvider)
          .reschedulePending(
            repository: ref.read(taskRepositoryProvider),
            dueSoonText: l10n.taskReminderDueSoon,
            dueNowText: l10n.taskReminderDueNow,
          );
    }

    await _rollover();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rollover());
    }
  }

  /// Loads the IANA timezone database and pins the device's local zone so
  /// `zonedSchedule` fires at the right wall-clock time. Deferred until a
  /// reminder actually needs scheduling.
  Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
      );
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
