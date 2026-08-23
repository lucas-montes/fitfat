import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../models/units.dart';

/// App-level `SharedPreferences` instance. Overridden in `main()` after
/// `SharedPreferences.getInstance()` so settings load synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

final class SettingsState {
  final ThemeMode themeMode;
  final Locale? locale; // null = follow the device locale
  final int? age;
  final BodyWeightGoal? bodyWeightGoal; // null = unset

  // Calorie-profile inputs (schema-agnostic, prefs-backed).
  final Gender? gender; // null = unset
  final ActivityLevel? activityLevel; // null = unset (static mode)
  final bool computeActivity; // true = derive activity from workouts + steps
  final bool trackBodyFat; // true = enable Katch-McArdle when body fat set
  final double? bodyFatPercent; // null = unset
  final bool
  plannerNotifications; // app-wide task reminders toggle (default on)
  final bool restAlarmSound; // rest alarm plays a sound (default on)
  final bool restAlarmVibration; // rest alarm vibrates (default on)
  // Master switch for experiment check-in reminders (default on). When off,
  // all scheduled experiment reminders are cancelled.
  final bool experimentRemindersEnabled;

  final String baseCurrency; // ISO-4217-ish code, default 'USD'

  // Display units (storage stays metric).
  final WeightUnit weightUnit; // default kg
  final LengthUnit lengthUnit; // default cm

  // What replay prefills the new occurrence's planned sets from:
  // 'actuals' (previous completion's actuals, progressive overload) or
  // 'planned' (the source's planned values).
  final String replayPrefill; // default 'actuals'

  // Base URL of the user's sync server (exercises/ingredients/currencies).
  // Empty until configured; the sync clients refuse to run without it.
  final String remoteSyncBaseUrl; // default ''
  // API key sent as a Bearer token on every sync request.
  final String remoteSyncApiKey; // default ''

  // How many days ahead recurring planner tasks are materialized
  // (default 90).
  final int plannerHorizonDays;
  // kcal adjustment applied on top of TDEE for lose/gain goals (default 500).
  final double calorieGoalAdjustment;
  // Length of the baseline phase shown on an experiment's chart, in days
  // (default 14).
  final int experimentBaselineDays;
  // Prefill for new planned sets' rest field, in seconds; 0 = empty
  // (current behavior, default).
  final int defaultRestSeconds;
  // Minutes before a task's start time at which the advance reminder fires
  // (default 30).
  final int reminderLeadMinutes;
  // Sync HTTP request timeout in seconds (default 15).
  final int apiTimeoutSeconds;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.age,
    this.bodyWeightGoal,
    this.gender,
    this.activityLevel,
    this.computeActivity = false,
    this.trackBodyFat = false,
    this.bodyFatPercent,
    this.plannerNotifications = true,
    this.restAlarmSound = true,
    this.restAlarmVibration = true,
    this.experimentRemindersEnabled = true,
    this.baseCurrency = 'USD',
    this.weightUnit = WeightUnit.kg,
    this.lengthUnit = LengthUnit.cm,
    this.replayPrefill = 'actuals',
    this.remoteSyncBaseUrl = '',
    this.remoteSyncApiKey = '',
    this.plannerHorizonDays = 90,
    this.calorieGoalAdjustment = 500,
    this.experimentBaselineDays = 14,
    this.defaultRestSeconds = 0,
    this.reminderLeadMinutes = 30,
    this.apiTimeoutSeconds = 15,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    int? age,
    bool clearAge = false,
    BodyWeightGoal? bodyWeightGoal,
    bool clearBodyWeightGoal = false,
    Gender? gender,
    bool clearGender = false,
    ActivityLevel? activityLevel,
    bool clearActivityLevel = false,
    bool? computeActivity,
    bool? trackBodyFat,
    double? bodyFatPercent,
    bool clearBodyFatPercent = false,
    bool? plannerNotifications,
    bool? restAlarmSound,
    bool? restAlarmVibration,
    bool? experimentRemindersEnabled,
    String? baseCurrency,
    WeightUnit? weightUnit,
    LengthUnit? lengthUnit,
    String? replayPrefill,
    String? remoteSyncBaseUrl,
    String? remoteSyncApiKey,
    int? plannerHorizonDays,
    double? calorieGoalAdjustment,
    int? experimentBaselineDays,
    int? defaultRestSeconds,
    int? reminderLeadMinutes,
    int? apiTimeoutSeconds,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    locale: clearLocale ? null : (locale ?? this.locale),
    age: clearAge ? null : (age ?? this.age),
    bodyWeightGoal: clearBodyWeightGoal
        ? null
        : (bodyWeightGoal ?? this.bodyWeightGoal),
    gender: clearGender ? null : (gender ?? this.gender),
    activityLevel: clearActivityLevel
        ? null
        : (activityLevel ?? this.activityLevel),
    computeActivity: computeActivity ?? this.computeActivity,
    trackBodyFat: trackBodyFat ?? this.trackBodyFat,
    bodyFatPercent: clearBodyFatPercent
        ? null
        : (bodyFatPercent ?? this.bodyFatPercent),
    plannerNotifications: plannerNotifications ?? this.plannerNotifications,
    restAlarmSound: restAlarmSound ?? this.restAlarmSound,
    restAlarmVibration: restAlarmVibration ?? this.restAlarmVibration,
    experimentRemindersEnabled:
        experimentRemindersEnabled ?? this.experimentRemindersEnabled,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    weightUnit: weightUnit ?? this.weightUnit,
    lengthUnit: lengthUnit ?? this.lengthUnit,
    replayPrefill: replayPrefill ?? this.replayPrefill,
    remoteSyncBaseUrl: remoteSyncBaseUrl ?? this.remoteSyncBaseUrl,
    remoteSyncApiKey: remoteSyncApiKey ?? this.remoteSyncApiKey,
    plannerHorizonDays: plannerHorizonDays ?? this.plannerHorizonDays,
    calorieGoalAdjustment: calorieGoalAdjustment ?? this.calorieGoalAdjustment,
    experimentBaselineDays:
        experimentBaselineDays ?? this.experimentBaselineDays,
    defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    apiTimeoutSeconds: apiTimeoutSeconds ?? this.apiTimeoutSeconds,
  );
}

final class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeModeKey = 'settings_theme_mode';
  static const _localeKey = 'settings_locale';
  static const _ageKey = 'settings_age';
  static const _bodyWeightGoalKey = 'settings_body_weight_goal';
  static const _genderKey = 'settings_gender';
  static const _activityLevelKey = 'settings_activity_level';
  static const _computeActivityKey = 'settings_compute_activity';
  static const _trackBodyFatKey = 'settings_track_body_fat';
  static const _bodyFatPercentKey = 'settings_body_fat_percent';
  static const _plannerNotificationsKey = 'settings_planner_notifications';
  static const _restAlarmSoundKey = 'settings_rest_alarm_sound';
  static const _restAlarmVibrationKey = 'settings_rest_alarm_vibration';
  static const _experimentRemindersKey = 'settings_experiment_reminders';
  static const _baseCurrencyKey = 'settings_base_currency';
  static const _weightUnitKey = 'settings_weight_unit';
  static const _lengthUnitKey = 'settings_length_unit';
  static const _replayPrefillKey = 'settings_replay_prefill';
  static const _remoteSyncBaseUrlKey = 'settings_remote_sync_base_url';
  static const _remoteSyncApiKeyKey = 'settings_remote_sync_api_key';
  static const _plannerHorizonDaysKey = 'settings_planner_horizon_days';
  static const _calorieGoalAdjustmentKey = 'settings_calorie_goal_adjustment';
  static const _experimentBaselineDaysKey = 'settings_experiment_baseline_days';
  static const _defaultRestSecondsKey = 'settings_default_rest_seconds';

  /// Public so the reminder scheduler can read the lead time directly from
  /// prefs (it receives SharedPreferences, not the settings notifier).
  static const reminderLeadMinutesKey = 'settings_reminder_lead_minutes';
  static const _apiTimeoutSecondsKey = 'settings_api_timeout_seconds';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
      locale: _localeFromCode(prefs.getString(_localeKey)),
      age: prefs.getInt(_ageKey),
      bodyWeightGoal: _bodyWeightGoalFromName(
        prefs.getString(_bodyWeightGoalKey),
      ),
      gender: _genderFromName(prefs.getString(_genderKey)),
      activityLevel: _activityLevelFromName(prefs.getString(_activityLevelKey)),
      computeActivity: prefs.getBool(_computeActivityKey) ?? false,
      trackBodyFat: prefs.getBool(_trackBodyFatKey) ?? false,
      bodyFatPercent: prefs.getDouble(_bodyFatPercentKey),
      plannerNotifications: prefs.getBool(_plannerNotificationsKey) ?? true,
      restAlarmSound: prefs.getBool(_restAlarmSoundKey) ?? true,
      restAlarmVibration: prefs.getBool(_restAlarmVibrationKey) ?? true,
      experimentRemindersEnabled:
          prefs.getBool(_experimentRemindersKey) ?? true,
      baseCurrency: prefs.getString(_baseCurrencyKey) ?? 'USD',
      weightUnit: _weightUnitFromName(prefs.getString(_weightUnitKey)),
      lengthUnit: _lengthUnitFromName(prefs.getString(_lengthUnitKey)),
      replayPrefill: prefs.getString(_replayPrefillKey) == 'planned'
          ? 'planned'
          : 'actuals',
      remoteSyncBaseUrl: prefs.getString(_remoteSyncBaseUrlKey) ?? '',
      remoteSyncApiKey: prefs.getString(_remoteSyncApiKeyKey) ?? '',
      plannerHorizonDays: prefs.getInt(_plannerHorizonDaysKey) ?? 90,
      calorieGoalAdjustment:
          prefs.getDouble(_calorieGoalAdjustmentKey) ?? 500.0,
      experimentBaselineDays: prefs.getInt(_experimentBaselineDaysKey) ?? 14,
      defaultRestSeconds: prefs.getInt(_defaultRestSecondsKey) ?? 0,
      reminderLeadMinutes: prefs.getInt(reminderLeadMinutesKey) ?? 30,
      apiTimeoutSeconds: prefs.getInt(_apiTimeoutSecondsKey) ?? 15,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_localeKey, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  Future<void> setLocaleToSystem() async {
    await ref.read(sharedPreferencesProvider).remove(_localeKey);
    state = state.copyWith(locale: null, clearLocale: true);
  }

  Future<void> setAge(int? age) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (age == null) {
      await prefs.remove(_ageKey);
    } else {
      await prefs.setInt(_ageKey, age);
    }
    state = state.copyWith(age: age, clearAge: age == null);
  }

  Future<void> setBodyWeightGoal(BodyWeightGoal? goal) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (goal == null) {
      await prefs.remove(_bodyWeightGoalKey);
    } else {
      await prefs.setString(_bodyWeightGoalKey, goal.name);
    }
    state = state.copyWith(
      bodyWeightGoal: goal,
      clearBodyWeightGoal: goal == null,
    );
  }

  Future<void> setGender(Gender? gender) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (gender == null) {
      await prefs.remove(_genderKey);
    } else {
      await prefs.setString(_genderKey, gender.name);
    }
    state = state.copyWith(gender: gender, clearGender: gender == null);
  }

  Future<void> setActivityLevel(ActivityLevel? level) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (level == null) {
      await prefs.remove(_activityLevelKey);
    } else {
      await prefs.setString(_activityLevelKey, level.name);
    }
    state = state.copyWith(
      activityLevel: level,
      clearActivityLevel: level == null,
    );
  }

  Future<void> setComputeActivity(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_computeActivityKey, enabled);
    state = state.copyWith(computeActivity: enabled);
  }

  Future<void> setTrackBodyFat(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_trackBodyFatKey, enabled);
    state = state.copyWith(trackBodyFat: enabled);
  }

  Future<void> setBodyFatPercent(double? percent) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (percent == null) {
      await prefs.remove(_bodyFatPercentKey);
    } else {
      await prefs.setDouble(_bodyFatPercentKey, percent);
    }
    state = state.copyWith(
      bodyFatPercent: percent,
      clearBodyFatPercent: percent == null,
    );
  }

  Future<void> setPlannerNotifications(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_plannerNotificationsKey, enabled);
    state = state.copyWith(plannerNotifications: enabled);
  }

  Future<void> setRestAlarmSound(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_restAlarmSoundKey, enabled);
    state = state.copyWith(restAlarmSound: enabled);
  }

  Future<void> setRestAlarmVibration(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_restAlarmVibrationKey, enabled);
    state = state.copyWith(restAlarmVibration: enabled);
  }

  Future<void> setBaseCurrency(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_baseCurrencyKey, normalized);
    state = state.copyWith(baseCurrency: normalized);
  }

  Future<void> setExperimentRemindersEnabled(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_experimentRemindersKey, enabled);
    state = state.copyWith(experimentRemindersEnabled: enabled);
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_weightUnitKey, unit.name);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setLengthUnit(LengthUnit unit) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_lengthUnitKey, unit.name);
    state = state.copyWith(lengthUnit: unit);
  }

  /// Only 'actuals' | 'planned' are accepted; anything else keeps the current
  /// value.
  Future<void> setReplayPrefill(String value) async {
    if (value != 'actuals' && value != 'planned') return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_replayPrefillKey, value);
    state = state.copyWith(replayPrefill: value);
  }

  Future<void> setRemoteSyncBaseUrl(String value) async {
    final trimmed = value.trim();
    await ref
        .read(sharedPreferencesProvider)
        .setString(_remoteSyncBaseUrlKey, trimmed);
    state = state.copyWith(remoteSyncBaseUrl: trimmed);
  }

  Future<void> setRemoteSyncApiKey(String value) async {
    final trimmed = value.trim();
    await ref
        .read(sharedPreferencesProvider)
        .setString(_remoteSyncApiKeyKey, trimmed);
    state = state.copyWith(remoteSyncApiKey: trimmed);
  }

  Future<void> setPlannerHorizonDays(int days) async {
    final clamped = days < 1 ? 1 : days;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_plannerHorizonDaysKey, clamped);
    state = state.copyWith(plannerHorizonDays: clamped);
  }

  Future<void> setCalorieGoalAdjustment(double kcal) async {
    final clamped = kcal < 0 ? 0.0 : kcal;
    await ref
        .read(sharedPreferencesProvider)
        .setDouble(_calorieGoalAdjustmentKey, clamped);
    state = state.copyWith(calorieGoalAdjustment: clamped);
  }

  Future<void> setExperimentBaselineDays(int days) async {
    final clamped = days < 1 ? 1 : days;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_experimentBaselineDaysKey, clamped);
    state = state.copyWith(experimentBaselineDays: clamped);
  }

  Future<void> setDefaultRestSeconds(int seconds) async {
    final clamped = seconds < 0 ? 0 : seconds;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_defaultRestSecondsKey, clamped);
    state = state.copyWith(defaultRestSeconds: clamped);
  }

  Future<void> setReminderLeadMinutes(int minutes) async {
    final clamped = minutes < 0 ? 0 : minutes;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(reminderLeadMinutesKey, clamped);
    state = state.copyWith(reminderLeadMinutes: clamped);
  }

  Future<void> setApiTimeoutSeconds(int seconds) async {
    final clamped = seconds < 1 ? 1 : seconds;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_apiTimeoutSecondsKey, clamped);
    state = state.copyWith(apiTimeoutSeconds: clamped);
  }

  WeightUnit _weightUnitFromName(String? name) =>
      name == 'lb' ? WeightUnit.lb : WeightUnit.kg;

  LengthUnit _lengthUnitFromName(String? name) =>
      name == 'inch' ? LengthUnit.inch : LengthUnit.cm;

  ThemeMode _themeModeFromName(String? name) => ThemeMode.values.firstWhere(
    (mode) => mode.name == name,
    orElse: () => ThemeMode.system,
  );

  Locale? _localeFromCode(String? code) => switch (code) {
    'en' => const Locale('en'),
    'fr' => const Locale('fr'),
    'es' => const Locale('es'),
    _ => null,
  };

  BodyWeightGoal? _bodyWeightGoalFromName(String? name) {
    for (final goal in BodyWeightGoal.values) {
      if (goal.name == name) return goal;
    }
    return null;
  }

  Gender? _genderFromName(String? name) {
    for (final gender in Gender.values) {
      if (gender.name == name) return gender;
    }
    return null;
  }

  ActivityLevel? _activityLevelFromName(String? name) {
    for (final level in ActivityLevel.values) {
      if (level.name == name) return level;
    }
    return null;
  }
}
