// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbound_event_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboundEventEntity {

 int get id; String get serializedEvent; OutboundStatus get status; DateTime get createdAt; int get retryCount;
/// Create a copy of OutboundEventEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboundEventEntityCopyWith<OutboundEventEntity> get copyWith => _$OutboundEventEntityCopyWithImpl<OutboundEventEntity>(this as OutboundEventEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboundEventEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.serializedEvent, serializedEvent) || other.serializedEvent == serializedEvent)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,serializedEvent,status,createdAt,retryCount);

@override
String toString() {
  return 'OutboundEventEntity(id: $id, serializedEvent: $serializedEvent, status: $status, createdAt: $createdAt, retryCount: $retryCount)';
}


}

/// @nodoc
abstract mixin class $OutboundEventEntityCopyWith<$Res>  {
  factory $OutboundEventEntityCopyWith(OutboundEventEntity value, $Res Function(OutboundEventEntity) _then) = _$OutboundEventEntityCopyWithImpl;
@useResult
$Res call({
 int id, String serializedEvent, OutboundStatus status, DateTime createdAt, int retryCount
});




}
/// @nodoc
class _$OutboundEventEntityCopyWithImpl<$Res>
    implements $OutboundEventEntityCopyWith<$Res> {
  _$OutboundEventEntityCopyWithImpl(this._self, this._then);

  final OutboundEventEntity _self;
  final $Res Function(OutboundEventEntity) _then;

/// Create a copy of OutboundEventEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serializedEvent = null,Object? status = null,Object? createdAt = null,Object? retryCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,serializedEvent: null == serializedEvent ? _self.serializedEvent : serializedEvent // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboundStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OutboundEventEntity].
extension OutboundEventEntityPatterns on OutboundEventEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboundEventEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboundEventEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboundEventEntity value)  $default,){
final _that = this;
switch (_that) {
case _OutboundEventEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboundEventEntity value)?  $default,){
final _that = this;
switch (_that) {
case _OutboundEventEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String serializedEvent,  OutboundStatus status,  DateTime createdAt,  int retryCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboundEventEntity() when $default != null:
return $default(_that.id,_that.serializedEvent,_that.status,_that.createdAt,_that.retryCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String serializedEvent,  OutboundStatus status,  DateTime createdAt,  int retryCount)  $default,) {final _that = this;
switch (_that) {
case _OutboundEventEntity():
return $default(_that.id,_that.serializedEvent,_that.status,_that.createdAt,_that.retryCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String serializedEvent,  OutboundStatus status,  DateTime createdAt,  int retryCount)?  $default,) {final _that = this;
switch (_that) {
case _OutboundEventEntity() when $default != null:
return $default(_that.id,_that.serializedEvent,_that.status,_that.createdAt,_that.retryCount);case _:
  return null;

}
}

}

/// @nodoc


class _OutboundEventEntity implements OutboundEventEntity {
  const _OutboundEventEntity({required this.id, required this.serializedEvent, required this.status, required this.createdAt, required this.retryCount});
  

@override final  int id;
@override final  String serializedEvent;
@override final  OutboundStatus status;
@override final  DateTime createdAt;
@override final  int retryCount;

/// Create a copy of OutboundEventEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboundEventEntityCopyWith<_OutboundEventEntity> get copyWith => __$OutboundEventEntityCopyWithImpl<_OutboundEventEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboundEventEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.serializedEvent, serializedEvent) || other.serializedEvent == serializedEvent)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,serializedEvent,status,createdAt,retryCount);

@override
String toString() {
  return 'OutboundEventEntity(id: $id, serializedEvent: $serializedEvent, status: $status, createdAt: $createdAt, retryCount: $retryCount)';
}


}

/// @nodoc
abstract mixin class _$OutboundEventEntityCopyWith<$Res> implements $OutboundEventEntityCopyWith<$Res> {
  factory _$OutboundEventEntityCopyWith(_OutboundEventEntity value, $Res Function(_OutboundEventEntity) _then) = __$OutboundEventEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String serializedEvent, OutboundStatus status, DateTime createdAt, int retryCount
});




}
/// @nodoc
class __$OutboundEventEntityCopyWithImpl<$Res>
    implements _$OutboundEventEntityCopyWith<$Res> {
  __$OutboundEventEntityCopyWithImpl(this._self, this._then);

  final _OutboundEventEntity _self;
  final $Res Function(_OutboundEventEntity) _then;

/// Create a copy of OutboundEventEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serializedEvent = null,Object? status = null,Object? createdAt = null,Object? retryCount = null,}) {
  return _then(_OutboundEventEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,serializedEvent: null == serializedEvent ? _self.serializedEvent : serializedEvent // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutboundStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
