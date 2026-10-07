// Real-device check of the pending-embeddings queue (#231): a note handed to
// EmbedAndStoreNoteUseCase is queued, embedded by NoteEmbeddingWorker with the
// real Gecko model, its vector is stored, and its queue row is gone.
// Embedding is slow on weak phones (about 12 s a note on a Snapdragon 710), so
// the wait is generous. The test vector is deleted afterwards.
//
//   scripts/device_test.sh run integration_test/note_embedding_queue_e2e_test.dart

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a queued note is embedded, stored and leaves the queue',
    (tester) async {
      await configureDependencies();
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final pending = getIt<PendingEmbeddingRepository>();
      final vectors = getIt<VectorRepository>();
      final embedding = getIt<EmbeddingService>();

      // A cold embedder load is the first embed: fail loudly, never skip, since
      // Gecko ships as a bundled asset.
      expect(
        await embedding.embed('probe'),
        isNotEmpty,
        reason: '[] means the bundled embedding model did not load',
      );

      final id = 'e2e-pending-${DateTime.now().microsecondsSinceEpoch}';
      const text = 'The harbour lighthouse keeper logged every ship at dawn.';
      // Search returns a hit's text from the notes tables, so the note must exist
      // there, as a saved or own note would.
      final isar = getIt<Isar>();
      await isar.writeTxn(
        () => isar.noteModels.put(
          NoteModel(
            eventId: id,
            sig: '',
            authorPubkey: 'e2e',
            content: text,
            type: NoteType.text,
            eTagRefs: const [],
            pTagRefs: const [],
            tTags: const [],
            created: DateTime.now(),
          ),
        ),
      );
      await getIt<EmbedAndStoreNoteUseCase>().call((id, text));
      expect(await pending.count(), greaterThanOrEqualTo(1));

      try {
        final deadline = DateTime.now().add(const Duration(minutes: 3));
        while (await pending.count() > 0 && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }

        expect(await pending.count(), 0, reason: 'queue should be drained');

        // Read the stored vector back directly. A similarity search is not used
        // here: notes still go through ToStore's approximate index, which the
        // audit records as reaching only part of what is stored.
        final stored = await getIt<ToStore>()
            .query(embeddingsTableName)
            .where(embeddingsIdField, '=', id);
        expect(
          stored.data,
          hasLength(1),
          reason: 'the vector should be stored',
        );
        expect(stored.data.single[embeddingsVectorField], isA<VectorData>());
      } finally {
        await vectors.delete(id);
        await isar.writeTxn(
          () => isar.noteModels
              .filter()
              .eventIdStartsWith('e2e-pending-')
              .deleteAll(),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
