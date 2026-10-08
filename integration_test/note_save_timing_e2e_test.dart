// Times saving notes on a real device with the real Gecko model: how long until
// the vector is stored for one note and for a burst of four, and how long a Shiv
// question waits when it arrives right after the burst. It uses only
// EmbedAndStoreNoteUseCase, EmbeddingService and the vector store, so it runs
// unchanged on code with and without the pending-embeddings queue (#231) and the
// two can be compared. Prints TIMING lines; asserts only that every vector lands.
//
//   scripts/device_test.sh run integration_test/note_save_timing_e2e_test.dart

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'time to store one note, a burst of four, and a question after it',
    (tester) async {
      await configureDependencies();
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final save = getIt<EmbedAndStoreNoteUseCase>();
      final embedding = getIt<EmbeddingService>();
      final store = getIt<ToStore>();
      final vectors = getIt<VectorRepository>();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final ids = <String>[];

      expect(
        await embedding.embed('probe'),
        isNotEmpty,
        reason: '[] means the bundled embedding model did not load',
      );

      Future<bool> stored(String id) async {
        final rows = await store
            .query(embeddingsTableName)
            .where(embeddingsIdField, '=', id);
        return rows.data.isNotEmpty;
      }

      /// Milliseconds after [start] at which each id first shows up as stored.
      Future<Map<String, int>> whenStored(
        List<String> want,
        Stopwatch start,
      ) async {
        final seen = <String, int>{};
        final deadline = DateTime.now().add(const Duration(minutes: 3));
        while (seen.length < want.length && DateTime.now().isBefore(deadline)) {
          for (final id in want) {
            if (!seen.containsKey(id) && await stored(id)) {
              seen[id] = start.elapsedMilliseconds;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return seen;
      }

      String note(int i) =>
          'Timing note $i: small habits compound over time, and reviewing them '
          'on day ${i % 7} changes what I remember. Reference $stamp.';

      try {
        // One note.
        final oneId = 'e2e-timing-$stamp-one';
        ids.add(oneId);
        final one = Stopwatch()..start();
        await save.call((oneId, note(0)));
        final oneSeen = await whenStored([oneId], one);

        // A burst of four, saved at once.
        final burstIds = [for (var i = 1; i <= 4; i++) 'e2e-timing-$stamp-b$i'];
        ids.addAll(burstIds);
        final burst = Stopwatch()..start();
        await Future.wait([
          for (var i = 0; i < 4; i++) save.call((burstIds[i], note(i + 1))),
        ]);
        final burstSeen = await whenStored(burstIds, burst);

        // A question arriving right after a second burst of four.
        final qIds = [for (var i = 5; i <= 8; i++) 'e2e-timing-$stamp-q$i'];
        ids.addAll(qIds);
        final q = Stopwatch()..start();
        await Future.wait([
          for (var i = 0; i < 4; i++) save.call((qIds[i], note(i + 5))),
        ]);
        final question = await embedding.embed('what did I write about habits');
        final questionMs = q.elapsedMilliseconds;
        final qSeen = await whenStored(qIds, q);

        final burstTimes = burstIds.map((id) => burstSeen[id]).toList();
        // ignore: avoid_print
        print(
          '\nTIMING one note stored after:        ${oneSeen[oneId]} ms'
          '\nTIMING burst of 4, each stored after: $burstTimes ms'
          '\nTIMING question after a burst of 4 answered after: $questionMs ms'
          '\nTIMING ...and that burst fully stored after: '
          '${qIds.map((id) => qSeen[id]).toList()} ms\n',
        );

        expect(question, isNotEmpty);
        expect(oneSeen, hasLength(1));
        expect(burstSeen, hasLength(4));
        expect(qSeen, hasLength(4));
      } finally {
        for (final id in ids) {
          await vectors.delete(id);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
