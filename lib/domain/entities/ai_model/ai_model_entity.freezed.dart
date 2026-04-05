// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_model_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AIModelEntity {

 AIModelId get modelId;/// Human-readable size string e.g. "586 MB", "1.7 GB".
 String get sizeLabel; int get sizeBytes; AIModelTier get tier; bool get isRecommended; AIModelOptimization get optimization;/// Remote URL to download the model file.
 String get downloadUrl; bool get isDownloaded;
/// Create a copy of AIModelEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIModelEntityCopyWith<AIModelEntity> get copyWith => _$AIModelEntityCopyWithImpl<AIModelEntity>(this as AIModelEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModelEntity&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.sizeLabel, sizeLabel) || other.sizeLabel == sizeLabel)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.optimization, optimization) || other.optimization == optimization)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded));
}


@override
int get hashCode => Object.hash(runtimeType,modelId,sizeLabel,sizeBytes,tier,isRecommended,optimization,downloadUrl,isDownloaded);

@override
String toString() {
  return 'AIModelEntity(modelId: $modelId, sizeLabel: $sizeLabel, sizeBytes: $sizeBytes, tier: $tier, isRecommended: $isRecommended, optimization: $optimization, downloadUrl: $downloadUrl, isDownloaded: $isDownloaded)';
}


}

/// @nodoc
abstract mixin class $AIModelEntityCopyWith<$Res>  {
  factory $AIModelEntityCopyWith(AIModelEntity value, $Res Function(AIModelEntity) _then) = _$AIModelEntityCopyWithImpl;
@useResult
$Res call({
 AIModelId modelId, String sizeLabel, int sizeBytes, AIModelTier tier, bool isRecommended, AIModelOptimization optimization, String downloadUrl, bool isDownloaded
});




}
/// @nodoc
class _$AIModelEntityCopyWithImpl<$Res>
    implements $AIModelEntityCopyWith<$Res> {
  _$AIModelEntityCopyWithImpl(this._self, this._then);

  final AIModelEntity _self;
  final $Res Function(AIModelEntity) _then;

/// Create a copy of AIModelEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modelId = null,Object? sizeLabel = null,Object? sizeBytes = null,Object? tier = null,Object? isRecommended = null,Object? optimization = null,Object? downloadUrl = null,Object? isDownloaded = null,}) {
  return _then(_self.copyWith(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as AIModelId,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as AIModelTier,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,optimization: null == optimization ? _self.optimization : optimization // ignore: cast_nullable_to_non_nullable
as AIModelOptimization,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AIModelEntity].
extension AIModelEntityPatterns on AIModelEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AIModelEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AIModelEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AIModelEntity value)  $default,){
final _that = this;
switch (_that) {
case _AIModelEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AIModelEntity value)?  $default,){
final _that = this;
switch (_that) {
case _AIModelEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AIModelId modelId,  String sizeLabel,  int sizeBytes,  AIModelTier tier,  bool isRecommended,  AIModelOptimization optimization,  String downloadUrl,  bool isDownloaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AIModelEntity() when $default != null:
return $default(_that.modelId,_that.sizeLabel,_that.sizeBytes,_that.tier,_that.isRecommended,_that.optimization,_that.downloadUrl,_that.isDownloaded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AIModelId modelId,  String sizeLabel,  int sizeBytes,  AIModelTier tier,  bool isRecommended,  AIModelOptimization optimization,  String downloadUrl,  bool isDownloaded)  $default,) {final _that = this;
switch (_that) {
case _AIModelEntity():
return $default(_that.modelId,_that.sizeLabel,_that.sizeBytes,_that.tier,_that.isRecommended,_that.optimization,_that.downloadUrl,_that.isDownloaded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AIModelId modelId,  String sizeLabel,  int sizeBytes,  AIModelTier tier,  bool isRecommended,  AIModelOptimization optimization,  String downloadUrl,  bool isDownloaded)?  $default,) {final _that = this;
switch (_that) {
case _AIModelEntity() when $default != null:
return $default(_that.modelId,_that.sizeLabel,_that.sizeBytes,_that.tier,_that.isRecommended,_that.optimization,_that.downloadUrl,_that.isDownloaded);case _:
  return null;

}
}

}

/// @nodoc


class _AIModelEntity implements AIModelEntity {
  const _AIModelEntity({required this.modelId, required this.sizeLabel, required this.sizeBytes, required this.tier, required this.isRecommended, required this.optimization, required this.downloadUrl, this.isDownloaded = false});
  

@override final  AIModelId modelId;
/// Human-readable size string e.g. "586 MB", "1.7 GB".
@override final  String sizeLabel;
@override final  int sizeBytes;
@override final  AIModelTier tier;
@override final  bool isRecommended;
@override final  AIModelOptimization optimization;
/// Remote URL to download the model file.
@override final  String downloadUrl;
@override@JsonKey() final  bool isDownloaded;

/// Create a copy of AIModelEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AIModelEntityCopyWith<_AIModelEntity> get copyWith => __$AIModelEntityCopyWithImpl<_AIModelEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AIModelEntity&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.sizeLabel, sizeLabel) || other.sizeLabel == sizeLabel)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.optimization, optimization) || other.optimization == optimization)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.isDownloaded, isDownloaded) || other.isDownloaded == isDownloaded));
}


@override
int get hashCode => Object.hash(runtimeType,modelId,sizeLabel,sizeBytes,tier,isRecommended,optimization,downloadUrl,isDownloaded);

@override
String toString() {
  return 'AIModelEntity(modelId: $modelId, sizeLabel: $sizeLabel, sizeBytes: $sizeBytes, tier: $tier, isRecommended: $isRecommended, optimization: $optimization, downloadUrl: $downloadUrl, isDownloaded: $isDownloaded)';
}


}

/// @nodoc
abstract mixin class _$AIModelEntityCopyWith<$Res> implements $AIModelEntityCopyWith<$Res> {
  factory _$AIModelEntityCopyWith(_AIModelEntity value, $Res Function(_AIModelEntity) _then) = __$AIModelEntityCopyWithImpl;
@override @useResult
$Res call({
 AIModelId modelId, String sizeLabel, int sizeBytes, AIModelTier tier, bool isRecommended, AIModelOptimization optimization, String downloadUrl, bool isDownloaded
});




}
/// @nodoc
class __$AIModelEntityCopyWithImpl<$Res>
    implements _$AIModelEntityCopyWith<$Res> {
  __$AIModelEntityCopyWithImpl(this._self, this._then);

  final _AIModelEntity _self;
  final $Res Function(_AIModelEntity) _then;

/// Create a copy of AIModelEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modelId = null,Object? sizeLabel = null,Object? sizeBytes = null,Object? tier = null,Object? isRecommended = null,Object? optimization = null,Object? downloadUrl = null,Object? isDownloaded = null,}) {
  return _then(_AIModelEntity(
modelId: null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as AIModelId,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as AIModelTier,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,optimization: null == optimization ? _self.optimization : optimization // ignore: cast_nullable_to_non_nullable
as AIModelOptimization,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,isDownloaded: null == isDownloaded ? _self.isDownloaded : isDownloaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AIModelDownloadEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModelDownloadEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AIModelDownloadEvent()';
}


}

/// @nodoc
class $AIModelDownloadEventCopyWith<$Res>  {
$AIModelDownloadEventCopyWith(AIModelDownloadEvent _, $Res Function(AIModelDownloadEvent) __);
}


/// Adds pattern-matching-related methods to [AIModelDownloadEvent].
extension AIModelDownloadEventPatterns on AIModelDownloadEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AIModelDownloadProgress value)?  progress,TResult Function( AIModelDownloadComplete value)?  complete,TResult Function( AIModelDownloadFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AIModelDownloadProgress() when progress != null:
return progress(_that);case AIModelDownloadComplete() when complete != null:
return complete(_that);case AIModelDownloadFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AIModelDownloadProgress value)  progress,required TResult Function( AIModelDownloadComplete value)  complete,required TResult Function( AIModelDownloadFailed value)  failed,}){
final _that = this;
switch (_that) {
case AIModelDownloadProgress():
return progress(_that);case AIModelDownloadComplete():
return complete(_that);case AIModelDownloadFailed():
return failed(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AIModelDownloadProgress value)?  progress,TResult? Function( AIModelDownloadComplete value)?  complete,TResult? Function( AIModelDownloadFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AIModelDownloadProgress() when progress != null:
return progress(_that);case AIModelDownloadComplete() when complete != null:
return complete(_that);case AIModelDownloadFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( double value)?  progress,TResult Function( AIModelId modelId)?  complete,TResult Function( String message)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AIModelDownloadProgress() when progress != null:
return progress(_that.value);case AIModelDownloadComplete() when complete != null:
return complete(_that.modelId);case AIModelDownloadFailed() when failed != null:
return failed(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( double value)  progress,required TResult Function( AIModelId modelId)  complete,required TResult Function( String message)  failed,}) {final _that = this;
switch (_that) {
case AIModelDownloadProgress():
return progress(_that.value);case AIModelDownloadComplete():
return complete(_that.modelId);case AIModelDownloadFailed():
return failed(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( double value)?  progress,TResult? Function( AIModelId modelId)?  complete,TResult? Function( String message)?  failed,}) {final _that = this;
switch (_that) {
case AIModelDownloadProgress() when progress != null:
return progress(_that.value);case AIModelDownloadComplete() when complete != null:
return complete(_that.modelId);case AIModelDownloadFailed() when failed != null:
return failed(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class AIModelDownloadProgress implements AIModelDownloadEvent {
  const AIModelDownloadProgress(this.value);
  

 final  double value;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIModelDownloadProgressCopyWith<AIModelDownloadProgress> get copyWith => _$AIModelDownloadProgressCopyWithImpl<AIModelDownloadProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModelDownloadProgress&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'AIModelDownloadEvent.progress(value: $value)';
}


}

/// @nodoc
abstract mixin class $AIModelDownloadProgressCopyWith<$Res> implements $AIModelDownloadEventCopyWith<$Res> {
  factory $AIModelDownloadProgressCopyWith(AIModelDownloadProgress value, $Res Function(AIModelDownloadProgress) _then) = _$AIModelDownloadProgressCopyWithImpl;
@useResult
$Res call({
 double value
});




}
/// @nodoc
class _$AIModelDownloadProgressCopyWithImpl<$Res>
    implements $AIModelDownloadProgressCopyWith<$Res> {
  _$AIModelDownloadProgressCopyWithImpl(this._self, this._then);

  final AIModelDownloadProgress _self;
  final $Res Function(AIModelDownloadProgress) _then;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(AIModelDownloadProgress(
null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class AIModelDownloadComplete implements AIModelDownloadEvent {
  const AIModelDownloadComplete(this.modelId);
  

 final  AIModelId modelId;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIModelDownloadCompleteCopyWith<AIModelDownloadComplete> get copyWith => _$AIModelDownloadCompleteCopyWithImpl<AIModelDownloadComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModelDownloadComplete&&(identical(other.modelId, modelId) || other.modelId == modelId));
}


@override
int get hashCode => Object.hash(runtimeType,modelId);

@override
String toString() {
  return 'AIModelDownloadEvent.complete(modelId: $modelId)';
}


}

/// @nodoc
abstract mixin class $AIModelDownloadCompleteCopyWith<$Res> implements $AIModelDownloadEventCopyWith<$Res> {
  factory $AIModelDownloadCompleteCopyWith(AIModelDownloadComplete value, $Res Function(AIModelDownloadComplete) _then) = _$AIModelDownloadCompleteCopyWithImpl;
@useResult
$Res call({
 AIModelId modelId
});




}
/// @nodoc
class _$AIModelDownloadCompleteCopyWithImpl<$Res>
    implements $AIModelDownloadCompleteCopyWith<$Res> {
  _$AIModelDownloadCompleteCopyWithImpl(this._self, this._then);

  final AIModelDownloadComplete _self;
  final $Res Function(AIModelDownloadComplete) _then;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? modelId = null,}) {
  return _then(AIModelDownloadComplete(
null == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as AIModelId,
  ));
}


}

/// @nodoc


class AIModelDownloadFailed implements AIModelDownloadEvent {
  const AIModelDownloadFailed(this.message);
  

 final  String message;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AIModelDownloadFailedCopyWith<AIModelDownloadFailed> get copyWith => _$AIModelDownloadFailedCopyWithImpl<AIModelDownloadFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AIModelDownloadFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'AIModelDownloadEvent.failed(message: $message)';
}


}

/// @nodoc
abstract mixin class $AIModelDownloadFailedCopyWith<$Res> implements $AIModelDownloadEventCopyWith<$Res> {
  factory $AIModelDownloadFailedCopyWith(AIModelDownloadFailed value, $Res Function(AIModelDownloadFailed) _then) = _$AIModelDownloadFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$AIModelDownloadFailedCopyWithImpl<$Res>
    implements $AIModelDownloadFailedCopyWith<$Res> {
  _$AIModelDownloadFailedCopyWithImpl(this._self, this._then);

  final AIModelDownloadFailed _self;
  final $Res Function(AIModelDownloadFailed) _then;

/// Create a copy of AIModelDownloadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(AIModelDownloadFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
