// How much does an embed that is already running slow a Shiv chat reply? On a
// real device with the real Gecko embedder and Gemma 4 E2B: time to the first
// token and to the full reply for a chat turn alone, then for the same turn
// started while a note embed is in flight (an embed cannot be interrupted).
// Prints CONTENTION lines; asserts only that replies arrive.
//
//   scripts/device_test.sh push-model gemma-4-E2B-it.litertlm   # once
//   scripts/device_test.sh run integration_test/chat_embed_contention_e2e_test.dart

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';

import 'support/test_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a chat turn alone vs while an embed is running',
    (tester) async {
      if (!await provisionTestModel(AIModelId.gemma4E2b)) {
        // ignore: avoid_print
        print('SKIP: push the model first — scripts/device_test.sh push-model');
        return;
      }
      await FlutterGemma.initialize(
        inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
        embeddingBackends: const [LiteRtEmbeddingBackend()],
      );
      final gateway = FlutterGemmaGatewayImpl();
      final embedding = EmbeddingService(gateway, EmbeddingQueue());
      final settings = AppSettingsStore(await SharedPreferences.getInstance());
      final runner = AIModelRunner(InferenceScheduler(), settings, gateway);

      /// (first token ms, whole reply ms) for one chat turn.
      Future<(int, int)> turn() async {
        final sw = Stopwatch()..start();
        int? first;
        await for (final _ in runner.sendAndStream(
          'Write two short sentences about small habits.',
          systemInstruction: 'You answer briefly.',
        )) {
          first ??= sw.elapsedMilliseconds;
        }
        return (first ?? -1, sw.elapsedMilliseconds);
      }

      // Warm both models so neither timing includes a cold load.
      expect(await embedding.embed('probe', isDocument: true), isNotEmpty);
      await turn();

      final alone = [await turn(), await turn()];

      final embedSw = Stopwatch()..start();
      final embedding1 = embedding
          .embed(
            'A note being embedded at the moment the chat starts.',
            isDocument: true,
          )
          .then((v) {
            embedSw.stop();
            return v;
          });
      final during = await turn();
      final embedStillRunningWhenChatEnded = embedSw.isRunning;
      final vec = await embedding1;

      // ignore: avoid_print
      print(
        '\nCONTENTION chat alone (first token, whole reply): $alone ms'
        '\nCONTENTION chat started while an embed runs:     $during ms'
        '\nCONTENTION the embed took ${embedSw.elapsedMilliseconds} ms; '
        'still running when the reply ended: $embedStillRunningWhenChatEnded\n',
      );

      expect(vec, isNotEmpty);
      expect(during.$1, greaterThan(0));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
