# Navigation — GoRouter

## How routing works

fitfat uses `go_router` for navigation. Routes are declared in `lib/src/router/app_router.dart`.

```dart
final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Global route (outside shell, covers full screen)
    GoRoute(path: '/current-seance', ...),
    // Shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/diet', ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/exercise', ...)]),
      ],
    ),
  ],
);
```

### Key concepts

| Concept | What it means |
|---|---|
| **Route** | A destination. Has a path like `/diet` and a builder |
| **Navigator** | A stack of screens. Push adds, pop removes |
| **Shell** | Persistent wrapper (like bottom nav). Each branch has its own Navigator |
| **Root Navigtor** | The top-level GoRouter navigator. Screens pushed here cover the bottom nav |
| **Branch** | A tab in the bottom navigation. Has its own history |

---

## Navigaton methods

```dart
// Inside the app (with context):
context.go('/dashboard');        // Replace current location (no back)
context.push('/current-seance'); // Push on top (back works)
context.pop();                    // Go back

// From anywhere (using key):
GoRouter.of(rootNavigatorKey.currentContext!).go('/dashboard');

// Inside a dialog or bottom sheet:
Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(...));
```

### Why `rootNavigator: true`?

Inside a shell branch (tab), `Navigator.of(context)` finds the **tab's own Navigator**. To push a screen that covers the whole app (like the seance screen), you need:

```dart
Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute(builder: (_) => const MyScreen()),
);
```

Or simply use `context.push('/my-route')` if the route is registered at the top level.

---

## The AppShell

```dart
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        navigationShell,
        const SeanceFloatingPill(), // floating timer when seance is active
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Diet'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Exercise'),
        ],
        onDestinationSelected: (index) => navigationShell.goBranch(index),
      ),
    );
  }
}
```

---

## Current seance route

The `/current-seance` route is outside the shell so it covers the bottom navigation. When the seance is completed or cancelled, the user is redirected to `/exercise` via `context.go('/exercise')`.

**Important:** Never use `Navigator.pop()` for the seance route — there may be no history. Always use `context.go()` to a known destination.

---

## Links

| What | Link |
|---|---|
| GoRouter docs | https://pub.dev/documentation/go_router/latest/ |
| StatefulShellRoute | https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html |
| Navigator class | https://api.flutter.dev/flutter/widgets/Navigator-class.html |
