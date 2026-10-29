import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_edge_ai_gateway.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import '../../../../_helpers/fake_embedding_model.dart';

class _MockGateway extends Mock implements FlutterEdgeAiGateway {}


/// Covers EmbeddingService's real orchestration logic — install-once,
/// GPU→CPU backend fallback, embed()'s lazy-init + degrade-to-empty
/// contract, L2 normalisation — via the FlutterEdgeAiGateway seam
/// (see docs/AUDIT.md, Group A native-ceiling closure). Before the seam,
/// this class called `FlutterEdgeAi.*` statics directly with no mockable
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
    when(() => gateway.installEmbedder(
          modelAsset: any(named: 'modelAsset'),
          tokenizerAsset: any(named: 'tokenizerAsset'),
        )).thenAnswer((_) async {});
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
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);

      await service.init();

      expect(service.isReady, isTrue);
      verify(() => gateway.getActiveEmbedder(preferredBackend: PreferredBackend.gpu))
          .called(1);
    });

    test('is idempotent — a second call is a no-op once ready', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
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
      final cpuModel = FakeEmbeddingModel();
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
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any()))
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
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any()))
          .thenAnswer((_) async => [1.0]);

      await service.embed('q', isDocument: true);
      await service.embed('q');

      verify(() => model.calls.embed('q', TaskType.retrievalDocument))
          .called(1);
      verify(() => model.calls.embed('q', TaskType.retrievalQuery))
          .called(1);
    });

    test('L2-normalizes a non-unit vector', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any()))
          .thenAnswer((_) async => [3.0, 4.0]); // norm = 5

      final vec = await service.embed('hello');

      expect(vec[0], closeTo(0.6, 1e-9));
      expect(vec[1], closeTo(0.8, 1e-9));
    });

    test('a zero vector is returned unchanged (no divide-by-zero)', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any()))
          .thenAnswer((_) async => [0.0, 0.0]);

      final vec = await service.embed('hello');

      expect(vec, [0.0, 0.0]);
    });

    test('an over-long input is shortened by the reported ratio and retried',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      final seen = <int>[];
      when(() => model.calls.embed(any(), any())).thenAnswer((i) async {
        final text = i.positionalArguments.first as String;
        seen.add(text.length);
        if (text.length > 600) {
          throw const EmbeddingInputTooLongException(
            'too long',
            maxInputTokens: 512,
            actualTokens: 1024,
          );
        }
        return [1.0, 0.0];
      });

      final vec = await service.embed('x' * 1000, isDocument: true);

      expect(vec, [1.0, 0.0]);
      expect(seen.first, 1000);
      expect(seen.last, lessThanOrEqualTo(600));
    });

    test('an input that never fits gives up with [] instead of looping',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      var calls = 0;
      when(() => model.calls.embed(any(), any())).thenAnswer((_) async {
        calls++;
        throw const EmbeddingInputTooLongException(
          'too long',
          maxInputTokens: 8,
        );
      });

      final vec = await service.embed('y' * 5000);

      expect(vec, isEmpty);
      expect(calls, 4);
    });

    test('a one-character input that is too long stops after one try',
        () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      var calls = 0;
      when(() => model.calls.embed(any(), any())).thenAnswer((_) async {
        calls++;
        throw const EmbeddingInputTooLongException('x', maxInputTokens: 1);
      });

      expect(await service.embed('z'), isEmpty);
      expect(calls, 1);
    });

    test('a generateEmbedding failure degrades to [], not a throw', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any()))
          .thenThrow(Exception('inference crashed'));

      final vec = await service.embed('hello');

      expect(vec, isEmpty);
    });
  });

  group('embedNote (#296)', () {
    late FakeEmbeddingModel model;
    late List<String> seen;

    setUp(() {
      model = FakeEmbeddingModel(maxInputTokens: 256);
      seen = [];
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      when(() => gateway.getActiveEmbedder(
            preferredBackend: any(named: 'preferredBackend'),
          )).thenAnswer((_) async => model);
      when(() => model.calls.embed(any(), any())).thenAnswer((i) async {
        seen.add(i.positionalArguments.first as String);
        return [1.0, 0.0];
      });
    });

    String sentences(int n) =>
        List.generate(n, (i) => 'Sentence number $i is here.').join(' ');

    test('a short note is one piece embedded as a document', () async {
      expect(await service.embedNote('my bike service is on friday'), [
        [1.0, 0.0],
      ]);

      verify(() => model.calls.embed(
            'my bike service is on friday',
            TaskType.retrievalDocument,
          )).called(1);
    });

    test('a note of exactly the piece length stays one piece', () async {
      expect(await service.embedNote('a' * EmbeddingService.notePieceChars),
          hasLength(1));
    });

    test('a long note becomes pieces no longer than the limit, in order',
        () async {
      final text = sentences(60); // ~1,600 characters
      final vecs = await service.embedNote(text);

      expect(vecs.length, greaterThan(1));
      expect(seen.length, vecs.length);
      expect(seen.every((p) => p.length <= EmbeddingService.notePieceChars),
          isTrue);
      expect(seen.first, startsWith('Sentence number 0'));
      expect(seen.last, endsWith('Sentence number 59 is here.'));
    });

    test('a note beyond the piece cap is cut at the cap', () async {
      final vecs = await service.embedNote(sentences(2000));

      expect(vecs, hasLength(EmbeddingService.maxNotePieces));
    });

    test('a piece the model finds too long is split in two, never cut',
        () async {
      var rejected = 0;
      when(() => model.calls.embed(any(), any())).thenAnswer((i) async {
        final text = i.positionalArguments.first as String;
        seen.add(text);
        if (text.length > 300) {
          rejected++;
          throw const EmbeddingInputTooLongException(
            'too long',
            maxInputTokens: 256,
            actualTokens: 400,
          );
        }
        return [1.0, 0.0];
      });
      final text = 'word ' * 120; // 600 characters, one piece

      final vecs = await service.embedNote(text.trim());

      expect(rejected, 1);
      expect(vecs.length, 2);
      final accepted = seen.where((p) => p.length <= 300).join(' ');
      expect(accepted.replaceAll(' ', '').length, text.replaceAll(' ', '').length,
          reason: 'every word is embedded');
    });

    test('a piece that can never fit gives up with [] after the split depth',
        () async {
      when(() => model.calls.embed(any(), any())).thenThrow(
        const EmbeddingInputTooLongException('x', maxInputTokens: 1),
      );

      expect(await service.embedNote('hello there world'), isEmpty);
    });

    test('one failing piece fails the note: nothing half-embedded', () async {
      var calls = 0;
      when(() => model.calls.embed(any(), any())).thenAnswer((_) async {
        calls++;
        if (calls == 2) throw Exception('inference crashed');
        return [1.0, 0.0];
      });

      expect(await service.embedNote(sentences(60)), isEmpty);
    });

    test('model not loaded answers [] so the worker keeps the note', () async {
      when(() => gateway.getActiveEmbedder(
            preferredBackend: any(named: 'preferredBackend'),
          )).thenThrow(Exception('no model'));

      expect(await service.embedNote('anything at all'), isEmpty);
      expect(service.isReady, isFalse);
    });

    test('an empty or blank note has no pieces', () async {
      expect(await service.embedNote('   \n\n  '), isEmpty);
    });

    test('unicode, emoji and Devanagari notes are embedded like any other',
        () async {
      final text = List.generate(
        80,
        (i) => 'नमस्ते दुनिया $i 🌟 مرحبا।',
      ).join(' ');

      final vecs = await service.embedNote(text);

      expect(vecs, isNotEmpty);
      expect(seen.join(' ').contains('🌟'), isTrue);
    });

    test('a question waits for at most one piece of a long note', () async {
      final order = <String>[];
      when(() => model.calls.embed(any(), any())).thenAnswer((i) async {
        order.add(i.positionalArguments.first as String);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return [1.0, 0.0];
      });

      final note = service.embedNote(sentences(120));
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await service.embed('what is my bike service date?');
      await note;

      final q = order.indexOf('what is my bike service date?');
      expect(q, lessThan(order.length - 1),
          reason: 'the question did not wait for the whole note');
    });

    test('dispose forgets the model, the next embed loads it again', () async {
      await service.embedNote('first');
      when(() => model.calls.close()).thenAnswer((_) async {});

      await service.dispose();
      await service.embedNote('second');

      verify(() => gateway.getActiveEmbedder(
            preferredBackend: any(named: 'preferredBackend'),
          )).called(2);
    });
  });

  group('dispose', () {
    test('closes the model and resets isReady to false', () async {
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      final model = FakeEmbeddingModel();
      when(() => gateway.getActiveEmbedder(preferredBackend: any(named: 'preferredBackend')))
          .thenAnswer((_) async => model);
      when(() => model.calls.close()).thenAnswer((_) async {});
      await service.init();

      await service.dispose();

      verify(() => model.calls.close()).called(1);
      expect(service.isReady, isFalse);
    });

    test('is a no-op when nothing was ever loaded', () async {
      await service.dispose();

      expect(service.isReady, isFalse);
    });
  });

  group('the shared gate', () {
    late FakeEmbeddingModel model;
    final started = <String>[];
    final release = <String, Completer<List<double>>>{};

    setUp(() {
      started.clear();
      release.clear();
      model = FakeEmbeddingModel();
      when(() => gateway.hasActiveEmbedder()).thenReturn(true);
      when(
        () => gateway.getActiveEmbedder(
          preferredBackend: any(named: 'preferredBackend'),
        ),
      ).thenAnswer((_) async => model);
      // Each embed starts, then waits until the test lets it finish.
      when(
        () => model.calls.embed(any(), any()),
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
        () => model.calls.embed('boom', any()),
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
