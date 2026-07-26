import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

/// Session controller for the whole app — the template every later feature's
/// `AsyncNotifier` copies.
///
/// `AsyncLoading` (before [build] resolves) stands in for "haven't checked
/// storage yet". The router treats that as its own case and parks on a
/// splash screen, so it never flashes login before landing on the dashboard
/// (or vice versa) on cold start.
///
/// Deliberately never sets `state` back to `AsyncLoading` after that first
/// build — not even during [login]/[register]. If it did, the router would
/// read a mid-submit request as "session unknown again" and bounce to
/// splash while the user is still typing their password: the classic
/// async-redirect loop. Submit-button spinners are local widget state
/// instead; only the *outcome* of an action (a new [AuthState], or a thrown
/// `ApiException` the screen catches directly) ever touches this state.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final subscription = ref.read(sessionEventsProvider).onSessionExpired.listen(
          (_) => state = const AsyncData(AuthState.unauthenticated()),
        );
    ref.onDispose(subscription.cancel);

    final user = await ref.read(authRepositoryProvider).restoreSession();
    return user == null ? const AuthState.unauthenticated() : AuthState.authenticated(user);
  }

  Future<void> login({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .register(email: email, password: password, name: name);
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
