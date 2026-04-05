// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'select_ai_model_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SelectAIModelState {

 SelectAIModelStatus get status; List<AIModelEntity> get models;/// The card the user has tapped (highlighted in UI).
 AIModelId? get selectedModelId;/// The model that is already downloaded and active.
 AIModelId? get activeModelId; double get downloadProgress; String? get errorMessage;
/// Create a copy of SelectAIModelState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelectAIModelStateCopyWith<SelectAIModelState> get copyWith => _$SelectAIModelStateCopyWithImpl<SelectAIModelState>(this as SelectAIModelState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelectAIModelState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.models, models)&&(identical(other.selectedModelId, selectedModelId) || other.selectedModelId == selectedModelId)&&(identical(other.activeModelId, activeModelId) || other.activeModelId == activeModelId)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(models),selectedModelId,activeModelId,downloadProgress,errorMessage);

@override
String toString() {
  return 'SelectAIModelState(status: $status, models: $models, selectedModelId: $selectedModelId, activeModelId: $activeModelId, downloadProgress: $downloadProgress, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SelectAIModelStateCopyWith<$Res>  {
  factory $SelectAIModelStateCopyWith(SelectAIModelState value, $Res Function(SelectAIModelState) _then) = _$SelectAIModelStateCopyWithImpl;
@useResult
$Res call({
 SelectAIModelStatus status, List<AIModelEntity> models, AIModelId? selectedModelId, AIModelId? activeModelId, double downloadProgress, String? errorMessage
});




}
/// @nodoc
class _$SelectAIModelStateCopyWithImpl<$Res>
    implements $SelectAIModelStateCopyWith<$Res> {
  _$SelectAIModelStateCopyWithImpl(this._self, this._then);

  final SelectAIModelState _self;
  final $Res Function(SelectAIModelState) _then;

/// Create a copy of SelectAIModelState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? models = null,Object? selectedModelId = freezed,Object? activeModelId = freezed,Object? downloadProgress = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SelectAIModelStatus,models: null == models ? _self.models : models // ignore: cast_nullable_to_non_nullable
as List<AIModelEntity>,selectedModelId: freezed == selectedModelId ? _self.selectedModelId : selectedModelId // ignore: cast_nullable_to_non_nullable
as AIModelId?,activeModelId: freezed == activeModelId ? _self.activeModelId : activeModelId // ignore: cast_nullable_to_non_nullable
as AIModelId?,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SelectAIModelState].
extension SelectAIModelStatePatterns on SelectAIModelState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelectAIModelState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectAIModelState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelectAIModelState value)  $default,){
final _that = this;
switch (_that) {
case _SelectAIModelState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelectAIModelState value)?  $default,){
final _that = this;
switch (_that) {
case _SelectAIModelState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SelectAIModelStatus status,  List<AIModelEntity> models,  AIModelId? selectedModelId,  AIModelId? activeModelId,  double downloadProgress,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectAIModelState() when $default != null:
return $default(_that.status,_that.models,_that.selectedModelId,_that.activeModelId,_that.downloadProgress,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SelectAIModelStatus status,  List<AIModelEntity> models,  AIModelId? selectedModelId,  AIModelId? activeModelId,  double downloadProgress,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SelectAIModelState():
return $default(_that.status,_that.models,_that.selectedModelId,_that.activeModelId,_that.downloadProgress,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SelectAIModelStatus status,  List<AIModelEntity> models,  AIModelId? selectedModelId,  AIModelId? activeModelId,  double downloadProgress,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SelectAIModelState() when $default != null:
return $default(_that.status,_that.models,_that.selectedModelId,_that.activeModelId,_that.downloadProgress,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SelectAIModelState implements SelectAIModelState {
  const _SelectAIModelState({this.status = SelectAIModelStatus.initial, final  List<AIModelEntity> models = const [], this.selectedModelId, this.activeModelId, this.downloadProgress = 0.0, this.errorMessage}): _models = models;
  

@override@JsonKey() final  SelectAIModelStatus status;
 final  List<AIModelEntity> _models;
@override@JsonKey() List<AIModelEntity> get models {
  if (_models is EqualUnmodifiableListView) return _models;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_models);
}

/// The card the user has tapped (highlighted in UI).
@override final  AIModelId? selectedModelId;
/// The model that is already downloaded and active.
@override final  AIModelId? activeModelId;
@override@JsonKey() final  double downloadProgress;
@override final  String? errorMessage;

/// Create a copy of SelectAIModelState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectAIModelStateCopyWith<_SelectAIModelState> get copyWith => __$SelectAIModelStateCopyWithImpl<_SelectAIModelState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectAIModelState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._models, _models)&&(identical(other.selectedModelId, selectedModelId) || other.selectedModelId == selectedModelId)&&(identical(other.activeModelId, activeModelId) || other.activeModelId == activeModelId)&&(identical(other.downloadProgress, downloadProgress) || other.downloadProgress == downloadProgress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_models),selectedModelId,activeModelId,downloadProgress,errorMessage);

@override
String toString() {
  return 'SelectAIModelState(status: $status, models: $models, selectedModelId: $selectedModelId, activeModelId: $activeModelId, downloadProgress: $downloadProgress, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SelectAIModelStateCopyWith<$Res> implements $SelectAIModelStateCopyWith<$Res> {
  factory _$SelectAIModelStateCopyWith(_SelectAIModelState value, $Res Function(_SelectAIModelState) _then) = __$SelectAIModelStateCopyWithImpl;
@override @useResult
$Res call({
 SelectAIModelStatus status, List<AIModelEntity> models, AIModelId? selectedModelId, AIModelId? activeModelId, double downloadProgress, String? errorMessage
});




}
/// @nodoc
class __$SelectAIModelStateCopyWithImpl<$Res>
    implements _$SelectAIModelStateCopyWith<$Res> {
  __$SelectAIModelStateCopyWithImpl(this._self, this._then);

  final _SelectAIModelState _self;
  final $Res Function(_SelectAIModelState) _then;

/// Create a copy of SelectAIModelState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? models = null,Object? selectedModelId = freezed,Object? activeModelId = freezed,Object? downloadProgress = null,Object? errorMessage = freezed,}) {
  return _then(_SelectAIModelState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SelectAIModelStatus,models: null == models ? _self._models : models // ignore: cast_nullable_to_non_nullable
as List<AIModelEntity>,selectedModelId: freezed == selectedModelId ? _self.selectedModelId : selectedModelId // ignore: cast_nullable_to_non_nullable
as AIModelId?,activeModelId: freezed == activeModelId ? _self.activeModelId : activeModelId // ignore: cast_nullable_to_non_nullable
as AIModelId?,downloadProgress: null == downloadProgress ? _self.downloadProgress : downloadProgress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
