import 'dart:typed_data';

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_llm_data_source.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';

class _MockRunner extends Mock implements AIModelRunner {}

class _MockModelCatalog extends Mock implements AIModelRepository {}

AIModelEntity _entry(AIModelId id) => AIModelEntity(
      modelId: id,
      sizeLabel: '1 GB',
      sizeBytes: 1000,
      tier: AIModelTier.balanced,
      isRecommended: false,
      optimization: AIModelOptimization.cpu,
      downloadUrl: 'https://example.com/$id',
    );

/// InferenceScheduler is used REAL (not mocked) — the foreground-coordination
/// tests below assert on its real setForeground state, matching the pattern
/// already established for AIModelRunner tests this session.
void main() {
  setUpAll(() {
    registerFallbackValue(LlmTaskKind.extract);
  });

  late _MockRunner runner;
  late InferenceScheduler scheduler;
  late _MockModelCatalog catalog;
  late LocalLlmDataSource ds;

  setUp(() {
    runner = _MockRunner();
    scheduler = InferenceScheduler();
    catalog = _MockModelCatalog();
    ds = LocalLlmDataSource(runner, scheduler, catalog);
  });

  group('hasActiveModel', () {
    test('delegates to the runner', () async {
      when(() => runner.hasActiveModel).thenReturn(true);
      expect(await ds.hasActiveModel(), isTrue);

      when(() => runner.hasActiveModel).thenReturn(false);
      expect(await ds.hasActiveModel(), isFalse);
    });
  });

  group('openConversation / closeConversation', () {
    test('open succeeds when the runner validates a model is active',
        () async {
      when(() => runner.initChat()).thenAnswer((_) async {});

      final result = await ds.openConversation();

      expect(result, const Right<dynamic, Unit>(unit));
    });

    test('open surfaces the runner\'s StateError as a Left', () async {
      when(() => runner.initChat())
          .thenThrow(StateError('No AI model is active.'));

      final result = await ds.openConversation();

      expect(result.isLeft(), isTrue);
    });

    test('close delegates to the runner and succeeds', () async {
      when(() => runner.close()).thenAnswer((_) async {});

      final result = await ds.closeConversation();

      expect(result, const Right<dynamic, Unit>(unit));
    });

    test('close surfaces a runner failure as a Left', () async {
      when(() => runner.close()).thenThrow(Exception('teardown failed'));

      final result = await ds.closeConversation();

      expect(result.isLeft(), isTrue);
    });
  });

  group('sendChat', () {
    test('forwards message/cleanHistory and defaults a null '
        'systemInstruction to empty string', () async {
      when(() => runner.sendAndStream(
            any(),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => Stream.fromIterable(['a', 'b']));

      final tokens = await ds
          .sendChat(message: 'hi', cleanHistory: [('q', 'a')])
          .toList();

      expect(tokens, ['a', 'b']);
      verify(() => runner.sendAndStream(
            'hi',
            systemInstruction: '',
            cleanHistory: [('q', 'a')],
          )).called(1);
    });

    test('the images of a turn reach the runner', () async {
      final photo = Uint8List.fromList([5, 6, 7]);
      when(() => runner.sendAndStream(
            any(),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
            images: any(named: 'images'),
          )).thenAnswer((_) => const Stream.empty());

      await ds.sendChat(message: 'what is this?', images: [photo]).toList();

      verify(() => runner.sendAndStream(
            'what is this?',
            systemInstruction: '',
            cleanHistory: const [],
            images: [photo],
          )).called(1);
    });

    test('a non-null systemInstruction passes through unchanged', () async {
      when(() => runner.sendAndStream(
            any(),
            systemInstruction: any(named: 'systemInstruction'),
            cleanHistory: any(named: 'cleanHistory'),
          )).thenAnswer((_) => const Stream.empty());

      await ds.sendChat(message: 'hi', systemInstruction: 'persona').toList();

      verify(() => runner.sendAndStream(
            'hi',
            systemInstruction: 'persona',
            cleanHistory: const [],
          )).called(1);
    });
  });

  group('generateOneShot', () {
    test('forwards prompt/maxTokens/kind and wraps the result in Right',
        () async {
      when(() => runner.generateOneShot(
            any(),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
          )).thenAnswer((_) async => 'answer');

      final result = await ds.generateOneShot(
        prompt: 'p',
        maxTokens: 42,
        kind: LlmTaskKind.gana,
      );

      expect(result, const Right<dynamic, String?>('answer'));
      verify(() => runner.generateOneShot(
            'p',
            maxTokens: 42,
            kind: LlmTaskKind.gana,
          )).called(1);
    });

    test('a null result (no active model / cancelled) is still a Right',
        () async {
      when(() => runner.generateOneShot(
            any(),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
          )).thenAnswer((_) async => null);

      final result = await ds.generateOneShot(prompt: 'p');

      expect(result, const Right<dynamic, String?>(null));
    });

    test('a runner exception surfaces as a Left', () async {
      when(() => runner.generateOneShot(
            any(),
            maxTokens: any(named: 'maxTokens'),
            kind: any(named: 'kind'),
          )).thenThrow(Exception('native crash'));

      final result = await ds.generateOneShot(prompt: 'p');

      expect(result.isLeft(), isTrue);
    });
  });

  group('preemptBackgroundWork / resumeBackgroundWork', () {
    test('preempt sets the scheduler foreground hint to chat', () async {
      final result = await ds.preemptBackgroundWork();

      expect(result, const Right<dynamic, Unit>(unit));
      // Real scheduler — assert on its actual state, not a mock expectation.
      // T2+ work is now blocked while foreground=chat (see InferenceScheduler
      // ._pickBestInternal's blockBackground check).
      final blocked = scheduler.run<String>(
        kind: LlmTaskKind.extract,
        modelId: 'm',
        work: (_) async => 'ran',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(scheduler.runningKind, isNot(LlmTaskKind.extract));
      unawaited(blocked.catchError((_) => ''));
    });

    test('resume clears the scheduler foreground hint', () async {
      await ds.preemptBackgroundWork();
      final result = await ds.resumeBackgroundWork();

      expect(result, const Right<dynamic, Unit>(unit));
      final ran = await scheduler.run<String>(
        kind: LlmTaskKind.extract,
        modelId: 'm',
        work: (_) async => 'ran',
      );
      expect(ran, 'ran');
    });
  });

  group('listAvailableModels', () {
    test('returns only the downloaded catalog entries, mapped with the '
        'local backend and a real display name', () async {
      when(() => catalog.getAvailableModels()).thenAnswer((_) async => [
            _entry(AIModelId.qwen25_05b),
            _entry(AIModelId.deepseekR1),
            _entry(AIModelId.gemma4E2b),
          ]);
      when(() => catalog.getDownloadedModelIds())
          .thenAnswer((_) async => {AIModelId.deepseekR1});

      final result = await ds.listAvailableModels();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (infos) {
        expect(infos, hasLength(1));
        expect(infos.single.id, 'deepseekR1');
        expect(infos.single.displayName, 'DeepSeek R1 1.5B');
        expect(infos.single.backend, LlmBackendType.localGemma);
      });
    });

    test('every AIModelId maps to a distinct real display name', () async {
      when(() => catalog.getAvailableModels()).thenAnswer((_) async =>
          AIModelId.values.map(_entry).toList());
      when(() => catalog.getDownloadedModelIds())
          .thenAnswer((_) async => AIModelId.values.toSet());

      final result = await ds.listAvailableModels();

      result.fold((_) => fail('expected Right'), (infos) {
        final names = infos.map((i) => i.displayName).toSet();
        expect(names, hasLength(AIModelId.values.length));
      });
    });

    test('no downloaded models — returns an empty list, not an error',
        () async {
      when(() => catalog.getAvailableModels())
          .thenAnswer((_) async => [_entry(AIModelId.qwen25_05b)]);
      when(() => catalog.getDownloadedModelIds())
          .thenAnswer((_) async => <AIModelId>{});

      final result = await ds.listAvailableModels();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (infos) => expect(infos, isEmpty));
    });

    test('a catalog failure surfaces as a Left', () async {
      when(() => catalog.getAvailableModels())
          .thenThrow(Exception('isar closed'));

      final result = await ds.listAvailableModels();

      expect(result.isLeft(), isTrue);
    });
  });
}
