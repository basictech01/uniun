part of 'gana_form_bloc.dart';

enum GanaFormStatus { initial, loading, ready, saving, saved, deleted, error }

class GanaFormState {
  const GanaFormState({
    this.status = GanaFormStatus.initial,
    this.isEditMode = false,
    this.ganaId,
    this.name = '',
    this.selectedManasId,
    this.taskPrompt = '',
    this.inputType,
    this.inputRefId,
    this.outputType = GanaOutputType.feed,
    this.outputGroupId,
    this.outputPrivateGroupId,
    this.outputDmConversationId,
    this.desiredModelId,
    this.desiredBackend,
    this.triggerReactive = false,
    this.triggerIntervalMinutes,
    this.triggerMode = GanaTriggerMode.recurring,
    this.maxOutputs,
    this.enabled = false,
    this.createdAt,
    this.manases = const [],
    this.groups = const [],
    this.privateGroups = const [],
    this.dmConversations = const [],
    this.dmDisplayNames = const {},
    this.followedNotes = const [],
    this.errorMessage,
  });

  final GanaFormStatus status;
  final bool isEditMode;
  final String? ganaId;

  final String name;

  /// A selected Manas, or null for the whole Brahma knowledge base.
  final String? selectedManasId;
  final String taskPrompt;

  final GanaInputType? inputType;
  final String? inputRefId;

  final GanaOutputType outputType;
  final String? outputGroupId;
  final String? outputPrivateGroupId;
  final int? outputDmConversationId;

  final String? desiredModelId;
  final LlmBackendType? desiredBackend;

  final bool triggerReactive;
  final int? triggerIntervalMinutes;
  final GanaTriggerMode triggerMode;

  /// Recurring-only safety cap (1..1000). Ignored for one-shot. Required
  /// for recurring — otherwise a forgotten Gana publishes forever.
  final int? maxOutputs;

  final bool enabled;

  final DateTime? createdAt;

  // Picker pools — loaded once on form open.
  final List<ManasEntity> manases;
  final List<GroupEntity> groups;
  final List<PrivateGroupEntity> privateGroups;
  final List<DmConversationEntity> dmConversations;

  /// pubkeyHex → cached display name (profile.name ?? profile.username).
  /// Empty entry means the profile isn't in Isar yet; UI falls back to a
  /// short hex label until the profile arrives and _onLoad re-fires.
  final Map<String, String> dmDisplayNames;
  final List<FollowedNoteEntity> followedNotes;

  final String? errorMessage;

  /// Folds the raw (mode, reactive, interval) triple into the single preset
  /// the UI radio displays. Returns `null` mid-edit when the triple doesn't
  /// map cleanly to a preset (e.g. mode switched but interval not set yet).
  GanaTriggerPreset? get triggerPreset => GanaTriggerPreset.fromFields(
        mode: triggerMode,
        reactive: triggerReactive,
        intervalMinutes: triggerIntervalMinutes,
        inputType: inputType,
      );

  /// Save gating — minimum config the engine needs to make sense of the Gana.
  bool get canSave {
    if (name.trim().isEmpty) return false;
    if (taskPrompt.trim().isEmpty) return false;
    if (inputType != null && (inputRefId == null || inputRefId!.isEmpty)) {
      return false;
    }
    switch (outputType) {
      case GanaOutputType.feed:
        break;
      case GanaOutputType.group:
        if (outputGroupId == null) return false;
        break;
      case GanaOutputType.privateGroup:
        if (outputPrivateGroupId == null) return false;
        break;
      case GanaOutputType.dm:
        if (outputDmConversationId == null) return false;
        break;
    }
    // Trigger gating — every (mode, input) combo must have one valid
    // trigger so the Gana actually fires once enabled:
    //
    //   one-shot + standalone : fires immediately on enable (no extra gate)
    //   one-shot + input      : needs reactive on (fires on first match)
    //   recurring + standalone: needs interval (≥5 min)
    //   recurring + input     : needs reactive OR interval
    if (triggerMode == GanaTriggerMode.oneShot) {
      if (inputType != null && !triggerReactive) return false;
    } else {
      if (inputType == null) {
        if (triggerIntervalMinutes == null ||
            triggerIntervalMinutes! < 5) {
          return false;
        }
      } else {
        if (!triggerReactive &&
            (triggerIntervalMinutes == null ||
                triggerIntervalMinutes! < 5)) {
          return false;
        }
      }
      // Recurring also needs a max-outputs cap so the Gana can't run
      // forever if the user forgets about it. Hard ceiling at 1000.
      if (maxOutputs == null || maxOutputs! < 1 || maxOutputs! > 1000) {
        return false;
      }
    }
    return true;
  }

  /// Human-readable reason save is blocked. Returned only when [canSave]
  /// is false — UI shows this to explain what's missing. Null means
  /// "no reason; save should be possible".
  String? saveBlocker(AppLocalizations l10n) {
    if (name.trim().isEmpty) return l10n.ganaFormBlockerName;
    if (taskPrompt.trim().isEmpty) return l10n.ganaFormBlockerTask;
    if (inputType != null && (inputRefId == null || inputRefId!.isEmpty)) {
      return l10n.ganaFormBlockerInputRef;
    }
    switch (outputType) {
      case GanaOutputType.feed:
        break;
      case GanaOutputType.group:
        if (outputGroupId == null) return l10n.ganaFormBlockerOutputRef;
        break;
      case GanaOutputType.privateGroup:
        if (outputPrivateGroupId == null) return l10n.ganaFormBlockerOutputRef;
        break;
      case GanaOutputType.dm:
        if (outputDmConversationId == null) return l10n.ganaFormBlockerOutputRef;
        break;
    }
    if (triggerMode == GanaTriggerMode.oneShot) {
      if (inputType != null && !triggerReactive) {
        return l10n.ganaFormBlockerOneShotReactive;
      }
    } else {
      if (inputType == null &&
          (triggerIntervalMinutes == null ||
              triggerIntervalMinutes! < 5)) {
        return l10n.ganaFormBlockerInterval;
      }
      if (inputType != null &&
          !triggerReactive &&
          (triggerIntervalMinutes == null ||
              triggerIntervalMinutes! < 5)) {
        return l10n.ganaFormBlockerTrigger;
      }
      if (maxOutputs == null || maxOutputs! < 1 || maxOutputs! > 1000) {
        return l10n.ganaFormBlockerMaxOutputs;
      }
    }
    return null;
  }

  GanaFormState copyWith({
    GanaFormStatus? status,
    bool? isEditMode,
    String? ganaId,
    String? name,
    String? selectedManasId,
    bool clearSelectedManasId = false,
    String? taskPrompt,
    GanaInputType? inputType,
    bool clearInputType = false,
    String? inputRefId,
    bool clearInputRefId = false,
    GanaOutputType? outputType,
    String? outputGroupId,
    bool clearOutputGroupId = false,
    String? outputPrivateGroupId,
    bool clearOutputPrivateGroupId = false,
    int? outputDmConversationId,
    bool clearOutputDmConversationId = false,
    String? desiredModelId,
    bool clearModel = false,
    LlmBackendType? desiredBackend,
    bool? triggerReactive,
    int? triggerIntervalMinutes,
    bool clearInterval = false,
    GanaTriggerMode? triggerMode,
    int? maxOutputs,
    bool clearMaxOutputs = false,
    bool? enabled,
    DateTime? createdAt,
    List<ManasEntity>? manases,
    List<GroupEntity>? groups,
    List<PrivateGroupEntity>? privateGroups,
    List<DmConversationEntity>? dmConversations,
    Map<String, String>? dmDisplayNames,
    List<FollowedNoteEntity>? followedNotes,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GanaFormState(
      status: status ?? this.status,
      isEditMode: isEditMode ?? this.isEditMode,
      ganaId: ganaId ?? this.ganaId,
      name: name ?? this.name,
      selectedManasId: clearSelectedManasId
          ? null
          : (selectedManasId ?? this.selectedManasId),
      taskPrompt: taskPrompt ?? this.taskPrompt,
      inputType: clearInputType ? null : (inputType ?? this.inputType),
      inputRefId: clearInputRefId ? null : (inputRefId ?? this.inputRefId),
      outputType: outputType ?? this.outputType,
      outputGroupId: clearOutputGroupId
          ? null
          : (outputGroupId ?? this.outputGroupId),
      outputPrivateGroupId:
          clearOutputPrivateGroupId ? null : (outputPrivateGroupId ?? this.outputPrivateGroupId),
      outputDmConversationId: clearOutputDmConversationId
          ? null
          : (outputDmConversationId ?? this.outputDmConversationId),
      desiredModelId:
          clearModel ? null : (desiredModelId ?? this.desiredModelId),
      desiredBackend:
          clearModel ? null : (desiredBackend ?? this.desiredBackend),
      triggerReactive: triggerReactive ?? this.triggerReactive,
      triggerIntervalMinutes: clearInterval
          ? null
          : (triggerIntervalMinutes ?? this.triggerIntervalMinutes),
      triggerMode: triggerMode ?? this.triggerMode,
      maxOutputs:
          clearMaxOutputs ? null : (maxOutputs ?? this.maxOutputs),
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      manases: manases ?? this.manases,
      groups: groups ?? this.groups,
      privateGroups: privateGroups ?? this.privateGroups,
      dmConversations: dmConversations ?? this.dmConversations,
      dmDisplayNames: dmDisplayNames ?? this.dmDisplayNames,
      followedNotes: followedNotes ?? this.followedNotes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
