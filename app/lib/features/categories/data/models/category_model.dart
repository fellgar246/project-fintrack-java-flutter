import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';

enum CategoryKind {
  income,
  expense,
}

extension CategoryKindApi on CategoryKind {
  String get apiValue => name.toUpperCase();

  static CategoryKind fromApi(String value) =>
      CategoryKind.values.firstWhere((e) => e.apiValue == value);
}

@Freezed(fromJson: false, toJson: false)
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String name,
    required CategoryKind kind,
    required String color,
    required String icon,
    required bool archived,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: CategoryKindApi.fromApi(json['kind'] as String),
        color: json['color'] as String,
        icon: json['icon'] as String,
        archived: json['archived'] as bool,
      );
}
