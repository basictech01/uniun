import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/gana_input_type.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/enum/gana_trigger_preset.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/group/group_entity.dart';
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
import 'package:uniun/features/shiv/gana/form/bloc/gana_form_bloc.dart';

import '../../../../../_helpers/fixtures.dart';

class _MockUpsert extends Mock implements UpsertGanaUseCase {}

class _MockGetById extends Mock implements GetGanaByIdUseCase {}

class _MockDelete extends Mock implements DeleteGanaUseCase {}

class _MockGetManases extends Mock implements GetManasListUseCase {}

class _MockGetGroups extends Mock implements GetGroupsUseCase {}

class _MockGetPrivateGroups extends Mock implements GetPrivateGroupsUsecase {}

class _MockGetDms extends Mock implements GetDmConversationsUseCase {}

class _MockGetFollowed extends Mock implements GetAllFollowedNotesUseCase {}

class _MockGetProfile extends Mock implements GetProfileUseCase {}

class _MockRequestProfileFetch extends Mock
    implements RequestProfileFetchUseCase {}

GanaEntity _cloudGana({String ganaId = 'g-1'}) => GanaEntity(
      ganaId: ganaId,
      name: 'Digest bot',
      manasIds: const ['m-1'],
      taskPrompt: 'Summarize',
      outputType: GanaOutputType.feed,
      desiredModelId: 'claude-cloud-mini',
      desiredBackend: LlmBackendType.uniunCloud,
      triggerMode: GanaTriggerMode.oneShot,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Covers: [GanaFormBloc] model-override event handling (local/cloud/clear)
/// and its round-trip through load (edit mode) + submit (upsert payload).
void main() {
  setUpAll(() {
    registerFallbackValue(_cloudGana());
  });

  late _MockUpsert upsert;
  late _MockGetById getById;
  late _MockDelete delete;
  late _MockGetManases getManases;
  late _MockGetGroups getGroups;
  late _MockGetPrivateGroups getPrivateGroups;
  late _MockGetDms getDms;
  late _MockGetFollowed getFollowed;
  late _MockGetProfile getProfile;
  late _MockRequestProfileFetch requestProfileFetch;

  GanaFormBloc build() => GanaFormBloc(
        upsert,
        getById,
        delete,
        getManases,
        getGroups,
        getPrivateGroups,
        getDms,
        getFollowed,
        getProfile,
        requestProfileFetch,
      );

  setUp(() {
    upsert = _MockUpsert();
    getById = _MockGetById();
    delete = _MockDelete();
    getManases = _MockGetManases();
    getGroups = _MockGetGroups();
    getPrivateGroups = _MockGetPrivateGroups();
    getDms = _MockGetDms();
    getFollowed = _MockGetFollowed();
    getProfile = _MockGetProfile();
    requestProfileFetch = _MockRequestProfileFetch();

    when(() => getManases.call())
        .thenAnswer((_) async => const Right(<ManasEntity>[]));
    when(() => getGroups.call())
        .thenAnswer((_) async => const Right(<GroupEntity>[]));
    when(() => getPrivateGroups.execute())
        .thenAnswer((_) => Stream.value(const <PrivateGroupEntity>[]));
    when(() => getDms.call())
        .thenAnswer((_) async => const Right(<DmConversationEntity>[]));
    when(() => getFollowed.call())
        .thenAnswer((_) async => const Right(<FollowedNoteEntity>[]));
    when(() => upsert.call(any()))
        .thenAnswer((i) async => Right(i.positionalArguments.first as GanaEntity));
  });

  group('GanaFormModelChangedEvent', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'picking a local model sets desiredModelId + desiredBackend=local',
      build: build,
      act: (b) => b.add(const GanaFormModelChangedEvent(
        'qwen3_06b',
        backend: LlmBackendType.localGemma,
      )),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.desiredModelId, 'desiredModelId', 'qwen3_06b')
            .having((s) => s.desiredBackend, 'desiredBackend',
                LlmBackendType.localGemma),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'picking a cloud model sets desiredModelId + desiredBackend=uniunCloud',
      build: build,
      act: (b) => b.add(const GanaFormModelChangedEvent(
        'claude-cloud-mini',
        backend: LlmBackendType.uniunCloud,
      )),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.desiredModelId, 'desiredModelId',
                'claude-cloud-mini')
            .having((s) => s.desiredBackend, 'desiredBackend',
                LlmBackendType.uniunCloud),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'picking "use active" (null) clears both desiredModelId and desiredBackend',
      build: build,
      seed: () => const GanaFormState(
        desiredModelId: 'claude-cloud-mini',
        desiredBackend: LlmBackendType.uniunCloud,
      ),
      act: (b) => b.add(const GanaFormModelChangedEvent(null)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.desiredModelId, 'desiredModelId', isNull)
            .having((s) => s.desiredBackend, 'desiredBackend', isNull),
      ],
    );
  });

  group('load (edit mode) round-trips desiredBackend', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'a cloud-pinned Gana loads with desiredBackend=uniunCloud',
      build: build,
      setUp: () {
        when(() => getById.call('g-1'))
            .thenAnswer((_) async => Right(_cloudGana()));
      },
      act: (b) => b.add(const GanaFormLoadEvent('g-1')),
      verify: (b) {
        expect(b.state.desiredModelId, 'claude-cloud-mini');
        expect(b.state.desiredBackend, LlmBackendType.uniunCloud);
      },
    );
  });

  group('Manas picker refresh and Brahma scope', () {
    final newManas = ManasEntity(
      manasId: 'm-new',
      name: 'New collection',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'returning from Manas creation keeps the unsaved Gana draft and refreshes the picker',
      build: build,
      act: (b) async {
        b.add(const GanaFormLoadEvent(null));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        final originalId = b.state.ganaId;
        b.add(const GanaFormNameChangedEvent('My Gana'));
        b.add(const GanaFormTaskPromptChangedEvent('Summarize'));
        when(
          () => getManases.call(),
        ).thenAnswer((_) async => Right([newManas]));
        b.add(const GanaFormRefreshManasesEvent());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(b.state.ganaId, originalId);
      },
      verify: (b) {
        expect(b.state.status, GanaFormStatus.ready);
        expect(b.state.isEditMode, isFalse);
        expect(b.state.name, 'My Gana');
        expect(b.state.taskPrompt, 'Summarize');
        expect(b.state.manases.single.manasId, 'm-new');
        verifyNever(() => getById.call(any()));
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'refresh failure preserves the draft and existing picker',
      build: build,
      seed: () => const GanaFormState(
        status: GanaFormStatus.ready,
        ganaId: 'draft-gana',
        name: 'Keep me',
      ),
      setUp: () => when(
        () => getManases.call(),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('offline'))),
      act: (b) => b.add(const GanaFormRefreshManasesEvent()),
      expect: () => [],
      verify: (b) => expect(b.state.name, 'Keep me'),
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'Brahma selection clears a selected Manas',
      build: build,
      seed: () => const GanaFormState(selectedManasId: 'm-old'),
      act: (b) => b.add(const GanaFormSelectBrahmaEvent()),
      verify: (b) => expect(b.state.selectedManasId, isNull),
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a Gana can save with Brahma as its knowledge scope',
      build: build,
      seed: () => const GanaFormState(
        name: 'Brahma Gana',
        taskPrompt: 'Summarize',
        triggerMode: GanaTriggerMode.oneShot,
      ),
      act: (b) => b.add(const GanaFormSubmitEvent()),
      verify: (_) {
        final saved =
            verify(() => upsert.call(captureAny())).captured.single
                as GanaEntity;
        expect(saved.manasIds, isEmpty);
      },
    );
  });

  group('submit persists the cloud override', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'canSave gana with a cloud model pin upserts an entity carrying it',
      build: build,
      act: (b) async {
        b.add(const GanaFormLoadEvent(null));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        b.add(const GanaFormNameChangedEvent('Digest bot'));
        b.add(const GanaFormTaskPromptChangedEvent('Summarize my notes'));
        b.add(const GanaFormToggleManasEvent('m-1'));
        // Standalone one-shot: no input source, fires on enable — needs no
        // interval/maxOutputs to satisfy canSave.
        b.add(const GanaFormTriggerPresetChangedEvent(
            GanaTriggerPreset.onceOnEnable));
        b.add(const GanaFormModelChangedEvent(
          'claude-cloud-mini',
          backend: LlmBackendType.uniunCloud,
        ));
        b.add(const GanaFormSubmitEvent());
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        final captured =
            verify(() => upsert.call(captureAny())).captured.single
                as GanaEntity;
        expect(captured.desiredModelId, 'claude-cloud-mini');
        expect(captured.desiredBackend, LlmBackendType.uniunCloud);
        expect(captured.name, 'Digest bot');
      },
    );
  });

  group('load — create mode DM display name resolution', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'a profile with a name uses it directly',
      build: () {
        when(() => getDms.call()).thenAnswer(
            (_) async => const Right([DmConversationEntity(id: 1, otherPubkey: 'pk1')]));
        when(() => getProfile.call('pk1'))
            .thenAnswer((_) async => Right(aProfile(name: 'Alice')));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.dmDisplayNames['pk1'], 'Alice');
        verifyNever(() => requestProfileFetch.call(any()));
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a profile with no name falls back to username',
      build: () {
        when(() => getDms.call()).thenAnswer(
            (_) async => const Right([DmConversationEntity(id: 1, otherPubkey: 'pk1')]));
        when(() => getProfile.call('pk1')).thenAnswer(
            (_) async => Right(aProfile(name: null, username: 'alice_handle')));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.dmDisplayNames['pk1'], 'alice_handle');
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'no name and no username requests a profile fetch, no display name '
      'entry',
      build: () {
        when(() => getDms.call()).thenAnswer(
            (_) async => const Right([DmConversationEntity(id: 1, otherPubkey: 'pk1')]));
        when(() => getProfile.call('pk1'))
            .thenAnswer((_) async => Right(anAnonymousProfile(pubkey: 'pk1')));
        when(() => requestProfileFetch.call('pk1'))
            .thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.dmDisplayNames.containsKey('pk1'), isFalse);
        verify(() => requestProfileFetch.call('pk1')).called(1);
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a getProfile failure also requests a fetch (treated as missing)',
      build: () {
        when(() => getDms.call()).thenAnswer(
            (_) async => const Right([DmConversationEntity(id: 1, otherPubkey: 'pk1')]));
        when(() => getProfile.call('pk1'))
            .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
        when(() => requestProfileFetch.call('pk1'))
            .thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.dmDisplayNames.containsKey('pk1'), isFalse);
        verify(() => requestProfileFetch.call('pk1')).called(1);
      },
    );
  });

  group('load — private groups + create-mode defaults', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'a private-groups stream failure degrades to an empty list',
      build: () {
        when(() => getPrivateGroups.execute())
            .thenAnswer((_) => Stream.error(Exception('stream broke')));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.status, GanaFormStatus.ready);
        expect(b.state.privateGroups, isEmpty);
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'create mode (ganaId: null) seeds a fresh ganaId/createdAt, not edit '
      'mode',
      build: build,
      act: (b) => b.add(const GanaFormLoadEvent(null)),
      verify: (b) {
        expect(b.state.isEditMode, isFalse);
        expect(b.state.ganaId, isNotNull);
        expect(b.state.createdAt, isNotNull);
        expect(b.state.status, GanaFormStatus.ready);
      },
    );
  });

  group('load — edit mode', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'a gana id that resolves to nothing surfaces an error status',
      build: () {
        when(() => getById.call('missing'))
            .thenAnswer((_) async => const Left(Failure.errorFailure('not found')));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent('missing')),
      verify: (b) {
        expect(b.state.status, GanaFormStatus.error);
        expect(b.state.errorMessage, 'Gana not found');
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a found gana with no manasIds leaves selectedManasId null',
      build: () {
        when(() => getById.call('g-2')).thenAnswer((_) async => Right(GanaEntity(
              ganaId: 'g-2',
              name: 'x',
              manasIds: const [],
              taskPrompt: 'p',
              outputType: GanaOutputType.feed,
              triggerMode: GanaTriggerMode.oneShot,
              createdAt: DateTime(2026, 1, 1),
              updatedAt: DateTime(2026, 1, 1),
            )));
        return build();
      },
      act: (b) => b.add(const GanaFormLoadEvent('g-2')),
      verify: (b) {
        expect(b.state.isEditMode, isTrue);
        expect(b.state.selectedManasId, isNull);
      },
    );
  });

  group('_onToggleManas', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'selects an unselected Manas',
      build: build,
      act: (b) => b.add(const GanaFormToggleManasEvent('m-1')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.selectedManasId, 'selected', 'm-1'),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'tapping the already-selected Manas clears the selection',
      build: build,
      seed: () => const GanaFormState(selectedManasId: 'm-1'),
      act: (b) => b.add(const GanaFormToggleManasEvent('m-1')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.selectedManasId, 'selected', isNull),
      ],
    );
  });

  group('_onInputType', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'switching to standalone (null) clears the ref and forces '
      'triggerReactive off',
      build: build,
      seed: () => const GanaFormState(
        inputType: GanaInputType.user,
        inputRefId: 'ref1',
        triggerReactive: true,
      ),
      act: (b) => b.add(const GanaFormInputTypeChangedEvent(null)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.inputType, 'inputType', isNull)
            .having((s) => s.inputRefId, 'inputRefId', isNull)
            .having((s) => s.triggerReactive, 'triggerReactive', false),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'switching to a real input type clears the old ref but preserves '
      'triggerReactive',
      build: build,
      seed: () => const GanaFormState(
        inputType: GanaInputType.user,
        inputRefId: 'ref1',
        triggerReactive: true,
      ),
      act: (b) => b.add(const GanaFormInputTypeChangedEvent(GanaInputType.followedNote)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.inputType, 'inputType', GanaInputType.followedNote)
            .having((s) => s.inputRefId, 'inputRefId', isNull)
            .having((s) => s.triggerReactive, 'triggerReactive', true),
      ],
    );
  });

  group('_onOutputType', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'switching output type clears every output ref field',
      build: build,
      seed: () => const GanaFormState(
        outputType: GanaOutputType.group,
        outputGroupId: 'g1',
        outputPrivateGroupId: 'pg1',
        outputDmConversationId: 5,
      ),
      act: (b) => b.add(const GanaFormOutputTypeChangedEvent(GanaOutputType.dm)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.outputType, 'outputType', GanaOutputType.dm)
            .having((s) => s.outputGroupId, 'outputGroupId', isNull)
            .having((s) => s.outputPrivateGroupId, 'outputPrivateGroupId', isNull)
            .having((s) => s.outputDmConversationId, 'outputDmConversationId', isNull),
      ],
    );
  });

  group('_onOutputRef', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'feed output type clears all refs regardless of the given value',
      build: build,
      seed: () => const GanaFormState(
          outputType: GanaOutputType.feed, outputGroupId: 'stale'),
      act: (b) => b.add(const GanaFormOutputRefChangedEvent('ignored')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.outputGroupId, 'outputGroupId', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'group output type sets outputGroupId from a String value',
      build: build,
      seed: () => const GanaFormState(outputType: GanaOutputType.group),
      act: (b) => b.add(const GanaFormOutputRefChangedEvent('g-42')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.outputGroupId, 'outputGroupId', 'g-42'),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'privateGroup output type sets outputPrivateGroupId from a String '
      'value',
      build: build,
      seed: () => const GanaFormState(outputType: GanaOutputType.privateGroup),
      act: (b) => b.add(const GanaFormOutputRefChangedEvent('pg-42')),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.outputPrivateGroupId, 'outputPrivateGroupId', 'pg-42'),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'dm output type sets outputDmConversationId from an int value',
      build: build,
      seed: () => const GanaFormState(outputType: GanaOutputType.dm),
      act: (b) => b.add(const GanaFormOutputRefChangedEvent(7)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.outputDmConversationId, 'outputDmConversationId', 7),
      ],
    );
  });

  group('simple field-changed events', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'name changed clears any stale error',
      build: build,
      seed: () => const GanaFormState(errorMessage: 'stale'),
      act: (b) => b.add(const GanaFormNameChangedEvent('New name')),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.name, 'name', 'New name')
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'taskPrompt changed updates the prompt',
      build: build,
      act: (b) => b.add(const GanaFormTaskPromptChangedEvent('do the thing')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.taskPrompt, 'taskPrompt', 'do the thing'),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'inputRef changed updates inputRefId',
      build: build,
      act: (b) => b.add(const GanaFormInputRefChangedEvent('ref-9')),
      expect: () => [
        isA<GanaFormState>().having((s) => s.inputRefId, 'inputRefId', 'ref-9'),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'reactive toggle flips triggerReactive',
      build: build,
      act: (b) => b.add(const GanaFormReactiveToggleEvent(true)),
      expect: () => [
        isA<GanaFormState>().having((s) => s.triggerReactive, 'triggerReactive', true),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'interval changed to a value sets it',
      build: build,
      act: (b) => b.add(const GanaFormIntervalChangedEvent(15)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerIntervalMinutes, 'triggerIntervalMinutes', 15),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'interval changed to null clears it',
      build: build,
      seed: () => const GanaFormState(triggerIntervalMinutes: 15),
      act: (b) => b.add(const GanaFormIntervalChangedEvent(null)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerIntervalMinutes, 'triggerIntervalMinutes', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'switching triggerMode to oneShot voids interval AND maxOutputs',
      build: build,
      seed: () => const GanaFormState(
        triggerMode: GanaTriggerMode.recurring,
        triggerIntervalMinutes: 10,
        maxOutputs: 5,
      ),
      act: (b) => b.add(const GanaFormTriggerModeChangedEvent(GanaTriggerMode.oneShot)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'triggerMode', GanaTriggerMode.oneShot)
            .having((s) => s.triggerIntervalMinutes, 'triggerIntervalMinutes', isNull)
            .having((s) => s.maxOutputs, 'maxOutputs', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'switching triggerMode to recurring leaves interval/maxOutputs '
      'untouched',
      build: build,
      seed: () => const GanaFormState(
        triggerMode: GanaTriggerMode.oneShot,
        triggerIntervalMinutes: 10,
        maxOutputs: 5,
      ),
      act: (b) => b.add(const GanaFormTriggerModeChangedEvent(GanaTriggerMode.recurring)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerIntervalMinutes, 'triggerIntervalMinutes', 10)
            .having((s) => s.maxOutputs, 'maxOutputs', 5),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'maxOutputs changed to a value sets it',
      build: build,
      act: (b) => b.add(const GanaFormMaxOutputsChangedEvent(42)),
      expect: () => [
        isA<GanaFormState>().having((s) => s.maxOutputs, 'maxOutputs', 42),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'maxOutputs changed to null clears it',
      build: build,
      seed: () => const GanaFormState(maxOutputs: 42),
      act: (b) => b.add(const GanaFormMaxOutputsChangedEvent(null)),
      expect: () => [
        isA<GanaFormState>().having((s) => s.maxOutputs, 'maxOutputs', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'enabled toggle flips enabled',
      build: build,
      act: (b) => b.add(const GanaFormEnabledToggleEvent(true)),
      expect: () => [
        isA<GanaFormState>().having((s) => s.enabled, 'enabled', true),
      ],
    );
  });

  group('_onTriggerPreset', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'onceOnEnable: one-shot, not reactive, no interval/maxOutputs',
      build: build,
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.onceOnEnable)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'mode', GanaTriggerMode.oneShot)
            .having((s) => s.triggerReactive, 'reactive', false)
            .having((s) => s.triggerIntervalMinutes, 'interval', isNull)
            .having((s) => s.maxOutputs, 'maxOutputs', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'onceOnFirstMessage: one-shot, reactive',
      build: build,
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.onceOnFirstMessage)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'mode', GanaTriggerMode.oneShot)
            .having((s) => s.triggerReactive, 'reactive', true),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'everyMessage: recurring + reactive, interval cleared',
      build: build,
      seed: () => const GanaFormState(triggerIntervalMinutes: 30),
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.everyMessage)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'mode', GanaTriggerMode.recurring)
            .having((s) => s.triggerReactive, 'reactive', true)
            .having((s) => s.triggerIntervalMinutes, 'interval', isNull),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'onSchedule: recurring, not reactive, defaults interval to 5 when '
      'missing',
      build: build,
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.onSchedule)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'mode', GanaTriggerMode.recurring)
            .having((s) => s.triggerReactive, 'reactive', false)
            .having((s) => s.triggerIntervalMinutes, 'interval', 5),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'onSchedule preserves an existing interval instead of overwriting it',
      build: build,
      seed: () => const GanaFormState(triggerIntervalMinutes: 20),
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.onSchedule)),
      expect: () => [
        isA<GanaFormState>().having((s) => s.triggerIntervalMinutes, 'interval', 20),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'messageOrSchedule: recurring + reactive, defaults interval to 5',
      build: build,
      act: (b) => b.add(const GanaFormTriggerPresetChangedEvent(
          GanaTriggerPreset.messageOrSchedule)),
      expect: () => [
        isA<GanaFormState>()
            .having((s) => s.triggerMode, 'mode', GanaTriggerMode.recurring)
            .having((s) => s.triggerReactive, 'reactive', true)
            .having((s) => s.triggerIntervalMinutes, 'interval', 5),
      ],
    );
  });

  group('_onSubmit', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'canSave:false is a no-op — never calls upsert',
      build: build,
      seed: () => const GanaFormState(), // empty name/prompt -> canSave false
      act: (b) => b.add(const GanaFormSubmitEvent()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => upsert.call(any()));
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a recurring gana keeps maxOutputs on the persisted entity',
      build: build,
      seed: () => const GanaFormState(
        name: 'n',
        taskPrompt: 'p',
        selectedManasId: 'm1',
        triggerMode: GanaTriggerMode.recurring,
        triggerIntervalMinutes: 10,
        maxOutputs: 3,
      ),
      act: (b) => b.add(const GanaFormSubmitEvent()),
      verify: (_) {
        final captured =
            verify(() => upsert.call(captureAny())).captured.single as GanaEntity;
        expect(captured.maxOutputs, 3);
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'an upsert failure emits an error status with the message',
      build: build,
      seed: () => const GanaFormState(
        name: 'n',
        taskPrompt: 'p',
        selectedManasId: 'm1',
        triggerMode: GanaTriggerMode.oneShot,
      ),
      setUp: () {
        when(() => upsert.call(any()))
            .thenAnswer((_) async => const Left(Failure.errorFailure('disk full')));
      },
      act: (b) => b.add(const GanaFormSubmitEvent()),
      expect: () => [
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.saving),
        isA<GanaFormState>()
            .having((s) => s.status, 'status', GanaFormStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('disk full')),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'success emits saved status',
      build: build,
      seed: () => const GanaFormState(
        name: 'n',
        taskPrompt: 'p',
        selectedManasId: 'm1',
        triggerMode: GanaTriggerMode.oneShot,
      ),
      act: (b) => b.add(const GanaFormSubmitEvent()),
      expect: () => [
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.saving),
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.saved),
      ],
    );
  });

  group('_onDelete', () {
    blocTest<GanaFormBloc, GanaFormState>(
      'no ganaId — no-op',
      build: build,
      seed: () => const GanaFormState(),
      act: (b) => b.add(const GanaFormDeleteEvent()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => delete.call(any()));
      },
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'success emits deleted status',
      build: build,
      seed: () => const GanaFormState(ganaId: 'g-1'),
      setUp: () {
        when(() => delete.call('g-1')).thenAnswer((_) async => const Right(unit));
      },
      act: (b) => b.add(const GanaFormDeleteEvent()),
      expect: () => [
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.saving),
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.deleted),
      ],
    );

    blocTest<GanaFormBloc, GanaFormState>(
      'a failure emits an error status with the message',
      build: build,
      seed: () => const GanaFormState(ganaId: 'g-1'),
      setUp: () {
        when(() => delete.call('g-1'))
            .thenAnswer((_) async => const Left(Failure.errorFailure('not allowed')));
      },
      act: (b) => b.add(const GanaFormDeleteEvent()),
      expect: () => [
        isA<GanaFormState>().having((s) => s.status, 'status', GanaFormStatus.saving),
        isA<GanaFormState>()
            .having((s) => s.status, 'status', GanaFormStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('not allowed')),
      ],
    );
  });
}
