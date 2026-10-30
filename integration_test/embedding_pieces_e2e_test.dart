// Real-device guard for long notes embedded in pieces on the 256-token Gecko
// file (#296). Runs the real EmbeddingService over a corpus of long, short and
// very long notes and checks that the right note is found as often as the
// measurements in docs/SHIVA/embedding.md say it is.
//
//   scripts/device_test.sh run integration_test/embedding_pieces_e2e_test.dart

import 'dart:math';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_embeddings/flutter_edge_ai_embeddings.dart'
    show GemmaEmbeddingTokenizers;
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_edge_ai_mediapipe/flutter_edge_ai_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

import 'support/embedding_corpus.dart';

double _dot(List<double> a, List<double> b) {
  var d = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < a.length; i++) {
    d += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return d / (sqrt(na) * sqrt(nb));
}

const _unrelatedQuestions = <String>[
  'What is the capital of Mongolia?',
  'How do I change a flat tyre on a bicycle?',
  'Who won the football world cup in 1998?',
  'What is the boiling point of liquid nitrogen?',
  'How many moons does Jupiter have?',
  'What does the Rust borrow checker do?',
  'Which chess opening starts with e4 e5 Nf3 Nc6 Bb5?',
  'How do I renew a passport in Canada?',
  'What is the plot of the film Inception?',
  'How do tides work?',
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'long notes in pieces are found as well as short ones',
    (tester) async {
      await FlutterEdgeAi.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
        embeddingTokenizers: const [GemmaEmbeddingTokenizers()],
      );
      if (!getIt.isRegistered<Isar>()) await configureDependencies();
      final service = getIt<EmbeddingService>();
      await service.ensureInstalled();

      final probe = await service.embed('probe');
      expect(probe, hasLength(EmbeddingService.embeddingDim));

      final index = <String, List<List<double>>>{};
      for (final n in [...longNotes, ...shortNotes, ...veryLongNotes]) {
        final pieces = await service.embedNote(n.text);
        expect(pieces, isNotEmpty, reason: n.id);
        index[n.id] = pieces;
      }

      final answering = <double>[];
      final firsts = <String, int>{};
      final totals = <String, int>{};
      for (final q in [
        ...longQuestions,
        ...shortQuestions,
        ...veryLongQuestions,
      ]) {
        final v = await service.embed(q.text);
        final scored = [
          for (final e in index.entries)
            (id: e.key, score: e.value.map((p) => _dot(v, p)).reduce(max)),
        ]..sort((a, b) => b.score.compareTo(a.score));
        answering.add(scored.firstWhere((e) => e.id == q.noteId).score);
        totals[q.where] = (totals[q.where] ?? 0) + 1;
        if (scored.first.id == q.noteId) {
          firsts[q.where] = (firsts[q.where] ?? 0) + 1;
        }
      }
      // Questions about nothing in the corpus: the closest note must stay under
      // PromptBudget.smallModelMinScore.
      final unrelated = <double>[];
      for (final q in _unrelatedQuestions) {
        final v = await service.embed(q);
        unrelated.add(
          [
            for (final e in index.values) e.map((p) => _dot(v, p)).reduce(max),
          ].reduce(max),
        );
      }
      answering.sort();
      unrelated.sort();
      // ignore: avoid_print
      print(
        'PIECES answering note score min ${answering.first.toStringAsFixed(3)} '
        'p10 ${answering[answering.length ~/ 10].toStringAsFixed(3)} | '
        'unrelated closest max ${unrelated.last.toStringAsFixed(3)} '
        'all ${unrelated.map((u) => u.toStringAsFixed(2)).join(' ')}',
      );
      // ignore: avoid_print
      print('PIECES first-hit $firsts of $totals');

      // Measured on a Snapdragon 710: 27/28, 27/28, 16/16, 3/3.
      expect(firsts['start'] ?? 0, greaterThanOrEqualTo(24));
      expect(firsts['end'] ?? 0, greaterThanOrEqualTo(24));
      expect(firsts['short'] ?? 0, totals['short']);
      expect(firsts['veryend'] ?? 0, totals['veryend']);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
