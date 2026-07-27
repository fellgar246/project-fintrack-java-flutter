// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  AccountType get type => throw _privateConstructorUsedError;
  String get initialBalance => throw _privateConstructorUsedError;
  String get currentBalance => throw _privateConstructorUsedError;
  bool get archived => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of AccountModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountModelCopyWith<AccountModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountModelCopyWith<$Res> {
  factory $AccountModelCopyWith(
    AccountModel value,
    $Res Function(AccountModel) then,
  ) = _$AccountModelCopyWithImpl<$Res, AccountModel>;
  @useResult
  $Res call({
    String id,
    String name,
    AccountType type,
    String initialBalance,
    String currentBalance,
    bool archived,
    DateTime createdAt,
  });
}

/// @nodoc
class _$AccountModelCopyWithImpl<$Res, $Val extends AccountModel>
    implements $AccountModelCopyWith<$Res> {
  _$AccountModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? initialBalance = null,
    Object? currentBalance = null,
    Object? archived = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as AccountType,
            initialBalance: null == initialBalance
                ? _value.initialBalance
                : initialBalance // ignore: cast_nullable_to_non_nullable
                      as String,
            currentBalance: null == currentBalance
                ? _value.currentBalance
                : currentBalance // ignore: cast_nullable_to_non_nullable
                      as String,
            archived: null == archived
                ? _value.archived
                : archived // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountModelImplCopyWith<$Res>
    implements $AccountModelCopyWith<$Res> {
  factory _$$AccountModelImplCopyWith(
    _$AccountModelImpl value,
    $Res Function(_$AccountModelImpl) then,
  ) = __$$AccountModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    AccountType type,
    String initialBalance,
    String currentBalance,
    bool archived,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$AccountModelImplCopyWithImpl<$Res>
    extends _$AccountModelCopyWithImpl<$Res, _$AccountModelImpl>
    implements _$$AccountModelImplCopyWith<$Res> {
  __$$AccountModelImplCopyWithImpl(
    _$AccountModelImpl _value,
    $Res Function(_$AccountModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? initialBalance = null,
    Object? currentBalance = null,
    Object? archived = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$AccountModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as AccountType,
        initialBalance: null == initialBalance
            ? _value.initialBalance
            : initialBalance // ignore: cast_nullable_to_non_nullable
                  as String,
        currentBalance: null == currentBalance
            ? _value.currentBalance
            : currentBalance // ignore: cast_nullable_to_non_nullable
                  as String,
        archived: null == archived
            ? _value.archived
            : archived // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc

class _$AccountModelImpl extends _AccountModel {
  const _$AccountModelImpl({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    required this.archived,
    required this.createdAt,
  }) : super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final AccountType type;
  @override
  final String initialBalance;
  @override
  final String currentBalance;
  @override
  final bool archived;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'AccountModel(id: $id, name: $name, type: $type, initialBalance: $initialBalance, currentBalance: $currentBalance, archived: $archived, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.initialBalance, initialBalance) ||
                other.initialBalance == initialBalance) &&
            (identical(other.currentBalance, currentBalance) ||
                other.currentBalance == currentBalance) &&
            (identical(other.archived, archived) ||
                other.archived == archived) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    type,
    initialBalance,
    currentBalance,
    archived,
    createdAt,
  );

  /// Create a copy of AccountModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountModelImplCopyWith<_$AccountModelImpl> get copyWith =>
      __$$AccountModelImplCopyWithImpl<_$AccountModelImpl>(this, _$identity);
}

abstract class _AccountModel extends AccountModel {
  const factory _AccountModel({
    required final String id,
    required final String name,
    required final AccountType type,
    required final String initialBalance,
    required final String currentBalance,
    required final bool archived,
    required final DateTime createdAt,
  }) = _$AccountModelImpl;
  const _AccountModel._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  AccountType get type;
  @override
  String get initialBalance;
  @override
  String get currentBalance;
  @override
  bool get archived;
  @override
  DateTime get createdAt;

  /// Create a copy of AccountModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountModelImplCopyWith<_$AccountModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
