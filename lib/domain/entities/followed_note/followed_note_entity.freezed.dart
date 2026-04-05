// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'followed_note_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FollowedNoteEntity {

 String get eventId; String get contentPreview; DateTime get followedAt; int get newReferenceCount;
/// Create a copy of FollowedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowedNoteEntityCopyWith<FollowedNoteEntity> get copyWith => _$FollowedNoteEntityCopyWithImpl<FollowedNoteEntity>(this as FollowedNoteEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.contentPreview, contentPreview) || other.contentPreview == contentPreview)&&(identical(other.followedAt, followedAt) || other.followedAt == followedAt)&&(identical(other.newReferenceCount, newReferenceCount) || other.newReferenceCount == newReferenceCount));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,contentPreview,followedAt,newReferenceCount);

@override
String toString() {
  return 'FollowedNoteEntity(eventId: $eventId, contentPreview: $contentPreview, followedAt: $followedAt, newReferenceCount: $newReferenceCount)';
}


}

/// @nodoc
abstract mixin class $FollowedNoteEntityCopyWith<$Res>  {
  factory $FollowedNoteEntityCopyWith(FollowedNoteEntity value, $Res Function(FollowedNoteEntity) _then) = _$FollowedNoteEntityCopyWithImpl;
@useResult
$Res call({
 String eventId, String contentPreview, DateTime followedAt, int newReferenceCount
});




}
/// @nodoc
class _$FollowedNoteEntityCopyWithImpl<$Res>
    implements $FollowedNoteEntityCopyWith<$Res> {
  _$FollowedNoteEntityCopyWithImpl(this._self, this._then);

  final FollowedNoteEntity _self;
  final $Res Function(FollowedNoteEntity) _then;

/// Create a copy of FollowedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? contentPreview = null,Object? followedAt = null,Object? newReferenceCount = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,contentPreview: null == contentPreview ? _self.contentPreview : contentPreview // ignore: cast_nullable_to_non_nullable
as String,followedAt: null == followedAt ? _self.followedAt : followedAt // ignore: cast_nullable_to_non_nullable
as DateTime,newReferenceCount: null == newReferenceCount ? _self.newReferenceCount : newReferenceCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowedNoteEntity].
extension FollowedNoteEntityPatterns on FollowedNoteEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowedNoteEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowedNoteEntity value)  $default,){
final _that = this;
switch (_that) {
case _FollowedNoteEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowedNoteEntity value)?  $default,){
final _that = this;
switch (_that) {
case _FollowedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String contentPreview,  DateTime followedAt,  int newReferenceCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowedNoteEntity() when $default != null:
return $default(_that.eventId,_that.contentPreview,_that.followedAt,_that.newReferenceCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String contentPreview,  DateTime followedAt,  int newReferenceCount)  $default,) {final _that = this;
switch (_that) {
case _FollowedNoteEntity():
return $default(_that.eventId,_that.contentPreview,_that.followedAt,_that.newReferenceCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String contentPreview,  DateTime followedAt,  int newReferenceCount)?  $default,) {final _that = this;
switch (_that) {
case _FollowedNoteEntity() when $default != null:
return $default(_that.eventId,_that.contentPreview,_that.followedAt,_that.newReferenceCount);case _:
  return null;

}
}

}

/// @nodoc


class _FollowedNoteEntity implements FollowedNoteEntity {
  const _FollowedNoteEntity({required this.eventId, required this.contentPreview, required this.followedAt, required this.newReferenceCount});
  

@override final  String eventId;
@override final  String contentPreview;
@override final  DateTime followedAt;
@override final  int newReferenceCount;

/// Create a copy of FollowedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowedNoteEntityCopyWith<_FollowedNoteEntity> get copyWith => __$FollowedNoteEntityCopyWithImpl<_FollowedNoteEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.contentPreview, contentPreview) || other.contentPreview == contentPreview)&&(identical(other.followedAt, followedAt) || other.followedAt == followedAt)&&(identical(other.newReferenceCount, newReferenceCount) || other.newReferenceCount == newReferenceCount));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,contentPreview,followedAt,newReferenceCount);

@override
String toString() {
  return 'FollowedNoteEntity(eventId: $eventId, contentPreview: $contentPreview, followedAt: $followedAt, newReferenceCount: $newReferenceCount)';
}


}

/// @nodoc
abstract mixin class _$FollowedNoteEntityCopyWith<$Res> implements $FollowedNoteEntityCopyWith<$Res> {
  factory _$FollowedNoteEntityCopyWith(_FollowedNoteEntity value, $Res Function(_FollowedNoteEntity) _then) = __$FollowedNoteEntityCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String contentPreview, DateTime followedAt, int newReferenceCount
});




}
/// @nodoc
class __$FollowedNoteEntityCopyWithImpl<$Res>
    implements _$FollowedNoteEntityCopyWith<$Res> {
  __$FollowedNoteEntityCopyWithImpl(this._self, this._then);

  final _FollowedNoteEntity _self;
  final $Res Function(_FollowedNoteEntity) _then;

/// Create a copy of FollowedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? contentPreview = null,Object? followedAt = null,Object? newReferenceCount = null,}) {
  return _then(_FollowedNoteEntity(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,contentPreview: null == contentPreview ? _self.contentPreview : contentPreview // ignore: cast_nullable_to_non_nullable
as String,followedAt: null == followedAt ? _self.followedAt : followedAt // ignore: cast_nullable_to_non_nullable
as DateTime,newReferenceCount: null == newReferenceCount ? _self.newReferenceCount : newReferenceCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
