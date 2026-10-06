import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';

class _MockLlmRepository extends Mock implements LlmRepository {}

class _MockUniunRepository extends Mock implements UniunRepository {}

/// Every use case here is pure delegation to a repository method — no
/// branching logic of its own. Coverage goal is proving the delegation is
/// wired correctly (right method, right argument mapping) and that a
/// repository failure propagates verbatim, not re-testing the repository.
void main() {
  late _MockLlmRepository llmRepo;
  late _MockUniunRepository uniunRepo;

  setUpAll(() {
    registerFallbackValue(LlmBackendType.localGemma);
    registerFallbackValue(LlmTaskKind.extract);
  });

  setUp(() {
    llmRepo = _MockLlmRepository();
    uniunRepo = _MockUniunRepository();
  });

  group('HasActiveLlmModelUseCase', () {
    test('delegates to hasActiveModel', () async {
      when(() => llmRepo.hasActiveModel()).thenAnswer((_) async => true);

      final result = await HasActiveLlmModelUseCase(llmRepo).call();

      expect(result, isTrue);
      verify(() => llmRepo.hasActiveModel()).called(1);
    });
  });

  group('OpenLlmConversationUseCase / CloseLlmConversationUseCase', () {
    test('open delegates to openConversation', () async {
      when(() => llmRepo.openConversation())
          .thenAnswer((_) async => const Right(unit));

      final result = await OpenLlmConversationUseCase(llmRepo).call();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.openConversation()).called(1);
    });

    test('close delegates to closeConversation', () async {
      when(() => llmRepo.closeConversation())
          .thenAnswer((_) async => const Right(unit));

      final result = await CloseLlmConversationUseCase(llmRepo).call();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.closeConversation()).called(1);
    });

    test('open propagates a repository failure verbatim', () async {
      const failure = Failure.errorFailure('boom');
      when(() => llmRepo.openConversation())
          .thenAnswer((_) async => const Left(failure));

      final result = await OpenLlmConversationUseCase(llmRepo).call();

      expect(result, const Left<Failure, Unit>(failure));
    });
  });

  group('SendChatStreamUseCase', () {
    test('forwards message, systemInstruction and cleanHistory unchanged',
        () async {
      when(() => llmRepo.sendChat(
            message: any(named: 'message'),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => Stream.fromIterable(['a', 'b']));

      final tokens = await SendChatStreamUseCase(llmRepo)
          .call(const SendChatStreamInput(
            message: 'hi',
            systemInstruction: 'sys',
            cleanHistory: [('q', 'a')],
          ))
          .toList();

      expect(tokens, ['a', 'b']);
      verify(() => llmRepo.sendChat(
            message: 'hi',
            systemInstruction: 'sys',
            cleanHistory: [('q', 'a')],
            images: const [],
          )).called(1);
    });

    test('systemInstruction/cleanHistory default to null/empty when omitted',
        () async {
      when(() => llmRepo.sendChat(
            message: any(named: 'message'),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => const Stream.empty());

      await SendChatStreamUseCase(llmRepo)
          .call(const SendChatStreamInput(message: 'hi'))
          .toList();

      verify(() => llmRepo.sendChat(
            message: 'hi',
            systemInstruction: null,
            cleanHistory: const [],
            images: const [],
          )).called(1);
    });

    test('the images of a turn reach the repository unchanged', () async {
      final photo = Uint8List.fromList([1, 2, 3]);
      when(() => llmRepo.sendChat(
            message: any(named: 'message'),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => const Stream.empty());

      await SendChatStreamUseCase(llmRepo)
          .call(SendChatStreamInput(message: 'what is this?', images: [photo]))
          .toList();

      verify(() => llmRepo.sendChat(
            message: 'what is this?',
            systemInstruction: null,
            cleanHistory: const [],
            images: [photo],
          )).called(1);
    });
  });

  group('GenerateOneShotUseCase', () {
    test('forwards every field including overrides', () async {
      when(() => llmRepo.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            backendOverride: any(named: 'backendOverride'),
            modelIdOverride: any(named: 'modelIdOverride'),
          )).thenAnswer((_) async => const Right('done'));

      final result = await GenerateOneShotUseCase(llmRepo).call(
        const GenerateOneShotInput(
          prompt: 'p',
          maxTokens: 42,
          kind: LlmTaskKind.gana,
          backendOverride: LlmBackendType.uniunCloud,
          modelIdOverride: 'model-x',
        ),
      );

      expect(result, const Right<Failure, String?>('done'));
      verify(() => llmRepo.generateOneShot(
            prompt: 'p',
            maxTokens: 42,
            kind: LlmTaskKind.gana,
            backendOverride: LlmBackendType.uniunCloud,
            modelIdOverride: 'model-x',
          )).called(1);
    });

    test('defaults maxTokens/kind and leaves overrides null when omitted',
        () async {
      when(() => llmRepo.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            backendOverride: any(named: 'backendOverride'),
            modelIdOverride: any(named: 'modelIdOverride'),
          )).thenAnswer((_) async => const Right(null));

      await GenerateOneShotUseCase(llmRepo)
          .call(const GenerateOneShotInput(prompt: 'p'));

      verify(() => llmRepo.generateOneShot(
            prompt: 'p',
            maxTokens: 1024,
            kind: LlmTaskKind.extract,
            backendOverride: null,
            modelIdOverride: null,
          )).called(1);
    });

    test('propagates a repository failure verbatim', () async {
      const failure = Failure.errorFailure('no active model');
      when(() => llmRepo.generateOneShot(
            prompt: any(named: 'prompt'),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
            backendOverride: any(named: 'backendOverride'),
            modelIdOverride: any(named: 'modelIdOverride'),
          )).thenAnswer((_) async => const Left(failure));

      final result = await GenerateOneShotUseCase(llmRepo)
          .call(const GenerateOneShotInput(prompt: 'p'));

      expect(result, const Left<Failure, String?>(failure));
    });
  });

  group('PreemptBackgroundWorkUseCase / ResumeBackgroundWorkUseCase', () {
    test('preempt delegates to preemptBackgroundWork', () async {
      when(() => llmRepo.preemptBackgroundWork())
          .thenAnswer((_) async => const Right(unit));

      final result = await PreemptBackgroundWorkUseCase(llmRepo).call();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.preemptBackgroundWork()).called(1);
    });

    test('resume delegates to resumeBackgroundWork', () async {
      when(() => llmRepo.resumeBackgroundWork())
          .thenAnswer((_) async => const Right(unit));

      final result = await ResumeBackgroundWorkUseCase(llmRepo).call();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.resumeBackgroundWork()).called(1);
    });
  });

  group('Backend / model selection', () {
    test('GetActiveLlmBackendUseCase delegates to getActiveBackend',
        () async {
      when(() => llmRepo.getActiveBackend())
          .thenAnswer((_) async => const Right(LlmBackendType.localGemma));

      final result = await GetActiveLlmBackendUseCase(llmRepo).call();

      expect(result, const Right<Failure, LlmBackendType>(LlmBackendType.localGemma));
    });

    test('SetActiveLlmBackendUseCase forwards the backend argument',
        () async {
      when(() => llmRepo.setActiveBackend(any()))
          .thenAnswer((_) async => const Right(unit));

      final result = await SetActiveLlmBackendUseCase(llmRepo)
          .call(LlmBackendType.uniunCloud);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.setActiveBackend(LlmBackendType.uniunCloud))
          .called(1);
    });

    test('ListAvailableLlmModelsUseCase delegates to listAvailableModels',
        () async {
      when(() => llmRepo.listAvailableModels())
          .thenAnswer((_) async => const Right(<LlmModelInfo>[]));

      final result = await ListAvailableLlmModelsUseCase(llmRepo).call();

      expect(result, const Right<Failure, List<LlmModelInfo>>([]));
    });

    test('ListCloudLlmModelsUseCase delegates to listCloudModels', () async {
      when(() => llmRepo.listCloudModels())
          .thenAnswer((_) async => const Right(<LlmModelInfo>[]));

      final result = await ListCloudLlmModelsUseCase(llmRepo).call();

      expect(result, const Right<Failure, List<LlmModelInfo>>([]));
    });

    test('SetActiveLlmModelUseCase forwards the modelId argument', () async {
      when(() => llmRepo.setActiveModel(any()))
          .thenAnswer((_) async => const Right(unit));

      final result = await SetActiveLlmModelUseCase(llmRepo).call('model-x');

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => llmRepo.setActiveModel('model-x')).called(1);
    });

    test('GetActiveLlmModelUseCase delegates to getActiveModel', () async {
      when(() => llmRepo.getActiveModel())
          .thenAnswer((_) async => const Right(null));

      final result = await GetActiveLlmModelUseCase(llmRepo).call();

      expect(result, const Right<Failure, LlmModelInfo?>(null));
    });
  });

  group('UNIUN cloud connection', () {
    test('ConnectUniunCloudUseCase delegates to connect', () async {
      when(() => uniunRepo.connect())
          .thenAnswer((_) async => const Right(unit));

      final result = await ConnectUniunCloudUseCase(uniunRepo).call();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => uniunRepo.connect()).called(1);
    });

    test('DisconnectUniunCloudUseCase forwards confirm:true', () async {
      when(() => uniunRepo.disconnect(confirm: any(named: 'confirm')))
          .thenAnswer((_) async => const Right(unit));

      final result = await DisconnectUniunCloudUseCase(uniunRepo).call(true);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => uniunRepo.disconnect(confirm: true)).called(1);
    });

    test('DisconnectUniunCloudUseCase forwards confirm:false and surfaces '
        'a Failure (e.g. last-active-key guard)', () async {
      const failure = Failure.errorFailure('cannot disconnect last key');
      when(() => uniunRepo.disconnect(confirm: any(named: 'confirm')))
          .thenAnswer((_) async => const Left(failure));

      final result = await DisconnectUniunCloudUseCase(uniunRepo).call(false);

      expect(result, const Left<Failure, Unit>(failure));
      verify(() => uniunRepo.disconnect(confirm: false)).called(1);
    });

    test('IsUniunCloudConnectedUseCase delegates to isConnected', () async {
      when(() => uniunRepo.isConnected()).thenAnswer((_) async => true);

      final result = await IsUniunCloudConnectedUseCase(uniunRepo).call();

      expect(result, isTrue);
    });

    test('GetUniunCloudStatusUseCase delegates to accountStatus', () async {
      when(() => uniunRepo.accountStatus()).thenAnswer(
          (_) async => const Right((plan: 'pro', balance: 12.5)));

      final result = await GetUniunCloudStatusUseCase(uniunRepo).call();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (status) {
        expect(status.plan, 'pro');
        expect(status.balance, 12.5);
      });
    });
  });
}
