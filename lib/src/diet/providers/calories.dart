import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../body/providers/body_metrics.dart';
import '../../settings/providers/settings.dart';
import '../services/activity_factor_source.dart';
import '../services/bmr_equation.dart';
import '../services/calorie_calculator.dart';
import '../services/calorie_inputs.dart';

// The derivation itself lives in [CalorieCalculator] and its two strategies.
// This file only wires them to the app's state: which body is measured, which
// inputs the user has entered, and what the active phase asks for.

// ---------------------------------------------------------------------------
// Strategies
// ---------------------------------------------------------------------------

/// The calculator the app runs on.
///
/// Mifflin-St Jeor is the default equation and [PalActivityFactor] the default
/// activity term; both are constructor arguments so a measured-activity source
/// or a different equation can replace one without touching the derivation.
final calorieCalculatorProvider = Provider<CalorieCalculator>((ref) {
  return const CalorieCalculator(
    bmrEquation: MifflinStJeorEquation(),
    activity: PalActivityFactor(),
  );
});

// ---------------------------------------------------------------------------
// Input sources
// ---------------------------------------------------------------------------

/// The latest measured body, from the body-metrics table.
final bodyProfileSourceProvider = Provider<BodyProfileSource>((ref) {
  return _RiverpodBodyProfileSource(ref);
});

/// The self-reported calorie inputs, from settings.
final userProfileSourceProvider = Provider<UserProfileSource>((ref) {
  return _RiverpodUserProfileSource(ref);
});

final class _RiverpodBodyProfileSource implements BodyProfileSource {
  final Ref _ref;
  const _RiverpodBodyProfileSource(this._ref);

  @override
  Future<BodyProfile> latest() async {
    final entry = await _ref.watch(latestBodyMetricsProvider.future);
    return (weightKg: entry?.weightKg, heightCm: entry?.heightCm);
  }
}

final class _RiverpodUserProfileSource implements UserProfileSource {
  final Ref _ref;
  const _RiverpodUserProfileSource(this._ref);

  @override
  CalorieInputs current() {
    final settings = _ref.watch(settingsProvider);
    return (
      age: settings.age,
      gender: settings.gender,
      bodyFatPercent: settings.bodyFatPercent,
      trackBodyFat: settings.trackBodyFat,
      activityLevel: settings.activityLevel,
    );
  }
}

// ---------------------------------------------------------------------------
// Targets
// ---------------------------------------------------------------------------

/// Today's calorie target with BMR, TDEE and the equation that produced them.
final calorieTargetMetaProvider = FutureProvider<CalorieTargetMeta>((
  ref,
) async {
  final settings = ref.watch(settingsProvider);
  return ref.watch(calorieCalculatorProvider).target(
    profile: await ref.watch(bodyProfileSourceProvider).latest(),
    inputs: ref.watch(userProfileSourceProvider).current(),
    phase: settings.activePhase,
    config: settings.activePhaseConfig,
  );
});

/// The calorie target alone, for callers that only need the number.
final calorieTargetProvider = FutureProvider<double>((ref) async {
  final meta = await ref.watch(calorieTargetMetaProvider.future);
  return meta.target;
});

/// The active phase's macro targets.
final macroTargetsProvider = FutureProvider<MacroTargets>((ref) async {
  final settings = ref.watch(settingsProvider);
  final target = await ref.watch(calorieTargetProvider.future);
  return ref
      .watch(calorieCalculatorProvider)
      .macros(
        targetKcal: target,
        config: settings.activePhaseConfig,
        profile: await ref.watch(bodyProfileSourceProvider).latest(),
      );
});