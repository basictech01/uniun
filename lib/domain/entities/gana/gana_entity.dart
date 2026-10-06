import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/gana_input_type.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';

part 'gana_entity.freezed.dart';

@freezed
abstract class GanaEntity with _$GanaEntity {
  const factory GanaEntity({
    required String ganaId,
    required String name,
    @Default(<String>[]) List<String> manasIds,
    required String taskPrompt,

    // Input
    GanaInputType? inputType,
    String? inputRefId,

    // Output
    required GanaOutputType outputType,
    String? outputGroupId,
    String? outputPrivateGroupId,
    int? outputDmConversationId,

    // Model preference
    String? desiredModelId,

    /// Which backend [desiredModelId] belongs to. Null on legacy rows and on
    /// rows that predate cloud support — treated as local for compatibility.
    LlmBackendType? desiredBackend,

    // Triggers
    @Default(false) bool triggerReactive,
    int? triggerIntervalMinutes,
    @Default(GanaTriggerMode.recurring) GanaTriggerMode triggerMode,

    /// Required for recurring mode (1..1000). When set, the engine
    /// auto-disables the Gana once it has produced this many successful
    /// publishes. Null/ignored for one-shot.
    int? maxOutputs,

    // Master switch
    @Default(false) bool enabled,

    // Cursor
    String? lastProcessedEventId,
    DateTime? lastProcessedCreated,
    DateTime? lastRunAt,

    // Lifetime run counters (per device)
    @Default(0) int runsSucceeded,
    @Default(0) int runsFailed,
    @Default(0) int runsSkipped,

    // Metadata
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GanaEntity;
}
