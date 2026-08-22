import 'dart:io';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../budget/providers/fx_rates.dart';
import '../../budget/providers/services.dart';
import '../../experiments/notifications/experiment_reminder.dart';
import '../../experiments/providers/experiments.dart';
import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../models/units.dart';
import '../../notifications/task_reminders.dart';
import '../../planner/providers/planner.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../providers/settings.dart';
import '../services/data_reset.dart';

/// Settings hub: a list of category tiles that push dedicated sub-screens
/// (Profile / Notifications / Appearance & Language / Budget & Currency / Data).
final class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    void push(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(l10n.settingsAppBar),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HubTile(
            icon: Icons.person_outline,
            title: l10n.settingsProfile,
            subtitle: l10n.settingsProfileSubtitle,
            onTap: () => push(const _ProfileScreen()),
          ),
          _HubTile(
            icon: Icons.notifications_outlined,
            title: l10n.settingsNotifications,
            subtitle: l10n.settingsNotificationsSubtitle,
            onTap: () => push(const _NotificationsScreen()),
          ),
          _HubTile(
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearanceLanguage,
            subtitle: l10n.settingsAppearanceLanguageSubtitle,
            onTap: () => push(const _AppearanceLanguageScreen()),
          ),
          _HubTile(
            icon: Icons.currency_exchange_outlined,
            title: l10n.settingsCurrencyBudget,
            subtitle: l10n.settingsCurrencyBudgetSubtitle,
            onTap: () => push(const _BudgetCurrencyScreen()),
          ),
          _HubTile(
            icon: Icons.delete_forever_outlined,
            iconColor: theme.colorScheme.error,
            titleColor: theme.colorScheme.error,
            title: l10n.settingsData,
            subtitle: l10n.settingsResetDataSubtitle,
            onTap: () => push(const _DataScreen()),
          ),
        ],
      ),
    );
  }
}

/// Consistent settings hub tile with a trailing chevron.
final class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? colorScheme.primary),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Profile: age, gender, activity source/level, body fat, body weight goal.
final class _ProfileScreen extends ConsumerStatefulWidget {
  const _ProfileScreen();

  @override
  ConsumerState<_ProfileScreen> createState() => _ProfileScreenState();
}

final class _ProfileScreenState extends ConsumerState<_ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _bodyFatController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _ageController = TextEditingController(
      text: settings.age?.toString() ?? '',
    );
    _bodyFatController = TextEditingController(
      text: settings.bodyFatPercent?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _saveAge() {
    if (!_formKey.currentState!.validate()) return;
    final text = _ageController.text.trim();
    ref
        .read(settingsProvider.notifier)
        .setAge(text.isEmpty ? null : int.parse(text));
  }

  String? _validateAge(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final age = int.tryParse(text);
    if (age == null || age < 0 || age > 120) return l10n.settingsAgeInvalid;
    return null;
  }

  void _saveBodyFat() {
    final text = _bodyFatController.text.trim();
    if (text.isEmpty) {
      ref.read(settingsProvider.notifier).setBodyFatPercent(null);
      return;
    }
    final value = double.tryParse(text);
    if (value == null || value < 0 || value > 70) return;
    ref.read(settingsProvider.notifier).setBodyFatPercent(value);
  }

  String? _validateBodyFat(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final value_ = double.tryParse(text);
    if (value_ == null || value_ < 0 || value_ > 70) {
      return l10n.settingsBodyFatInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsProfile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.settingsAgeLabel,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: l10n.commonSave,
                      onPressed: _saveAge,
                    ),
                  ),
                  validator: _validateAge,
                  onFieldSubmitted: (_) => _saveAge(),
                ),
                const SizedBox(height: 16),

                // Gender
                Text(l10n.settingsGender, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<Gender>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: Gender.male,
                      label: Text(l10n.settingsGenderMale),
                    ),
                    ButtonSegment(
                      value: Gender.female,
                      label: Text(l10n.settingsGenderFemale),
                    ),
                  ],
                  selected: settings.gender == null
                      ? const <Gender>{}
                      : {settings.gender!},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return; // deselect is not supported
                    notifier.setGender(selection.first);
                  },
                ),
                const SizedBox(height: 16),

                // Activity source toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsComputeActivity),
                  value: settings.computeActivity,
                  onChanged: notifier.setComputeActivity,
                ),
                if (settings.computeActivity)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l10n.settingsActivityLevel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.settingsActivityLevel,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  _ActivitySegmentedButton(
                    selected: settings.activityLevel,
                    onChanged: notifier.setActivityLevel,
                  ),
                  const SizedBox(height: 16),
                ],

                // Body fat tracking
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsTrackBodyFat),
                  value: settings.trackBodyFat,
                  onChanged: notifier.setTrackBodyFat,
                ),
                if (settings.trackBodyFat)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextFormField(
                      controller: _bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.settingsBodyFatLabel,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: l10n.commonSave,
                          onPressed: _saveBodyFat,
                        ),
                      ),
                      validator: _validateBodyFat,
                      onFieldSubmitted: (_) => _saveBodyFat(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Body weight goal
          Text(l10n.settingsBodyWeightGoal, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<BodyWeightGoal>(
            // No goal stored yet (unset) -> nothing selected.
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: BodyWeightGoal.lose,
                label: Text(l10n.settingsGoalLose),
              ),
              ButtonSegment(
                value: BodyWeightGoal.maintain,
                label: Text(l10n.settingsGoalMaintain),
              ),
              ButtonSegment(
                value: BodyWeightGoal.gain,
                label: Text(l10n.settingsGoalGain),
              ),
            ],
            selected: settings.bodyWeightGoal == null
                ? const <BodyWeightGoal>{}
                : {settings.bodyWeightGoal!},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return; // deselect is not supported
              notifier.setBodyWeightGoal(selection.first);
            },
          ),

          const SizedBox(height: 24),

          // Display units (storage stays metric).
          Text(l10n.settingsUnits, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(l10n.settingsWeightUnitLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<WeightUnit>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: WeightUnit.kg, label: const Text('kg')),
              ButtonSegment(value: WeightUnit.lb, label: const Text('lb')),
            ],
            selected: {settings.weightUnit},
            onSelectionChanged: (selection) =>
                notifier.setWeightUnit(selection.first),
          ),
          const SizedBox(height: 12),
          Text(l10n.settingsLengthUnitLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          SegmentedButton<LengthUnit>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: LengthUnit.cm, label: const Text('cm')),
              ButtonSegment(value: LengthUnit.inch, label: const Text('in')),
            ],
            selected: {settings.lengthUnit},
            onSelectionChanged: (selection) =>
                notifier.setLengthUnit(selection.first),
          ),

          const SizedBox(height: 24),

          // Workout replay prefill.
          DropdownButtonFormField<String>(
            key: const ValueKey('replay-prefill'),
            initialValue: settings.replayPrefill,
            decoration: InputDecoration(
              labelText: l10n.settingsReplayPrefillLabel,
            ),
            items: [
              DropdownMenuItem(
                value: 'actuals',
                child: Text(l10n.settingsReplayPrefillActuals),
              ),
              DropdownMenuItem(
                value: 'planned',
                child: Text(l10n.settingsReplayPrefillPlanned),
              ),
            ],
            onChanged: (v) {
              if (v != null) notifier.setReplayPrefill(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Notifications: planner task reminders + rest alarm sound/vibration.
final class _NotificationsScreen extends ConsumerWidget {
  const _NotificationsScreen();

  /// App-wide task-reminder toggle: turning off cancels every scheduled
  /// planner reminder; turning back on re-schedules pending future timed tasks.
  Future<void> _setPlannerNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (!enabled) {
      await ref.read(taskReminderSchedulerProvider).cancelAll();
    } else {
      final l10n = AppLocalizations.of(context)!;
      await ref
          .read(taskReminderSchedulerProvider)
          .reschedulePending(
            repository: ref.read(plannerRepositoryProvider),
            dueSoonText: l10n.taskReminderDueSoon,
            dueNowText: l10n.taskReminderDueNow,
          );
    }
    await notifier.setPlannerNotifications(enabled);
  }

  /// Master switch for experiment check-in reminders: off cancels every
  /// scheduled experiment reminder; on re-schedules the active ones (the
  /// scheduler itself skips non-active / per-experiment-disabled rows).
  Future<void> _setExperimentReminders(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final scheduler = ref.read(experimentReminderSchedulerProvider);
    final experiments = await ref.read(experimentRepositoryProvider).getAll();
    for (final experiment in experiments) {
      if (!enabled) {
        await scheduler.cancelForExperiment(experiment.id);
      } else {
        await scheduler.scheduleForExperiment(
          experiment,
          title: l10n.experimentReminderTitle(experiment.name),
          body: l10n.experimentReminderBody,
        );
      }
    }
    await ref
        .read(settingsProvider.notifier)
        .setExperimentRemindersEnabled(enabled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsPlannerNotifications),
            subtitle: Text(l10n.settingsPlannerNotificationsSubtitle),
            value: settings.plannerNotifications,
            onChanged: (enabled) =>
                _setPlannerNotifications(context, ref, enabled),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsExperimentReminders),
            subtitle: Text(l10n.settingsExperimentRemindersSubtitle),
            value: settings.experimentRemindersEnabled,
            onChanged: (enabled) =>
                _setExperimentReminders(context, ref, enabled),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsRestAlarmSound),
            value: settings.restAlarmSound,
            onChanged: notifier.setRestAlarmSound,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsRestAlarmVibration),
            value: settings.restAlarmVibration,
            onChanged: notifier.setRestAlarmVibration,
          ),
        ],
      ),
    );
  }
}

/// Appearance & Language: theme mode + app language (System default).
final class _AppearanceLanguageScreen extends ConsumerWidget {
  const _AppearanceLanguageScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppearanceLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -----------------------------------------------------------------
          // Theme
          // -----------------------------------------------------------------
          Text(l10n.settingsAppearance, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                notifier.setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Language
          // -----------------------------------------------------------------
          Text(l10n.settingsLanguage, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            // System is always the default; a stored locale overrides it.
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'system',
                label: Text(l10n.settingsLangSystem),
                icon: const Icon(Icons.language),
              ),
              ButtonSegment(value: 'en', label: Text(l10n.settingsLangEn)),
              ButtonSegment(value: 'fr', label: Text(l10n.settingsLangFr)),
              ButtonSegment(value: 'es', label: Text(l10n.settingsLangEs)),
            ],
            selected: {settings.locale?.languageCode ?? 'system'},
            onSelectionChanged: (selection) {
              final value = selection.first;
              if (value == 'system') {
                notifier.setLocaleToSystem();
              } else {
                notifier.setLocale(Locale(value));
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Budget & Currency: base currency + cached FX rates.
final class _BudgetCurrencyScreen extends StatelessWidget {
  const _BudgetCurrencyScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCurrencyBudget)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [_CurrencySection()],
      ),
    );
  }
}

/// Data: destructive reset-all with its confirm dialog.
final class _DataScreen extends ConsumerStatefulWidget {
  const _DataScreen();

  @override
  ConsumerState<_DataScreen> createState() => _DataScreenState();
}

final class _DataScreenState extends ConsumerState<_DataScreen> {
  /// Shares a dated copy of the local SQLite database via the system share
  /// sheet. Restore/import is out of scope this round.
  Future<void> _exportDatabase() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'fitfat.sqlite'));
      if (!await dbFile.exists()) {
        throw StateError('Database file not found');
      }
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final tempDir = await getTemporaryDirectory();
      final copy = await dbFile.copy(
        p.join(tempDir.path, 'fitfat-$stamp.sqlite'),
      );
      await SharePlus.instance.share(
        ShareParams(files: [XFile(copy.path)], title: l10n.settingsExportDb),
      );
    } catch (e) {
      if (mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }

  /// Destructive "reset all data": double-gated by a confirm dialog, then
  /// wipes everything and re-seeds the catalog.
  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsResetDataConfirmTitle),
        content: Text(l10n.settingsResetDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsResetDataConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await resetAllData(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsData)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share_outlined),
            title: Text(l10n.settingsExportDb),
            subtitle: Text(l10n.settingsExportDbSubtitle),
            onTap: _exportDatabase,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.settingsResetData,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(l10n.settingsResetDataSubtitle),
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }
}

final class _ActivitySegmentedButton extends StatelessWidget {
  final ActivityLevel? selected;
  final ValueChanged<ActivityLevel?> onChanged;

  const _ActivitySegmentedButton({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<ActivityLevel>(
      emptySelectionAllowed: true,
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ActivityLevel.sedentary,
          label: Text(l10n.settingsActivitySedentary),
        ),
        ButtonSegment(
          value: ActivityLevel.light,
          label: Text(l10n.settingsActivityLight),
        ),
        ButtonSegment(
          value: ActivityLevel.moderate,
          label: Text(l10n.settingsActivityModerate),
        ),
        ButtonSegment(
          value: ActivityLevel.active,
          label: Text(l10n.settingsActivityActive),
        ),
        ButtonSegment(
          value: ActivityLevel.veryActive,
          label: Text(l10n.settingsActivityVeryActive),
        ),
      ],
      selected: selected == null ? <ActivityLevel>{} : {selected!},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return; // deselect is not supported
        onChanged(selection.first);
      },
    );
  }
}

const _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'CHF', 'AUD'];

/// Settings section: choose the base currency and view/edit the cached FX
/// rates used to convert transactions to the base currency. Rates can be
/// refreshed from the (mock) remote FX service.
final class _CurrencySection extends ConsumerWidget {
  const _CurrencySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final base = settings.baseCurrency;
    final entriesAsync = ref.watch(fxRateEntriesProvider);

    final currencyOptions = {base, ..._currencies}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(base),
          initialValue: base,
          decoration: InputDecoration(labelText: l10n.settingsBaseCurrency),
          items: currencyOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(settingsProvider.notifier).setBaseCurrency(v);
            }
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsFxAutoRefresh),
          subtitle: Text(l10n.settingsFxAutoRefreshSubtitle),
          value: settings.fxAutoRefresh,
          onChanged: ref.read(settingsProvider.notifier).setFxAutoRefresh,
        ),
        if (settings.fxAutoRefresh)
          DropdownButtonFormField<int>(
            key: const ValueKey('fx-interval'),
            initialValue: settings.fxRefreshIntervalHours,
            decoration: InputDecoration(
              labelText: l10n.settingsFxRefreshInterval,
            ),
            items: const [6, 12, 24, 48, 72]
                .map((h) => DropdownMenuItem(value: h, child: Text('$h h')))
                .toList(),
            onChanged: (h) {
              if (h != null) {
                ref
                    .read(settingsProvider.notifier)
                    .setFxRefreshIntervalHours(h);
              }
            },
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.settingsFxRates, style: theme.textTheme.bodyMedium),
            TextButton.icon(
              onPressed: () => _refreshRates(context, ref, base),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.settingsFxRefresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(l10n.errorWithMessage('$e')),
          data: (entries) {
            if (entries.isEmpty) {
              return Text(l10n.settingsFxRatesEmpty);
            }
            return Column(
              children: entries.map((e) {
                final inverse = e.rateToBase == 0
                    ? null
                    : formatFxRate(1 / e.rateToBase);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsRateRow(e.code, e.rateToBase, base)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (inverse != null)
                        Text(
                          l10n.settingsRateInverse(base, inverse, e.code),
                          style: theme.textTheme.bodySmall,
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.settingsRateUpdated(
                                DateFormats.formatDate(context, e.updatedAt),
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (e.manual) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(
                                  FitFatTokens.radiusFull,
                                ),
                              ),
                              child: Text(
                                l10n.settingsRateManual,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: l10n.settingsRateEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        _editRate(context, ref, base, e.code, e.rateToBase),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _refreshRates(
    BuildContext context,
    WidgetRef ref,
    String base,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final fetched = await ref.read(remoteFxProvider).fetchRates(base);
      await ref.read(fxRepositoryProvider).replaceAll(base, fetched);
      ref.invalidate(fxRatesProvider);
    } catch (e) {
      if (context.mounted) {
        showTopBanner(context, message: l10n.errorWithMessage('$e'));
      }
    }
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    String base,
    String code,
    double current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: current.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsRateEdit),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.settingsRateRow(code, 0, base),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (saved != true || !context.mounted) return;
    final value = double.tryParse(controller.text.trim());
    if (value == null) return;
    await ref.read(fxRepositoryProvider).setRate(code, value, base);
    ref.invalidate(fxRatesProvider);
  }
}
