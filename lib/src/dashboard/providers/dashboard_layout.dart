import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings.dart';

/// The cards the dashboard can show. The enum order is the default order:
/// nutrition and tasks first, since those are checked most often.
enum DashboardCard { nutrition, tasks, training, weight, goals, money }

/// Which cards the dashboard shows, and in what order. Edited in
/// Settings › Dashboard; saved instantly.
@immutable
final class DashboardLayout {
  const DashboardLayout({required this.order, required this.hidden});

  static const defaults = DashboardLayout(
    order: DashboardCard.values,
    hidden: {},
  );

  final List<DashboardCard> order;
  final Set<DashboardCard> hidden;

  /// Cards to render, in order.
  List<DashboardCard> get visible => [
    for (final c in order)
      if (!hidden.contains(c)) c,
  ];
}

final dashboardLayoutProvider =
    NotifierProvider<DashboardLayoutNotifier, DashboardLayout>(
      DashboardLayoutNotifier.new,
    );

final class DashboardLayoutNotifier extends Notifier<DashboardLayout> {
  static const orderKey = 'settings_dashboard_order';
  static const hiddenKey = 'settings_dashboard_hidden';

  @override
  DashboardLayout build() {
    final prefs = ref.watch(sharedPreferencesHolderProvider);
    if (prefs == null) return DashboardLayout.defaults;
    return DashboardLayout(
      order: parseOrder(prefs.getStringList(orderKey)),
      hidden: {
        for (final name in prefs.getStringList(hiddenKey) ?? const <String>[])
          ?_byName(name),
      },
    );
  }

  /// Saved order, dropping unknown names and appending cards added in later
  /// releases so a new card is never lost.
  static List<DashboardCard> parseOrder(List<String>? names) {
    final saved = [for (final n in names ?? const <String>[]) ?_byName(n)];
    final seen = <DashboardCard>{};
    return [
      for (final c in saved)
        if (seen.add(c)) c,
      for (final c in DashboardCard.values)
        if (!seen.contains(c)) c,
    ];
  }

  static DashboardCard? _byName(String name) {
    for (final c in DashboardCard.values) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// Moves the card at [oldIndex] to [newIndex] (already adjusted for the
  /// removal, as `onReorderItem` reports it).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final order = [...state.order];
    final card = order.removeAt(oldIndex);
    order.insert(newIndex, card);
    state = DashboardLayout(order: order, hidden: state.hidden);
    await ref.read(sharedPreferencesHolderProvider)?.setStringList(orderKey, [
      for (final c in order) c.name,
    ]);
  }

  Future<void> setVisible(DashboardCard card, bool visible) async {
    final hidden = {...state.hidden};
    visible ? hidden.remove(card) : hidden.add(card);
    state = DashboardLayout(order: state.order, hidden: hidden);
    await ref.read(sharedPreferencesHolderProvider)?.setStringList(hiddenKey, [
      for (final c in hidden) c.name,
    ]);
  }

  Future<void> reset() async {
    state = DashboardLayout.defaults;
    final prefs = ref.read(sharedPreferencesHolderProvider);
    await prefs?.remove(orderKey);
    await prefs?.remove(hiddenKey);
  }
}
