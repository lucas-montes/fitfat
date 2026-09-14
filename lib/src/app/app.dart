import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'dart:developer' as developer;

import '../../l10n/app_localizations.dart';
import '../dashboard/providers/dashboard.dart';
import '../database/database_provider.dart';
import '../experiments/notifications/experiment_reminder.dart';
import '../experiments/providers/experiments_repository.dart';
import '../notifications/active_workout_notifier.dart';
import '../notifications/notification_plugin.dart';
import '../notifications/rest_alarm.dart';
import '../goals/notifications/goal_reminder.dart';
import '../goals/providers/goals.dart';
import '../notifications/task_reminders.dart';
import '../planner/providers/planner.dart';
import '../settings/providers/settings.dart';
import '../sync/sync_service.dart';
import 'router.dart';
import 'startup_gate.dart';
import 'theme.dart';

final class FitFatApp extends ConsumerStatefulWidget {
  const FitFatApp({super.key});

  @override
  ConsumerState<FitFatApp> createState() => _FitFatAppState();
}

final class _FitFatAppState extends ConsumerState<FitFatApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.Timeline.instantSync('startup.firstFrame');
      if (mounted) ref.read(startupGateProvider.notifier).complete();
    });
  }

  @override
  Widget build(BuildContext context) {
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

  /// Refreshes the selective-sync catalog in the background (best-effort,
  /// silent, cursor-free). Throttled to every 15 minutes so resumes don't
  /// hammer the server; a missing server configuration is a no-op.
  Future<void> _refreshSelectiveCatalogs() async {
    try {
      final prefs = ref.read(sharedPreferencesHolderProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = prefs?.getInt('selective_catalog_last_refresh') ?? 0;
      if (now - last < const Duration(minutes: 15).inMilliseconds) return;
      final settings = ref.read(settingsProvider);
      final base = settings.remoteSyncBaseUrl;
      if (base.isEmpty) return;
      await ref
          .read(syncServiceProvider)
          .refreshSelectiveCatalogs(
            base,
            settings.remoteSyncApiKey,
            exercisesEndpoint: '${settings.endpointExercises}/catalog',
            ingredientsEndpoint: '${settings.endpointIngredients}/catalog',
            timeout: Duration(seconds: settings.apiTimeoutSeconds),
          );
      await prefs?.setInt('selective_catalog_last_refresh', now);
    } catch (_) {
      return; // Background refresh must never surface errors.
    }
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
    final weekStartUtc = DateTime.utc(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));
    final weekStart = DateTime(
      weekStartUtc.year,
      weekStartUtc.month,
      weekStartUtc.day,
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    ref.invalidate(rangeEntriesProvider((weekStart, weekEnd)));
    ref.invalidate(monthEntriesProvider(DateTime(today.year, today.month, 1)));
    invalidateDashboard(ref);
  }

  Future<void> _run() async {
    if (_ran || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
      return;
    }
    _ran = true;

    final prefs = await ref.read(sharedPreferencesReadyProvider.future);
    developer.Timeline.instantSync('startup.db.warmup.start');
    unawaited(
      Future(() async {
        try {
          await ref.read(databaseProvider).customStatement('SELECT 1');
          developer.Timeline.instantSync('startup.db.warmup.done');
        } catch (_) {}
      }),
    );

    // Native plugin init (independent — run concurrently). The foreground-task
    // channel is HIGH priority + public visibility so the ongoing-workout
    // notification alerts on a locked screen; the notification plugin init
    // wires the tap handlers. Foreground init is shared/idempotent with
    // ActiveWorkoutNotifier so an early workout start never races startup.
    await Future.wait([
      ensureForegroundServiceInitialized(),
      initializeNotifications(
        plugin: ref.read(flutterLocalNotificationsProvider),
        onTapPlan: () => appRouter.go('/plan'),
        onTapActiveWorkout: () => appRouter.go('/active-workout'),
        // Experiments now live inside the Planner tab.
        onTapExperiments: () => appRouter.go('/plan'),
      ),
    ]);

    // Recover an ongoing workout session after a process kill / reboot
    // (autoRunOnBoot is false, so the service is gone but prefs persist).
    await restoreWorkoutServiceIfNeeded(prefs);

    // Cache the localized rest-alarm text for the scheduler (it schedules from
    // contexts without `AppLocalizations`, e.g. the rest-timer notifier).
    await prefs.setString(restAlarmTitleKey, l10n.restAlarmTitle);
    await prefs.setString(restAlarmBodyKey, l10n.restAlarmBody);
    // Template with {duration} placeholder for the scheduler to fill in
    await prefs.setString(
      'rest_alarm_body_with_duration',
      l10n.restAlarmBodyWithDuration('{duration}'),
    );

    final settings = ref.read(settingsProvider);
    final goals = await ref.read(goalRepositoryProvider).getGoals();
    final needsTimezone =
        settings.plannerNotifications ||
        settings.experimentRemindersEnabled ||
        goals.any((g) => g.isActive && g.reminderEnabled);
    if (needsTimezone) {
      await _initTimeZone();
    }

    if (settings.plannerNotifications) {
      await ref
          .read(taskReminderSchedulerProvider)
          .reschedulePending(
            repository: ref.read(taskRepositoryProvider),
            dueSoonText: l10n.taskReminderDueSoon,
            dueNowText: l10n.taskReminderDueNow,
          );
    }

    for (final goal in goals) {
      await ref
          .read(goalReminderSchedulerProvider)
          .scheduleForGoal(
            goal,
            title: goal.title,
            body: l10n.goalsReminderSubtitle,
          );
    }

    if (settings.experimentRemindersEnabled) {
      final experiments = await ref
          .read(experimentRepositoryProvider)
          .getAll();
      for (final exp in experiments) {
        await ref
            .read(experimentReminderSchedulerProvider)
            .scheduleForExperiment(
              exp,
              title: l10n.experimentReminderTitle(exp.name),
              body: l10n.experimentReminderBody,
            );
      }
    }

    await _rollover();
    unawaited(_refreshSelectiveCatalogs());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_rollover());
      unawaited(_refreshSelectiveCatalogs());
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
