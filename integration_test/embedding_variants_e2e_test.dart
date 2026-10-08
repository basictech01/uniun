// Compares Gecko embedding models on a real device: time per embed, vector size,
// and search quality with real vectors, both exact (rank by cosine) and through
// NoteVectorStore's approximate index. The model is picked with
// --dart-define=EMBED_MODEL=asset|256|512 (default: the bundled 1024 asset); the
// 256 and 512 files are pushed with
//   adb push Gecko_256_quant.tflite /data/local/tmp/uniun_test/
// and the test prints one VARIANT line.
//
//   scripts/device_test.sh run integration_test/embedding_variants_e2e_test.dart \
//     --dart-define=EMBED_MODEL=256 [--dart-define=TIMING_ONLY=1]

import 'dart:io';
import 'dart:math';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

const _variant = String.fromEnvironment('EMBED_MODEL', defaultValue: 'asset');

/// --dart-define=TIMING_ONLY=1 stops after the speed lines (a few embeds).
const _timingOnly = bool.fromEnvironment('TIMING_ONLY');

/// (note, a question about it that shares few of its words)
const _pairs = <(String, String)>[
  (
    'Espresso needs finely ground beans and about nine bars of pressure to extract properly.',
    'How do I get a good shot from my coffee machine?',
  ),
  (
    'The Rust borrow checker stops two parts of a program from changing the same data at once.',
    'Why does Rust prevent data races?',
  ),
  (
    'Tomato plants need full sun, regular watering and a stake or cage as they grow tall.',
    'What care do tomatoes need in summer?',
  ),
  (
    'Compound interest means you earn returns on your earlier returns, so savings grow faster over time.',
    'Why do long term investments grow so fast?',
  ),
  (
    'A good night of sleep usually means seven to nine hours without waking up repeatedly.',
    'How many hours should an adult sleep?',
  ),
  (
    'The Pythagorean theorem says the square of the hypotenuse equals the sum of the squares of the other two sides.',
    'How do I find the long side of a right triangle?',
  ),
  (
    'To reduce the build time of our Flutter app we enabled the Gradle cache and parallel builds.',
    'How did we speed up Android compilation?',
  ),
  (
    'Marathon training plans usually build up the weekly long run slowly and include rest days.',
    'How should I prepare to run 42 kilometres?',
  ),
  (
    'The Nostr protocol uses relays to store and forward signed events instead of a central server.',
    'How does a decentralised social network share posts without one company?',
  ),
  (
    'Sourdough bread needs a live starter, a long slow rise and a very hot oven for a crisp crust.',
    'What is the secret to a crusty homemade loaf?',
  ),
  (
    'Photosynthesis lets plants turn sunlight, water and carbon dioxide into sugar and oxygen.',
    'How do leaves make food?',
  ),
  (
    'Our team agreed to review pull requests within one working day and keep them under 400 lines.',
    'What is our code review policy?',
  ),
  (
    'Learning a language works best with daily short practice and speaking with real people early.',
    'What is the best way to become fluent in Spanish?',
  ),
  (
    'The tides are caused mainly by the moon\'s gravity pulling on the oceans.',
    'Why does the sea level rise and fall every day?',
  ),
  (
    'To change a flat bicycle tyre remove the wheel, take out the tube, patch the hole and refit it.',
    'How do I fix a puncture on my bike?',
  ),
  (
    'A balanced budget lists income first, then fixed bills, then savings, and what is left is for spending.',
    'How should I plan my monthly money?',
  ),
];

double _cosine(List<double> a, List<double> b) {
  var dot = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / (sqrt(na) * sqrt(nb));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Gecko $_variant: speed and search quality',
    (tester) async {
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final gateway = FlutterGemmaGatewayImpl();
      if (_variant == 'asset') {
        await EmbeddingService(gateway, EmbeddingQueue()).ensureInstalled();
      } else {
        await FlutterGemma.installEmbedder()
            .modelFromFile(
              '/data/local/tmp/uniun_test/Gecko_${_variant}_quant.tflite',
            )
            .tokenizerFromAsset(EmbeddingService.tokenizerAsset)
            .install();
      }
      final model = await gateway.getActiveEmbedder(
        preferredBackend: PreferredBackend.cpu,
      );

      Future<(List<double>, int)> timed(String text, TaskType task) async {
        final sw = Stopwatch()..start();
        final v = await model.generateEmbedding(text, taskType: task);
        return (v, sw.elapsedMilliseconds);
      }

      final cold = (await timed('warm up', TaskType.retrievalDocument)).$2;
      final short = <int>[];
      for (var i = 0; i < 3; i++) {
        short.add((await timed(_pairs[0].$1, TaskType.retrievalDocument)).$2);
      }
      final long = (await timed(
        List.filled(
          40,
          _pairs.map((p) => p.$1).join(' '),
        ).join(' ').substring(0, 3500),
        TaskType.retrievalDocument,
      )).$2;

      final avgShortOnly = short.reduce((a, b) => a + b) / short.length;
      if (_timingOnly) {
        // ignore: avoid_print
        print(
          '\nTIMING $_variant: cold $cold ms, short note '
          '${avgShortOnly.toStringAsFixed(0)} ms avg of 3 ($short), '
          '3,500-char note $long ms\n',
        );
        return;
      }

      final notes = <List<double>>[];
      final questions = <List<double>>[];
      for (final (note, question) in _pairs) {
        notes.add((await timed(note, TaskType.retrievalDocument)).$1);
        questions.add((await timed(question, TaskType.retrievalQuery)).$1);
      }
      final dims = notes.first.length;

      var top1 = 0, top3 = 0;
      final exactBest = <int>[];
      for (var q = 0; q < questions.length; q++) {
        final order = List.generate(notes.length, (i) => i)
          ..sort(
            (a, b) => _cosine(
              questions[q],
              notes[b],
            ).compareTo(_cosine(questions[q], notes[a])),
          );
        exactBest.add(order.first);
        if (order.first == q) top1++;
        if (order.take(3).contains(q)) top3++;
      }

      // The same vectors through the approximate index the app uses.
      final dir = await Directory.systemTemp.createTemp('variants_');
      var annTop1 = 0, annHasExact = 0, annOwn = 0;
      try {
        final store = await NoteVectorStore.open(dir.path);
        for (var i = 0; i < notes.length; i++) {
          await store.upsert('n$i', notes[i]);
        }
        for (var q = 0; q < questions.length; q++) {
          final hits = await store.search(questions[q], topK: 3);
          final ids = hits.map((h) => h.id).toList();
          if (ids.isNotEmpty && ids.first == 'n${exactBest[q]}') annTop1++;
          if (ids.contains('n${exactBest[q]}')) annHasExact++;
          final own = await store.search(notes[q], topK: 1);
          if (own.isNotEmpty && own.first.id == 'n$q') annOwn++;
        }
        await store.close();
      } finally {
        await dir.delete(recursive: true);
      }

      final avgShort = short.reduce((a, b) => a + b) / short.length;
      // ignore: avoid_print
      print(
        '\nVARIANT $_variant: vector size $dims, cold $cold ms, '
        'short note ${avgShort.toStringAsFixed(0)} ms avg of 3, 3,500-char note $long ms'
        '\nVARIANT $_variant: exact search puts the right note first for $top1/16 questions, '
        'in the top 3 for $top3/16'
        '\nVARIANT $_variant: through the app\'s approximate index: its top hit matches the '
        'exact top hit for $annTop1/16, exact top hit is within its top 3 for $annHasExact/16, '
        'each note is found by its own vector $annOwn/16\n',
      );

      expect(dims, greaterThan(0));
      expect(annOwn, greaterThanOrEqualTo(15));
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
