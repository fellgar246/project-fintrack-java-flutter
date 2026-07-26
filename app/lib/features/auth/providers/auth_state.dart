import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/models/user_model.dart';

part 'auth_state.freezed.dart';

/// Session state, once we know it. The third "unknown" phase from the plan
/// is represented by `AsyncNotifier`'s own `AsyncLoading` — see the doc
/// comment on [AuthController] for why folding it into a third value here
/// would invite the redirect-loop bug the router has to avoid.
@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
}
