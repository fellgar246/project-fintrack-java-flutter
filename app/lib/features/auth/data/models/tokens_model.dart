import 'package:freezed_annotation/freezed_annotation.dart';

part 'tokens_model.freezed.dart';
part 'tokens_model.g.dart';

@freezed
class TokensModel with _$TokensModel {
  const factory TokensModel({
    required String accessToken,
    required String refreshToken,
  }) = _TokensModel;

  factory TokensModel.fromJson(Map<String, dynamic> json) => _$TokensModelFromJson(json);
}
