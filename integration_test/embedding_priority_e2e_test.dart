// Real-device check of the shared embedding gate (#231): with background
// embeds (a note, PDF chunks) already queued, a Shiv question's embed must run
// right after the one in flight, not after the whole backlog. Uses the real
// Gecko model, so it checks order, not timing (one embed is ~12 s on a
// Snapdragon 710).
//
//   scripts/device_test.sh run integration_test/embedding_priority_e2e_test.dart

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a question is embedded right after the one in flight, ahead of '
      'the queued background embeds', (tester) async {
    await configureDependencies();
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    final embedding = getIt<EmbeddingService>();

    // Loads the model once, so the ordering below is not about a cold start.
    expect(
      await embedding.embed('probe'),
      isNotEmpty,
      reason: '[] means the bundled embedding model did not load',
    );

    final finished = <String>[];
    Future<void> run(
      String name,
      String text, {
      required bool isDocument,
    }) async {
      final vec = await embedding.embed(text, isDocument: isDocument);
      expect(vec, isNotEmpty, reason: '$name returned no vector');
      finished.add(name);
    }

    final all = [
      run('note', 'A note about small habits.', isDocument: true),
      run('chunk-1', 'First page of a PDF about habits.', isDocument: true),
      run('chunk-2', 'Second page of a PDF about habits.', isDocument: true),
    ];
    // The note is now in flight; ask the question behind the queued chunks.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    all.add(
      run('question', 'what did I write about habits', isDocument: false),
    );
    await Future.wait(all);

    expect(
      finished.first,
      'note',
      reason: 'the in-flight embed finishes first',
    );
    expect(
      finished[1],
      'question',
      reason: 'the question must not wait behind the chunks: $finished',
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
