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
| baseCurrency | String | 'USD' | persisted as `settings_base_currency`; budget base currency (uppercase ISO-4217-ish) |

`SettingsNotifier` (`extends Notifier<SettingsState>`):

- `build()` reads the keys from prefs synchronously.
- `setThemeMode(ThemeMode)` / `setLocale(Locale)` / `setLocaleToSystem()` / `setAge(int?)` / `setBodyWeightGoal(BodyWeightGoal?)` / `setGender(Gender?)` / `setActivityLevel(ActivityLevel?)` / `setComputeActivity(bool)` / `setTrackBodyFat(bool)` / `setBodyFatPercent(double?)` / `setPlannerNotifications(bool)` / `setRestAlarmSound(bool)` / `setRestAlarmVibration(bool)` / `setBaseCurrency(String)` — persist first, then update state (apply immediately). Nullable setters remove the key when null (blank clears age/body-fat; there is no UI to clear the goal — once set it is always one of the three, default null = no badge). `setLocaleToSystem()` removes `settings_locale` so `state.locale` becomes null (device default); `SettingsState.copyWith` supports `clearLocale` for this.

## Settings screen

`SettingsScreen` (`ConsumerStatefulWidget`) — **hub** (settings-rework, 2026-08-17) of five `ListTile`s
that push dedicated sub-screens via `MaterialPageRoute`:

- **Profile** (`_ProfileScreen`) — `TextFormField` for age (numeric, validated 0–120; blank clears; saved via check icon or keyboard done); `SegmentedButton<Gender>` (Male / Female); an activity-source `SwitchListTile` (`settingsComputeActivity`) that switches between the static `SegmentedButton<ActivityLevel>` (sedentary…very active) and computed-from-workouts+steps mode; a body-fat `SwitchListTile` (`settingsTrackBodyFat`) that reveals a body-fat `TextFormField` (%) when on; **Body weight goal** `SegmentedButton<BodyWeightGoal>` (Lose / Maintain / Gain, `emptySelectionAllowed` + empty guard). These feed the dashboard calorie target (see [dashboard/dashboard.md](../dashboard/dashboard.md)).
- **Notifications** (`_NotificationsScreen`) — `SwitchListTile` (`settingsPlannerNotifications` + `settingsPlannerNotificationsSubtitle`): app-wide task-reminder toggle (off → `TaskReminderScheduler.cancelAll()`; on → `reschedulePending(repository)`); rest alarm `SwitchListTile`s for sound + vibration (see [notifications/notifications.md](../notifications/notifications.md)).
- **Appearance & Language** (`_AppearanceLanguageScreen`) — `SegmentedButton<ThemeMode>` (System / Light / Dark) + a **four-segment language selector with a System default** (`settingsLangSystem`, icon `Icons.language`): System / English / Français / Español. System is the default empty state and calls `setLocaleToSystem()`; the others persist via `settings_locale`.
- **Budget & Currency** (`_BudgetCurrencyScreen`) — base-currency dropdown + cached FX-rate list with refresh/edit (see [budget/../architecture.md](../architecture.md)). Each rate row shows `cur → base`, the inverse, the last-updated date, a "Manual" pill for edit-set rates, plus an edit icon (fx-display T02). Transactions in a non-base currency and the recent-transactions rows show the conversion rate applied via `rateUsed` (fx-display T03).
- **Data** (`_DataScreen`) — destructive reset-all `ListTile` with its confirm dialog.

## Wiring

- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()` → `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` (Android edge-to-edge, T10) → `await SharedPreferences.getInstance()` → `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), taskReminderSchedulerProvider.overrideWithValue(taskScheduler)], child: FitFatApp()))`.
- `FitFatApp` (`lib/src/app/app.dart`): `ConsumerWidget` watching `settingsProvider`; passes `theme: FitFatTheme.light`, `darkTheme: FitFatTheme.dark`, `themeMode: settings.themeMode`, `locale: settings.locale` to `MaterialApp.router`, with a `builder` that mounts the one-shot `_StartupReminderSync` (startup task-reminder reschedule). Supported locales are en/fr/es.

See also: [overview.md](../overview.md), [architecture.md](../architecture.md), [context-map.md](../context-map.md)
