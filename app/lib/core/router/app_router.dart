import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/placeholder_screen.dart';

/// Rutas de navegación (§5.1 del plan maestro). `/login` y `/register` quedan
/// fuera del shell; el resto vive bajo el shell con bottom nav.
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const PlaceholderScreen(title: 'Login'),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const PlaceholderScreen(title: 'Registro'),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Dashboard'),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/transactions',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Transacciones'),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Nueva transacción'),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PlaceholderScreen(
                  title: 'Transacción ${state.pathParameters['id']}',
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/budgets',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Presupuestos'),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/reports',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Reportes'),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Ajustes'),
            routes: [
              GoRoute(
                path: 'accounts',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Cuentas'),
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Categorías'),
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transacciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Presupuestos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
