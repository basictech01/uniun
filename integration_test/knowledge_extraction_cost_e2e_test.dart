// How much of the main isolate does knowledge extraction use? On a real device
// with Gemma 4 E2B: a 2 ms timer on the main isolate records stalls (a stall
// over 16 ms is a dropped frame) first while idle, then while
// ExtractKnowledgeUseCase runs for one note with similar notes as context
// (similar-note lookup, prompt, the one-shot model call, JSON parse, graph and
// memory writes to Isar). Prints EXTRACT lines; asserts only that it finished.
//
//   scripts/device_test.sh push-model gemma-4-E2B-it.litertlm   # once
//   scripts/device_test.sh run integration_test/knowledge_extraction_cost_e2e_test.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/pending_extraction_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';

import 'support/test_model.dart';

typedef _Stalls = ({int ms, double worstMs, int over16, int over50});

Future<_Stalls> _watch(Future<void> Function() work) async {
  final gaps = <int>[];
  var last = DateTime.now().microsecondsSinceEpoch;
  final timer = Timer.periodic(const Duration(milliseconds: 2), (_) {
    final now = DateTime.now().microsecondsSinceEpoch;
    gaps.add(now - last);
    last = now;
  });
  final sw = Stopwatch()..start();
  await work();
  timer.cancel();
  gaps.sort();
  return (
    ms: sw.elapsedMilliseconds,
    worstMs: gaps.last / 1000,
    over16: gaps.where((g) => g > 16000).length,
    over50: gaps.where((g) => g > 50000).length,
  );
}

String _line(String name, _Stalls s) =>
    'EXTRACT $name: ${s.ms} ms, worst main-isolate stall '
    '${s.worstMs.toStringAsFixed(1)} ms, stalls >16 ms: ${s.over16}, '
    '>50 ms: ${s.over50}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'extraction for one note: how much it stalls the main isolate',
    (tester) async {
      await configureDependencies();
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      await getIt<GetActiveAIModelUseCase>().call();
      if (!FlutterGemma.hasActiveModel() &&
          !await provisionTestModel(AIModelId.gemma4E2b)) {
        // ignore: avoid_print
        print('SKIP: push the model first — scripts/device_test.sh push-model');
        return;
      }

      final isar = getIt<Isar>();
      final vectors = getIt<VectorRepository>();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final main = 'e2e-extract-$stamp-main';
      final similar = ['e2e-extract-$stamp-s1', 'e2e-extract-$stamp-s2'];
      const content =
          'Our team agreed to review pull requests within one working day and '
          'keep them under 400 lines. Reviewers leave comments in the first pass '
          'and approve once the main concerns are addressed.';

      // A vector, and near copies of it so the similar-note lookup finds them.
      final r = Random(1);
      final base = [for (var i = 0; i < 768; i++) r.nextDouble() - .5];
      List<double> near(double noise) {
        final v = [for (final x in base) x + (r.nextDouble() - .5) * noise];
        final n = sqrt(v.fold<double>(0, (a, b) => a + b * b));
        return [for (final x in v) x / n];
      }

      NoteModel note(String id, String text) => NoteModel(
        eventId: id,
        sig: '',
        authorPubkey: 'e2e',
        content: text,
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        created: DateTime.now(),
      );

      await isar.writeTxn(() async {
        await isar.noteModels.put(note(main, content));
        await isar.noteModels.put(
          note(
            similar[0],
            'Pull requests should be small so reviews stay quick.',
          ),
        );
        await isar.noteModels.put(
          note(similar[1], 'We use a checklist when reviewing code changes.'),
        );
      });
      await vectors.upsert(similar[0], near(0.05));
      await vectors.upsert(similar[1], near(0.05));

      try {
        final idle = await _watch(
          () => Future<void>.delayed(const Duration(seconds: 20)),
        );
        final extraction = await _watch(
          () => getIt<ExtractKnowledgeUseCase>().call((
            main,
            content,
            near(0.01),
          )),
        );
        // ignore: avoid_print
        print(
          '\n${_line('idle for 20 s (baseline)', idle)}'
          '\n${_line('knowledge extraction for one note', extraction)}\n',
        );
      } finally {
        await getIt<DeleteKnowledgeForNoteUseCase>().call(main);
        await getIt<PendingExtractionRepository>().clear(main);
        for (final id in [main, ...similar]) {
          await vectors.delete(id);
        }
        await isar.writeTxn(
          () => isar.noteModels
              .filter()
              .eventIdStartsWith('e2e-extract-')
              .deleteAll(),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
