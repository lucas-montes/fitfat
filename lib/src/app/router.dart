import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../budget/screens/account_detail_screen.dart';
import '../budget/screens/account_form.dart';
import '../budget/screens/receipt_list_screen.dart';
import '../budget/screens/receipt_viewer_screen.dart';
import '../budget/screens/transaction_form.dart';
import '../budget/screens/transaction_list_screen.dart';
import '../budget/tabs/budget_tab.dart';
import '../exercise/providers/workouts.dart';
import '../exercise/screens/active_workout_screen.dart';
import '../exercise/screens/workout_summary_screen.dart';
import '../models/workout.dart';
import '../notifications/rest_timer.dart';
import '../settings/screens/settings_screen.dart';
import '../ui/tokens.dart';
import '../ui/theme_extensions.dart';
import '../ui/widgets/status_badge.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/diet_tab.dart';
import 'tabs/exercise_tab.dart';
import 'tabs/experiments_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/plan_tab.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, navigationShell) =>
          _ShellWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/exercise', builder: (_, _) => const ExerciseTab()),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/diet', builder: (_, _) => const DietTab())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/plan', builder: (_, _) => const PlanTab())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/notes', builder: (_, _) => const NotesTab()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/budget', builder: (_, _) => const BudgetTab()),
            GoRoute(
              path: '/budget/account/:id',
              builder: (_, state) {
                final id = state.pathParameters['id']!;
                // 'new' is the create route; otherwise it's an account id.
                if (id == 'new') {
                  return const AccountFormScreen();
                }
                return AccountDetailScreen(accountId: id);
              },
            ),
            GoRoute(
              path: '/budget/account/:id/edit',
              builder: (_, state) =>
                  AccountFormScreen(accountId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/budget/transaction/:id',
              builder: (_, state) {
                final id = state.pathParameters['id']!;
                if (id == 'new') {
                  final type = state.uri.queryParameters['type'];
                  final account = state.uri.queryParameters['account'];
                  return TransactionFormScreen(
                    initialType: type,
                    initialAccountId: account,
                  );
                }
                return TransactionFormScreen(transactionId: id);
              },
            ),
            GoRoute(
              path: '/budget/transactions',
              builder: (_, _) => const TransactionListScreen(),
            ),
            GoRoute(
              path: '/budget/receipts',
              builder: (_, _) => const ReceiptListScreen(),
            ),
            GoRoute(
              path: '/budget/receipt/:id',
              builder: (_, state) =>
                  ReceiptViewerScreen(receiptId: state.pathParameters['id']!),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/experiments',
              builder: (_, _) => const ExperimentsTab(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/active-workout',
      builder: (_, _) => const ActiveWorkoutScreen(),
    ),
    GoRoute(
      path: '/workout-summary/:id',
      builder: (_, state) =>
          WorkoutSummaryScreen(workoutId: state.pathParameters['id']!),
    ),
  ],
);

/// Shell scaffold rendered around every tab. While a workout is active it
/// shows the global active-workout bar (T08) directly above the
/// [NavigationBar]; the bar lives in the `bottomNavigationBar` area so
/// per-screen FABs float clear of it.
final class _ShellWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkout = ref.watch(activeWorkoutProvider);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: FitFatTokens.motionNormal,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: activeWorkout == null
                ? const SizedBox.shrink()
                : _ActiveWorkoutBar(
                    key: ValueKey(activeWorkout.id),
                    workout: activeWorkout,
                  ),
          ),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: l10n.tabDashboard,
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: l10n.tabExercise,
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: l10n.tabDiet,
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: l10n.tabPlan,
              ),
              NavigationDestination(
                icon: Icon(Icons.note_alt_outlined),
                selectedIcon: Icon(Icons.note_alt),
                label: l10n.tabNotes,
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: l10n.tabBudget,
              ),
              NavigationDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: l10n.tabExperiments,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slim global strip shown while a workout is active (T08): workout name,
/// live elapsed time (1 s ticker) and a resume affordance. Tapping the bar
/// or the play button reopens the workout detail over the shell via the root
/// navigator. Only mounted while a workout is active (the [AnimatedSwitcher]
/// removes it), so the ticker's lifecycle follows the active state.
final class _ActiveWorkoutBar extends StatefulWidget {
  final Workout workout;

  const _ActiveWorkoutBar({super.key, required this.workout});

  @override
  State<_ActiveWorkoutBar> createState() => _ActiveWorkoutBarState();
}

final class _ActiveWorkoutBarState extends State<_ActiveWorkoutBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openDetail(BuildContext context) {
    GoRouter.of(context).go('/active-workout');
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColors = theme.extension<FitFatColors>()!;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FitFatTokens.spaceL,
            vertical: FitFatTokens.spaceS,
          ),
          child: Row(
            children: [
              Icon(Icons.fitness_center, size: 18, color: statusColors.warning),
              const SizedBox(width: FitFatTokens.spaceS),
              Expanded(
                child: Text(
                  workout.name,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: FitFatTokens.spaceS),
              StatusBadge(
                label: l10n.statusActive,
                color: statusColors.warning,
              ),
              const SizedBox(width: FitFatTokens.spaceM),
              Text(
                formatRestDuration(workout.duration),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: FitFatTokens.spaceS),
              IconButton(
                tooltip: l10n.activeWorkoutResume,
                onPressed: () => _openDetail(context),
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
