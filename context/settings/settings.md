# Settings

App-level settings (theme mode, language, profile age, body-weight goal) persisted via `shared_preferences` and applied app-wide. Lives in `lib/src/settings/`.

## Current state

- `SettingsState` + `SettingsNotifier` (`lib/src/settings/providers/settings.dart`)
- `SettingsScreen` (`lib/src/settings/screens/settings_screen.dart`) — rendered by `SettingsTab` (`lib/src/app/tabs/settings_tab.dart`)
- Settings l10n strings in en/fr/es ARB files (`settings*` keys)
- `FitFatApp` (`lib/src/app/app.dart`) is a `ConsumerWidget` watching `settingsProvider` and wires `MaterialApp.router`: `theme`, `darkTheme`, `themeMode`, `locale`

## Providers

`lib/src/settings/providers/settings.dart`:

- `sharedPreferencesProvider` — `Provider<SharedPreferences>`; **overridden in `main()`** after `SharedPreferences.getInstance()` (synchronous load, no flicker). Throws if read un-overridden.
- `settingsProvider` — `NotifierProvider<SettingsNotifier, SettingsState>` (first Riverpod `Notifier` in the repo).

`SettingsState`:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| themeMode | ThemeMode | system | persisted as `settings_theme_mode` ('system'/'light'/'dark') |
| locale | Locale? | null (device default) | persisted as `settings_locale` ('en'/'fr'/'es') |
| age | int? | null | persisted as `settings_age` |
| bodyWeightGoal | BodyWeightGoal? | null (unset) | persisted as `settings_body_weight_goal` ('lose'/'maintain'/'gain'); enum in `lib/src/models/body_weight_goal.dart`; null = no badge on the dashboard card |
| gender | Gender? | null (unset) | persisted as `settings_gender` ('male'/'female'); enum in `lib/src/models/gender.dart`; calorie-profile input |
| activityLevel | ActivityLevel? | null (unset) | persisted as `settings_activity_level` ('sedentary'/'light'/'moderate'/'active'/'very_active'); enum in `lib/src/models/activity_level.dart`; used by the static-activity calorie mode |
| computeActivity | bool | false | persisted as `settings_compute_activity`; true = derive activity kcal from workouts + steps instead of `activityLevel` |
| trackBodyFat | bool | false | persisted as `settings_track_body_fat`; enables the body-fat input + Katch-McArdle |
| bodyFatPercent | double? | null | persisted as `settings_body_fat_percent` |
| plannerNotifications | bool | true | persisted as `settings_planner_notifications`; app-wide task-reminder toggle (T11) |
| restAlarmSound | bool | true | persisted as `settings_rest_alarm_sound`; rest alarm plays a sound |
| restAlarmVibration | bool | true | persisted as `settings_rest_alarm_vibration`; rest alarm vibrates |
| experimentRemindersEnabled | bool | true | persisted as `settings_experiment_reminders`; master switch for experiment check-in reminders (off cancels all, on reschedules active ones) |
| baseCurrency | String | 'USD' | persisted as `settings_base_currency`; budget base currency (uppercase ISO-4217-ish) |
| weightUnit | WeightUnit | kg | persisted as `settings_weight_unit` ('kg'/'lb'); enum in `lib/src/models/units.dart`; display-only conversion (storage stays metric) |
| lengthUnit | LengthUnit | cm | persisted as `settings_length_unit` ('cm'/'inch'; value named `inch` since `in` is a Dart keyword); display-only |
| replayPrefill | String | 'actuals' | persisted as `settings_replay_prefill` ('actuals'\|'planned'); what `replayWorkout` prefills the new occurrence's planned sets from — previous completion's actuals (progressive overload) or the source's planned values; dropdown on the Profile screen |
| remoteSyncBaseUrl | String | '' | persisted as `settings_remote_sync_base_url`; user's sync server URL (empty until configured; sync clients refuse to run without it) |
| remoteSyncApiKey | String | '' | persisted as `settings_remote_sync_api_key`; sent as a Bearer token on every sync request |
| plannerHorizonDays | int | 90 | persisted as `settings_planner_horizon_days`; how far ahead recurring planner tasks are materialized (Settings → Advanced) |
| calorieGoalAdjustment | double | 500 | persisted as `settings_calorie_goal_adjustment`; kcal added/subtracted from TDEE for gain/lose goals (`adjustForGoal`) |
| experimentBaselineDays | int | 14 | persisted as `settings_experiment_baseline_days`; pre-start baseline window on an experiment's charts |
| defaultRestSeconds | int | 0 (off) | persisted as `settings_default_rest_seconds`; prefills the rest field of newly added planned sets in the workout form (minutes UI, stored seconds) |
| reminderLeadMinutes | int | 30 | persisted as `settings_reminder_lead_minutes`; how long before a task's start time the advance reminder fires (read by `TaskReminderScheduler` directly from prefs via the public `reminderLeadMinutesKey`) |
| apiTimeoutSeconds | int | 15 | persisted as `settings_api_timeout_seconds`; HTTP timeout for sync requests (`HttpApiClient`, wired through `apiClientProvider`) |

Note: `fxAutoRefresh` / `fxRefreshIntervalHours` were removed together with the FX auto-refresh service and bundled remote-FX client (2026-08-24); currencies now update only through the sync client's daily snapshot pulls.

`SettingsNotifier` (`extends Notifier<SettingsState>`):

- `build()` reads the keys from prefs synchronously.
- `setThemeMode(ThemeMode)` / `setLocale(Locale)` / `setLocaleToSystem()` / `setAge(int?)` / `setBodyWeightGoal(BodyWeightGoal?)` / `setGender(Gender?)` / `setActivityLevel(ActivityLevel?)` / `setComputeActivity(bool)` / `setTrackBodyFat(bool)` / `setBodyFatPercent(double?)` / `setPlannerNotifications(bool)` / `setRestAlarmSound(bool)` / `setRestAlarmVibration(bool)` / `setExperimentRemindersEnabled(bool)` / `setBaseCurrency(String)` / `setWeightUnit(WeightUnit)` / `setLengthUnit(LengthUnit)` / `setReplayPrefill(String)` / `setRemoteSyncBaseUrl(String)` / `setRemoteSyncApiKey(String)` / `setPlannerHorizonDays(int)` / `setCalorieGoalAdjustment(double)` / `setExperimentBaselineDays(int)` / `setDefaultRestSeconds(int)` / `setReminderLeadMinutes(int)` / `setApiTimeoutSeconds(int)` — persist first, then update state (apply immediately). Nullable setters remove the key when null (blank clears age/body-fat; there is no UI to clear the goal — once set it is always one of the three, default null = no badge). `setLocaleToSystem()` removes `settings_locale` so `state.locale` becomes null (device default); `SettingsState.copyWith` supports `clearLocale` for this. `setReplayPrefill` rejects anything but 'actuals'/'planned'. The numeric Advanced setters clamp out-of-range input (horizon/baseline/timeout ≥ 1; adjustment/rest/lead ≥ 0).

## Settings screen

`SettingsScreen` (`ConsumerStatefulWidget`) — **hub** (settings-rework, 2026-08-17; currency folded
into Advanced 2026-08-25) of five `ListTile`s that push dedicated sub-screens via `MaterialPageRoute`:

- **Profile** (`_ProfileScreen`) — `TextFormField` for age (numeric, validated 0–120; blank clears; saved via check icon or keyboard done); `SegmentedButton<Gender>` (Male / Female); an activity-source `SwitchListTile` (`settingsComputeActivity`) that switches between the static `SegmentedButton<ActivityLevel>` (sedentary…very active) and computed-from-workouts+steps mode; a body-fat `SwitchListTile` (`settingsTrackBodyFat`) that reveals a body-fat `TextFormField` (%) when on; **Body weight goal** `SegmentedButton<BodyWeightGoal>` (Lose / Maintain / Gain, `emptySelectionAllowed` + empty guard). These feed the dashboard calorie target (see [dashboard/dashboard.md](../dashboard/dashboard.md)).
- **Notifications** (`_NotificationsScreen`) — `SwitchListTile` (`settingsPlannerNotifications` + `settingsPlannerNotificationsSubtitle`): app-wide task-reminder toggle (off → `TaskReminderScheduler.cancelAll()`; on → `reschedulePending(repository)`); experiment-reminders master `SwitchListTile` (off → cancel every scheduled experiment reminder; on → reschedule the active ones via `ExperimentReminderScheduler`, which itself skips non-active / per-experiment-disabled rows); rest alarm `SwitchListTile`s for sound + vibration (see [notifications/notifications.md](../notifications/notifications.md)).
- **Appearance & Language** (`_AppearanceLanguageScreen`) — `SegmentedButton<ThemeMode>` (System / Light / Dark) + a **four-segment language selector with a System default** (`settingsLangSystem`, icon `Icons.language`): System / English / Français / Español. System is the default empty state and calls `setLocaleToSystem()`; the others persist via `settings_locale`.
- **Advanced** (`_AdvancedScreen`, 2026-08-24; currency section moved in 2026-08-25) — six numeric fields promoting formerly-hardcoded tuning constants, each with a helper-text explanation: planner look-ahead days (`plannerHorizonDays`), calorie-goal adjustment kcal (`calorieGoalAdjustment`), experiment baseline days (`experimentBaselineDays`), default rest between sets in minutes with blank = no default (`defaultRestSeconds`), pre-reminder lead minutes (`reminderLeadMinutes`), and sync request timeout seconds (`apiTimeoutSeconds`). Each commits on submit (keyboard done or check icon); invalid input is rejected by validators and clamped by the setters. Below a divider sits the former Budget & Currency section: base-currency dropdown, the sync-server card (`_SyncServerCard`: base URL + API key + pull/push actions), and the cached FX-rate list with per-day snapshot rows and an inline `_RateEditDialog` for hand-edited rates (see [architecture.md](../architecture.md) and [sync-contract.md](../sync/sync-contract.md)).
- **Data** (`_DataScreen`) — "Export database" `ListTile` (copies `<docs>/fitfat.sqlite` to a dated temp file and shares it via `share_plus`; restore/import out of scope) and the destructive reset-all `ListTile` with its confirm dialog (no catalog re-seed — the bundled exercise catalog was removed 2026-08-24).

## Units display layer

Storage stays metric (kg/cm); conversion happens at render time only:

- `lib/src/ui/units.dart` — `weightFromKg` / `lengthFromCm` conversions, `weightUnitLabel` / `lengthUnitLabel` suffixes ('kg'/'lb', 'cm'/'in'), `formatWeightValue` / `formatLengthValue` formatters.
- Unit-bearing l10n keys take a `{unit}` placeholder instead of hardcoding kg/cm: `workoutDetailPlannedSetReps`, `workoutDetailActualSetReps`, `workoutDetailActualSetWeight`, `exerciseDetailWeightDelta`, `exerciseDetailTrendDelta` (already unit-parameterised), `workoutSummaryValueKg`, `dashboardVolumeKg`, `bodyMetricsLatestWeight/Height`, `bodyMetricsValueKg`.
- Applied surfaces: dashboard body card (latest weight/height + weight-evolution chart values), dashboard weekly-volume card, exercise detail History tab (summary tiles, trend/volume charts, per-workout cards, set grid), workout detail set chips, workout summary metric rows, active-workout set rows + inline history.
- Not converted (by design): data entry fields stay in the stored metric unit; body-metric input dialogs; chart axes show bare numbers.

## Wiring

- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()` → `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` (Android edge-to-edge, T10) → `await SharedPreferences.getInstance()` → `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), taskReminderSchedulerProvider.overrideWithValue(taskScheduler)], child: FitFatApp()))`.
- `FitFatApp` (`lib/src/app/app.dart`): `ConsumerWidget` watching `settingsProvider`; passes `theme: FitFatTheme.light`, `darkTheme: FitFatTheme.dark`, `themeMode: settings.themeMode`, `locale: settings.locale` to `MaterialApp.router`, with a `builder` that mounts `_BackgroundStartup` (post-first-frame startup: parallelized foreground-service + notification init, lazy timezone init when planner reminders are on, task-reminder reschedule; catalog import and FX auto-refresh were removed 2026-08-24). Supported locales are en/fr/es.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [context-map.md](../context-map.md)
