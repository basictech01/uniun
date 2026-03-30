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

 String get pubkeyHex;// hex public key — used in Nostr event authorship
 String get npub;// bech32 public key — display only
 String get nsec;// bech32 private key — from secure storage only
 DateTime get createdAt;
/// Create a copy of UserKeyEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserKeyEntityCopyWith<UserKeyEntity> get copyWith => _$UserKeyEntityCopyWithImpl<UserKeyEntity>(this as UserKeyEntity, _$identity);

  /// Serializes this UserKeyEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserKeyEntity&&(identical(other.pubkeyHex, pubkeyHex) || other.pubkeyHex == pubkeyHex)&&(identical(other.npub, npub) || other.npub == npub)&&(identical(other.nsec, nsec) || other.nsec == nsec)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pubkeyHex,npub,nsec,createdAt);

@override
String toString() {
  return 'UserKeyEntity(pubkeyHex: $pubkeyHex, npub: $npub, nsec: $nsec, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserKeyEntityCopyWith<$Res>  {
  factory $UserKeyEntityCopyWith(UserKeyEntity value, $Res Function(UserKeyEntity) _then) = _$UserKeyEntityCopyWithImpl;
@useResult
$Res call({
 String pubkeyHex, String npub, String nsec, DateTime createdAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? pubkeyHex = null,Object? npub = null,Object? nsec = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
pubkeyHex: null == pubkeyHex ? _self.pubkeyHex : pubkeyHex // ignore: cast_nullable_to_non_nullable
as String,npub: null == npub ? _self.npub : npub // ignore: cast_nullable_to_non_nullable
as String,nsec: null == nsec ? _self.nsec : nsec // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pubkeyHex,  String npub,  String nsec,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that.pubkeyHex,_that.npub,_that.nsec,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pubkeyHex,  String npub,  String nsec,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UserKeyEntity():
return $default(_that.pubkeyHex,_that.npub,_that.nsec,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pubkeyHex,  String npub,  String nsec,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UserKeyEntity() when $default != null:
return $default(_that.pubkeyHex,_that.npub,_that.nsec,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserKeyEntity implements UserKeyEntity {
  const _UserKeyEntity({required this.pubkeyHex, required this.npub, required this.nsec, required this.createdAt});
  factory _UserKeyEntity.fromJson(Map<String, dynamic> json) => _$UserKeyEntityFromJson(json);

@override final  String pubkeyHex;
// hex public key — used in Nostr event authorship
@override final  String npub;
// bech32 public key — display only
@override final  String nsec;
// bech32 private key — from secure storage only
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserKeyEntity&&(identical(other.pubkeyHex, pubkeyHex) || other.pubkeyHex == pubkeyHex)&&(identical(other.npub, npub) || other.npub == npub)&&(identical(other.nsec, nsec) || other.nsec == nsec)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pubkeyHex,npub,nsec,createdAt);

@override
String toString() {
  return 'UserKeyEntity(pubkeyHex: $pubkeyHex, npub: $npub, nsec: $nsec, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserKeyEntityCopyWith<$Res> implements $UserKeyEntityCopyWith<$Res> {
  factory _$UserKeyEntityCopyWith(_UserKeyEntity value, $Res Function(_UserKeyEntity) _then) = __$UserKeyEntityCopyWithImpl;
@override @useResult
$Res call({
 String pubkeyHex, String npub, String nsec, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? pubkeyHex = null,Object? npub = null,Object? nsec = null,Object? createdAt = null,}) {
  return _then(_UserKeyEntity(
pubkeyHex: null == pubkeyHex ? _self.pubkeyHex : pubkeyHex // ignore: cast_nullable_to_non_nullable
as String,npub: null == npub ? _self.npub : npub // ignore: cast_nullable_to_non_nullable
as String,nsec: null == nsec ? _self.nsec : nsec // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
