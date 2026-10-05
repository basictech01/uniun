import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

class _MockSettings extends Mock implements AppSettingsStore {}

class _MockGateway extends Mock implements FlutterGemmaGateway {}

class _MockInferenceModel extends Mock implements InferenceModel {}

class _MockInferenceChat extends Mock implements InferenceChat {}

class _MockScheduler extends Mock implements InferenceScheduler {}

/// Covers AIModelRunner's real generation logic (retry + backend fallback,
/// prompt composition/history trimming, stop-token scrubbing, cancellation)
/// via the FlutterGemmaGateway seam — unreachable before that seam existed
/// (see docs/AUDIT.md, Group C of the coverage push). The InferenceScheduler
/// is REAL (not mocked) throughout, so cancellation tests exercise genuine
/// preemption, not a simulated flag.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Message.text(text: ''));
    registerFallbackValue(PreferredBackend.cpu);
    registerFallbackValue(LlmTaskKind.chat);
  });

  late InferenceScheduler scheduler;
  late _MockSettings settings;
  late _MockGateway gateway;
  late AIModelRunner runner;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // gpu-preferred
    scheduler = InferenceScheduler();
    settings = _MockSettings();
    gateway = _MockGateway();
    runner = AIModelRunner(scheduler, settings, gateway);
    when(() => settings.activeModelId).thenReturn(AIModelId.deepseekR1);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  _MockInferenceChat chatReturning(List<ModelResponse> responses) {
    final chat = _MockInferenceChat();
    when(() => chat.addQueryChunk(any())).thenAnswer((_) async {});
    when(() => chat.generateChatResponseAsync())
        .thenAnswer((_) => Stream.fromIterable(responses));
    when(() => chat.stopGeneration()).thenAnswer((_) async {});
    when(() => chat.close()).thenAnswer((_) async {});
    return chat;
  }

  group('generateOneShot', () {
    test('no active model — returns null without touching the gateway',
        () async {
      when(() => gateway.hasActiveModel()).thenReturn(false);

      final result = await runner.generateOneShot('prompt');

      expect(result, isNull);
      verifyNever(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          ));
    });

    test('single clean attempt returns the sanitized text', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [
        TextResponse('Hello '),
        TextResponse('world'),
      ]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final result = await runner.generateOneShot('prompt');

      expect(result, 'Hello world');
      verify(() => chat.close()).called(1);
    });

    test('strips a stop token and any trailing BPE junk after it', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [
        TextResponse('answer<|im_end'),
        TextResponse('|>garbage-after-stop'),
      ]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final result = await runner.generateOneShot('prompt');

      expect(result, 'answer');
    });

    test('a trailing chunk that only LOOKS like the start of a stop token '
        '(stream ends before it completes) is flushed back as real text, '
        'not silently dropped', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      // "<|im_e" is held back as a possible stop-token prefix, but the
      // stream ends right there — it was never actually a stop token, so
      // flush() must return it rather than swallow it.
      final chat = chatReturning(const [
        TextResponse('answer'),
        TextResponse('<|im_e'),
      ]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final result = await runner.generateOneShot('prompt');

      expect(result, 'answer<|im_e');
    });

    /// GPU open throws; CPU succeeds. Shared by the two fallback tests below.
    _MockInferenceModel stubGpuFailsCpuWorks() {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final cpuModel = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: PreferredBackend.gpu,
          )).thenThrow(Exception('GPU texture binding overflow'));
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: PreferredBackend.cpu,
          )).thenAnswer((_) async => cpuModel);
      when(() => cpuModel.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer(
              (_) async => chatReturning(const [TextResponse('cpu-ok')]));
      return cpuModel;
    }

    test('sends the prompt untouched — isUser stays false so the plugin '
        'cannot append /no_think after our answer cue (#220)', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [TextResponse('ok')]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      await runner.generateOneShot('my prompt');

      final sent =
          verify(() => chat.addQueryChunk(captureAny())).captured.single
              as Message;
      expect(sent.isUser, isFalse);
      expect(sent.text, 'my prompt');
    });

    test('GPU open failure retries explicitly on CPU and succeeds', () async {
      stubGpuFailsCpuWorks();

      final result = await runner.generateOneShot('prompt');

      expect(result, 'cpu-ok');
      verify(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: PreferredBackend.cpu,
          )).called(1);
      // A null backend is GPU-then-CPU on LiteRT-LM: it would repeat the
      // failed GPU attempt instead of falling back.
      verifyNever(
          () => gateway.getActiveModel(maxTokens: any(named: 'maxTokens')));
    });

    test('after a GPU failure, later opens of the same model skip GPU',
        () async {
      stubGpuFailsCpuWorks();

      // Not the default `extract`: back-to-back extracts trip the scheduler's
      // T2 soft budget (>60% over 5 min) and the second one is never picked.
      await runner.generateOneShot('first', kind: LlmTaskKind.nataraj);
      await runner.generateOneShot('second', kind: LlmTaskKind.nataraj);

      verify(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: PreferredBackend.gpu,
          )).called(1);
      verify(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: PreferredBackend.cpu,
          )).called(2);
    });

    test('invoke failure resets the cached model and retries once, '
        'succeeding on the second attempt', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => model.close()).thenAnswer((_) async {});
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);

      var openChatCalls = 0;
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async {
        openChatCalls++;
        if (openChatCalls == 1) throw Exception('native runtime degraded');
        return chatReturning(const [TextResponse('recovered')]);
      });

      final result = await runner.generateOneShot('prompt');

      expect(result, 'recovered');
      expect(openChatCalls, 2);
      verify(() => model.close()).called(1); // the reset between attempts
    });

    test('invoke fails on both attempts — returns null, resets exactly once',
        () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => model.close()).thenAnswer((_) async {});
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenThrow(Exception('permanently broken'));

      final result = await runner.generateOneShot('prompt');

      expect(result, isNull);
      verify(() => model.close()).called(1);
    });

    test('an unexpected error surfacing from the scheduler itself (not the '
        'generation logic, which never rethrows internally) is caught by '
        'the outer guard and degrades to null', () async {
      // _attemptOneShot/_doGenerateOneShot catch every generation-side
      // exception internally and always resolve normally, so the only way
      // to reach generateOneShot's own outer try/catch is a failure from
      // the scheduler plumbing itself — simulated here via a mocked
      // scheduler instead of the real one used everywhere else in this file.
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final brokenScheduler = _MockScheduler();
      when(() => brokenScheduler.run<String?>(
            kind: any(named: 'kind'),
            modelId: any(named: 'modelId'),
            work: any(named: 'work'),
          )).thenThrow(Exception('scheduler internals corrupted'));
      final brokenRunner = AIModelRunner(brokenScheduler, settings, gateway);

      final result = await brokenRunner.generateOneShot('prompt');

      expect(result, isNull);
    });

    test('preempted mid-stream by a real higher-tier chat job is aborted, '
        'transparently re-queued by the scheduler, and still completes with '
        'the full result on retry', () async {
      // nataraj/extract/gana are re-queueable (see InferenceScheduler.
      // _isReQueueable) — the scheduler discards whatever the aborted
      // attempt's work returns and retries the whole job from scratch, so
      // the CALLER never observes a null/partial result from a preemption,
      // only from a genuine unrecoverable failure. This is real, documented
      // scheduler behavior (docs/SHIVA/scheduling.md), not a simulated flag.
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);

      final abortedChat = _MockInferenceChat();
      when(() => abortedChat.addQueryChunk(any())).thenAnswer((_) async {});
      when(() => abortedChat.generateChatResponseAsync())
          .thenAnswer((_) => (() async* {
                yield const TextResponse('partial-');
                await Future.delayed(const Duration(milliseconds: 60));
                yield const TextResponse('should-not-be-reached');
              })());
      when(() => abortedChat.stopGeneration()).thenAnswer((_) async {});
      when(() => abortedChat.close()).thenAnswer((_) async {});

      var openChatCalls = 0;
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async {
        openChatCalls++;
        if (openChatCalls == 1) return abortedChat;
        return chatReturning(const [TextResponse('retried-and-done')]);
      });

      final future = runner.generateOneShot('prompt', kind: LlmTaskKind.nataraj);
      await Future.delayed(const Duration(milliseconds: 10));
      // A real T0 chat job preempts the running nataraj job at the next
      // token boundary — genuine scheduler cancellation, not a simulated flag.
      await scheduler.run<void>(
        kind: LlmTaskKind.chat,
        modelId: 'x',
        work: (_) async {},
      );

      final result = await future;

      expect(result, 'retried-and-done');
      expect(openChatCalls, 2, reason: 'aborted attempt + the re-queued retry');
      verify(() => abortedChat.stopGeneration()).called(1);
    });
  });

  group('sendAndStream', () {
    test('throws StateError when no model is active', () {
      when(() => gateway.hasActiveModel()).thenReturn(false);

      expect(
        () => runner.sendAndStream('hi', systemInstruction: 'sys').toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('sends the chat prompt untouched — isUser stays false so the plugin '
        'cannot append /no_think after our answer cue (#220)', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [TextResponse('ok')]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      await runner.sendAndStream('hi', systemInstruction: 'sys').toList();

      final sent =
          verify(() => chat.addQueryChunk(captureAny())).captured.last
              as Message;
      expect(sent.isUser, isFalse);
    });

    group('image turns', () {
      final photo = Uint8List.fromList([1, 2, 3, 4]);

      /// A model whose chat answers 'ok', opened through [gateway].
      _MockInferenceModel visionModel(void Function(Invocation) onOpenChat) {
        when(() => gateway.hasActiveModel()).thenReturn(true);
        final model = _MockInferenceModel();
        when(
          () => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
            supportImage: any(named: 'supportImage'),
            maxNumImages: any(named: 'maxNumImages'),
          ),
        ).thenAnswer((_) async => model);
        when(() => model.close()).thenAnswer((_) async {});
        final chat = chatReturning(const [TextResponse('ok')]);
        when(
          () => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
            supportImage: any(named: 'supportImage'),
          ),
        ).thenAnswer((i) async {
          onOpenChat(i);
          return chat;
        });
        return model;
      }

      test(
        'the message carries the image, and the chat is opened for it',
        () async {
          bool? chatSupportImage;
          final model = visionModel(
            (i) => chatSupportImage = i.namedArguments[#supportImage] as bool?,
          );
          final chat = chatReturning(const [TextResponse('ok')]);
          when(
            () => model.openChat(
              temperature: any(named: 'temperature'),
              topK: any(named: 'topK'),
              tokenBuffer: any(named: 'tokenBuffer'),
              modelType: any(named: 'modelType'),
              isThinking: any(named: 'isThinking'),
              supportImage: any(named: 'supportImage'),
            ),
          ).thenAnswer((i) async {
            chatSupportImage = i.namedArguments[#supportImage] as bool?;
            return chat;
          });

          await runner
              .sendAndStream(
                'what is this?',
                systemInstruction: 'sys',
                images: [photo],
              )
              .toList();

          final sent =
              verify(() => chat.addQueryChunk(captureAny())).captured.last
                  as Message;
          expect(sent.hasImage, isTrue);
          expect(sent.imageBytes, photo);
          expect(chatSupportImage, isTrue);
        },
      );

      test(
        'the model is opened with its vision encoder for an image turn',
        () async {
          visionModel((_) {});

          await runner
              .sendAndStream('hi', systemInstruction: 's', images: [photo])
              .toList();

          verify(
            () => gateway.getActiveModel(
              maxTokens: any(named: 'maxTokens'),
              preferredBackend: any(named: 'preferredBackend'),
              supportImage: true,
              maxNumImages: 1,
            ),
          ).called(1);
        },
      );

      test('a text turn never turns vision on or sends an image', () async {
        bool? chatSupportImage = true;
        final model = visionModel(
          (i) => chatSupportImage = i.namedArguments[#supportImage] as bool?,
        );
        final chat = chatReturning(const [TextResponse('ok')]);
        when(
          () => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
            supportImage: any(named: 'supportImage'),
          ),
        ).thenAnswer((i) async {
          chatSupportImage = i.namedArguments[#supportImage] as bool?;
          return chat;
        });

        await runner.sendAndStream('hi', systemInstruction: 's').toList();

        verify(
          () => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
            supportImage: false,
            maxNumImages: null,
          ),
        ).called(1);
        expect(chatSupportImage, isNull);
        final sent =
            verify(() => chat.addQueryChunk(captureAny())).captured.last
                as Message;
        expect(sent.hasImage, isFalse);
      });

      test('a cached text-only model is closed and re-opened for the first '
          'image turn, then kept for the next', () async {
        final model = visionModel((_) {});

        await runner.sendAndStream('text', systemInstruction: 's').toList();
        await runner
            .sendAndStream('image', systemInstruction: 's', images: [photo])
            .toList();
        await runner
            .sendAndStream(
              'image again',
              systemInstruction: 's',
              images: [photo],
            )
            .toList();

        verify(() => model.close()).called(1);
        verify(
          () => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
            supportImage: true,
            maxNumImages: 1,
          ),
        ).called(2);
      });

      test('a text turn after an image turn keeps the vision model', () async {
        final model = visionModel((_) {});

        await runner
            .sendAndStream('image', systemInstruction: 's', images: [photo])
            .toList();
        await runner.sendAndStream('text', systemInstruction: 's').toList();

        verifyNever(() => model.close());
        verify(
          () => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
            supportImage: true,
            maxNumImages: 1,
          ),
        ).called(2);
      });
    });

    test('streams sanitized tokens in order and closes the chat', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [
        TextResponse('one '),
        TextResponse('two '),
        TextResponse('three'),
      ]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final tokens = await runner
          .sendAndStream('hi', systemInstruction: 'sys')
          .toList();

      expect(tokens.join(), 'one two three');
      verify(() => chat.close()).called(1);
    });

    test('a trailing chunk that only looks like a stop-token prefix is '
        'flushed back as real text when the stream ends before it completes',
        () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [
        TextResponse('hi'),
        TextResponse('<|im_e'),
      ]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final tokens = await runner
          .sendAndStream('hi', systemInstruction: 'sys')
          .toList();

      expect(tokens.join(), 'hi<|im_e');
    });

    test('composed prompt carries the system instruction, trimmed history '
        'within budget, and the current message', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [TextResponse('ok')]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      // deepseekR1's maxTokens is 1280 -> history budget = round(1280*0.2) = 256
      // "tokens" (chars/4). A long-enough oldest pair must be dropped while a
      // recent short pair survives.
      final oldPair = ('a' * 2000, 'b' * 2000); // ~1000 "tokens" — way over budget
      const recentPair = ('q2', 'a2');

      await runner
          .sendAndStream(
            'current turn',
            systemInstruction: 'SYSTEM_MARK',
            cleanHistory: [oldPair, recentPair],
          )
          .toList();

      final captured = verify(() => chat.addQueryChunk(captureAny()))
          .captured
          .single as Message;
      final prompt = captured.text;

      expect(prompt, contains('SYSTEM_MARK'));
      expect(prompt, contains('User: q2'));
      expect(prompt, contains('Assistant: a2'));
      expect(prompt, isNot(contains('User: ${oldPair.$1}')));
      expect(prompt, contains('current turn'));
    });

    test('a native error during streaming surfaces via the stream and still '
        'closes the chat', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = _MockInferenceChat();
      when(() => chat.addQueryChunk(any())).thenAnswer((_) async {});
      when(() => chat.generateChatResponseAsync())
          .thenAnswer((_) => Stream<ModelResponse>.error(Exception('native crash')));
      when(() => chat.close()).thenAnswer((_) async {});
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final stream = runner.sendAndStream('hi', systemInstruction: 'sys');

      await expectLater(stream, emitsError(isA<Exception>()));
      verify(() => chat.close()).called(1);
    });

    test('a forced model-switch (the delete-active-model path) preempts a '
        'running chat stream mid-generation — chat itself never preempts '
        'another chat turn at equal tier, only tier -1 outranks it',
        () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = _MockInferenceChat();
      when(() => chat.addQueryChunk(any())).thenAnswer((_) async {});
      when(() => chat.generateChatResponseAsync()).thenAnswer((_) => (() async* {
            yield const TextResponse('seen-');
            await Future.delayed(const Duration(milliseconds: 60));
            yield const TextResponse('not-seen');
          })());
      when(() => chat.stopGeneration()).thenAnswer((_) async {});
      when(() => chat.close()).thenAnswer((_) async {});
      when(() => model.close()).thenAnswer((_) async {});
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);

      final firstTurn =
          runner.sendAndStream('hi', systemInstruction: 'sys').toList();
      await Future.delayed(const Duration(milliseconds: 10));
      // Same coordination [deleteModel] relies on (issue #160): forcePreempt
      // is tier -1, which genuinely outranks a running chat turn (tier 0).
      final forcedSwitch = runner.runExclusiveModelOperation<void>(
        forcePreempt: true,
        action: () async {},
      );

      final tokens = await firstTurn;
      await forcedSwitch;

      expect(tokens.join(), 'seen-');
      verify(() => chat.stopGeneration()).called(1);
      verify(() => chat.close()).called(1);
    });
  });

  group('hasActiveModel / initChat', () {
    test('hasActiveModel delegates to the gateway', () {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      expect(runner.hasActiveModel, isTrue);

      when(() => gateway.hasActiveModel()).thenReturn(false);
      expect(runner.hasActiveModel, isFalse);
    });

    test('initChat throws when no model is active, no-op otherwise',
        () async {
      when(() => gateway.hasActiveModel()).thenReturn(false);
      await expectLater(runner.initChat(), throwsA(isA<StateError>()));

      when(() => gateway.hasActiveModel()).thenReturn(true);
      await runner.initChat(); // should not throw
    });

    test('close() is a no-op — chat has no long-lived per-conversation '
        'state to tear down', () async {
      await runner.close(); // should complete without throwing
    });
  });

  group('runExclusiveModelOperation', () {
    test('resets the cached model before running the action', () async {
      when(() => gateway.hasActiveModel()).thenReturn(true);
      final model = _MockInferenceModel();
      when(() => model.close()).thenAnswer((_) async {});
      when(() => gateway.getActiveModel(
            maxTokens: any(named: 'maxTokens'),
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      final chat = chatReturning(const [TextResponse('primed')]);
      when(() => model.openChat(
            temperature: any(named: 'temperature'),
            topK: any(named: 'topK'),
            tokenBuffer: any(named: 'tokenBuffer'),
            modelType: any(named: 'modelType'),
            isThinking: any(named: 'isThinking'),
          )).thenAnswer((_) async => chat);
      // Prime _activeModel via a real one-shot call first.
      await runner.generateOneShot('warm up');
      final order = <String>[];

      await runner.runExclusiveModelOperation<void>(
        forcePreempt: false,
        action: () async => order.add('action'),
      );

      verify(() => model.close()).called(1);
      expect(order, ['action']);
    });
  });
}
