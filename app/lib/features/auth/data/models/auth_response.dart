import 'package:freezed_annotation/freezed_annotation.dart';

import 'tokens_model.dart';
import 'user_model.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

/// Response shape shared by `POST /auth/register` and `POST /auth/login`
/// (§4.1): `{user, tokens}`.
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required UserModel user,
    required TokensModel tokens,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}
