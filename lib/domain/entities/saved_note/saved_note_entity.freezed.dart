// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_note_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedNoteEntity {

 String get eventId; String get sig; String get authorPubkey; String get content; NoteType get type; List<String> get eTagRefs; List<String> get pTagRefs; List<String> get tTags; DateTime get created; DateTime get savedAt;
/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedNoteEntityCopyWith<SavedNoteEntity> get copyWith => _$SavedNoteEntityCopyWithImpl<SavedNoteEntity>(this as SavedNoteEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sig, sig) || other.sig == sig)&&(identical(other.authorPubkey, authorPubkey) || other.authorPubkey == authorPubkey)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.eTagRefs, eTagRefs)&&const DeepCollectionEquality().equals(other.pTagRefs, pTagRefs)&&const DeepCollectionEquality().equals(other.tTags, tTags)&&(identical(other.created, created) || other.created == created)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,sig,authorPubkey,content,type,const DeepCollectionEquality().hash(eTagRefs),const DeepCollectionEquality().hash(pTagRefs),const DeepCollectionEquality().hash(tTags),created,savedAt);

@override
String toString() {
  return 'SavedNoteEntity(eventId: $eventId, sig: $sig, authorPubkey: $authorPubkey, content: $content, type: $type, eTagRefs: $eTagRefs, pTagRefs: $pTagRefs, tTags: $tTags, created: $created, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class $SavedNoteEntityCopyWith<$Res>  {
  factory $SavedNoteEntityCopyWith(SavedNoteEntity value, $Res Function(SavedNoteEntity) _then) = _$SavedNoteEntityCopyWithImpl;
@useResult
$Res call({
 String eventId, String sig, String authorPubkey, String content, NoteType type, List<String> eTagRefs, List<String> pTagRefs, List<String> tTags, DateTime created, DateTime savedAt
});




}
/// @nodoc
class _$SavedNoteEntityCopyWithImpl<$Res>
    implements $SavedNoteEntityCopyWith<$Res> {
  _$SavedNoteEntityCopyWithImpl(this._self, this._then);

  final SavedNoteEntity _self;
  final $Res Function(SavedNoteEntity) _then;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? sig = null,Object? authorPubkey = null,Object? content = null,Object? type = null,Object? eTagRefs = null,Object? pTagRefs = null,Object? tTags = null,Object? created = null,Object? savedAt = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sig: null == sig ? _self.sig : sig // ignore: cast_nullable_to_non_nullable
as String,authorPubkey: null == authorPubkey ? _self.authorPubkey : authorPubkey // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,eTagRefs: null == eTagRefs ? _self.eTagRefs : eTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,pTagRefs: null == pTagRefs ? _self.pTagRefs : pTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tTags: null == tTags ? _self.tTags : tTags // ignore: cast_nullable_to_non_nullable
as List<String>,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedNoteEntity].
extension SavedNoteEntityPatterns on SavedNoteEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedNoteEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedNoteEntity value)  $default,){
final _that = this;
switch (_that) {
case _SavedNoteEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedNoteEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String sig,  String authorPubkey,  String content,  NoteType type,  List<String> eTagRefs,  List<String> pTagRefs,  List<String> tTags,  DateTime created,  DateTime savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
return $default(_that.eventId,_that.sig,_that.authorPubkey,_that.content,_that.type,_that.eTagRefs,_that.pTagRefs,_that.tTags,_that.created,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String sig,  String authorPubkey,  String content,  NoteType type,  List<String> eTagRefs,  List<String> pTagRefs,  List<String> tTags,  DateTime created,  DateTime savedAt)  $default,) {final _that = this;
switch (_that) {
case _SavedNoteEntity():
return $default(_that.eventId,_that.sig,_that.authorPubkey,_that.content,_that.type,_that.eTagRefs,_that.pTagRefs,_that.tTags,_that.created,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String sig,  String authorPubkey,  String content,  NoteType type,  List<String> eTagRefs,  List<String> pTagRefs,  List<String> tTags,  DateTime created,  DateTime savedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedNoteEntity() when $default != null:
return $default(_that.eventId,_that.sig,_that.authorPubkey,_that.content,_that.type,_that.eTagRefs,_that.pTagRefs,_that.tTags,_that.created,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SavedNoteEntity implements SavedNoteEntity {
  const _SavedNoteEntity({required this.eventId, required this.sig, required this.authorPubkey, required this.content, required this.type, required final  List<String> eTagRefs, required final  List<String> pTagRefs, required final  List<String> tTags, required this.created, required this.savedAt}): _eTagRefs = eTagRefs,_pTagRefs = pTagRefs,_tTags = tTags;
  

@override final  String eventId;
@override final  String sig;
@override final  String authorPubkey;
@override final  String content;
@override final  NoteType type;
 final  List<String> _eTagRefs;
@override List<String> get eTagRefs {
  if (_eTagRefs is EqualUnmodifiableListView) return _eTagRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eTagRefs);
}

 final  List<String> _pTagRefs;
@override List<String> get pTagRefs {
  if (_pTagRefs is EqualUnmodifiableListView) return _pTagRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pTagRefs);
}

 final  List<String> _tTags;
@override List<String> get tTags {
  if (_tTags is EqualUnmodifiableListView) return _tTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tTags);
}

@override final  DateTime created;
@override final  DateTime savedAt;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedNoteEntityCopyWith<_SavedNoteEntity> get copyWith => __$SavedNoteEntityCopyWithImpl<_SavedNoteEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedNoteEntity&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.sig, sig) || other.sig == sig)&&(identical(other.authorPubkey, authorPubkey) || other.authorPubkey == authorPubkey)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._eTagRefs, _eTagRefs)&&const DeepCollectionEquality().equals(other._pTagRefs, _pTagRefs)&&const DeepCollectionEquality().equals(other._tTags, _tTags)&&(identical(other.created, created) || other.created == created)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode => Object.hash(runtimeType,eventId,sig,authorPubkey,content,type,const DeepCollectionEquality().hash(_eTagRefs),const DeepCollectionEquality().hash(_pTagRefs),const DeepCollectionEquality().hash(_tTags),created,savedAt);

@override
String toString() {
  return 'SavedNoteEntity(eventId: $eventId, sig: $sig, authorPubkey: $authorPubkey, content: $content, type: $type, eTagRefs: $eTagRefs, pTagRefs: $pTagRefs, tTags: $tTags, created: $created, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$SavedNoteEntityCopyWith<$Res> implements $SavedNoteEntityCopyWith<$Res> {
  factory _$SavedNoteEntityCopyWith(_SavedNoteEntity value, $Res Function(_SavedNoteEntity) _then) = __$SavedNoteEntityCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String sig, String authorPubkey, String content, NoteType type, List<String> eTagRefs, List<String> pTagRefs, List<String> tTags, DateTime created, DateTime savedAt
});




}
/// @nodoc
class __$SavedNoteEntityCopyWithImpl<$Res>
    implements _$SavedNoteEntityCopyWith<$Res> {
  __$SavedNoteEntityCopyWithImpl(this._self, this._then);

  final _SavedNoteEntity _self;
  final $Res Function(_SavedNoteEntity) _then;

/// Create a copy of SavedNoteEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? sig = null,Object? authorPubkey = null,Object? content = null,Object? type = null,Object? eTagRefs = null,Object? pTagRefs = null,Object? tTags = null,Object? created = null,Object? savedAt = null,}) {
  return _then(_SavedNoteEntity(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,sig: null == sig ? _self.sig : sig // ignore: cast_nullable_to_non_nullable
as String,authorPubkey: null == authorPubkey ? _self.authorPubkey : authorPubkey // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,eTagRefs: null == eTagRefs ? _self._eTagRefs : eTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,pTagRefs: null == pTagRefs ? _self._pTagRefs : pTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tTags: null == tTags ? _self._tTags : tTags // ignore: cast_nullable_to_non_nullable
as List<String>,created: null == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as DateTime,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
