@Timeout(Duration(minutes: 3))
library;

import 'dart:io';
import 'dart:math';

import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/repositories/pending_embedding_repository_impl.dart';
import 'package:uniun/data/repositories/tostore_vector_repository_impl.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/indexing/note_embedding_worker.dart';

import '../_helpers/note_embedding_worker_factory.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/isar_test_harness.dart';

class _MockGateway extends Mock implements FlutterGemmaGateway {}

class _MockModel extends Mock implements EmbeddingModel {}

class _MockExtract extends Mock implements ExtractKnowledgeUseCase {}

/// Covers: a published note reaching search through the real queue table,
/// worker, EmbeddingService gate, isolate-owned vector store and repository;
/// only the embedder model and knowledge extraction are doubled.
void main() {
  late Isar isar;
  late Directory dir;
  late PendingEmbeddingRepositoryImpl pending;
  late _MockGateway gateway;
  late _MockModel model;
  late _MockExtract extract;
  late EmbeddingService embedding;
  late NoteVectorStore store;
  late TostoreVectorRepositoryImpl repo;
  late NoteEmbeddingWorker worker;
  late EmbedAndStoreNoteUseCase save;
  Object? modelFailure;
  Duration embedTime = const Duration(milliseconds: 2);

  /// A bag-of-words vector: texts that share words share direction. Each word
  /// gets its own dimension, so no two words ever collide.
  final dictionary = <String, int>{};
  List<double> vectorFor(String text) {
    final v = List<double>.filled(embeddingsDimensions, 0);
    for (final w in RegExp(
      r'[\p{L}\p{M}\p{N}]+',
      unicode: true,
    ).allMatches(text.toLowerCase())) {
      v[dictionary.putIfAbsent(w.group(0)!, () => dictionary.length)] += 1;
    }
    final norm = sqrt(v.fold<double>(0, (a, b) => a + b * b));
    return norm == 0 ? v : [for (final x in v) x / norm];
  }

  void wire() {
    embedding = EmbeddingService(gateway, EmbeddingQueue());
    repo = TostoreVectorRepositoryImpl(store, isar);
    worker = aNoteEmbeddingWorker(
      pending: pending,
      embedding: embedding,
      vector: repo,
      extract: extract,
      scheduler: InferenceScheduler(),
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
    dir = await Directory.systemTemp.createTemp('note_vector_flow_');
    pending = PendingEmbeddingRepositoryImpl(isar: isar);
    gateway = _MockGateway();
    model = _MockModel();
    extract = _MockExtract();
    modelFailure = null;
    embedTime = const Duration(milliseconds: 2);
    dictionary.clear();
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
      await Future<void>.delayed(embedTime);
      return vectorFor(i.positionalArguments.first as String);
    });
    when(() => extract.call(any())).thenAnswer((_) async {});
    store = await NoteVectorStore.open(dir.path);
    wire();
  });

  tearDown(() async {
    try {
      await store.close();
    } on StateError {
      // the test already stopped it
    }
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  /// Publishes a note the way the app does: the row exists, then it is queued.
  Future<void> publish(String id, String text) async {
    final known = await isar.noteModels.filter().eventIdEqualTo(id).findFirst();
    if (known == null) {
      await isar.writeTxn(
        () => isar.noteModels.put(noteRow(id, content: text)),
      );
    }
    await save.call((id, text));
  }

  Future<void> drained() async {
    for (var i = 0; i < 600; i++) {
      if ((await pending.count()).getOrElse(() => -1) == 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<List<String>> ask(String question, {int topK = 5}) async {
    final hits = await repo.search(
      await embedding.embed(question),
      topK: topK,
      minScore: 0.1,
    );
    return [for (final h in hits) h.noteId];
  }

  group('a published note is found by search', () {
    test(
      'each of three notes comes back first for a question about it',
      () async {
        await publish(
          'espresso',
          'espresso machines grind beans at high pressure',
        );
        await publish('rust', 'the rust borrow checker prevents data races');
        await publish(
          'garden',
          'tomatoes need sun water and staking in summer',
        );
        await drained();

        expect(
          (await ask('how do espresso machines grind beans')).first,
          'espresso',
        );
        expect((await ask('rust borrow checker data races')).first, 'rust');
        expect((await ask('water the tomatoes in summer')).first, 'garden');
      },
    );

    test('the hit carries the note text', () async {
      await publish('n1', 'small habits compound over time');
      await drained();

      final hits = await repo.search(
        await embedding.embed('habits compound'),
        topK: 5,
        minScore: 0.1,
      );

      expect(hits.single.content, 'small habits compound over time');
    });

    test(
      'forty notes are each found first by their own text',
      () async {
        for (var i = 0; i < 40; i++) {
          await publish('n$i', 'unique${i}word topic$i alpha beta');
        }
        await drained();

        var found = 0;
        for (var i = 0; i < 40; i++) {
          if ((await ask('unique${i}word topic$i')).first == 'n$i') found++;
        }
        expect(found, 40);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('a Hindi note is found by its own words', () async {
      await publish('hi', 'नमस्ते दुनिया सीखना जारी है');
      await publish('en', 'completely different english text');
      await drained();

      expect((await ask('नमस्ते दुनिया')).first, 'hi');
    });

    test(
      'a media-only note and a 3-character note are never searchable',
      () async {
        await publish('pic', 'https://blossom.example/abc.jpg');
        await publish('tiny', 'abc');
        await publish('real', 'a real note about gardens');
        await drained();

        final ids = await ask('gardens abc blossom');

        expect(ids, ['real']);
      },
    );

    test('publishing the same note twice leaves one result', () async {
      await publish('n1', 'the same note body twice');
      await publish('n1', 'the same note body twice');
      await drained();

      expect(await ask('same note body'), ['n1']);
    });
  });

  group('nothing is lost', () {
    test('an embedder that cannot load keeps the notes, and they are '
        'searchable once it can', () async {
      modelFailure = Exception('asset missing');
      wire();
      await publish('a', 'first note about oceans');
      await publish('b', 'second note about mountains');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect((await pending.count()).getOrElse(() => -1), 2);
      expect(await store.contains('a'), isFalse);

      modelFailure = null;
      wire();
      worker.nudge();
      await drained();

      expect((await ask('oceans')).first, 'a');
      expect((await ask('mountains')).first, 'b');
    });

    test('the app restarting keeps every stored vector and finishes a '
        'half-done queue', () async {
      await publish('before', 'a note saved in the first run about rivers');
      await drained();
      embedTime = const Duration(milliseconds: 40);
      await publish('during', 'a note saved just before the app stopped');
      await store.close();

      // "Next launch": new store, service and worker over the same folders.
      store = await NoteVectorStore.open(dir.path);
      embedTime = const Duration(milliseconds: 2);
      wire();
      worker.nudge();
      await drained();

      expect((await ask('rivers first run')).first, 'before');
      expect((await ask('saved just before the app stopped')).first, 'during');
    });

    test('the store isolate stopping mid-backlog loses no note: every row '
        'stays, none is dropped, and a new store takes them all', () async {
      embedTime = const Duration(milliseconds: 30);
      for (var i = 0; i < 6; i++) {
        await publish('n$i', 'backlog note number $i about topic$i');
      }
      await Future<void>.delayed(const Duration(milliseconds: 70));
      store.kill();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Far more failing passes than the attempt limit.
      for (var i = 0; i < NoteEmbeddingWorker.maxAttempts + 3; i++) {
        worker.nudge();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final left = (await pending.count()).getOrElse(() => -1);
      expect(
        left,
        greaterThan(0),
        reason:
            'notes embedded before the stop are '
            'stored; the rest must still be queued, not dropped',
      );

      store = await NoteVectorStore.open(dir.path);
      embedTime = const Duration(milliseconds: 2);
      wire();
      worker.nudge();
      await drained();

      for (var i = 0; i < 6; i++) {
        expect((await ask('topic$i')).first, 'n$i', reason: 'note n$i');
      }
      verify(() => extract.call(any())).called(6);
    });
  });

  group('knowledge extraction', () {
    test('runs once per stored note, after its vector is stored', () async {
      var storedWhenExtracted = false;
      when(() => extract.call(any())).thenAnswer((i) async {
        final input =
            i.positionalArguments.first as (String, String, List<double>);
        storedWhenExtracted = await store.contains(input.$1);
      });

      await publish('n1', 'a note whose vector must exist before extraction');
      await drained();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => extract.call(any())).called(1);
      expect(storedWhenExtracted, isTrue);
    });
  });
}
