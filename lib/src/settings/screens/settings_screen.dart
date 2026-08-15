import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../budget/providers/fx_rates.dart';
import '../../budget/providers/services.dart';
import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../notifications/task_reminders.dart';
import '../../planner/providers/planner.dart';
import '../providers/settings.dart';
import '../services/data_reset.dart';

/// Settings screen: Profile (age, gender, activity, body fat), Appearance
/// (theme mode), Language.
final class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  /// App-wide task-reminder toggle: turning off cancels every scheduled
  /// planner reminder; turning back on re-schedules pending future timed tasks.
  Future<void> _setPlannerNotifications(bool enabled) async {
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

  /// Destructive "reset all data": double-gated by a confirm dialog, then
  /// wipes everything and re-seeds the catalog. Returns once the reset is done
  /// so the caller can show a confirmation.
  Future<bool> _confirmReset() async {
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
    return confirmed ?? false;
  }

  Future<void> _resetData() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmReset()) return;
    await resetAllData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.settingsResetDataDone)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
          // -----------------------------------------------------------------
          // Profile
          // -----------------------------------------------------------------
          Text(l10n.settingsProfile, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
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

          // -----------------------------------------------------------------
          // Notifications
          // -----------------------------------------------------------------
          Text(l10n.settingsNotifications, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsPlannerNotifications),
            subtitle: Text(l10n.settingsPlannerNotificationsSubtitle),
            value: settings.plannerNotifications,
            onChanged: _setPlannerNotifications,
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
          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Appearance
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
          SegmentedButton<Locale>(
            // No locale stored yet (device default) -> nothing selected.
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: const Locale('en'),
                label: Text(l10n.settingsLangEn),
              ),
              ButtonSegment(
                value: const Locale('fr'),
                label: Text(l10n.settingsLangFr),
              ),
              ButtonSegment(
                value: const Locale('es'),
                label: Text(l10n.settingsLangEs),
              ),
            ],
            selected: settings.locale == null
                ? const <Locale>{}
                : {settings.locale!},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return; // deselect is not supported
              notifier.setLocale(selection.first);
            },
          ),

          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Currency & Budget
          // -----------------------------------------------------------------
          Text(
            l10n.settingsCurrencyBudget,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _CurrencySection(),
          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // Data
          // -----------------------------------------------------------------
          Text(l10n.settingsData, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
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
            onTap: _resetData,
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
    final ratesAsync = ref.watch(fxRatesProvider);

    final currencyOptions = {base, ..._currencies}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(base),
          initialValue: base,
          decoration: InputDecoration(
            labelText: l10n.settingsBaseCurrency,
          ),
          items: currencyOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) ref.read(settingsProvider.notifier).setBaseCurrency(v);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.settingsFxRates,
              style: theme.textTheme.bodyMedium,
            ),
            TextButton.icon(
              onPressed: () => _refreshRates(context, ref, base),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.settingsFxRefresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ratesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(l10n.errorWithMessage('$e')),
          data: (rates) {
            if (rates.isEmpty) {
              return Text(l10n.settingsFxRatesEmpty);
            }
            return Column(
              children: rates.entries.map((e) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsRateRow(e.key, e.value, base)),
                  trailing: IconButton(
                    tooltip: l10n.settingsRateEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editRate(context, ref, base, e.key, e.value),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsFxRefreshed)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage('$e'))),
        );
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
