import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../dashboard/providers/dashboard_layout.dart';
import '../../ui/tokens.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/settings_section.dart';

/// Settings › Dashboard: drag to reorder the dashboard cards, switch them on
/// or off. Saved instantly.
final class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key, this.embed = false});

  final bool embed;

  static IconData iconFor(DashboardCard c) => switch (c) {
    DashboardCard.nutrition => Icons.restaurant_outlined,
    DashboardCard.tasks => Icons.checklist,
    DashboardCard.training => Icons.fitness_center,
    DashboardCard.weight => Icons.monitor_weight_outlined,
    DashboardCard.goals => Icons.flag_outlined,
    DashboardCard.money => Icons.account_balance_wallet_outlined,
  };

  static String labelFor(AppLocalizations l10n, DashboardCard c) => switch (c) {
    DashboardCard.nutrition => l10n.dashboardNutrition,
    DashboardCard.tasks => l10n.dashboardTasks,
    DashboardCard.training => l10n.dashboardTraining,
    DashboardCard.weight => l10n.dashboardWeight,
    DashboardCard.goals => l10n.dashboardGoalsTitle,
    DashboardCard.money => l10n.dashboardMoney,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final layout = ref.watch(dashboardLayoutProvider);
    final notifier = ref.read(dashboardLayoutProvider.notifier);

    final body = ListView(
      padding: const EdgeInsets.all(FitFatTokens.spaceL),
      children: [
        Text(
          l10n.settingsDashboardHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Card(
          margin: EdgeInsets.zero,
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: notifier.reorder,
            children: [
              for (final (i, card) in layout.order.indexed)
                ReorderableDragStartListener(
                  key: ValueKey(card),
                  index: i,
                  child: SettingsRow(
                    icon: iconFor(card),
                    title: labelFor(l10n, card),
                    control: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: !layout.hidden.contains(card),
                          onChanged: (v) => notifier.setVisible(card, v),
                        ),
                        const SizedBox(width: FitFatTokens.spaceS),
                        Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: FitFatTokens.spaceM),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: notifier.reset,
            child: Text(l10n.settingsResetOrder),
          ),
        ),
      ],
    );
    if (embed) return SettingsBody(child: body);
    return SettingsSubScreenScaffold(title: l10n.settingsDashboard, body: body);
  }
}
