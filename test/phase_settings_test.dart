import 'package:fitfat/src/models/body_weight_goal.dart';
import 'package:fitfat/src/models/diet_phase.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase configuration is twelve prefs plus the existing goal key standing in for
/// the active phase. What matters here is that each phase keeps its own numbers
/// and that an existing user's magnitude survives the upgrade.
void main() {
  late ProviderContainer container;
  late SettingsNotifier notifier;
  late SharedPreferences prefs;

  Future<void> loadWith(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer();
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);
    notifier = container.read(settingsProvider.notifier);
  }

  tearDown(() => container.dispose());

  group('phase config defaults', () {
    test('an empty store loads every seed', () async {
      await loadWith({});
      final state = container.read(settingsProvider);

      expect(
        state.phaseConfigs[DietPhase.cutting]!.adjustment,
        kDefaultCuttingAdjustment,
      );
      expect(
        state.phaseConfigs[DietPhase.bulking]!.adjustment,
        kDefaultBulkingAdjustment,
      );
      expect(
        state.phaseConfigs[DietPhase.maintenance]!.adjustment,
        kDefaultMaintenanceAdjustment,
      );
    });

    test('an unset goal means the maintenance phase', () async {
      await loadWith({});
      expect(container.read(settingsProvider).activePhase,
          DietPhase.maintenance);
    });

    test('a stored goal selects its phase', () async {
      await loadWith({'settings_body_weight_goal': 'gain'});
      final state = container.read(settingsProvider);
      expect(state.activePhase, DietPhase.bulking);
      expect(state.activePhaseConfig.adjustment, kDefaultBulkingAdjustment);
    });
  });

  group('legacy adjustment', () {
    test('a stored magnitude seeds cutting and bulking symmetrically', () async {
      // The old knob was unsigned and applied +/- depending on the goal, so a
      // 750 setting has to become -750 cutting and +750 bulking.
      await loadWith({'settings_calorie_goal_adjustment': 750.0});
      final configs = container.read(settingsProvider).phaseConfigs;

      expect(configs[DietPhase.cutting]!.adjustment, -750);
      expect(configs[DietPhase.bulking]!.adjustment, 750);
      expect(configs[DietPhase.maintenance]!.adjustment, 0);
    });

    test('an explicit phase value wins over the legacy magnitude', () async {
      await loadWith({
        'settings_calorie_goal_adjustment': 750.0,
        'settings_phase_cutting_adjustment': -300.0,
      });
      final configs = container.read(settingsProvider).phaseConfigs;

      expect(configs[DietPhase.cutting]!.adjustment, -300);
      // Bulking had no explicit value, so it still inherits.
      expect(configs[DietPhase.bulking]!.adjustment, 750);
    });
  });

  group('writing a knob', () {
    test('persists and survives a reload', () async {
      await loadWith({});
      await notifier.setPhaseProteinPerKg(DietPhase.cutting, 2.4);

      // Rebuild the provider stack over the same stored prefs.
      container.dispose();
      container = ProviderContainer();
      container.read(sharedPreferencesHolderProvider.notifier).set(prefs);

      final configs = container.read(settingsProvider).phaseConfigs;
      expect(configs[DietPhase.cutting]!.proteinPerKg, 2.4);
      // Other knobs in the same phase keep their seeds.
      expect(configs[DietPhase.cutting]!.fatPercent, kDefaultFatPercent);
      // Other phases are untouched.
      expect(configs[DietPhase.bulking]!.proteinPerKg, kDefaultProteinPerKg);
    });

    test('a negative adjustment is kept, not clamped at zero', () async {
      await loadWith({});
      await notifier.setPhaseAdjustment(DietPhase.cutting, -650);

      expect(
        container.read(settingsProvider).phaseConfigs[DietPhase.cutting]!
            .adjustment,
        -650,
      );
    });

    test('fat percent is clamped to 0-100 and others to non-negative', () async {
      await loadWith({});
      await notifier.setPhaseFatPercent(DietPhase.bulking, 150);
      await notifier.setPhaseProteinPerKg(DietPhase.bulking, -3);
      await notifier.setPhaseFiberTarget(DietPhase.bulking, -8);

      final config = container.read(settingsProvider).phaseConfigs[
          DietPhase.bulking]!;
      expect(config.fatPercent, 100);
      expect(config.proteinPerKg, 0);
      expect(config.fiberTarget, 0);
    });

    test('editing one phase leaves the others alone', () async {
      await loadWith({});
      await notifier.setPhaseAdjustment(DietPhase.cutting, -800);

      final configs = container.read(settingsProvider).phaseConfigs;
      expect(configs[DietPhase.cutting]!.adjustment, -800);
      expect(configs[DietPhase.bulking]!.adjustment,
          kDefaultBulkingAdjustment);
    });
  });

  group('selecting a phase', () {
    test('sets the goal that stands in for the active phase', () async {
      await loadWith({});
      await notifier.setActivePhase(DietPhase.cutting);

      final state = container.read(settingsProvider);
      expect(state.activePhase, DietPhase.cutting);
      expect(state.bodyWeightGoal, BodyWeightGoal.lose);
    });

    test('switching phases switches which config is active', () async {
      await loadWith({});
      await notifier.setPhaseAdjustment(DietPhase.cutting, -800);
      await notifier.setPhaseAdjustment(DietPhase.bulking, 400);

      await notifier.setActivePhase(DietPhase.cutting);
      expect(container.read(settingsProvider).activePhaseConfig.adjustment,
          -800);

      await notifier.setActivePhase(DietPhase.bulking);
      expect(container.read(settingsProvider).activePhaseConfig.adjustment, 400);
    });
  });
}