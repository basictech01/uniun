// Times the bundled Gecko embedder three ways on a real device, for #125/#231:
// one call at a time, two at a time (what EmbeddingQueue allows), and
// flutter_gemma's generateEmbeddings. Prints a table; it only asserts that every way
// returns the same number of vectors, of the same size, for the same text.
//
//   scripts/device_test.sh run integration_test/embedding_benchmark_test.dart

import 'dart:math' as math;

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniun/core/utils/llm_backend.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

const _count = int.fromEnvironment('NOTES', defaultValue: 12);

/// Note-sized text (~200 chars), different each time so nothing is cached.
List<String> _texts() => [
  for (var i = 0; i < _count; i++)
    'Note $i: learning about topic ${i % 13}. Small habits compound over '
        'time, and the way I review my notes on day ${i % 7} changes what '
        'I remember. Idea #${i * 7919 % 1000} links to project ${i % 5}.',
];

double _cosine(List<double> a, List<double> b) {
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / (math.sqrt(na) * math.sqrt(nb));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'per-call vs two-at-a-time vs generateEmbeddings',
    (tester) async {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final gateway = FlutterGemmaGatewayImpl();
      final service = EmbeddingService(gateway, EmbeddingQueue());
      await service.ensureInstalled();
      final model = await gateway.getActiveEmbedder(
        preferredBackend: preferredLlmBackend,
      );
      final texts = _texts();
      const task = TaskType.retrievalDocument;

      // Warm-up: the first calls pay model load and GPU setup.
      final warm = Stopwatch()..start();
      await model.generateEmbedding(texts[0], taskType: task);
      // ignore: avoid_print
      print('BENCH first call (cold): ${warm.elapsedMilliseconds} ms');
      warm.reset();
      await model.generateEmbedding(texts[1], taskType: task);
      // ignore: avoid_print
      print('BENCH second call (warm): ${warm.elapsedMilliseconds} ms');

      Future<int> time(
        Future<List<List<double>>> Function() run,
        List<List<double>> out,
      ) async {
        final sw = Stopwatch()..start();
        out.addAll(await run());
        sw.stop();
        return sw.elapsedMilliseconds;
      }

      final seq = <List<double>>[];
      final seqMs = await time(() async {
        final r = <List<double>>[];
        for (final t in texts) {
          final one = Stopwatch()..start();
          r.add(await model.generateEmbedding(t, taskType: task));
          // ignore: avoid_print
          print('BENCH one call: ${one.elapsedMilliseconds} ms');
        }
        return r;
      }, seq);

      final queue = EmbeddingQueue();
      final two = <List<double>>[];
      final twoMs = await time(
        () => Future.wait([
          for (final t in texts)
            queue.run(() => model.generateEmbedding(t, taskType: task)),
        ]),
        two,
      );

      final batch16 = <List<double>>[];
      final batch16Ms = await time(() async {
        final r = <List<double>>[];
        for (var i = 0; i < texts.length; i += 4) {
          r.addAll(
            await model.generateEmbeddings(
              texts.sublist(i, math.min(i + 4, texts.length)),
              taskType: task,
            ),
          );
        }
        return r;
      }, batch16);

      final batchAll = <List<double>>[];
      final batchAllMs = await time(
        () => model.generateEmbeddings(texts, taskType: task),
        batchAll,
      );

      String row(String name, int ms) =>
          '${name.padRight(26)} '
          '${ms.toString().padLeft(6)} ms total   '
          '${(ms / _count).toStringAsFixed(1).padLeft(6)} ms/note   '
          '${(seqMs / ms).toStringAsFixed(2)}x vs sequential';
      // ignore: avoid_print
      print(
        '\nEMBEDDING BENCHMARK ($_count notes, backend=$preferredLlmBackend)\n'
        '${row('one at a time', seqMs)}\n'
        '${row('2 at a time (queue)', twoMs)}\n'
        '${row('generateEmbeddings x4', batch16Ms)}\n'
        '${row('generateEmbeddings all', batchAllMs)}\n',
      );

      // The model emits 768 where the app declares 1024 (#234), so check that
      // every way agrees with the sequential one instead of a fixed length.
      for (final r in [seq, two, batch16, batchAll]) {
        expect(r, hasLength(_count));
        expect(r.first, isNotEmpty);
        expect(r.first, hasLength(seq.first.length));
      }
      expect(_cosine(seq.first, batch16.first), greaterThan(0.99));
      expect(_cosine(seq.last, batchAll.last), greaterThan(0.99));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  testWidgets(
    'text length: a few characters vs several thousand',
    (tester) async {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final gateway = FlutterGemmaGatewayImpl();
      await EmbeddingService(gateway, EmbeddingQueue()).ensureInstalled();
      final model = await gateway.getActiveEmbedder(
        preferredBackend: preferredLlmBackend,
      );
      await model.generateEmbedding(
        'warm up',
        taskType: TaskType.retrievalDocument,
      );

      final lines = <String>[];
      for (final (label, text) in [
        ('4 chars', 'Hi!!'),
        ('~200 chars', 'Small habits compound over time. ' * 6),
        ('~1,500 chars', 'Small habits compound over time. ' * 45),
        ('~6,000 chars', 'Small habits compound over time. ' * 180),
      ]) {
        final sw = Stopwatch()..start();
        await model.generateEmbedding(
          text,
          taskType: TaskType.retrievalDocument,
        );
        lines.add('${label.padRight(14)} ${sw.elapsedMilliseconds} ms');
      }
      // ignore: avoid_print
      print('\nTEXT LENGTH vs EMBED TIME\n${lines.join('\n')}\n');
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
