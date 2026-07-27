import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../shared/widgets/splash_screen.dart';

/// Navigation routes (§5.1 of the master plan). `/login`, `/register` and
/// `/splash` stay outside the shell; everything else lives under the shell
/// with bottom nav.
///
/// [redirect] treats an in-progress bootstrap (`authControllerProvider` in
/// `AsyncLoading`) as its own case, parked on `/splash`, distinct from a
/// settled `unauthenticated`/`authenticated` value. Collapsing those into
/// two states instead of three is exactly the classic bug: a request that's
/// merely loading (e.g. mid-login) would otherwise read as "unknown" and
/// bounce the user back to splash before the result even lands.
GoRouter buildRouter(Ref ref) {
  final refreshNotifier = _AuthRefreshListenable(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isSplash = location == '/splash';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final isAuthenticated = authState.valueOrNull?.maybeWhen(
            authenticated: (_) => true,
            orElse: () => false,
          ) ??
          false;

      if (isAuthenticated) {
        return (isAuthRoute || isSplash) ? '/dashboard' : null;
      }
      return isAuthRoute ? null : '/login';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'accounts',
                builder: (context, state) => const AccountsScreen(),
              ),
              GoRoute(
                path: 'categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
        ]),
      ],
    ),
    ],
  );
}

/// Bridges Riverpod state changes into the `Listenable` `go_router` expects
/// for [GoRouter.refreshListenable] — `ref.listen` outside a widget works
/// fine inside a provider's own scope.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _subscription = ref.listen(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

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
