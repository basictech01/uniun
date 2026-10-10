import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import 'package:uniun/core/enum/gana_input_type.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/enum/gana_trigger_preset.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/domain/entities/group/group_entity.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/private_group/private_group_entity.dart';
import 'package:uniun/domain/usecases/dm_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/gana_usecases.dart';
import 'package:uniun/domain/usecases/get_groups_usecase.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/private_group_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uuid/uuid.dart';

part 'gana_form_event.dart';
part 'gana_form_state.dart';

@injectable
class GanaFormBloc extends Bloc<GanaFormEvent, GanaFormState> {
  final UpsertGanaUseCase _upsert;
  final GetGanaByIdUseCase _getById;
  final DeleteGanaUseCase _delete;
  final GetManasListUseCase _getManases;
  final GetGroupsUseCase _getGroups;
  final GetPrivateGroupsUsecase _getPrivateGroups;
  final GetDmConversationsUseCase _getDms;
  final GetAllFollowedNotesUseCase _getFollowed;
  final GetProfileUseCase _getProfile;
  final RequestProfileFetchUseCase _requestProfileFetch;

  GanaFormBloc(
    this._upsert,
    this._getById,
    this._delete,
    this._getManases,
    this._getGroups,
    this._getPrivateGroups,
    this._getDms,
    this._getFollowed,
    this._getProfile,
    this._requestProfileFetch,
  ) : super(const GanaFormState()) {
    on<GanaFormLoadEvent>(_onLoad);
    on<GanaFormRefreshManasesEvent>((event, emit) async {
      final result = await _getManases.call();
      result.fold((_) {}, (manases) => emit(state.copyWith(manases: manases)));
    });
    on<GanaFormNameChangedEvent>((e, em) =>
        em(state.copyWith(name: e.value, clearError: true)));
    on<GanaFormToggleManasEvent>(_onToggleManas);
    on<GanaFormSelectBrahmaEvent>(
      (event, emit) => emit(state.copyWith(clearSelectedManasId: true)),
    );
    on<GanaFormTaskPromptChangedEvent>(
        (e, em) => em(state.copyWith(taskPrompt: e.value)));
    on<GanaFormInputTypeChangedEvent>(_onInputType);
    on<GanaFormInputRefChangedEvent>(
        (e, em) => em(state.copyWith(inputRefId: e.value)));
    on<GanaFormOutputTypeChangedEvent>(_onOutputType);
    on<GanaFormOutputRefChangedEvent>(_onOutputRef);
    on<GanaFormModelChangedEvent>((e, em) => em(state.copyWith(
          desiredModelId: e.value,
          desiredBackend: e.backend,
          clearModel: e.value == null,
        )));
    on<GanaFormReactiveToggleEvent>(
        (e, em) => em(state.copyWith(triggerReactive: e.value)));
    on<GanaFormIntervalChangedEvent>(
        (e, em) => em(state.copyWith(triggerIntervalMinutes: e.value, clearInterval: e.value == null)));
    on<GanaFormTriggerModeChangedEvent>((e, em) {
      // Switching to one-shot voids the interval AND the maxOutputs cap
      // — both are recurring-only. Persisting them misleads the UI.
      if (e.value == GanaTriggerMode.oneShot) {
        em(state.copyWith(
          triggerMode: e.value,
          clearInterval: true,
          clearMaxOutputs: true,
        ));
      } else {
        em(state.copyWith(triggerMode: e.value));
      }
    });
    on<GanaFormMaxOutputsChangedEvent>(
        (e, em) => em(state.copyWith(
              maxOutputs: e.value,
              clearMaxOutputs: e.value == null,
            )));
    on<GanaFormTriggerPresetChangedEvent>(_onTriggerPreset);
    on<GanaFormEnabledToggleEvent>(
        (e, em) => em(state.copyWith(enabled: e.value)));
    on<GanaFormSubmitEvent>(_onSubmit, transformer: droppable());
    on<GanaFormDeleteEvent>(_onDelete, transformer: droppable());
  }

  Future<void> _onLoad(
      GanaFormLoadEvent event, Emitter<GanaFormState> emit) async {
    emit(state.copyWith(status: GanaFormStatus.loading));

    // Load picker pools in parallel.
    final manasFuture = _getManases.call();
    final groupsFuture = _getGroups.call();
    final dmsFuture = _getDms.call();
    final followedFuture = _getFollowed.call();
    // Private groups are a stream; take first emission.
    final privateGroups =
        await _getPrivateGroups.execute().first.catchError((_) =>
            <PrivateGroupEntity>[]);

    final manases = (await manasFuture)
        .fold<List<ManasEntity>>((_) => const [], (l) => l);
    final groups = (await groupsFuture)
        .fold<List<GroupEntity>>((_) => const [], (l) => l);
    final dms = (await dmsFuture)
        .fold<List<DmConversationEntity>>((_) => const [], (l) => l);
    final followed = (await followedFuture)
        .fold<List<FollowedNoteEntity>>((_) => const [], (l) => l);

    // Resolve peer display names for the DM picker so it shows the same
    // username the User Profile page shows. Missing profiles are nudged
    // for a Kind-0 fetch; the form is one-shot (no live watch) so users
    // may need to reopen the form after the profile lands.
    final dmDisplayNames = <String, String>{};
    for (final d in dms) {
      final result = await _getProfile.call(d.otherPubkey);
      final name = result.fold<String?>(
        (_) => null,
        (p) => (p.name?.trim().isNotEmpty == true)
            ? p.name
            : (p.username?.trim().isNotEmpty == true ? p.username : null),
      );
      if (name != null) {
        dmDisplayNames[d.otherPubkey] = name;
      } else {
        unawaited(_requestProfileFetch.call(d.otherPubkey));
      }
    }

    if (event.ganaId == null) {
      emit(state.copyWith(
        status: GanaFormStatus.ready,
        isEditMode: false,
        ganaId: const Uuid().v4(),
        createdAt: DateTime.now(),
        manases: manases,
        groups: groups,
        privateGroups: privateGroups,
        dmConversations: dms,
        dmDisplayNames: dmDisplayNames,
        followedNotes: followed,
      ));
      return;
    }

    final res = await _getById.call(event.ganaId!);
    final gana = res.fold<GanaEntity?>((_) => null, (g) => g);
    if (gana == null) {
      emit(state.copyWith(
        status: GanaFormStatus.error,
        errorMessage: 'Gana not found',
      ));
      return;
    }

    emit(state.copyWith(
      status: GanaFormStatus.ready,
      isEditMode: true,
      ganaId: gana.ganaId,
      name: gana.name,
      selectedManasId: gana.manasIds.isEmpty ? null : gana.manasIds.first,
      taskPrompt: gana.taskPrompt,
      inputType: gana.inputType,
      inputRefId: gana.inputRefId,
      outputType: gana.outputType,
      outputGroupId: gana.outputGroupId,
      outputPrivateGroupId: gana.outputPrivateGroupId,
      outputDmConversationId: gana.outputDmConversationId,
      desiredModelId: gana.desiredModelId,
      desiredBackend: gana.desiredBackend,
      triggerReactive: gana.triggerReactive,
      triggerIntervalMinutes: gana.triggerIntervalMinutes,
      triggerMode: gana.triggerMode,
      maxOutputs: gana.maxOutputs,
      enabled: gana.enabled,
      createdAt: gana.createdAt,
      manases: manases,
      groups: groups,
      privateGroups: privateGroups,
      dmConversations: dms,
      dmDisplayNames: dmDisplayNames,
      followedNotes: followed,
    ));
  }

  void _onToggleManas(
      GanaFormToggleManasEvent event, Emitter<GanaFormState> emit) {
    // Single-select: tapping the active Manas clears it; tapping another
    // replaces the selection.
    if (state.selectedManasId == event.manasId) {
      emit(state.copyWith(clearSelectedManasId: true));
    } else {
      emit(state.copyWith(selectedManasId: event.manasId));
    }
  }

  void _onInputType(
      GanaFormInputTypeChangedEvent event, Emitter<GanaFormState> emit) {
    // Changing input type clears the ref (it's type-specific) and forces
    // re-pick. Standalone (null) also clears reactive trigger.
    emit(state.copyWith(
      inputType: event.value,
      clearInputType: event.value == null,
      inputRefId: null,
      clearInputRefId: true,
      triggerReactive: event.value == null ? false : state.triggerReactive,
    ));
  }

  void _onOutputType(
      GanaFormOutputTypeChangedEvent event, Emitter<GanaFormState> emit) {
    emit(state.copyWith(
      outputType: event.value,
      outputGroupId: null,
      outputPrivateGroupId: null,
      outputDmConversationId: null,
      clearOutputGroupId: true,
      clearOutputPrivateGroupId: true,
      clearOutputDmConversationId: true,
    ));
  }

  void _onOutputRef(
      GanaFormOutputRefChangedEvent event, Emitter<GanaFormState> emit) {
    // Set exactly the field that matches the current outputType.
    switch (state.outputType) {
      case GanaOutputType.feed:
        // No ref for feed; clear all.
        emit(state.copyWith(
          clearOutputGroupId: true,
          clearOutputPrivateGroupId: true,
          clearOutputDmConversationId: true,
        ));
        return;
      case GanaOutputType.group:
        emit(state.copyWith(outputGroupId: event.value as String?));
        return;
      case GanaOutputType.privateGroup:
        emit(state.copyWith(outputPrivateGroupId: event.value as String?));
        return;
      case GanaOutputType.dm:
        emit(state.copyWith(outputDmConversationId: event.value as int?));
        return;
    }
  }

  /// Fold a preset back into the raw (mode, reactive, interval) triple.
  /// Interval / maxOutputs are preserved when switching between recurring
  /// presets so a half-filled value isn't lost mid-edit; one-shot presets
  /// void both because they're recurring-only.
  void _onTriggerPreset(GanaFormTriggerPresetChangedEvent event,
      Emitter<GanaFormState> emit) {
    switch (event.value) {
      case GanaTriggerPreset.onceOnEnable:
        emit(state.copyWith(
          triggerMode: GanaTriggerMode.oneShot,
          triggerReactive: false,
          clearInterval: true,
          clearMaxOutputs: true,
        ));
      case GanaTriggerPreset.onceOnFirstMessage:
        emit(state.copyWith(
          triggerMode: GanaTriggerMode.oneShot,
          triggerReactive: true,
          clearInterval: true,
          clearMaxOutputs: true,
        ));
      case GanaTriggerPreset.everyMessage:
        emit(state.copyWith(
          triggerMode: GanaTriggerMode.recurring,
          triggerReactive: true,
          clearInterval: true,
        ));
      case GanaTriggerPreset.onSchedule:
        emit(state.copyWith(
          triggerMode: GanaTriggerMode.recurring,
          triggerReactive: false,
          // Default interval to 5min when missing. Required for fromFields()
          // to resolve back to onSchedule on the next rebuild; without it
          // the radio appears un-selected because the state collapses to no
          // preset.
          triggerIntervalMinutes: state.triggerIntervalMinutes ?? 5,
        ));
      case GanaTriggerPreset.messageOrSchedule:
        emit(state.copyWith(
          triggerMode: GanaTriggerMode.recurring,
          triggerReactive: true,
          // Same as onSchedule above — interval is what disambiguates this
          // preset from everyMessage in fromFields().
          triggerIntervalMinutes: state.triggerIntervalMinutes ?? 5,
        ));
    }
  }

  Future<void> _onSubmit(
      GanaFormSubmitEvent event, Emitter<GanaFormState> emit) async {
    if (!state.canSave) return;
    emit(state.copyWith(status: GanaFormStatus.saving, clearError: true));

    final now = DateTime.now();
    final entity = GanaEntity(
      ganaId: state.ganaId ?? const Uuid().v4(),
      name: state.name.trim(),
      manasIds:
          state.selectedManasId == null ? const [] : [state.selectedManasId!],
      taskPrompt: state.taskPrompt.trim(),
      inputType: state.inputType,
      inputRefId: state.inputRefId,
      outputType: state.outputType,
      outputGroupId: state.outputGroupId,
      outputPrivateGroupId: state.outputPrivateGroupId,
      outputDmConversationId: state.outputDmConversationId,
      desiredModelId: state.desiredModelId,
      desiredBackend: state.desiredBackend,
      triggerReactive: state.triggerReactive,
      triggerIntervalMinutes: state.triggerIntervalMinutes,
      triggerMode: state.triggerMode,
      maxOutputs: state.triggerMode == GanaTriggerMode.recurring
          ? state.maxOutputs
          : null,
      enabled: state.enabled,
      createdAt: state.createdAt ?? now,
      updatedAt: now,
    );

    final res = await _upsert.call(entity);
    res.fold(
      (f) => emit(state.copyWith(
          status: GanaFormStatus.error, errorMessage: f.toString())),
      (_) => emit(state.copyWith(status: GanaFormStatus.saved)),
    );
  }

  Future<void> _onDelete(
      GanaFormDeleteEvent event, Emitter<GanaFormState> emit) async {
    final id = state.ganaId;
    if (id == null) return;
    emit(state.copyWith(status: GanaFormStatus.saving));
    final r = await _delete.call(id);
    r.fold(
      (f) => emit(state.copyWith(
          status: GanaFormStatus.error, errorMessage: f.toString())),
      (_) => emit(state.copyWith(status: GanaFormStatus.deleted)),
    );
  }
}
