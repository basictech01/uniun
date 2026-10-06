// Real image turn on a vision model: Gemma 4 E2B must name the colour of a
// solid-red picture. Needs the model pushed first:
//   scripts/device_test.sh push-model gemma-4-E2B-it.litertlm
//   scripts/device_test.sh run integration_test/chat_image_turn_test.dart

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

import 'support/test_model.dart';

Future<List<int>> _solidPng(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(
    recorder,
  ).drawRect(const Rect.fromLTWH(0, 0, 256, 256), Paint()..color = color);
  final image = await recorder.endRecording().toImage(256, 256);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gemma 4 E2B reads the colour of an attached image', (
    tester,
  ) async {
    if (!await provisionTestModel(AIModelId.gemma4E2b)) {
      // ignore: avoid_print
      print('SKIP: push the model first — scripts/device_test.sh push-model');
      return;
    }
    final settings = AppSettingsStore(await SharedPreferences.getInstance());
    final runner = AIModelRunner(
      InferenceScheduler(),
      settings,
      FlutterGemmaGatewayImpl(),
    );

    final red = Uint8List.fromList(await _solidPng(const Color(0xFFE53935)));
    final answer = await runner
        .sendAndStream(
          'What colour is this image? Answer with one word.',
          systemInstruction: 'You answer briefly.',
          images: [red],
        )
        .join();
    // ignore: avoid_print
    print('image answer: $answer');
    expect(answer.toLowerCase(), contains('red'));

    final followUp = await runner
        .sendAndStream('Say hello.', systemInstruction: 'You answer briefly.')
        .join();
    expect(
      followUp.trim(),
      isNotEmpty,
      reason: 'text turn after an image turn',
    );
  });
}
