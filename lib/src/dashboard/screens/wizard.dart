import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../body/providers/body_metrics.dart';
import '../../models/activity_level.dart';
import '../../models/body_weight_goal.dart';
import '../../models/gender.dart';
import '../../models/units.dart';
import '../../settings/providers/settings.dart';
import '../../ui/tokens.dart';

final class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

final class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  final _pageController = PageController();
  int _page = 0;

  final _ageCtrl = TextEditingController();
  Gender? _gender;
  BodyWeightGoal? _goal;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  ActivityLevel? _activity;
  WeightUnit _weightUnit = WeightUnit.kg;
  LengthUnit _lengthUnit = LengthUnit.cm;
  String _currency = 'USD';
  final _horizonCtrl = TextEditingController(text: '90');

  @override
  void dispose() {
    _pageController.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _horizonCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete({bool skipped = false}) async {
    final notifier = ref.read(settingsProvider.notifier);
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age != null) await notifier.setAge(age);
    if (_gender != null) await notifier.setGender(_gender);
    if (_goal != null) await notifier.setBodyWeightGoal(_goal);
    if (_activity != null) await notifier.setActivityLevel(_activity);
    await notifier.setWeightUnit(_weightUnit);
    await notifier.setLengthUnit(_lengthUnit);
    if (_currency.isNotEmpty) await notifier.setBaseCurrency(_currency);
    final horizon = int.tryParse(_horizonCtrl.text.trim());
    if (horizon != null) await notifier.setPlannerHorizonDays(horizon);
    final weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    final height = double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.'));
    if (weight != null || height != null) {
      final repo = ref.read(bodyMetricsRepositoryProvider);
      await repo.upsert(DateTime.now(), weightKg: weight, heightCm: height);
      ref.invalidate(bodyMetricsProvider);
      ref.invalidate(latestBodyMetricsProvider);
    }
    await notifier.setHasSeenWizard(true);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _next() {
    if (_page < 3) {
      setState(() => _page++);
      _pageController.animateToPage(_page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_page > 0) {
      setState(() => _page--);
      _pageController.animateToPage(_page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsAppBar),
        leading: _page > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
        actions: [
          TextButton(
            onPressed: () => _complete(skipped: true),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / 4, minHeight: 4),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _buildProfileStep(l10n, theme),
                _buildBodyStep(l10n, theme),
                _buildUnitsStep(l10n, theme),
                _buildPlannerStep(l10n, theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(FitFatTokens.spaceL),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == 3 ? 'Done' : l10n.commonContinue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep(AppLocalizations l10n, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(l10n.settingsProfile, style: theme.textTheme.headlineSmall),
        const SizedBox(height: FitFatTokens.spaceL),
        TextFormField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.settingsAgeLabel),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsGender, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<Gender>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: Gender.male, label: Text(l10n.settingsGenderMale)),
            ButtonSegment(value: Gender.female, label: Text(l10n.settingsGenderFemale)),
          ],
          selected: _gender == null ? const {} : {_gender!},
          onSelectionChanged: (s) => setState(() => _gender = s.first),
          emptySelectionAllowed: true,
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsBodyWeightGoal, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<BodyWeightGoal>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(value: BodyWeightGoal.lose, label: Text(l10n.settingsGoalLose)),
            ButtonSegment(value: BodyWeightGoal.maintain, label: Text(l10n.settingsGoalMaintain)),
            ButtonSegment(value: BodyWeightGoal.gain, label: Text(l10n.settingsGoalGain)),
          ],
          selected: _goal == null ? const {} : {_goal!},
          onSelectionChanged: (s) => setState(() => _goal = s.first),
        ),
      ],
    );
  }

  Widget _buildBodyStep(AppLocalizations l10n, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(l10n.bodyMetricsTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: FitFatTokens.spaceL),
        TextFormField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.bodyMetricsWeightLabel, suffixText: 'kg'),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        TextFormField(
          controller: _heightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.bodyMetricsHeightLabel, suffixText: 'cm'),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsActivityLevel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ActivityLevel>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(value: ActivityLevel.sedentary, label: Text(l10n.settingsActivitySedentary)),
            ButtonSegment(value: ActivityLevel.light, label: Text(l10n.settingsActivityLight)),
            ButtonSegment(value: ActivityLevel.moderate, label: Text(l10n.settingsActivityModerate)),
            ButtonSegment(value: ActivityLevel.active, label: Text(l10n.settingsActivityActive)),
            ButtonSegment(value: ActivityLevel.veryActive, label: Text(l10n.settingsActivityVeryActive)),
          ],
          selected: _activity == null ? const {} : {_activity!},
          onSelectionChanged: (s) => setState(() => _activity = s.first),
        ),
      ],
    );
  }

  Widget _buildUnitsStep(AppLocalizations l10n, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(l10n.settingsUnits, style: theme.textTheme.headlineSmall),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsWeightUnitLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<WeightUnit>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
            ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
          ],
          selected: {_weightUnit},
          onSelectionChanged: (s) => setState(() => _weightUnit = s.first),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsLengthUnitLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<LengthUnit>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: LengthUnit.cm, label: Text('cm')),
            ButtonSegment(value: LengthUnit.inch, label: Text('in')),
          ],
          selected: {_lengthUnit},
          onSelectionChanged: (s) => setState(() => _lengthUnit = s.first),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        TextFormField(
          initialValue: _currency,
          decoration: InputDecoration(labelText: l10n.settingsBaseCurrency),
          onChanged: (v) => _currency = v.trim().toUpperCase(),
        ),
      ],
    );
  }

  Widget _buildPlannerStep(AppLocalizations l10n, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(l10n.settingsPlanner, style: theme.textTheme.headlineSmall),
        const SizedBox(height: FitFatTokens.spaceL),
        TextFormField(
          controller: _horizonCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.settingsPlannerHorizonLabel,
            helperText: l10n.settingsPlannerHorizonHelp,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceL),
        Text(l10n.settingsData, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(l10n.settingsPlannerHorizonHelp, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
