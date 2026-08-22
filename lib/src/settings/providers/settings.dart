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
  // Auto-refresh cached FX rates from the remote service in the background.
  final bool fxAutoRefresh; // default off
  final int fxRefreshIntervalHours; // default 24

  // Display units (storage stays metric).
  final WeightUnit weightUnit; // default kg
  final LengthUnit lengthUnit; // default cm

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
    this.fxAutoRefresh = false,
    this.fxRefreshIntervalHours = 24,
    this.weightUnit = WeightUnit.kg,
    this.lengthUnit = LengthUnit.cm,
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
    bool? fxAutoRefresh,
    int? fxRefreshIntervalHours,
    WeightUnit? weightUnit,
    LengthUnit? lengthUnit,
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
    fxAutoRefresh: fxAutoRefresh ?? this.fxAutoRefresh,
    fxRefreshIntervalHours:
        fxRefreshIntervalHours ?? this.fxRefreshIntervalHours,
    weightUnit: weightUnit ?? this.weightUnit,
    lengthUnit: lengthUnit ?? this.lengthUnit,
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
  static const _fxAutoRefreshKey = 'settings_fx_auto_refresh';
  static const _fxRefreshIntervalHoursKey =
      'settings_fx_refresh_interval_hours';
  static const _weightUnitKey = 'settings_weight_unit';
  static const _lengthUnitKey = 'settings_length_unit';

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
      fxAutoRefresh: prefs.getBool(_fxAutoRefreshKey) ?? false,
      fxRefreshIntervalHours: prefs.getInt(_fxRefreshIntervalHoursKey) ?? 24,
      weightUnit: _weightUnitFromName(prefs.getString(_weightUnitKey)),
      lengthUnit: _lengthUnitFromName(prefs.getString(_lengthUnitKey)),
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

  Future<void> setFxAutoRefresh(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_fxAutoRefreshKey, enabled);
    state = state.copyWith(fxAutoRefresh: enabled);
  }

  Future<void> setFxRefreshIntervalHours(int hours) async {
    if (hours <= 0) return;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_fxRefreshIntervalHoursKey, hours);
    state = state.copyWith(fxRefreshIntervalHours: hours);
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
