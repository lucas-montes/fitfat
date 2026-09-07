import 'dart:io';

import 'package:flutter/material.dart';
import '../../ui/widgets/top_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../database/database_provider.dart';
import '../../network/api_client.dart';
import '../../sync/data_push_service.dart';
import '../../budget/providers/fx_rates.dart';
import '../../experiments/notifications/experiment_reminder.dart';
import '../../experiments/providers/experiments_repository.dart';
import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../models/units.dart';
import '../../notifications/task_reminders.dart';
import '../../planner/providers/planner.dart';
import '../../tags/screens/tag_manager_screen.dart';
import '../../sync/sync_button.dart';
import '../../sync/sync_service.dart';
import '../../ui/date_formats.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../providers/settings.dart';
import '../services/data_reset.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_scaffold.dart';

/// Settings hub: a list of category tiles that push dedicated sub-screens
/// (Profile / Notifications / Appearance & Language / Budget & Currency / Data).
final class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

final class _HubDestination {
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final String label;
  final String subtitle;
  final Widget Function({required bool embed}) build;

  const _HubDestination({
    required this.icon,
    this.iconColor,
    this.titleColor,
    required this.label,
    required this.subtitle,
    required this.build,
  });
}

final class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedIndex = 0;

  List<_HubDestination> _destinations(AppLocalizations l10n, ColorScheme scheme) =>
      [
        _HubDestination(
          icon: Icons.person_outline,
          label: l10n.settingsProfile,
          subtitle: l10n.settingsProfileSubtitle,
          build: ({required embed}) => _ProfileScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.event_note_outlined,
          label: l10n.settingsPlanner,
          subtitle: l10n.settingsPlannerSubtitle,
          build: ({required embed}) => _PlannerScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.restaurant_menu_outlined,
          label: l10n.settingsNutrition,
          subtitle: l10n.settingsNutritionSubtitle,
          build: ({required embed}) => _NutritionScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.settingsCurrencyBudget,
          subtitle: l10n.settingsBudgetCurrencySubtitle,
          build: ({required embed}) => _BudgetCurrencyScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.notifications_outlined,
          label: l10n.settingsNotifications,
          subtitle: l10n.settingsNotificationsSubtitle,
          build: ({required embed}) => _NotificationsScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.palette_outlined,
          label: l10n.settingsAppearanceLanguage,
          subtitle: l10n.settingsAppearanceLanguageSubtitle,
          build: ({required embed}) => _AppearanceLanguageScreen(embed: embed),
        ),
        _HubDestination(
          icon: Icons.sell_outlined,
          label: l10n.prioritiesTitle,
          subtitle: l10n.prioritiesManage,
          build: ({required embed}) => const TagManagerScreen(),
        ),
        _HubDestination(
          icon: Icons.delete_forever_outlined,
          iconColor: scheme.error,
          titleColor: scheme.error,
          label: l10n.settingsData,
          subtitle: l10n.settingsResetDataSubtitle,
          build: ({required embed}) => _DataScreen(embed: embed),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final destinations = _destinations(l10n, scheme);
    final isWide =
        MediaQuery.of(context).size.width >= FitFatTokens.kRailBreakpoint;

    void push(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    if (!isWide) {
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
          padding: const EdgeInsets.all(FitFatTokens.spaceL),
          children: [
            for (var i = 0; i < destinations.length; i++)
              _HubTile(
                icon: destinations[i].icon,
                iconColor: destinations[i].iconColor,
                titleColor: destinations[i].titleColor,
                title: destinations[i].label,
                subtitle: destinations[i].subtitle,
                onTap: () => push(destinations[i].build(embed: false)),
              ),
          ],
        ),
      );
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon, color: d.iconColor),
                  selectedIcon: d.iconColor == null
                      ? Icon(d.icon)
                      : Icon(d.icon, color: d.iconColor),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: destinations[_selectedIndex].build(embed: true)),
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
  final bool embed;

  const _ProfileScreen({this.embed = false});

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

    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsProfile,
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
                  Text(
                    l10n.settingsGender,
                    style: theme.textTheme.bodyMedium,
                  ),
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
                      if (selection.isEmpty) {
                        return; // deselect is not supported
                      }
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
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        SettingsSection(
          title: l10n.settingsBodyWeightGoal,
          children: [
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
                if (selection.isEmpty) {
                  return; // deselect is not supported
                }
                notifier.setBodyWeightGoal(selection.first);
              },
            ),
          ],
        ),
      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(title: l10n.settingsProfile, body: body);
  }
}

/// Notifications: planner task reminders + rest alarm sound/vibration.
final class _NotificationsScreen extends ConsumerStatefulWidget {
  final bool embed;

  const _NotificationsScreen({this.embed = false});

  @override
  ConsumerState<_NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

final class _NotificationsScreenState extends ConsumerState<_NotificationsScreen> {
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
            repository: ref.read(taskRepositoryProvider),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
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
      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(
      title: l10n.settingsNotifications,
      body: body,
    );
  }
}

/// Appearance & Language: theme mode + app language (System default).
final class _AppearanceLanguageScreen extends ConsumerStatefulWidget {
  final bool embed;

  const _AppearanceLanguageScreen({this.embed = false});

  @override
  ConsumerState<_AppearanceLanguageScreen> createState() =>
      _AppearanceLanguageScreenState();
}

final class _AppearanceLanguageScreenState
    extends ConsumerState<_AppearanceLanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsAppearance,
          children: [
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
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        SettingsSection(
          title: l10n.settingsLanguage,
          children: [
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
      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(
      title: l10n.settingsAppearanceLanguage,
      body: body,
    );
  }
}

/// Shared numeric settings field + validators, reused by the Planner and
/// Nutrition screens.
Widget _settingsField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  String? help,
  required String? Function(String?) validator,
  required VoidCallback onSave,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          helperMaxLines: 3,
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            tooltip: AppLocalizations.of(context)!.commonSave,
            onPressed: () {
              if (validator(controller.text) != null) return;
              onSave();
            },
          ),
        ),
        validator: validator,
        onFieldSubmitted: (_) {
          if (validator(controller.text) != null) return;
          onSave();
        },
      ),
    );

String? _validatePositiveInt(BuildContext context, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null; // blank keeps the stored value
  final parsed = int.tryParse(text);
  if (parsed == null || parsed <= 0) {
    return AppLocalizations.of(context)!.settingsValueInvalid;
  }
  return null;
}

String? _validateNonNegative(BuildContext context, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final parsed = double.tryParse(text);
  if (parsed == null || parsed < 0) {
    return AppLocalizations.of(context)!.settingsValueInvalid;
  }
  return null;
}

void _saveIfValid(TextEditingController ctrl, VoidCallback commit) {
  if (ctrl.text.trim().isEmpty) return;
  commit();
}

/// Planner: workout rest, planning horizon, reminder lead, experiment baseline.
final class _PlannerScreen extends ConsumerStatefulWidget {
  final bool embed;

  const _PlannerScreen({this.embed = false});

  @override
  ConsumerState<_PlannerScreen> createState() => _PlannerScreenState();
}

final class _PlannerScreenState extends ConsumerState<_PlannerScreen> {
  late final TextEditingController _horizonCtrl;
  late final TextEditingController _restCtrl;
  late final TextEditingController _leadCtrl;
  late final TextEditingController _baselineCtrl;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _horizonCtrl = TextEditingController(
      text: settings.plannerHorizonDays.toString(),
    );
    _restCtrl = settings.defaultRestSeconds > 0
        ? TextEditingController(
            text: (settings.defaultRestSeconds / 60).toStringAsFixed(1),
          )
        : TextEditingController();
    _leadCtrl = TextEditingController(
      text: settings.reminderLeadMinutes.toString(),
    );
    _baselineCtrl = TextEditingController(
      text: settings.experimentBaselineDays.toString(),
    );
  }

  @override
  void dispose() {
    _horizonCtrl.dispose();
    _restCtrl.dispose();
    _leadCtrl.dispose();
    _baselineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(settingsProvider.notifier);
    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsPlanner,
          children: [
            _settingsField(
              context: context,
              controller: _horizonCtrl,
              label: l10n.settingsPlannerHorizonLabel,
              help: l10n.settingsPlannerHorizonHelp,
              validator: (v) => _validatePositiveInt(context, v),
              onSave: () => _saveIfValid(_horizonCtrl, () {
                notifier.setPlannerHorizonDays(int.parse(_horizonCtrl.text));
              }),
            ),
            _settingsField(
              context: context,
              controller: _restCtrl,
              label: l10n.settingsDefaultRestLabel,
              help: l10n.settingsDefaultRestHelp,
              validator: (v) => _validateNonNegative(context, v),
              onSave: () {
                final text = _restCtrl.text.trim();
                final seconds = text.isEmpty
                    ? 0
                    : (double.parse(text) * 60).round();
                notifier.setDefaultRestSeconds(seconds);
              },
            ),
            _settingsField(
              context: context,
              controller: _leadCtrl,
              label: l10n.settingsReminderLeadLabel,
              help: l10n.settingsReminderLeadHelp,
              validator: (v) => _validateNonNegative(context, v),
              onSave: () => _saveIfValid(_leadCtrl, () {
                notifier.setReminderLeadMinutes(int.parse(_leadCtrl.text));
              }),
            ),
            _settingsField(
              context: context,
              controller: _baselineCtrl,
              label: l10n.settingsExperimentBaselineLabel,
              help: l10n.settingsExperimentBaselineHelp,
              validator: (v) => _validatePositiveInt(context, v),
              onSave: () => _saveIfValid(_baselineCtrl, () {
                notifier.setExperimentBaselineDays(
                  int.parse(_baselineCtrl.text),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        SettingsSection(
          title: l10n.settingsCascadeDeleteLabel,
          children: [
            Text(
              l10n.settingsCascadeDeleteHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<CascadeDeleteBehavior>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: CascadeDeleteBehavior.ask,
                  label: Text(l10n.settingsCascadeAsk),
                ),
                ButtonSegment(
                  value: CascadeDeleteBehavior.alwaysCascade,
                  label: Text(l10n.settingsCascadeAlways),
                ),
                ButtonSegment(
                  value: CascadeDeleteBehavior.neverCascade,
                  label: Text(l10n.settingsCascadeNever),
                ),
              ],
              selected: {ref.watch(settingsProvider).cascadeDeleteBehavior},
              onSelectionChanged: (s) =>
                  notifier.setCascadeDeleteBehavior(s.first),
            ),
          ],
        ),
      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(title: l10n.settingsPlanner, body: body);
  }
}

/// Nutrition: display units + calorie goal adjustment.
final class _NutritionScreen extends ConsumerStatefulWidget {
  final bool embed;

  const _NutritionScreen({this.embed = false});

  @override
  ConsumerState<_NutritionScreen> createState() => _NutritionScreenState();
}

final class _NutritionScreenState extends ConsumerState<_NutritionScreen> {
  late final TextEditingController _adjustmentCtrl;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _adjustmentCtrl = TextEditingController(
      text: settings.calorieGoalAdjustment.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _adjustmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsCalorieAdjustmentLabel,
          children: [
            _settingsField(
              context: context,
              controller: _adjustmentCtrl,
              label: l10n.settingsCalorieAdjustmentLabel,
              help: l10n.settingsCalorieAdjustmentHelp,
              validator: (v) => _validateNonNegative(context, v),
              onSave: () => _saveIfValid(_adjustmentCtrl, () {
                notifier.setCalorieGoalAdjustment(
                  double.parse(_adjustmentCtrl.text),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        SettingsSection(
          title: l10n.settingsUnits,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsWeightUnitLabel,
                  style: theme.textTheme.bodyMedium,
                ),
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
                Text(
                  l10n.settingsLengthUnitLabel,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                SegmentedButton<LengthUnit>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: LengthUnit.cm,
                      label: const Text('cm'),
                    ),
                    ButtonSegment(
                      value: LengthUnit.inch,
                      label: const Text('in'),
                    ),
                  ],
                  selected: {settings.lengthUnit},
                  onSelectionChanged: (selection) =>
                      notifier.setLengthUnit(selection.first),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(title: l10n.settingsNutrition, body: body);
  }
}

/// Budget & Currency: base currency + cached FX rates.
final class _BudgetCurrencyScreen extends ConsumerWidget {
  final bool embed;

  const _BudgetCurrencyScreen({this.embed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsCurrencyBudget,
          subtitle: l10n.settingsBudgetCurrencySubtitle,
          children: [ const _CurrencySection() ],
        ),
      ],
    );
    if (embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(
      title: l10n.settingsCurrencyBudget,
      body: body,
    );
  }
}


/// Data: destructive reset-all with its confirm dialog.
final class _DataScreen extends ConsumerStatefulWidget {
  final bool embed;

  const _DataScreen({this.embed = false});

  @override
  ConsumerState<_DataScreen> createState() => _DataScreenState();
}

final class _DataScreenState extends ConsumerState<_DataScreen> {
  late final TextEditingController _timeoutCtrl;

  @override
  void initState() {
    super.initState();
    _timeoutCtrl = TextEditingController(
      text: ref.read(settingsProvider).apiTimeoutSeconds.toString(),
    );
  }

  @override
  void dispose() {
    _timeoutCtrl.dispose();
    super.dispose();
  }

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
    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        SettingsSection(
          title: l10n.settingsData,
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

      ],
    );
    if (widget.embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(title: l10n.settingsData, body: body);
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
        const SizedBox(height: 16),
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

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    String base,
    String code,
    double current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // The dialog owns the controller (see [_RateEditDialog]) so it is disposed
    // only after the route — including its exit animation — is torn down.
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _RateEditDialog(
        title: l10n.settingsRateEdit,
        label: l10n.settingsRateRow(code, 0, base),
        initial: current,
      ),
    );
    if (value == null || !context.mounted) return;
    await ref.read(fxRepositoryProvider).setRate(code, value, base);
    ref.invalidate(fxRatesProvider);
  }
}

/// Numeric prompt for editing one cached FX rate. Owns its text controller so
/// disposal happens after the route exit animation (never mid-rebuild).
final class _RateEditDialog extends StatefulWidget {
  final String title;
  final String label;
  final double initial;

  const _RateEditDialog({
    required this.title,
    required this.label,
    required this.initial,
  });

  @override
  State<_RateEditDialog> createState() => _RateEditDialogState();
}

final class _RateEditDialogState extends State<_RateEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextFormField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: widget.label),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(_controller.text.trim());
            if (value != null) Navigator.of(context).pop(value);
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

/// Configures the user's sync server (URL + API key) and lets them pull the
/// latest currency rates. The same URL/key is reused by the exercise and
/// ingredient list screens.
final class _SyncServerCard extends ConsumerStatefulWidget {
  const _SyncServerCard();

  @override
  ConsumerState<_SyncServerCard> createState() => _SyncServerCardState();
}

final class _SyncServerCardState extends ConsumerState<_SyncServerCard> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final Map<String, TextEditingController> _epControllers = {};
  bool _busy = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _urlController.text = settings.remoteSyncBaseUrl;
    _keyController.text = settings.remoteSyncApiKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    for (final c in _epControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _epController(String key, String value) {
    return _epControllers.putIfAbsent(
      key,
      () => TextEditingController(text: value),
    );
  }

  Widget _syncAction({required String description, required Widget button}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(description, style: theme.textTheme.bodySmall),
        const SizedBox(height: FitFatTokens.spaceS),
        SizedBox(width: double.infinity, child: button),
      ],
    );
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showTopBanner(context, message: e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<_EndpointDef> _endpointDefs(SettingsState s) {
    final defaults = const SettingsState();
    return [
      _EndpointDef('Exercises', s.endpointExercises, defaults.endpointExercises,
          ref.read(settingsProvider.notifier).setEndpointExercises),
      _EndpointDef('Ingredients', s.endpointIngredients,
          defaults.endpointIngredients,
          ref.read(settingsProvider.notifier).setEndpointIngredients),
      _EndpointDef('Currencies', s.endpointCurrencies, defaults.endpointCurrencies,
          ref.read(settingsProvider.notifier).setEndpointCurrencies),
      _EndpointDef('Workouts', s.endpointWorkouts, defaults.endpointWorkouts,
          ref.read(settingsProvider.notifier).setEndpointWorkouts),
      _EndpointDef('Templates', s.endpointTemplates, defaults.endpointTemplates,
          ref.read(settingsProvider.notifier).setEndpointTemplates),
      _EndpointDef('Notes', s.endpointNotes, defaults.endpointNotes,
          ref.read(settingsProvider.notifier).setEndpointNotes),
      _EndpointDef('Tasks', s.endpointTasks, defaults.endpointTasks,
          ref.read(settingsProvider.notifier).setEndpointTasks),
      _EndpointDef('Goals', s.endpointGoals, defaults.endpointGoals,
          ref.read(settingsProvider.notifier).setEndpointGoals),
      _EndpointDef('Meals', s.endpointMeals, defaults.endpointMeals,
          ref.read(settingsProvider.notifier).setEndpointMeals),
      _EndpointDef('Transactions', s.endpointTransactions,
          defaults.endpointTransactions,
          ref.read(settingsProvider.notifier).setEndpointTransactions),
      _EndpointDef('Budget accounts', s.endpointBudgetAccounts,
          defaults.endpointBudgetAccounts,
          ref.read(settingsProvider.notifier).setEndpointBudgetAccounts),
      _EndpointDef('Receipt pictures', s.endpointReceiptPictures,
          defaults.endpointReceiptPictures,
          ref.read(settingsProvider.notifier).setEndpointReceiptPictures),
      _EndpointDef('Export', s.endpointExport, defaults.endpointExport,
          ref.read(settingsProvider.notifier).setEndpointExport),
      _EndpointDef('Import', s.endpointImport, defaults.endpointImport,
          ref.read(settingsProvider.notifier).setEndpointImport),
    ];
  }

  Future<void> _pushAll() => _runBusy(() async {
        final s = ref.read(settingsProvider);
        if (s.remoteSyncBaseUrl.isEmpty) {
          showTopBanner(context, message: l10n.syncServerNotConfigured);
          return;
        }
        final types = <String>[
          'workouts',
          'templates',
          'notes',
          'noteAudio',
          'tasks',
          'goals',
          'meals',
          'transactions',
          'budgetAccounts',
          'receiptPictures',
        ];
        final failures = <String>[];
        for (final t in types) {
          final res = await pushDataType(ref, t);
          if (!res.ok) failures.add('$t: ${res.error}');
        }
        if (!mounted) return;
        if (failures.isEmpty) {
          showTopBanner(context, message: l10n.pushAllSuccess);
        } else {
          showTopBanner(context, message: failures.join('\n'));
        }
      });

  Future<void> _export() => _runBusy(() async {
        final s = ref.read(settingsProvider);
        if (s.remoteSyncBaseUrl.isEmpty) {
          showTopBanner(context, message: l10n.syncServerNotConfigured);
          return;
        }
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'fitfat.sqlite'));
        if (!await file.exists()) {
          if (!mounted) return;
          showTopBanner(context, message: l10n.exportFailed);
          return;
        }
        final bytes = await file.readAsBytes();
        final client = HttpApiClient(http.Client(), baseUrl: s.remoteSyncBaseUrl);
        await client.postBytes(
          s.endpointExport,
          body: bytes,
          headers: authHeaders(s.remoteSyncApiKey),
        );
        if (!mounted) return;
        showTopBanner(context, message: l10n.exportSuccess);
      });

  Future<void> _import() => _runBusy(() async {
        final s = ref.read(settingsProvider);
        if (s.remoteSyncBaseUrl.isEmpty) {
          showTopBanner(context, message: l10n.syncServerNotConfigured);
          return;
        }
        final client = HttpApiClient(http.Client(), baseUrl: s.remoteSyncBaseUrl);
        final bytes = await client.getBytes(
          s.endpointImport,
          headers: authHeaders(s.remoteSyncApiKey),
        );
        if (bytes.isEmpty) {
          if (!mounted) return;
          showTopBanner(context, message: l10n.importNothing);
          return;
        }
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.importConfirmTitle),
                content: Text(l10n.importConfirmBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.commonContinue),
                  ),
                ],
              ),
            ) ??
            false;
        if (!confirmed || !mounted) return;
        final dir = await getApplicationDocumentsDirectory();
        final path = p.join(dir.path, 'fitfat.sqlite');
        await ref.read(databaseProvider).close();
        await File(path).writeAsBytes(bytes, flush: true);
        ref.invalidate(databaseProvider);
        if (!mounted) return;
        showTopBanner(context, message: l10n.importSuccess);
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final sync = ref.read(syncServiceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FitFatTokens.spaceS,
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(labelText: l10n.settingsSyncBaseUrl),
          onChanged: ref.read(settingsProvider.notifier).setRemoteSyncBaseUrl,
        ),
        TextField(
          controller: _keyController,
          decoration: InputDecoration(labelText: l10n.settingsSyncApiKey),
          obscureText: true,
          onChanged: ref.read(settingsProvider.notifier).setRemoteSyncApiKey,
        ),
        ExpansionTile(
              title: Text(l10n.settingsSyncEndpoints),
              subtitle: Text(
                l10n.settingsSyncEndpointsHint,
                style: theme.textTheme.bodySmall,
              ),
              children: [
                ..._endpointDefs(settings).map((def) {
                  final c = _epController(def.label, def.value);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: c,
                            decoration: InputDecoration(
                              labelText: def.label,
                              hintText: def.defaultValue,
                            ),
                            onChanged: def.onChanged,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.restore),
                          tooltip: l10n.endpointReset,
                          onPressed: () {
                            c.text = def.defaultValue;
                            def.onChanged(def.defaultValue);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: FitFatTokens.spaceM),
            _syncAction(
              description: l10n.syncExercisesHelp,
              button: SizedBox(
                width: double.infinity,
                child: SyncButton(
                  tooltip: l10n.syncExercisesTooltip,
                  label: Text(l10n.syncExercisesTooltip),
                  run: () => sync.syncExercises(
                    settings.remoteSyncBaseUrl,
                    settings.remoteSyncApiKey,
                    endpoint: settings.endpointExercises,
                  ),
                ),
              ),
            ),
            _syncAction(
              description: l10n.syncIngredientsHelp,
              button: SizedBox(
                width: double.infinity,
                child: SyncButton(
                  tooltip: l10n.syncIngredientsTooltip,
                  label: Text(l10n.syncIngredientsTooltip),
                  run: () => sync.syncIngredients(
                    settings.remoteSyncBaseUrl,
                    settings.remoteSyncApiKey,
                    endpoint: settings.endpointIngredients,
                  ),
                ),
              ),
            ),
            _syncAction(
              description: l10n.syncCurrenciesHelp,
              button: SizedBox(
                width: double.infinity,
                child: SyncButton(
                  tooltip: l10n.syncCurrenciesTooltip,
                  label: Text(l10n.syncCurrenciesTooltip),
                  run: () => sync.syncCurrencies(
                    settings.remoteSyncBaseUrl,
                    settings.remoteSyncApiKey,
                    settings.baseCurrency,
                    endpoint: settings.endpointCurrencies,
                  ),
                ),
              ),
            ),
            _syncAction(
              description: l10n.pushAllDataHelp,
              button: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _pushAll,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(l10n.pushAllData),
                ),
              ),
            ),
            _syncAction(
              description: l10n.exportServerHelp,
              button: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(Icons.backup),
                  label: Text(l10n.exportServer),
                ),
              ),
            ),
            _syncAction(
              description: l10n.importServerHelp,
              button: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.restore),
                  label: Text(l10n.importServer),
                ),
              ),
            ),
          ],
        );
  }
}

final class _EndpointDef {
  const _EndpointDef(
    this.label,
    this.value,
    this.defaultValue,
    this.onChanged,
  );

  final String label;
  final String value;
  final String defaultValue;
  final void Function(String) onChanged;
}
