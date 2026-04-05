// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GetFeedInput {

 int get limit; DateTime? get before;
/// Create a copy of GetFeedInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetFeedInputCopyWith<GetFeedInput> get copyWith => _$GetFeedInputCopyWithImpl<GetFeedInput>(this as GetFeedInput, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetFeedInput&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.before, before) || other.before == before));
}


@override
int get hashCode => Object.hash(runtimeType,limit,before);

@override
String toString() {
  return 'GetFeedInput(limit: $limit, before: $before)';
}


}

/// @nodoc
abstract mixin class $GetFeedInputCopyWith<$Res>  {
  factory $GetFeedInputCopyWith(GetFeedInput value, $Res Function(GetFeedInput) _then) = _$GetFeedInputCopyWithImpl;
@useResult
$Res call({
 int limit, DateTime? before
});




}
/// @nodoc
class _$GetFeedInputCopyWithImpl<$Res>
    implements $GetFeedInputCopyWith<$Res> {
  _$GetFeedInputCopyWithImpl(this._self, this._then);

  final GetFeedInput _self;
  final $Res Function(GetFeedInput) _then;

/// Create a copy of GetFeedInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? limit = null,Object? before = freezed,}) {
  return _then(_self.copyWith(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GetFeedInput].
extension GetFeedInputPatterns on GetFeedInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GetFeedInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GetFeedInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GetFeedInput value)  $default,){
final _that = this;
switch (_that) {
case _GetFeedInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GetFeedInput value)?  $default,){
final _that = this;
switch (_that) {
case _GetFeedInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int limit,  DateTime? before)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GetFeedInput() when $default != null:
return $default(_that.limit,_that.before);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int limit,  DateTime? before)  $default,) {final _that = this;
switch (_that) {
case _GetFeedInput():
return $default(_that.limit,_that.before);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int limit,  DateTime? before)?  $default,) {final _that = this;
switch (_that) {
case _GetFeedInput() when $default != null:
return $default(_that.limit,_that.before);case _:
  return null;

}
}

}

/// @nodoc


class _GetFeedInput implements GetFeedInput {
  const _GetFeedInput({required this.limit, this.before});
  

@override final  int limit;
@override final  DateTime? before;

/// Create a copy of GetFeedInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GetFeedInputCopyWith<_GetFeedInput> get copyWith => __$GetFeedInputCopyWithImpl<_GetFeedInput>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetFeedInput&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.before, before) || other.before == before));
}


@override
int get hashCode => Object.hash(runtimeType,limit,before);

@override
String toString() {
  return 'GetFeedInput(limit: $limit, before: $before)';
}


}

/// @nodoc
abstract mixin class _$GetFeedInputCopyWith<$Res> implements $GetFeedInputCopyWith<$Res> {
  factory _$GetFeedInputCopyWith(_GetFeedInput value, $Res Function(_GetFeedInput) _then) = __$GetFeedInputCopyWithImpl;
@override @useResult
$Res call({
 int limit, DateTime? before
});




}
/// @nodoc
class __$GetFeedInputCopyWithImpl<$Res>
    implements _$GetFeedInputCopyWith<$Res> {
  __$GetFeedInputCopyWithImpl(this._self, this._then);

  final _GetFeedInput _self;
  final $Res Function(_GetFeedInput) _then;

/// Create a copy of GetFeedInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? limit = null,Object? before = freezed,}) {
  return _then(_GetFeedInput(
limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,before: freezed == before ? _self.before : before // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$ComposeNoteInput {

/// The text content of the note.
 String get content;/// Derived from content — caller sets this (text / image / link / reference).
 NoteType get type;/// Thread root event ID — null = this is a new top-level note.
 String? get rootEventId;/// Direct parent event ID — null = this is a new top-level note.
 String? get replyToEventId;/// Pubkeys explicitly @-mentioned in the note.
 List<String> get pTagRefs;/// Hashtags extracted from content.
 List<String> get tTags;/// Extra e-tag "mention" references (e.g. quoting another note).
 List<String> get mentionEventIds;
/// Create a copy of ComposeNoteInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComposeNoteInputCopyWith<ComposeNoteInput> get copyWith => _$ComposeNoteInputCopyWithImpl<ComposeNoteInput>(this as ComposeNoteInput, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComposeNoteInput&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.rootEventId, rootEventId) || other.rootEventId == rootEventId)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&const DeepCollectionEquality().equals(other.pTagRefs, pTagRefs)&&const DeepCollectionEquality().equals(other.tTags, tTags)&&const DeepCollectionEquality().equals(other.mentionEventIds, mentionEventIds));
}


@override
int get hashCode => Object.hash(runtimeType,content,type,rootEventId,replyToEventId,const DeepCollectionEquality().hash(pTagRefs),const DeepCollectionEquality().hash(tTags),const DeepCollectionEquality().hash(mentionEventIds));

@override
String toString() {
  return 'ComposeNoteInput(content: $content, type: $type, rootEventId: $rootEventId, replyToEventId: $replyToEventId, pTagRefs: $pTagRefs, tTags: $tTags, mentionEventIds: $mentionEventIds)';
}


}

/// @nodoc
abstract mixin class $ComposeNoteInputCopyWith<$Res>  {
  factory $ComposeNoteInputCopyWith(ComposeNoteInput value, $Res Function(ComposeNoteInput) _then) = _$ComposeNoteInputCopyWithImpl;
@useResult
$Res call({
 String content, NoteType type, String? rootEventId, String? replyToEventId, List<String> pTagRefs, List<String> tTags, List<String> mentionEventIds
});




}
/// @nodoc
class _$ComposeNoteInputCopyWithImpl<$Res>
    implements $ComposeNoteInputCopyWith<$Res> {
  _$ComposeNoteInputCopyWithImpl(this._self, this._then);

  final ComposeNoteInput _self;
  final $Res Function(ComposeNoteInput) _then;

/// Create a copy of ComposeNoteInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? type = null,Object? rootEventId = freezed,Object? replyToEventId = freezed,Object? pTagRefs = null,Object? tTags = null,Object? mentionEventIds = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,rootEventId: freezed == rootEventId ? _self.rootEventId : rootEventId // ignore: cast_nullable_to_non_nullable
as String?,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,pTagRefs: null == pTagRefs ? _self.pTagRefs : pTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tTags: null == tTags ? _self.tTags : tTags // ignore: cast_nullable_to_non_nullable
as List<String>,mentionEventIds: null == mentionEventIds ? _self.mentionEventIds : mentionEventIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComposeNoteInput].
extension ComposeNoteInputPatterns on ComposeNoteInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComposeNoteInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComposeNoteInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComposeNoteInput value)  $default,){
final _that = this;
switch (_that) {
case _ComposeNoteInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComposeNoteInput value)?  $default,){
final _that = this;
switch (_that) {
case _ComposeNoteInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  NoteType type,  String? rootEventId,  String? replyToEventId,  List<String> pTagRefs,  List<String> tTags,  List<String> mentionEventIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComposeNoteInput() when $default != null:
return $default(_that.content,_that.type,_that.rootEventId,_that.replyToEventId,_that.pTagRefs,_that.tTags,_that.mentionEventIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  NoteType type,  String? rootEventId,  String? replyToEventId,  List<String> pTagRefs,  List<String> tTags,  List<String> mentionEventIds)  $default,) {final _that = this;
switch (_that) {
case _ComposeNoteInput():
return $default(_that.content,_that.type,_that.rootEventId,_that.replyToEventId,_that.pTagRefs,_that.tTags,_that.mentionEventIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  NoteType type,  String? rootEventId,  String? replyToEventId,  List<String> pTagRefs,  List<String> tTags,  List<String> mentionEventIds)?  $default,) {final _that = this;
switch (_that) {
case _ComposeNoteInput() when $default != null:
return $default(_that.content,_that.type,_that.rootEventId,_that.replyToEventId,_that.pTagRefs,_that.tTags,_that.mentionEventIds);case _:
  return null;

}
}

}

/// @nodoc


class _ComposeNoteInput implements ComposeNoteInput {
  const _ComposeNoteInput({required this.content, required this.type, this.rootEventId, this.replyToEventId, final  List<String> pTagRefs = const [], final  List<String> tTags = const [], final  List<String> mentionEventIds = const []}): _pTagRefs = pTagRefs,_tTags = tTags,_mentionEventIds = mentionEventIds;
  

/// The text content of the note.
@override final  String content;
/// Derived from content — caller sets this (text / image / link / reference).
@override final  NoteType type;
/// Thread root event ID — null = this is a new top-level note.
@override final  String? rootEventId;
/// Direct parent event ID — null = this is a new top-level note.
@override final  String? replyToEventId;
/// Pubkeys explicitly @-mentioned in the note.
 final  List<String> _pTagRefs;
/// Pubkeys explicitly @-mentioned in the note.
@override@JsonKey() List<String> get pTagRefs {
  if (_pTagRefs is EqualUnmodifiableListView) return _pTagRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pTagRefs);
}

/// Hashtags extracted from content.
 final  List<String> _tTags;
/// Hashtags extracted from content.
@override@JsonKey() List<String> get tTags {
  if (_tTags is EqualUnmodifiableListView) return _tTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tTags);
}

/// Extra e-tag "mention" references (e.g. quoting another note).
 final  List<String> _mentionEventIds;
/// Extra e-tag "mention" references (e.g. quoting another note).
@override@JsonKey() List<String> get mentionEventIds {
  if (_mentionEventIds is EqualUnmodifiableListView) return _mentionEventIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentionEventIds);
}


/// Create a copy of ComposeNoteInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComposeNoteInputCopyWith<_ComposeNoteInput> get copyWith => __$ComposeNoteInputCopyWithImpl<_ComposeNoteInput>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComposeNoteInput&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.rootEventId, rootEventId) || other.rootEventId == rootEventId)&&(identical(other.replyToEventId, replyToEventId) || other.replyToEventId == replyToEventId)&&const DeepCollectionEquality().equals(other._pTagRefs, _pTagRefs)&&const DeepCollectionEquality().equals(other._tTags, _tTags)&&const DeepCollectionEquality().equals(other._mentionEventIds, _mentionEventIds));
}


@override
int get hashCode => Object.hash(runtimeType,content,type,rootEventId,replyToEventId,const DeepCollectionEquality().hash(_pTagRefs),const DeepCollectionEquality().hash(_tTags),const DeepCollectionEquality().hash(_mentionEventIds));

@override
String toString() {
  return 'ComposeNoteInput(content: $content, type: $type, rootEventId: $rootEventId, replyToEventId: $replyToEventId, pTagRefs: $pTagRefs, tTags: $tTags, mentionEventIds: $mentionEventIds)';
}


}

/// @nodoc
abstract mixin class _$ComposeNoteInputCopyWith<$Res> implements $ComposeNoteInputCopyWith<$Res> {
  factory _$ComposeNoteInputCopyWith(_ComposeNoteInput value, $Res Function(_ComposeNoteInput) _then) = __$ComposeNoteInputCopyWithImpl;
@override @useResult
$Res call({
 String content, NoteType type, String? rootEventId, String? replyToEventId, List<String> pTagRefs, List<String> tTags, List<String> mentionEventIds
});




}
/// @nodoc
class __$ComposeNoteInputCopyWithImpl<$Res>
    implements _$ComposeNoteInputCopyWith<$Res> {
  __$ComposeNoteInputCopyWithImpl(this._self, this._then);

  final _ComposeNoteInput _self;
  final $Res Function(_ComposeNoteInput) _then;

/// Create a copy of ComposeNoteInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? type = null,Object? rootEventId = freezed,Object? replyToEventId = freezed,Object? pTagRefs = null,Object? tTags = null,Object? mentionEventIds = null,}) {
  return _then(_ComposeNoteInput(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NoteType,rootEventId: freezed == rootEventId ? _self.rootEventId : rootEventId // ignore: cast_nullable_to_non_nullable
as String?,replyToEventId: freezed == replyToEventId ? _self.replyToEventId : replyToEventId // ignore: cast_nullable_to_non_nullable
as String?,pTagRefs: null == pTagRefs ? _self._pTagRefs : pTagRefs // ignore: cast_nullable_to_non_nullable
as List<String>,tTags: null == tTags ? _self._tTags : tTags // ignore: cast_nullable_to_non_nullable
as List<String>,mentionEventIds: null == mentionEventIds ? _self._mentionEventIds : mentionEventIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
