// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileEntity {

 String get pubkey; String? get name; String? get username; String? get about; String? get avatarUrl; String? get nip05; DateTime get updatedAt;// Own profile is never evicted: caller sets lastSeenAt = DateTime(3000, 6, 1).
// CleanupManager evicts profiles where lastSeenAt < now - 30 days.
// Null lastSeenAt = never evict (safe default for own profile).
 DateTime? get lastSeenAt;
/// Create a copy of ProfileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileEntityCopyWith<ProfileEntity> get copyWith => _$ProfileEntityCopyWithImpl<ProfileEntity>(this as ProfileEntity, _$identity);

  /// Serializes this ProfileEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEntity&&(identical(other.pubkey, pubkey) || other.pubkey == pubkey)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.about, about) || other.about == about)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.nip05, nip05) || other.nip05 == nip05)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pubkey,name,username,about,avatarUrl,nip05,updatedAt,lastSeenAt);

@override
String toString() {
  return 'ProfileEntity(pubkey: $pubkey, name: $name, username: $username, about: $about, avatarUrl: $avatarUrl, nip05: $nip05, updatedAt: $updatedAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class $ProfileEntityCopyWith<$Res>  {
  factory $ProfileEntityCopyWith(ProfileEntity value, $Res Function(ProfileEntity) _then) = _$ProfileEntityCopyWithImpl;
@useResult
$Res call({
 String pubkey, String? name, String? username, String? about, String? avatarUrl, String? nip05, DateTime updatedAt, DateTime? lastSeenAt
});




}
/// @nodoc
class _$ProfileEntityCopyWithImpl<$Res>
    implements $ProfileEntityCopyWith<$Res> {
  _$ProfileEntityCopyWithImpl(this._self, this._then);

  final ProfileEntity _self;
  final $Res Function(ProfileEntity) _then;

/// Create a copy of ProfileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pubkey = null,Object? name = freezed,Object? username = freezed,Object? about = freezed,Object? avatarUrl = freezed,Object? nip05 = freezed,Object? updatedAt = null,Object? lastSeenAt = freezed,}) {
  return _then(_self.copyWith(
pubkey: null == pubkey ? _self.pubkey : pubkey // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,nip05: freezed == nip05 ? _self.nip05 : nip05 // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileEntity].
extension ProfileEntityPatterns on ProfileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileEntity value)  $default,){
final _that = this;
switch (_that) {
case _ProfileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pubkey,  String? name,  String? username,  String? about,  String? avatarUrl,  String? nip05,  DateTime updatedAt,  DateTime? lastSeenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileEntity() when $default != null:
return $default(_that.pubkey,_that.name,_that.username,_that.about,_that.avatarUrl,_that.nip05,_that.updatedAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pubkey,  String? name,  String? username,  String? about,  String? avatarUrl,  String? nip05,  DateTime updatedAt,  DateTime? lastSeenAt)  $default,) {final _that = this;
switch (_that) {
case _ProfileEntity():
return $default(_that.pubkey,_that.name,_that.username,_that.about,_that.avatarUrl,_that.nip05,_that.updatedAt,_that.lastSeenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pubkey,  String? name,  String? username,  String? about,  String? avatarUrl,  String? nip05,  DateTime updatedAt,  DateTime? lastSeenAt)?  $default,) {final _that = this;
switch (_that) {
case _ProfileEntity() when $default != null:
return $default(_that.pubkey,_that.name,_that.username,_that.about,_that.avatarUrl,_that.nip05,_that.updatedAt,_that.lastSeenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileEntity implements ProfileEntity {
  const _ProfileEntity({required this.pubkey, this.name, this.username, this.about, this.avatarUrl, this.nip05, required this.updatedAt, this.lastSeenAt});
  factory _ProfileEntity.fromJson(Map<String, dynamic> json) => _$ProfileEntityFromJson(json);

@override final  String pubkey;
@override final  String? name;
@override final  String? username;
@override final  String? about;
@override final  String? avatarUrl;
@override final  String? nip05;
@override final  DateTime updatedAt;
// Own profile is never evicted: caller sets lastSeenAt = DateTime(3000, 6, 1).
// CleanupManager evicts profiles where lastSeenAt < now - 30 days.
// Null lastSeenAt = never evict (safe default for own profile).
@override final  DateTime? lastSeenAt;

/// Create a copy of ProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileEntityCopyWith<_ProfileEntity> get copyWith => __$ProfileEntityCopyWithImpl<_ProfileEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileEntity&&(identical(other.pubkey, pubkey) || other.pubkey == pubkey)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.about, about) || other.about == about)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.nip05, nip05) || other.nip05 == nip05)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pubkey,name,username,about,avatarUrl,nip05,updatedAt,lastSeenAt);

@override
String toString() {
  return 'ProfileEntity(pubkey: $pubkey, name: $name, username: $username, about: $about, avatarUrl: $avatarUrl, nip05: $nip05, updatedAt: $updatedAt, lastSeenAt: $lastSeenAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileEntityCopyWith<$Res> implements $ProfileEntityCopyWith<$Res> {
  factory _$ProfileEntityCopyWith(_ProfileEntity value, $Res Function(_ProfileEntity) _then) = __$ProfileEntityCopyWithImpl;
@override @useResult
$Res call({
 String pubkey, String? name, String? username, String? about, String? avatarUrl, String? nip05, DateTime updatedAt, DateTime? lastSeenAt
});




}
/// @nodoc
class __$ProfileEntityCopyWithImpl<$Res>
    implements _$ProfileEntityCopyWith<$Res> {
  __$ProfileEntityCopyWithImpl(this._self, this._then);

  final _ProfileEntity _self;
  final $Res Function(_ProfileEntity) _then;

/// Create a copy of ProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pubkey = null,Object? name = freezed,Object? username = freezed,Object? about = freezed,Object? avatarUrl = freezed,Object? nip05 = freezed,Object? updatedAt = null,Object? lastSeenAt = freezed,}) {
  return _then(_ProfileEntity(
pubkey: null == pubkey ? _self.pubkey : pubkey // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,nip05: freezed == nip05 ? _self.nip05 : nip05 // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: freezed == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
