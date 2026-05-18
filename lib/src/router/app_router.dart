import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/food/food_screen.dart';
import '../screens/exercise/exercise_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _titles = ['Food', 'Exercise', 'Dashboard', 'Settings'];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu),
      label: 'Food',
    ),
    NavigationDestination(
      icon: Icon(Icons.fitness_center),
      label: 'Exercise',
    ),
    NavigationDestination(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[navigationShell.currentIndex])),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
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

final appRouter = GoRouter(
  initialLocation: '/food',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/food',
              name: 'food',
              builder: (context, state) => const FoodScreen(),
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
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
