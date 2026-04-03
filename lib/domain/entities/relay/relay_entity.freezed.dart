// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relay_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RelayEntity {

 String get url; bool get read; bool get write; RelayStatus get status; DateTime? get lastConnectedAt;
/// Create a copy of RelayEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelayEntityCopyWith<RelayEntity> get copyWith => _$RelayEntityCopyWithImpl<RelayEntity>(this as RelayEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelayEntity&&(identical(other.url, url) || other.url == url)&&(identical(other.read, read) || other.read == read)&&(identical(other.write, write) || other.write == write)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastConnectedAt, lastConnectedAt) || other.lastConnectedAt == lastConnectedAt));
}


@override
int get hashCode => Object.hash(runtimeType,url,read,write,status,lastConnectedAt);

@override
String toString() {
  return 'RelayEntity(url: $url, read: $read, write: $write, status: $status, lastConnectedAt: $lastConnectedAt)';
}


}

/// @nodoc
abstract mixin class $RelayEntityCopyWith<$Res>  {
  factory $RelayEntityCopyWith(RelayEntity value, $Res Function(RelayEntity) _then) = _$RelayEntityCopyWithImpl;
@useResult
$Res call({
 String url, bool read, bool write, RelayStatus status, DateTime? lastConnectedAt
});




}
/// @nodoc
class _$RelayEntityCopyWithImpl<$Res>
    implements $RelayEntityCopyWith<$Res> {
  _$RelayEntityCopyWithImpl(this._self, this._then);

  final RelayEntity _self;
  final $Res Function(RelayEntity) _then;

/// Create a copy of RelayEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? read = null,Object? write = null,Object? status = null,Object? lastConnectedAt = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,write: null == write ? _self.write : write // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RelayStatus,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RelayEntity].
extension RelayEntityPatterns on RelayEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelayEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelayEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelayEntity value)  $default,){
final _that = this;
switch (_that) {
case _RelayEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelayEntity value)?  $default,){
final _that = this;
switch (_that) {
case _RelayEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  bool read,  bool write,  RelayStatus status,  DateTime? lastConnectedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelayEntity() when $default != null:
return $default(_that.url,_that.read,_that.write,_that.status,_that.lastConnectedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  bool read,  bool write,  RelayStatus status,  DateTime? lastConnectedAt)  $default,) {final _that = this;
switch (_that) {
case _RelayEntity():
return $default(_that.url,_that.read,_that.write,_that.status,_that.lastConnectedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  bool read,  bool write,  RelayStatus status,  DateTime? lastConnectedAt)?  $default,) {final _that = this;
switch (_that) {
case _RelayEntity() when $default != null:
return $default(_that.url,_that.read,_that.write,_that.status,_that.lastConnectedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RelayEntity implements RelayEntity {
  const _RelayEntity({required this.url, required this.read, required this.write, required this.status, this.lastConnectedAt});
  

@override final  String url;
@override final  bool read;
@override final  bool write;
@override final  RelayStatus status;
@override final  DateTime? lastConnectedAt;

/// Create a copy of RelayEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelayEntityCopyWith<_RelayEntity> get copyWith => __$RelayEntityCopyWithImpl<_RelayEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelayEntity&&(identical(other.url, url) || other.url == url)&&(identical(other.read, read) || other.read == read)&&(identical(other.write, write) || other.write == write)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastConnectedAt, lastConnectedAt) || other.lastConnectedAt == lastConnectedAt));
}


@override
int get hashCode => Object.hash(runtimeType,url,read,write,status,lastConnectedAt);

@override
String toString() {
  return 'RelayEntity(url: $url, read: $read, write: $write, status: $status, lastConnectedAt: $lastConnectedAt)';
}


}

/// @nodoc
abstract mixin class _$RelayEntityCopyWith<$Res> implements $RelayEntityCopyWith<$Res> {
  factory _$RelayEntityCopyWith(_RelayEntity value, $Res Function(_RelayEntity) _then) = __$RelayEntityCopyWithImpl;
@override @useResult
$Res call({
 String url, bool read, bool write, RelayStatus status, DateTime? lastConnectedAt
});




}
/// @nodoc
class __$RelayEntityCopyWithImpl<$Res>
    implements _$RelayEntityCopyWith<$Res> {
  __$RelayEntityCopyWithImpl(this._self, this._then);

  final _RelayEntity _self;
  final $Res Function(_RelayEntity) _then;

/// Create a copy of RelayEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? read = null,Object? write = null,Object? status = null,Object? lastConnectedAt = freezed,}) {
  return _then(_RelayEntity(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,read: null == read ? _self.read : read // ignore: cast_nullable_to_non_nullable
as bool,write: null == write ? _self.write : write // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RelayStatus,lastConnectedAt: freezed == lastConnectedAt ? _self.lastConnectedAt : lastConnectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
