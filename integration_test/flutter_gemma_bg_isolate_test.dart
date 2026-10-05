// Phase 6a verification — does flutter_gemma 1.0.0 work in a background
// isolate via RootIsolateToken / BackgroundIsolateBinaryMessenger?
//
// PASS path: result starts with `OK:` → green light for true background
//            (app-killed) Ganas. flutter_gemma can be called from inside
//            the workmanager dispatcher.
// SKIP path: result starts with `SKIP:` → preconditions not met (no model
//            installed yet). Re-run after downloading one in Shiv.
// FAIL path: result starts with `FAIL:` (or test throws) → halt the
//            background plan. Document the limitation in `ganas.md`
//            §2.14 and ship Phase 6b in queue-then-foreground mode
//            (workmanager bumps `lastRunAt`, foreground engine actually
//            runs inference next time the user opens the app).
//
// Why this file lives at `integration_test/` (project root, not under
// `test/`): the `integration_test` plugin is only detected by the Flutter
// tool when the folder is literally `integration_test/` at the repo root.
// Move it elsewhere and `flutter test` runs the file as a plain host-VM
// test — platform channels don't work, `hasActiveModel` returns false,
// and the file silently SKIPs.
//
//   flutter test integration_test/ -d <device-id>
//
// PRECONDITIONS:
//   1. flutter_gemma ^1.0.0 + the matching engine sub-package present in
//      pubspec.yaml (we ship both LiteRtLm and MediaPipe; the test
//      registers both so whichever the active model needs works).
//   2. A model is already installed on the device — use the Shiv
//      "Select AI model" page to download one first. The test does NOT
//      download; that path is well-tested separately and the bg-isolate
//      question is specifically about inference, not download.
//
// WHAT THIS TEST PROBES (in one isolate, in this order):
//   1. RootIsolateToken is obtainable from the main isolate.
//   2. BackgroundIsolateBinaryMessenger.ensureInitialized accepts the token.
//   3. FlutterGemma.initialize() succeeds from the bg isolate (engine
//      registration is the part most likely to fail — engines may be
//      gated on main-isolate-only platform groups).
//   4. FlutterGemma.hasActiveModel() returns the same answer as the main
//      isolate (shared state via SharedPreferences-equivalent storage).
//   5. getActiveModel() returns a usable handle.
//   6. openChat() opens a session.
//   7. addQueryChunk + generateChatResponseAsync streams at least one
//      TextResponse token within 60s.
//
// We intentionally cap maxTokens at 64 and ask for a short answer — the
// goal is to confirm the pipeline works, not measure quality.

import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

import 'support/test_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('flutter_gemma 1.0.0 runs inference in a background isolate',
      () async {
    final token = RootIsolateToken.instance;
    expect(
      token,
      isNotNull,
      reason: 'RootIsolateToken unavailable — platform does not support '
          'BackgroundIsolateBinaryMessenger. Background Ganas cannot ship '
          'on this platform.',
    );

    await provisionTestModel(AIModelId.gemma4E2b);

    final replyPort = ReceivePort();
    await Isolate.spawn(
      _workerEntry,
      _WorkerMessage(token!, replyPort.sendPort),
    );

    final result = await replyPort.first.timeout(
      // Generous: model load + chat open + first token. A real run
      // shouldn't need anywhere near this much, but we'd rather not
      // false-FAIL on a slow emulator.
      const Duration(seconds: 60),
      onTimeout: () => 'FAIL: 60s timeout — generation never started',
    );
    replyPort.close();

    expect(result, isA<String>(),
        reason: 'worker did not return a string verdict');
    final verdict = result as String;

    if (verdict.startsWith('SKIP:')) {
      // Preconditions not met — emit a marker so the runner sees it but
      // don't fail the build. Re-running after installing a model is the
      // signal-bearing path.
      // ignore: avoid_print
      print('flutter_gemma bg-isolate test SKIPPED: $verdict');
      return;
    }
    if (!verdict.startsWith('OK:')) {
      fail('flutter_gemma bg-isolate test failed: $verdict');
    }
    // ignore: avoid_print
    print('flutter_gemma bg-isolate test PASSED: $verdict');
  }, timeout: const Timeout(Duration(seconds: 90)));
}

/// Payload for the worker isolate. Only plain types + the
/// `RootIsolateToken` and one `SendPort` — everything is sendable.
class _WorkerMessage {
  final RootIsolateToken token;
  final SendPort reply;
  const _WorkerMessage(this.token, this.reply);
}

/// Worker isolate body. Must be top-level so `Isolate.spawn` can resolve it.
Future<void> _workerEntry(_WorkerMessage msg) async {
  try {
    // 1. Open the platform-group bridge so plugin calls work.
    BackgroundIsolateBinaryMessenger.ensureInitialized(msg.token);

    // 2. Initialize flutter_gemma 1.0.0. Engine registration MAY throw
    //    on a background isolate if any registered engine touches a
    //    main-isolate-only group during initialize() — that's exactly
    //    what we want to detect.
    await FlutterGemma.initialize(
      inferenceEngines: const [
        LiteRtLmEngine(),
        MediaPipeEngine(),
      ],
      embeddingBackends: const [
        LiteRtEmbeddingBackend(),
      ],
    );

    // 3. Active-model state should be shared across isolates because it's
    //    backed by on-disk storage. If the main isolate has an active
    //    model, so should we.
    if (!FlutterGemma.hasActiveModel()) {
      msg.reply.send(
        'SKIP: no active model installed on this device — open Shiv → '
        'Select AI model → download one, then re-run',
      );
      return;
    }

    // 4. Get a handle. Keep maxTokens tiny — we only need to confirm the
    //    chain works, not produce useful output.
    //
    //    DIAGNOSTIC: time the model open. If this returns in <1s, the
    //    model wasn't actually loaded into THIS isolate's process space —
    //    flutter_gemma is delegating to the main-isolate native handle
    //    via the platform group. That works for "app alive, bg isolate
    //    speaking to main" (our current architecture) but does NOT prove
    //    the WorkManager-killed-app case. Annotate the result so we can
    //    tell which path the test actually exercised.
    final openStart = DateTime.now();
    final model = await FlutterGemma.getActiveModel(maxTokens: 64);
    final chat = await model.openChat(
      temperature: 0.2,
      topK: 20,
      tokenBuffer: 64,
    );
    final openDuration = DateTime.now().difference(openStart);

    // 5. Feed a tiny prompt and stream the response. Time the first
    //    token too — fresh model + first token <2s is implausible.
    final genStart = DateTime.now();
    await chat.addQueryChunk(Message.text(text: 'Reply with one word.'));
    String? firstToken;
    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse && response.token.isNotEmpty) {
        firstToken = response.token;
        break;
      }
      if (DateTime.now().difference(genStart) > const Duration(seconds: 45)) {
        await chat.close();
        msg.reply.send(
          'FAIL: stream opened but produced no TextResponse within 45s',
        );
        return;
      }
    }
    final genDuration = DateTime.now().difference(genStart);
    await chat.close();

    if (firstToken == null) {
      msg.reply.send(
        'FAIL: generation stream closed without emitting any TextResponse',
      );
      return;
    }

    // Heuristic: a real fresh model load into a separate process should
    // take ≥2s on Android. <500ms strongly suggests the native handle is
    // shared with the main isolate.
    final freshLoad = openDuration.inMilliseconds >= 2000;
    final loadPathLabel =
        freshLoad ? 'FRESH-LOAD' : 'SHARED-WITH-MAIN (suspect)';
    msg.reply.send(
      'OK: bg isolate produced "${firstToken.replaceAll('\n', '\\n')}" '
      '| openModel+openChat=${openDuration.inMilliseconds}ms '
      '| firstToken=${genDuration.inMilliseconds}ms '
      '| loadPath=$loadPathLabel',
    );
  } catch (e, st) {
    msg.reply.send('FAIL: $e\n$st');
  }
}
