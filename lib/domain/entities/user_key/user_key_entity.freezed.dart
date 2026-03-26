// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_key_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserKeyEntity {

 String get nsec; String get npub; DateTime get createdAt;
/// Create a copy of UserKeyEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserKeyEntityCopyWith<UserKeyEntity> get copyWith => _$UserKeyEntityCopyWithImpl<UserKeyEntity>(this as UserKeyEntity, _$identity);

  /// Serializes this UserKeyEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserKeyEntity&&(identical(other.nsec, nsec) || other.nsec == nsec)&&(identical(other.npub, npub) || other.npub == npub)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nsec,npub,createdAt);

@override
String toString() {
  return 'UserKeyEntity(nsec: $nsec, npub: $npub, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserKeyEntityCopyWith<$Res>  {
  factory $UserKeyEntityCopyWith(UserKeyEntity value, $Res Function(UserKeyEntity) _then) = _$UserKeyEntityCopyWithImpl;
@useResult
$Res call({
 String nsec, String npub, DateTime createdAt
});




}
/// @nodoc
class _$UserKeyEntityCopyWithImpl<$Res>
    implements $UserKeyEntityCopyWith<$Res> {
  _$UserKeyEntityCopyWithImpl(this._self, this._then);

  final UserKeyEntity _self;
  final $Res Function(UserKeyEntity) _then;

/// Create a copy of UserKeyEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nsec = null,Object? npub = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
nsec: null == nsec ? _self.nsec : nsec // ignore: cast_nullable_to_non_nullable
as String,npub: null == npub ? _self.npub : npub // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserKeyEntity].
extension UserKeyEntityPatterns on UserKeyEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserKeyEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserKeyEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserKeyEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserKeyEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nsec,  String npub,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that.nsec,_that.npub,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nsec,  String npub,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserKeyEntity():
return $default(_that.nsec,_that.npub,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nsec,  String npub,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that.nsec,_that.npub,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserKeyEntity implements UserKeyEntity {
  const _UserKeyEntity({required this.nsec, required this.npub, required this.createdAt});
  factory _UserKeyEntity.fromJson(Map<String, dynamic> json) => _$UserKeyEntityFromJson(json);

@override final  String nsec;
@override final  String npub;
@override final  DateTime createdAt;

/// Create a copy of UserKeyEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserKeyEntityCopyWith<_UserKeyEntity> get copyWith => __$UserKeyEntityCopyWithImpl<_UserKeyEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserKeyEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserKeyEntity&&(identical(other.nsec, nsec) || other.nsec == nsec)&&(identical(other.npub, npub) || other.npub == npub)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nsec,npub,createdAt);

@override
String toString() {
  return 'UserKeyEntity(nsec: $nsec, npub: $npub, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserKeyEntityCopyWith<$Res> implements $UserKeyEntityCopyWith<$Res> {
  factory _$UserKeyEntityCopyWith(_UserKeyEntity value, $Res Function(_UserKeyEntity) _then) = __$UserKeyEntityCopyWithImpl;
@override @useResult
$Res call({
 String nsec, String npub, DateTime createdAt
});




}
/// @nodoc
class __$UserKeyEntityCopyWithImpl<$Res>
    implements _$UserKeyEntityCopyWith<$Res> {
  __$UserKeyEntityCopyWithImpl(this._self, this._then);

  final _UserKeyEntity _self;
  final $Res Function(_UserKeyEntity) _then;

/// Create a copy of UserKeyEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nsec = null,Object? npub = null,Object? createdAt = null,}) {
  return _then(_UserKeyEntity(
nsec: null == nsec ? _self.nsec : nsec // ignore: cast_nullable_to_non_nullable
as String,npub: null == npub ? _self.npub : npub // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
