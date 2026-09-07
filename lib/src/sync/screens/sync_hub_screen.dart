import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../ui/tokens.dart';
import '../../settings/providers/settings.dart';
import '../sync_service.dart';
import '../sync_state_store.dart';
import '../sync_models.dart';
import '../../ui/widgets/top_banner.dart';

final class SyncHubScreen extends ConsumerWidget {
  const SyncHubScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAppBar), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard'))),
      body: ListView(padding: const EdgeInsets.all(FitFatTokens.spaceL), children: [
        _SectionCard(icon: Icons.cloud_download_outlined, title: 'Global pool', subtitle: 'Pull shared exercises, ingredients and currencies', child: _GlobalPoolSection()),
        const SizedBox(height: FitFatTokens.spaceL),
        _SectionCard(icon: Icons.cloud_upload_outlined, title: 'Personal pool', subtitle: 'Push/pull your tasks, notes, goals, workouts, templates, experiments, meals, body, budget', child: _PersonalPoolSection()),
        const SizedBox(height: FitFatTokens.spaceL),
        _SectionCard(icon: Icons.backup_outlined, title: 'Local backup', subtitle: 'Export to file or restore from file', child: _LocalBackupSection()),
      ]),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(FitFatTokens.spaceL), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: FitFatTokens.spaceS), Text(title, style: theme.textTheme.titleMedium)]),
      const SizedBox(height: 4),
      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: FitFatTokens.spaceM),
      child,
    ])));
  }
}

final class _GlobalPoolSection extends ConsumerStatefulWidget {
  const _GlobalPoolSection();
  @override
  ConsumerState<_GlobalPoolSection> createState() => _GlobalPoolSectionState();
}
final class _GlobalPoolSectionState extends ConsumerState<_GlobalPoolSection> {
  bool _busyEx = false; bool _busyIng = false; bool _busyFx = false;
  Future<void> _run(Future<SyncResult> Function() fn, void Function(bool) setBusy) async {
    setBusy(true);
    try {
      final result = await fn();
      if (!mounted) return;
      if (!result.ok && result.error != null) showTopBanner(context, message: result.error!);
    } finally { if (mounted) setBusy(false); }
  }
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final base = settings.remoteSyncBaseUrl;
    final key = settings.remoteSyncApiKey;
    final state = SyncStateStore(ref.watch(sharedPreferencesProvider));
    String last(SyncResource r) {
      final ms = state.getLastSyncedAt(r);
      if (ms == 0) return 'never';
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Exercises'), subtitle: Text('Last sync: ${last(SyncResource.exercises)}'), trailing: _busyEx ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncExercises(base, key, endpoint: settings.endpointExercises), (v) => setState(() => _busyEx = v)))),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Ingredients'), subtitle: Text('Last sync: ${last(SyncResource.ingredients)}'), trailing: _busyIng ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncIngredients(base, key, endpoint: settings.endpointIngredients), (v) => setState(() => _busyIng = v)))),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Currencies'), subtitle: Text('Last sync: ${last(SyncResource.currencies)}'), trailing: _busyFx ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.sync), onPressed: () => _run(() => ref.read(syncServiceProvider).syncCurrencies(base, key, settings.baseCurrency, endpoint: settings.endpointCurrencies), (v) => setState(() => _busyFx = v)))),
      const SizedBox(height: FitFatTokens.spaceS),
      OutlinedButton.icon(onPressed: () => showTopBanner(context, message: 'Select exercises to sync — per-item picker coming in T04'), icon: const Icon(Icons.checklist, size: 18), label: const Text('Select exercises…')),
      const SizedBox(height: FitFatTokens.spaceS),
      OutlinedButton.icon(onPressed: () => showTopBanner(context, message: 'Select ingredients to sync — per-item picker coming in T04'), icon: const Icon(Icons.checklist, size: 18), label: const Text('Select ingredients…')),
    ]);
  }
}

final class _PersonalPoolSection extends ConsumerWidget {
  const _PersonalPoolSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: FitFatTokens.spaceS, children: [for (final e in ['Tasks','Notes','Goals','Workouts','Templates','Experiments','Meals','Body','Budget','Receipts']) FilterChip(label: Text(e), selected: true, onSelected: (_) {})]),
      const SizedBox(height: FitFatTokens.spaceM),
      Wrap(spacing: FitFatTokens.spaceS, children: [
        FilledButton.icon(onPressed: () => showTopBanner(context, message: 'Push all — coming in T03'), icon: const Icon(Icons.cloud_upload, size: 18), label: const Text('Push all')),
        OutlinedButton.icon(onPressed: () => showTopBanner(context, message: 'Push selected — coming in T03'), icon: const Icon(Icons.upload, size: 18), label: const Text('Push selected')),
        OutlinedButton.icon(onPressed: () => showTopBanner(context, message: 'Pull — coming in T03'), icon: const Icon(Icons.cloud_download, size: 18), label: const Text('Pull')),
      ]),
    ]);
  }
}

final class _LocalBackupSection extends ConsumerWidget {
  const _LocalBackupSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Whole DB')), ButtonSegment(value: false, label: Text('Selected'))], selected: const {true}, onSelectionChanged: (_) {}),
      const SizedBox(height: FitFatTokens.spaceM),
      Wrap(spacing: FitFatTokens.spaceS, children: [
        FilledButton.icon(onPressed: () => showTopBanner(context, message: 'Export — coming in T02'), icon: const Icon(Icons.ios_share, size: 18), label: const Text('Export')),
        OutlinedButton.icon(onPressed: () => showTopBanner(context, message: 'Import — coming in T02'), icon: const Icon(Icons.file_open, size: 18), label: const Text('Import')),
      ]),
    ]);
  }
}
