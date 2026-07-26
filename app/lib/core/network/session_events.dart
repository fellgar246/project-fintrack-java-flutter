import 'dart:async';

/// Tiny event bus decoupling [AuthInterceptor] from the auth feature: the
/// interceptor lives in `core/` and must not import `features/auth/...`
/// (that would create a dependency cycle back through `dioProvider`, which
/// the auth feature's `data/` layer needs). Instead it just fires an event
/// here when it gives up trying to refresh the session; `AuthController`
/// listens and flips its own state to `unauthenticated`, which the router
/// picks up via `refreshListenable`.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() => _controller.add(null);

  void dispose() => _controller.close();
}
