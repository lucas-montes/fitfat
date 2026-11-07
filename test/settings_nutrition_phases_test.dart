import 'package:drift/native.dart';
import 'package:fitfat/l10n/app_localizations.dart';
import 'package:fitfat/src/app/startup_gate.dart';
import 'package:fitfat/src/database/app_database.dart' as db;
import 'package:fitfat/src/database/database_provider.dart';
import 'package:fitfat/src/models/body_weight_goal.dart';
import 'package:fitfat/src/models/diet_phase.dart';
import 'package:fitfat/src/settings/providers/settings.dart';
import 'package:fitfat/src/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for the phase-card refactor: tapping a card must only
/// expand/collapse it, never change which goal is active, and the old
/// duplicate selector in the Profile section must be gone.
void main() {
  late db.AppDatabase database;
  late ProviderContainer container;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    container.dispose();
    database.close();
  });

  Future<void> pumpHub(WidgetTester tester) async {
    // Tall enough that several expanded phase cards fit without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    container.read(startupGateProvider.notifier).complete();
    container.read(sharedPreferencesHolderProvider.notifier).set(prefs);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpNutrition(WidgetTester tester) async {
    await pumpHub(tester);
    await tester.tap(find.text(l10n.settingsNutrition));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'tapping a phase card only expands it, without changing the active goal',
    (tester) async {
      await pumpNutrition(tester);
      expect(
        container.read(settingsProvider).activePhase,
        DietPhase.maintenance,
      );

      await tester.tap(find.text(l10n.settingsGoalLose));
      await tester.pumpAndSettle();

      // Still maintenance: opening the card to look at it did not select it.
      expect(
        container.read(settingsProvider).activePhase,
        DietPhase.maintenance,
      );
      // The newly-expanded (inactive) card offers an explicit way to select it.
      expect(find.text(l10n.settingsSetActiveGoal), findsOneWidget);
    },
  );

  testWidgets('more than one phase card can be expanded at once', (
    tester,
  ) async {
    await pumpNutrition(tester);

    await tester.tap(find.text(l10n.settingsGoalLose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsGoalGain));
    await tester.pumpAndSettle();

    // Both cards' knob forms are visible simultaneously, not just the latest.
    expect(find.text(l10n.settingsCalorieAdjustmentLabel), findsNWidgets(2));
  });

  testWidgets('the explicit control in the form selects the active goal', (
    tester,
  ) async {
    await pumpNutrition(tester);

    await tester.tap(find.text(l10n.settingsGoalGain));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsSetActiveGoal));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).activePhase, DietPhase.bulking);
    // The now-active card shows the status label instead of the button.
    expect(find.text(l10n.settingsActiveGoalLabel), findsOneWidget);
  });

  testWidgets('the Profile section no longer has its own goal selector', (
    tester,
  ) async {
    await pumpHub(tester);
    await tester.tap(find.text(l10n.settingsProfile));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsBodyWeightGoal), findsNothing);
    expect(find.byType(SegmentedButton<BodyWeightGoal>), findsNothing);
  });
}
