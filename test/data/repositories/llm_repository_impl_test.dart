import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/data/datasources/llm/local_llm_data_source.dart';
import 'package:uniun/data/datasources/llm/remote_llm_data_source.dart';
import 'package:uniun/data/repositories/llm_repository_impl.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';

class _MockLocal extends Mock implements LocalLlmDataSource {}

class _MockRemote extends Mock implements RemoteLlmDataSource {}

class _MockPrefs extends Mock implements LlmPreferencesDataSource {}

class _MockCloudAuth extends Mock implements UniunRepository {}

class _MockLocalSettings extends Mock implements AppSettingsStore {}

class _MockLocalCatalog extends Mock implements AIModelRepository {}

AIModelEntity _entry(AIModelId id) => AIModelEntity(
      modelId: id,
      sizeLabel: '1 GB',
      sizeBytes: 1000,
      tier: AIModelTier.balanced,
      isRecommended: false,
      optimization: AIModelOptimization.cpu,
      downloadUrl: 'https://example.com/$id',
    );

/// Covers: [LlmRepositoryImpl.generateOneShot] dispatch — default routing
/// follows the globally-active backend; `backendOverride` bypasses it
/// (Gana's per-agent cloud pin) without touching global preference reads;
/// `modelIdOverride` passes through to the chosen data source untouched.
void main() {
  setUpAll(() {
    registerFallbackValue(LlmTaskKind.extract);
    registerFallbackValue(AIModelId.qwen25_05b);
    registerFallbackValue(LlmBackendType.localGemma);
  });

  late _MockLocal local;
  late _MockRemote remote;
  late _MockPrefs prefs;
  late _MockCloudAuth cloudAuth;
  late _MockLocalSettings localSettings;
  late _MockLocalCatalog localCatalog;
  late LlmRepositoryImpl repo;

  setUp(() {
    local = _MockLocal();
    remote = _MockRemote();
    prefs = _MockPrefs();
    cloudAuth = _MockCloudAuth();
    localSettings = _MockLocalSettings();
    localCatalog = _MockLocalCatalog();
    repo = LlmRepositoryImpl(
      local,
      remote,
      prefs,
      cloudAuth,
      localSettings,
      localCatalog,
    );

    when(() => local.generateOneShot(
          prompt: any(named: 'prompt'),
          maxTokens: any(named: 'maxTokens'),
          kind: any(named: 'kind'),
          modelIdOverride: any(named: 'modelIdOverride'),
        )).thenAnswer((_) async => const Right('local reply'));
    when(() => remote.generateOneShot(
          prompt: any(named: 'prompt'),
          maxTokens: any(named: 'maxTokens'),
          kind: any(named: 'kind'),
          modelIdOverride: any(named: 'modelIdOverride'),
        )).thenAnswer((_) async => const Right('cloud reply'));
  });

  group('no override — follows the global active backend', () {
    test('activeBackend=local routes to LocalLlmDataSource', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);

      final result = await repo.generateOneShot(prompt: 'hi');

      expect(result, const Right('local reply'));
      verify(() => local.generateOneShot(
            prompt: 'hi',
            maxTokens: 1024,
            kind: LlmTaskKind.extract,
            modelIdOverride: null,
          )).called(1);
      verifyNever(() => remote.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            modelIdOverride: any(named: 'modelIdOverride'),
          ));
    });

    test('activeBackend=uniunCloud routes to RemoteLlmDataSource', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);

      final result = await repo.generateOneShot(prompt: 'hi');

      expect(result, const Right('cloud reply'));
      verify(() => remote.generateOneShot(
            prompt: 'hi',
            maxTokens: 1024,
            kind: LlmTaskKind.extract,
            modelIdOverride: null,
          )).called(1);
      verifyNever(() => local.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            modelIdOverride: any(named: 'modelIdOverride'),
          ));
    });
  });

  group('backendOverride bypasses the global preference', () {
    test('backendOverride=uniunCloud routes to remote even when the global '
        'active backend is local (Gana per-agent cloud pin)', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);

      final result = await repo.generateOneShot(
        prompt: 'summarize',
        kind: LlmTaskKind.gana,
        backendOverride: LlmBackendType.uniunCloud,
        modelIdOverride: 'claude-cloud-mini',
      );

      expect(result, const Right('cloud reply'));
      verify(() => remote.generateOneShot(
            prompt: 'summarize',
            maxTokens: 1024,
            kind: LlmTaskKind.gana,
            modelIdOverride: 'claude-cloud-mini',
          )).called(1);
      verifyNever(() => local.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            modelIdOverride: any(named: 'modelIdOverride'),
          ));
      // The override path never even reads the global preference.
      verifyNever(() => prefs.activeBackend);
    });

    test('backendOverride=localGemma routes to local even when the global '
        'active backend is cloud', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);

      final result = await repo.generateOneShot(
        prompt: 'summarize',
        backendOverride: LlmBackendType.localGemma,
      );

      expect(result, const Right('local reply'));
      verify(() => local.generateOneShot(
            prompt: 'summarize',
            maxTokens: 1024,
            kind: LlmTaskKind.extract,
            modelIdOverride: null,
          )).called(1);
    });
  });

  group('setActiveModel — local (issue #160 regression: switching between '
      'two already-downloaded models must re-link flutter_gemma, not just '
      'write settings)', () {
    setUp(() {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => localSettings.setActiveModelId(any()))
          .thenAnswer((_) async {});
    });

    test('writes the settings id AND calls activateModel — a plain settings '
        'write alone leaves flutter_gemma pointed at the previous model',
        () async {
      when(() => localCatalog.activateModel(AIModelId.gemma4E2b))
          .thenAnswer((_) async => const Right(unit));

      final result = await repo.setActiveModel('gemma4E2b');

      expect(result.isRight(), isTrue);
      verify(() => localSettings.setActiveModelId(AIModelId.gemma4E2b))
          .called(1);
      verify(() => localCatalog.activateModel(AIModelId.gemma4E2b)).called(1);
    });

    test('an unknown model id fails before touching settings or the catalog',
        () async {
      final result = await repo.setActiveModel('not-a-real-model');

      expect(result.isLeft(), isTrue);
      verifyNever(() => localSettings.setActiveModelId(any()));
      verifyNever(() => localCatalog.activateModel(any()));
    });

    test('activateModel failure (e.g. the picked model was never actually '
        'downloaded) surfaces as a Left, even though settings already wrote',
        () async {
      when(() => localCatalog.activateModel(AIModelId.deepseekR1)).thenAnswer(
          (_) async => const Left(Failure.errorFailure('not downloaded')));

      final result = await repo.setActiveModel('deepseekR1');

      expect(result.isLeft(), isTrue);
      verify(() => localSettings.setActiveModelId(AIModelId.deepseekR1))
          .called(1);
    });

    test('a settings write failure surfaces as a Left, not an uncaught throw',
        () async {
      when(() => localSettings.setActiveModelId(any()))
          .thenThrow(Exception('prefs write failed'));

      final result = await repo.setActiveModel('gemma4E2b');

      expect(result.isLeft(), isTrue);
      verifyNever(() => localCatalog.activateModel(any()));
    });

    test('cloud backend never touches the local catalog at all', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => prefs.setActiveCloudModelId(any())).thenAnswer((_) async {});

      final result = await repo.setActiveModel('claude-sonnet-5');

      expect(result.isRight(), isTrue);
      verifyNever(() => localCatalog.activateModel(any()));
      verifyNever(() => localSettings.setActiveModelId(any()));
    });
  });

  group('simple _active-delegating members', () {
    test('hasActiveModel delegates to the active backend', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => local.hasActiveModel()).thenAnswer((_) async => true);

      expect(await repo.hasActiveModel(), isTrue);
      verifyNever(() => remote.hasActiveModel());
    });

    test('openConversation/closeConversation delegate to the active backend',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => remote.openConversation())
          .thenAnswer((_) async => const Right(unit));
      when(() => remote.closeConversation())
          .thenAnswer((_) async => const Right(unit));

      expect(await repo.openConversation(), const Right<Failure, Unit>(unit));
      expect(await repo.closeConversation(), const Right<Failure, Unit>(unit));
      verifyNever(() => local.openConversation());
      verifyNever(() => local.closeConversation());
    });

    test('sendChat forwards all fields to the active backend\'s stream',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => local.sendChat(
            message: any(named: 'message'),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => Stream.fromIterable(['a', 'b']));

      final tokens = await repo
          .sendChat(message: 'hi', systemInstruction: 'sys', cleanHistory: [('q', 'a')])
          .toList();

      expect(tokens, ['a', 'b']);
      verify(() => local.sendChat(
            message: 'hi',
            systemInstruction: 'sys',
            cleanHistory: [('q', 'a')],
            images: const [],
          )).called(1);
    });

    test('sendChat passes the images to the active backend', () async {
      final photo = Uint8List.fromList([9, 8, 7]);
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => local.sendChat(
            message: any(named: 'message'),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => Stream.fromIterable(['ok']));

      await repo.sendChat(message: 'what is this?', images: [photo]).toList();

      verify(() => local.sendChat(
            message: 'what is this?',
            systemInstruction: null,
            cleanHistory: const [],
            images: [photo],
          )).called(1);
    });

    test('preemptBackgroundWork/resumeBackgroundWork delegate to the active '
        'backend', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => local.preemptBackgroundWork())
          .thenAnswer((_) async => const Right(unit));
      when(() => local.resumeBackgroundWork())
          .thenAnswer((_) async => const Right(unit));

      expect(await repo.preemptBackgroundWork(), const Right<Failure, Unit>(unit));
      expect(await repo.resumeBackgroundWork(), const Right<Failure, Unit>(unit));
    });

    test('listAvailableModels delegates to the active backend', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => remote.listAvailableModels())
          .thenAnswer((_) async => const Right(<LlmModelInfo>[]));

      final result = await repo.listAvailableModels();

      expect(result, const Right<Failure, List<LlmModelInfo>>([]));
      verifyNever(() => local.listAvailableModels());
    });

    test('listCloudModels always queries remote, regardless of the active '
        'backend', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => remote.listAvailableModels())
          .thenAnswer((_) async => const Right(<LlmModelInfo>[]));

      final result = await repo.listCloudModels();

      expect(result, const Right<Failure, List<LlmModelInfo>>([]));
      verify(() => remote.listAvailableModels()).called(1);
    });
  });

  group('getActiveBackend', () {
    test('reflects the current preference', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);

      final result = await repo.getActiveBackend();

      expect(result, const Right<Failure, LlmBackendType>(LlmBackendType.uniunCloud));
    });
  });

  group('setActiveBackend', () {
    test('switching to local just persists the preference, no cloud connect',
        () async {
      when(() => prefs.setActiveBackend(any())).thenAnswer((_) async {});

      final result = await repo.setActiveBackend(LlmBackendType.localGemma);

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => cloudAuth.connect());
      verify(() => prefs.setActiveBackend(LlmBackendType.localGemma)).called(1);
    });

    test('switching to cloud silently connects first, then persists',
        () async {
      when(() => cloudAuth.connect()).thenAnswer((_) async => const Right(unit));
      when(() => prefs.setActiveBackend(any())).thenAnswer((_) async {});

      final result = await repo.setActiveBackend(LlmBackendType.uniunCloud);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => cloudAuth.connect()).called(1);
      verify(() => prefs.setActiveBackend(LlmBackendType.uniunCloud)).called(1);
    });

    test('a cloud connect failure aborts before persisting the preference',
        () async {
      when(() => cloudAuth.connect())
          .thenAnswer((_) async => const Left(Failure.errorFailure('no keys')));

      final result = await repo.setActiveBackend(LlmBackendType.uniunCloud);

      expect(result.isLeft(), isTrue);
      verifyNever(() => prefs.setActiveBackend(any()));
    });
  });

  group('getActiveModel', () {
    test('local backend, no active model — Right(null)', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => localCatalog.getActiveModel())
          .thenAnswer((_) async => const Right(null));

      final result = await repo.getActiveModel();

      expect(result, const Right<Failure, LlmModelInfo?>(null));
    });

    test('local backend, an active model — maps id/displayName/backend',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => localCatalog.getActiveModel())
          .thenAnswer((_) async => Right(_entry(AIModelId.deepseekR1)));

      final result = await repo.getActiveModel();

      result.fold((_) => fail('expected Right'), (info) {
        expect(info?.id, 'deepseekR1');
        expect(info?.backend, LlmBackendType.localGemma);
      });
    });

    test('a vision model reports it can take images; a text-only one does not',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      for (final (id, expected) in [
        (AIModelId.gemma4E2b, true),
        (AIModelId.gemma4E4b, true),
        (AIModelId.qwen25_05b, false),
        (AIModelId.deepseekR1, false),
      ]) {
        when(() => localCatalog.getActiveModel())
            .thenAnswer((_) async => Right(_entry(id)));

        final info = (await repo.getActiveModel()).getOrElse(() => null);

        expect(info?.supportsImages, expected, reason: '$id');
      }
    });

    test('a cloud model is never offered image input yet', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => prefs.activeCloudModelId).thenReturn('claude-sonnet-5');

      final info = (await repo.getActiveModel()).getOrElse(() => null);

      expect(info?.supportsImages, isFalse,
          reason: 'the gateway does not take images, so the button stays away');
    });

    test('local backend, catalog failure — surfaces as Left', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => localCatalog.getActiveModel())
          .thenAnswer((_) async => const Left(Failure.errorFailure('x')));

      final result = await repo.getActiveModel();

      expect(result.isLeft(), isTrue);
    });

    test('cloud backend, no active cloud model id — Right(null)', () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => prefs.activeCloudModelId).thenReturn(null);

      final result = await repo.getActiveModel();

      expect(result, const Right<Failure, LlmModelInfo?>(null));
    });

    test('cloud backend, an active id — id and displayName both echo it',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.uniunCloud);
      when(() => prefs.activeCloudModelId).thenReturn('claude-sonnet-5');

      final result = await repo.getActiveModel();

      result.fold((_) => fail('expected Right'), (info) {
        expect(info?.id, 'claude-sonnet-5');
        expect(info?.displayName, 'claude-sonnet-5');
        expect(info?.backend, LlmBackendType.uniunCloud);
      });
    });

    test('an unexpected exception surfaces as a Left, not an uncaught throw',
        () async {
      when(() => prefs.activeBackend).thenReturn(LlmBackendType.localGemma);
      when(() => localCatalog.getActiveModel())
          .thenThrow(Exception('isar closed'));

      final result = await repo.getActiveModel();

      expect(result.isLeft(), isTrue);
    });
  });
}
