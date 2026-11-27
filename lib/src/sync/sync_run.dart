import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/providers/settings.dart';
import 'entity_labels.dart';
import 'screens/sync_hub_screen.dart';
import 'sync_all.dart';
import 'sync_refresh.dart';
import 'widgets/server_sheet.dart';

/// Where the last (or current) "Sync now" run is.
enum SyncRunPhase { idle, running, ok, failed }

/// Shared state of the one-tap full sync, so the dashboard chip, its sheet
/// and the Sync screen all show the same progress and the same failure.
@immutable
final class SyncRunState {
  const SyncRunState({
    this.phase = SyncRunPhase.idle,
    this.step,
    this.pushing = true,
    this.done = 0,
    this.total = 0,
    this.error,
    this.unreachable = false,
  });

  final SyncRunPhase phase;

  /// Entity being sent or fetched right now (a `syncOrder` label).
  final String? step;

  /// True while sending, false while fetching.
  final bool pushing;
  final int done;
  final int total;

  /// Friendly reason for the last failure, already localized.
  final String? error;

  /// The last failure was "server not reachable" (offer Retry / Scan QR).
  final bool unreachable;

  bool get running => phase == SyncRunPhase.running;
  double get progress => total == 0 ? 0 : done / total;
}

final syncRunProvider = NotifierProvider<SyncRunNotifier, SyncRunState>(
  SyncRunNotifier.new,
);

final class SyncRunNotifier extends Notifier<SyncRunState> {
  @override
  SyncRunState build() => const SyncRunState();

  void set(SyncRunState s) => state = s;

  /// Clears a failure (e.g. after a successful QR rescan).
  void clearError() {
    if (state.phase == SyncRunPhase.failed) state = const SyncRunState();
  }
}

/// Number of steps a full sync runs: every pushable entity, then every
/// pullable one.
int get fullSyncStepCount =>
    syncOrder.where((e) => !syncPullOnly.contains(e)).length +
    syncPullOrder.where((e) => !syncPushOnly.contains(e)).length;

/// Runs the one-tap two-way sync and publishes its progress in
/// [syncRunProvider]. Opens the server sheet instead when no server is set
/// up. Safe to call twice: a second call while running is ignored.
Future<void> runFullSync(BuildContext context, WidgetRef ref) async {
  final run = ref.read(syncRunProvider.notifier);
  if (ref.read(syncRunProvider).running) return;
  if (ref.read(settingsProvider).remoteSyncBaseUrl.isEmpty) {
    await showServerSheet(context);
    return;
  }
  final l10n = AppLocalizations.of(context)!;
  final total = fullSyncStepCount;
  var done = 0;
  var pushing = true;
  String? previous;
  run.set(SyncRunState(phase: SyncRunPhase.running, total: total));
  try {
    final outcome = await syncEverything(
      ref,
      onStep: (entity) {
        // The pull pass starts again from the first entity in syncOrder.
        if (pushing && previous != null) {
          final prevIndex = syncOrder.indexOf(previous!);
          if (syncOrder.indexOf(entity) < prevIndex) pushing = false;
        }
        if (previous != null) done++;
        previous = entity;
        run.set(
          SyncRunState(
            phase: SyncRunPhase.running,
            step: entity,
            pushing: pushing,
            done: done,
            total: total,
          ),
        );
      },
    );
    await shipPhoneLogs(ref);
    invalidateAllData(ref);
    final base = ref.read(settingsProvider).remoteSyncBaseUrl;
    if (outcome.pushFailedEntity != null) {
      final err = outcome.pushError!;
      run.set(
        SyncRunState(
          phase: SyncRunPhase.failed,
          unreachable: isUnreachableSyncError(err),
          error: l10n.syncCouldNotPush(
            syncEntityLabel(l10n, outcome.pushFailedEntity!),
            friendlySyncError(l10n, base, err),
          ),
        ),
      );
    } else if (outcome.pullFailures.isNotEmpty) {
      run.set(
        SyncRunState(
          phase: SyncRunPhase.failed,
          error: l10n.syncPulledWithErrors(
            outcome.pullFailures
                .map((e) => syncEntityLabel(l10n, e))
                .join(', '),
          ),
        ),
      );
    } else {
      run.set(const SyncRunState(phase: SyncRunPhase.ok));
    }
  } catch (e) {
    run.set(
      SyncRunState(
        phase: SyncRunPhase.failed,
        error: l10n.syncUnknownError,
        unreachable: isUnreachableSyncError('$e'),
      ),
    );
  }
}

/// Scans the server's QR again after an "unreachable" failure.
Future<void> rescanAfterFailure(BuildContext context, WidgetRef ref) async {
  final ok = await rescanServerQr(context, ref);
  if (ok) ref.read(syncRunProvider.notifier).clearError();
}
