// Gives device tests an on-device model without downloading it each run.
//
// `flutter test` reinstalls the app per file, wiping its storage, so a model
// downloaded through the app is lost. Push it once to a path the uninstall
// does not touch (`scripts/device_test.sh push-model`); this installs it from
// there and marks it active. Same idea as flutter_edge_ai's own example tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:path/path.dart' as p;
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';

const kTestModelDir = '/data/local/tmp/uniun_test';

/// Replaces the blank/splash screen while a test provisions state.
void showTestScreen(String message) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    ),
  );
}

/// Installs [id] from [kTestModelDir] and makes it active. Returns false when
/// the file was never pushed, so the caller can SKIP with a useful message.
/// Requires `configureDependencies()` to have run.
Future<bool> provisionTestModel(AIModelId id) async {
  showTestScreen('UNIUN test starting — preparing ${id.name}…');
  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final catalog = await getIt<AIModelRepository>().getAvailableModels();
  final url = catalog.firstWhere((m) => m.modelId == id).downloadUrl;
  final filename = p.basename(Uri.parse(url).path);

  if (!await FlutterGemma.isModelInstalled(filename)) {
    final file = File(p.join(kTestModelDir, filename));
    if (!file.existsSync()) {
      showTestScreen('No pushed model — run scripts/device_test.sh push-model');
      return false;
    }
    await FlutterGemma.installModel(
      modelType: _modelType(id),
      fileType: filename.endsWith('.task')
          ? ModelFileType.task
          : ModelFileType.litertlm,
    ).fromFile(file.path).install();
  }
  await getIt<AppSettingsStore>().setActiveModelId(id);
  showTestScreen('UNIUN test running — almost done when this closes');
  return true;
}

ModelType _modelType(AIModelId id) => switch (id) {
  AIModelId.qwen25_05b => ModelType.qwen3,
  AIModelId.deepseekR1 => ModelType.deepSeek,
  AIModelId.gemma4E2b || AIModelId.gemma4E4b => ModelType.gemma4,
};
