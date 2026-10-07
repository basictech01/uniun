import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/services/note_embedding_worker.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

import '../_helpers/isar_test_harness.dart';

class _MockGateway extends Mock implements FlutterGemmaGateway {}

class _MockModel extends Mock implements EmbeddingModel {}

class _MockExtract extends Mock implements ExtractKnowledgeUseCase {}

class _MockChunkVectors extends Mock implements DocumentVectorRepository {}

/// In-memory note vector store: the only thing doubled besides the embedder.
class _Vectors implements VectorRepository {
  final Map<String, List<double>> stored = {};
  Object? failWith;

  @override
  Future<void> upsert(String id, List<double> vector) async {
    if (failWith != null) throw failWith!;
    stored[id] = vector;
  }

  @override
  Future<void> delete(String id) async => stored.remove(id);

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async => const [];
}

/// Saving a note to its vector being stored, through the real queue table, the
/// real worker, the real entry use case and the real [EmbeddingService] with
/// its gate. Only the embedder model and the vector store are doubled: the
/// model needs flutter_gemma, which is device-only (integration_test/ covers
/// the real one).
void main() {
  late Isar isar;
  late PendingEmbeddingRepositoryImpl pending;
  late _MockGateway gateway;
  late _MockModel model;
  late EmbeddingService embedding;
  late _Vectors vectors;
  late _MockExtract extract;
  late NoteEmbeddingWorker worker;
  late InferenceScheduler scheduler;
  late EmbedAndStoreNoteUseCase save;

  /// Texts the embedder was asked for, in order, with whether it is a document.
  late List<(String, TaskType)> asked;
  var inFlight = 0, maxInFlight = 0;
  Duration embedTime = const Duration(milliseconds: 5);
  Object? modelFailure;
  Set<String> poison = {};
  bool emptyVectors = false;

  void wire() {
    embedding = EmbeddingService(gateway, EmbeddingQueue());
    scheduler = InferenceScheduler();
    worker = NoteEmbeddingWorker(
      pending,
      embedding,
      vectors,
      extract,
      scheduler,
    );
    save = EmbedAndStoreNoteUseCase(pending, worker);
  }

  setUpAll(() {
    registerFallbackValue(TaskType.retrievalQuery);
    registerFallbackValue(PreferredBackend.cpu);
    registerFallbackValue(('', '', <double>[]));
  });

  setUp(() async {
    isar = await openTestIsar();
    pending = PendingEmbeddingRepositoryImpl(isar: isar);
    gateway = _MockGateway();
    model = _MockModel();
    vectors = _Vectors();
    extract = _MockExtract();
    asked = [];
    inFlight = maxInFlight = 0;
    embedTime = const Duration(milliseconds: 5);
    modelFailure = null;
    poison = {};
    emptyVectors = false;

    when(() => gateway.hasActiveEmbedder()).thenReturn(true);
    when(
      () => gateway.getActiveEmbedder(
        preferredBackend: any(named: 'preferredBackend'),
      ),
    ).thenAnswer((_) async {
      if (modelFailure != null) throw modelFailure!;
      return model;
    });
    when(
      () => model.generateEmbedding(any(), taskType: any(named: 'taskType')),
    ).thenAnswer((i) async {
      final text = i.positionalArguments.first as String;
      asked.add((text, i.namedArguments[#taskType] as TaskType));
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(embedTime);
      inFlight--;
      if (poison.contains(text)) throw StateError('cannot embed "$text"');
      return emptyVectors ? <double>[] : [text.length.toDouble(), 1.0];
    });
    when(() => extract.call(any())).thenAnswer((_) async {});
    wire();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  /// Waits until [done] is true (the pass runs unawaited).
  Future<void> until(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!done() && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> drained() async {
    for (var i = 0; i < 300; i++) {
      if (await pending.count() == 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  group('a saved note reaches the vector store', () {
    test(
      'queued, embedded as a document, stored, extracted, queue empty',
      () async {
        await save.call(('n1', 'Small habits compound over time.'));
        await drained();

        expect(vectors.stored.keys, ['n1']);
        expect(asked.single.$1, 'Small habits compound over time.');
        expect(asked.single.$2, TaskType.retrievalDocument);
        expect(await pending.count(), 0);
        final captured =
            verify(() => extract.call(captureAny())).captured.single
                as (String, String, List<double>);
        expect(captured.$1, 'n1');
      },
    );

    test('a caption keeps its words and loses its URL', () async {
      await save.call(('n1', 'look at this https://x.io/pic.png please'));
      await drained();

      expect(asked.single.$1, 'look at this  please');
    });

    test('a media-only note is never queued', () async {
      await save.call(('n1', 'https://blossom.example/abc.jpg'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await pending.count(), 0);
      expect(asked, isEmpty);
      expect(vectors.stored, isEmpty);
    });

    test(
      'whitespace, a bare emoji and 3 characters are skipped; 4 are kept',
      () async {
        for (final (id, text) in [
          ('a', '    \n\t '),
          ('b', '🌟'),
          ('c', 'abc'),
          ('d', 'abcd'),
        ]) {
          await save.call((id, text));
        }
        await drained();

        expect(vectors.stored.keys, ['d']);
      },
    );

    test('unicode, RTL and very long text go through unchanged', () async {
      final long = 'x' * 20000;
      for (final (id, text) in [
        ('hi', 'नमस्ते दुनिया — सीखना जारी है'),
        ('ar', 'مرحبا بالعالم، التعلم مستمر'),
        ('emoji', 'Shipped it 🚀🎉 finally'),
        ('long', long),
      ]) {
        await save.call((id, text));
      }
      await drained();

      expect(vectors.stored.keys.toSet(), {'hi', 'ar', 'emoji', 'long'});
      expect(asked.map((a) => a.$1), contains(long));
    });

    test('every length from the 4-character minimum to 200,000 characters is '
        'embedded whole', () async {
      final lengths = {
        'min': 4,
        'short': 5,
        'tweet': 280,
        'paragraph': 1500,
        'article': 20000,
        'huge': 200000,
      };
      for (final entry in lengths.entries) {
        await save.call((entry.key, 'w' * entry.value));
      }
      await drained();

      expect(vectors.stored.keys.toSet(), lengths.keys.toSet());
      for (final entry in lengths.entries) {
        expect(
          asked.map((a) => a.$1.length),
          contains(entry.value),
          reason: '${entry.key} must reach the embedder uncut',
        );
      }
    });

    test('a note that is only a long URL or only whitespace never reaches the '
        'embedder, whatever its length', () async {
      await save.call(('url', 'https://example.com/${'a' * 5000}'));
      await save.call(('blank', ' ' * 5000));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(asked, isEmpty);
      expect(await pending.count(), 0);
    });

    test('saving the same note twice embeds it once', () async {
      await save.call(('n1', 'the same note body'));
      await save.call(('n1', 'the same note body'));
      await drained();

      expect(asked, hasLength(1));
      expect(vectors.stored.keys, ['n1']);
    });
  });

  group('nothing is lost', () {
    test('an embedder that cannot load keeps the notes, a later pass stores '
        'them', () async {
      modelFailure = Exception('asset missing');
      wire();
      await save.call(('n1', 'first note body'));
      await save.call(('n2', 'second note body'));
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(await pending.count(), 2);
      expect(vectors.stored, isEmpty);

      modelFailure = null;
      wire();
      worker.nudge();
      await drained();

      expect(vectors.stored.keys.toSet(), {'n1', 'n2'});
    });

    test(
      'a model that answers an empty vector is treated as not ready',
      () async {
        emptyVectors = true;
        await save.call(('n1', 'a note with text'));
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(await pending.count(), 1);
        expect(vectors.stored, isEmpty);
        verifyNever(() => extract.call(any()));
      },
    );

    test(
      'the app dying mid-embed loses nothing: the next launch finishes it',
      () async {
        final hang = Completer<List<double>>();
        when(
          () =>
              model.generateEmbedding(any(), taskType: any(named: 'taskType')),
        ).thenAnswer((_) => hang.future); // never completes: the process "died"
        await save.call(('n1', 'a note that was mid-embed'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(await pending.count(), 1, reason: 'row survives the death');

        // "Next launch": new service and worker over the same database.
        when(
          () =>
              model.generateEmbedding(any(), taskType: any(named: 'taskType')),
        ).thenAnswer((_) async => [1.0, 2.0]);
        wire();
        worker.nudge();
        await drained();

        expect(vectors.stored.keys, ['n1']);
      },
    );

    test('a failing vector store keeps the note and skips extraction until it '
        'recovers', () async {
      vectors.failWith = StateError('store unavailable');
      await save.call(('n1', 'a note awaiting the store'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(await pending.count(), 1);
      verifyNever(() => extract.call(any()));

      vectors.failWith = null;
      worker.nudge();
      await drained();

      expect(vectors.stored.keys, ['n1']);
      verify(() => extract.call(any())).called(1);
    });

    test('a note that can never be embedded is dropped after 3 tries and does '
        'not hold up the rest', () async {
      poison = {'this note is poison'};
      await save.call(('good', 'a perfectly fine note'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await save.call(('bad', 'this note is poison'));
      for (var i = 0; i < NoteEmbeddingWorker.maxAttempts; i++) {
        worker.nudge();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      await drained();

      expect(vectors.stored.keys, ['good']);
      expect(await pending.count(), 0);
    });
  });

  group('load', () {
    test('twenty notes saved at once are each embedded exactly once, one at a '
        'time', () async {
      await Future.wait([
        for (var i = 0; i < 20; i++) save.call(('n$i', 'note body number $i')),
      ]);
      await until(() => vectors.stored.length == 20);
      await drained();

      expect(vectors.stored, hasLength(20));
      expect(asked, hasLength(20));
      expect(maxInFlight, 1);
    });

    test('a note saved while the backlog drains is not skipped', () async {
      embedTime = const Duration(milliseconds: 20);
      for (var i = 0; i < 5; i++) {
        await save.call(('old$i', 'old backlog note $i'));
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await save.call(('fresh', 'a note saved mid-drain'));
      await until(() => vectors.stored.length == 6);

      expect(vectors.stored.keys, contains('fresh'));
      expect(vectors.stored, hasLength(6));
    });
  });

  group('sharing the embedder with questions and PDF chunks', () {
    test('a Shiv question waits for one embed, not for the backlog', () async {
      embedTime = const Duration(milliseconds: 40);
      for (var i = 0; i < 6; i++) {
        await save.call(('n$i', 'backlog note number $i'));
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final started = asked.length;
      final answered = await embedding.embed('what did I write about habits');

      expect(answered, isNotEmpty);
      // The question ran after the in-flight note(s) at that moment, ahead of
      // the rest of the backlog.
      final position = asked.indexWhere(
        (a) => a.$1 == 'what did I write about habits',
      );
      expect(position, lessThanOrEqualTo(started + 1));
      expect(asked[position].$2, TaskType.retrievalQuery);
      await drained();
      expect(vectors.stored, hasLength(6));
    });

    test('a PDF chunk and a note never embed at the same time', () async {
      final chunks = _MockChunkVectors();
      when(() => chunks.upsert(any(), any())).thenAnswer((_) async {});
      final chunkUseCase = EmbedAndStoreChunkUseCase(embedding, chunks);
      embedTime = const Duration(milliseconds: 15);

      await Future.wait([
        for (var i = 0; i < 4; i++) save.call(('n$i', 'note body number $i')),
        for (var i = 0; i < 4; i++)
          chunkUseCase.call(('doc:$i', 'pdf chunk text number $i')),
      ]);
      await drained();

      expect(maxInFlight, 1);
      verify(() => chunks.upsert(any(), any())).called(4);
      expect(vectors.stored, hasLength(4));
    });

    test(
      'a chunk embed while the embedder cannot load reports not stored',
      () async {
        modelFailure = Exception('asset missing');
        wire();
        final chunks = _MockChunkVectors();

        final stored = await EmbedAndStoreChunkUseCase(
          embedding,
          chunks,
        ).call(('doc:1', 'pdf chunk text'));

        expect(stored, isFalse);
        verifyNever(() => chunks.upsert(any(), any()));
      },
    );
  });
}
