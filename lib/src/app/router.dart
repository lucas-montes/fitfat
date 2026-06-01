import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../diet/screens/main.dart';
import '../exercise/screens/current_seance_screen.dart';
import '../exercise/screens/main.dart';
import '../dashboard/screens/main.dart';
import '../widgets/appbar_seance_indicator.dart' show SeanceFloatingPill;
import 'package:fitfat/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Destinations constructed at build time to support localized labels
  // See T12: replaced hardcoded labels with AppLocalizations
  // (was static const — now built with context)
  // _destinations is intentionally a getter in build()

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.restaurant_menu),
        label: l10n.navDiet,
      ),
      NavigationDestination(
        icon: const Icon(Icons.dashboard),
        label: l10n.navDashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.fitness_center),
        label: l10n.navExercise,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(right: 16, bottom: 16, child: const SeanceFloatingPill()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Global route for active seance — accessible from anywhere
    GoRoute(
      path: '/current-seance',
      name: 'current-seance',
      builder: (context, state) => const CurrentSeanceScreen(),
    ),
    // Group of routes that share the same shell (bottom navigation bar)
    // They are kept in memory when switching between them, so their state is preserved
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/diet',
              name: 'diet',
              builder: (context, state) => const DietScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exercise',
              name: 'exercise',
              builder: (context, state) => const ExerciseScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
