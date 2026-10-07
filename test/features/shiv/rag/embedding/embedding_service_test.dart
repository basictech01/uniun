import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

class _MockGateway extends Mock implements FlutterGemmaGateway {}

class _MockEmbeddingModel extends Mock implements EmbeddingModel {}

/// Covers EmbeddingService's real orchestration logic — install-once,
/// GPU→CPU backend fallback, embed()'s lazy-init + degrade-to-empty
/// contract, L2 normalisation — via the FlutterGemmaGateway seam
/// (see docs/AUDIT.md, Group A native-ceiling closure). Before the seam,
/// this class called `FlutterGemma.*` statics directly with no mockable
/// path at all.
void main() {
  setUpAll(() {
    registerFallbackValue(TaskType.retrievalQuery);
    registerFallbackValue(PreferredBackend.cpu);
  });

  late _MockGateway gateway;
  late EmbeddingService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS; // gpu-preferred
    gateway = _MockGateway();
    service = EmbeddingService(gateway, EmbeddingQueue());
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('ensureInstalled', () {
    test('already active — skips the install call', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);

      await service.ensureInstalled();

      verifyNever(() => gateway.installEmbedder(
            modelAsset: any(named: 'modelAsset'),
            tokenizerAsset: any(named: 'tokenizerAsset'),
          ));
    });

    test('not active — installs with the bundled asset paths', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(false);
      when(() => gateway.installEmbedder(
            modelAsset: any(named: 'modelAsset'),
            tokenizerAsset: any(named: 'tokenizerAsset'),
          )).thenAnswer((_) async {});

      await service.ensureInstalled();

      verify(() => gateway.installEmbedder(
            modelAsset: EmbeddingService.modelAsset,
            tokenizerAsset: EmbeddingService.tokenizerAsset,
          )).called(1);
    });
  });

  group('init', () {
    test('installs (if needed) then opens the embedder on the preferred '
        'backend', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(false);
      when(() => gateway.installEmbedder(
            modelAsset: any(named: 'modelAsset'),
            tokenizerAsset: any(named: 'tokenizerAsset'),
          )).thenAnswer((_) async {});
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);

      await service.init();

      expect(service.isReady, isTrue);
      verify(() => gateway.getActiveEmbedder(preferredBackend: PreferredBackend.gpu))
          .called(1);
    });

    test('is idempotent — a second call is a no-op once ready', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);

      await service.init();
      await service.init();

      verify(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .called(1);
    });

    test('GPU open failure falls back to CPU and still becomes ready',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final cpuModel = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: PreferredBackend.gpu))
          .thenThrow(Exception('Metal texture binding overflow'));
      when(() => gateway.getActiveEmbedder(preferredBackend: PreferredBackend.cpu))
          .thenAnswer((_) async => cpuModel);

      await service.init();

      expect(service.isReady, isTrue);
    });

    test('a failure on both backends degrades to not-ready, not a throw',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenThrow(Exception('native init failed'));

      await service.init();

      expect(service.isReady, isFalse);
    });

    test('an ensureInstalled failure degrades to not-ready, not a throw',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(false);
      when(() => gateway.installEmbedder(
            modelAsset: any(named: 'modelAsset'),
            tokenizerAsset: any(named: 'tokenizerAsset'),
          )).thenThrow(Exception('asset copy failed'));

      await service.init();

      expect(service.isReady, isFalse);
    });
  });

  group('embed', () {
    test('lazily calls init() when not yet ready', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.generateEmbedding(any(), taskType: any(named: 'taskType')))
          .thenAnswer((_) async => [0.6, 0.8]); // already unit-norm

      final vec = await service.embed('hello');

      expect(vec, [0.6, 0.8]);
      expect(service.isReady, isTrue);
    });

    test('still not ready after init (model unavailable) — returns []',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenThrow(Exception('no model'));

      final vec = await service.embed('hello');

      expect(vec, isEmpty);
    });

    test('passes retrievalDocument taskType when isDocument:true, '
        'retrievalQuery otherwise', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.generateEmbedding(any(), taskType: any(named: 'taskType')))
          .thenAnswer((_) async => [1.0]);

      await service.embed('q', isDocument: true);
      await service.embed('q');

      verify(() => model.generateEmbedding('q', taskType: TaskType.retrievalDocument))
          .called(1);
      verify(() => model.generateEmbedding('q', taskType: TaskType.retrievalQuery))
          .called(1);
    });

    test('L2-normalizes a non-unit vector', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.generateEmbedding(any(), taskType: any(named: 'taskType')))
          .thenAnswer((_) async => [3.0, 4.0]); // norm = 5

      final vec = await service.embed('hello');

      expect(vec[0], closeTo(0.6, 1e-9));
      expect(vec[1], closeTo(0.8, 1e-9));
    });

    test('a zero vector is returned unchanged (no divide-by-zero)', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.generateEmbedding(any(), taskType: any(named: 'taskType')))
          .thenAnswer((_) async => [0.0, 0.0]);

      final vec = await service.embed('hello');

      expect(vec, [0.0, 0.0]);
    });

    test('a generateEmbedding failure degrades to [], not a throw', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.generateEmbedding(any(), taskType: any(named: 'taskType')))
          .thenThrow(Exception('inference crashed'));

      final vec = await service.embed('hello');

      expect(vec, isEmpty);
    });
  });

  group('dispose', () {
    test('closes the model and resets isReady to false', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = _MockEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.close()).thenAnswer((_) async {});
      await service.init();

      await service.dispose();

      verify(() => model.close()).called(1);
      expect(service.isReady, isFalse);
    });

    test('is a no-op when nothing was ever loaded', () async {
      await service.dispose();

      expect(service.isReady, isFalse);
    });
  });

  group('the shared gate', () {
    late _MockEmbeddingModel model;
    final started = <String>[];
    final release = <String, Completer<List<double>>>{};

    setUp(() {
      started.clear();
      release.clear();
      model = _MockEmbeddingModel();
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      when(
        () => gateway.getActiveEmbedder(
          preferredBackend: any(named: 'preferredBackend'),
        ),
      ).thenAnswer((_) async => model);
      // Each embed starts, then waits until the test lets it finish.
      when(
        () => model.generateEmbedding(any(), taskType: any(named: 'taskType')),
      ).thenAnswer((i) {
        final text = i.positionalArguments.first as String;
        started.add(text);
        return (release[text] = Completer<List<double>>()).future;
      });
    });

    Future<void> tick() =>
        Future<void>.delayed(const Duration(milliseconds: 5));

    test('runs one embed at a time', () async {
      final a = service.embed('a', isDocument: true);
      final b = service.embed('b', isDocument: true);
      await tick();

      expect(started, ['a'], reason: 'b must wait for a');
      release['a']!.complete([1.0, 0.0]);
      await tick();
      expect(started, ['a', 'b']);
      release['b']!.complete([0.0, 1.0]);
      await Future.wait([a, b]);
    });

    test('a question jumps ahead of queued note and PDF embeds', () async {
      final inFlight = service.embed('note-1', isDocument: true);
      await tick();
      final chunk = service.embed('pdf-chunk', isDocument: true);
      final note = service.embed('note-2', isDocument: true);
      final question = service.embed('question');
      await tick();

      release['note-1']!.complete([1.0]);
      await tick();
      release['question']!.complete([1.0]);
      await tick();
      release['pdf-chunk']!.complete([1.0]);
      await tick();
      release['note-2']!.complete([1.0]);
      await Future.wait([inFlight, chunk, note, question]);

      expect(started, ['note-1', 'question', 'pdf-chunk', 'note-2']);
    });

    test('a question still waits for the embed already running', () async {
      final running = service.embed('note-1', isDocument: true);
      await tick();
      final question = service.embed('question');
      await tick();

      expect(started, ['note-1']);
      release['note-1']!.complete([1.0]);
      await tick();
      release['question']!.complete([1.0]);
      await Future.wait([running, question]);
    });

    test(
      'a cold embedder is opened once, not once per waiting embed',
      () async {
        final calls = [
          service.embed('a', isDocument: true),
          service.embed('b', isDocument: true),
          service.embed('c', isDocument: true),
        ];
        for (final t in ['a', 'b', 'c']) {
          await tick();
          release[t]?.complete([1.0]);
        }
        await Future.wait(calls);

        verify(
          () => gateway.getActiveEmbedder(
            preferredBackend: any(named: 'preferredBackend'),
          ),
        ).called(1);
      },
    );

    test('a failed embed frees the gate for the next one', () async {
      when(
        () => model.generateEmbedding('boom', taskType: any(named: 'taskType')),
      ).thenThrow(Exception('inference crashed'));

      final failed = await service.embed('boom', isDocument: true);
      final next = service.embed('fine', isDocument: true);
      await tick();
      release['fine']!.complete([1.0]);

      expect(failed, isEmpty);
      expect(await next, isNotEmpty);
    });

    test('a model that never loads answers [] for every waiter', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(false);
      when(
        () => gateway.installEmbedder(
          modelAsset: any(named: 'modelAsset'),
          tokenizerAsset: any(named: 'tokenizerAsset'),
        ),
      ).thenThrow(Exception('asset missing'));

      final results = await Future.wait([
        service.embed('a', isDocument: true),
        service.embed('question'),
      ]);

      expect(results, [isEmpty, isEmpty]);
    });
  });
}
