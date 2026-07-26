import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'session_events.dart';

/// The Dio client every feature's `data/` layer should inject via
/// [dioProvider] — nothing outside `core/` should construct its own Dio.
/// It already carries [AuthInterceptor] (Bearer header + silent 401
/// refresh), so features never touch tokens directly.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: ref.read(tokenStorageProvider),
      onSessionExpired: () => ref.read(sessionEventsProvider).notifySessionExpired(),
    ),
  );

  return dio;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
