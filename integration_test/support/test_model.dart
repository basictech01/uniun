// Reuses a local model fixture across integration test runs. The fixture may
// be in the app documents directory, a configured directory, or the existing
// device test fixture directory.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

const kTestModelDir = '/data/local/tmp/uniun_test';
const _configuredTestModelDir = String.fromEnvironment('UNIUN_TEST_MODEL_DIR');

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

/// Installs [id] from an available test fixture and makes it active. Returns
/// false when no fixture or installed model is available.
/// Needs no DI, so it also works in tests that never call
/// `configureDependencies()`.
Future<bool> provisionTestModel(AIModelId id) async {
  showTestScreen('UNIUN test starting — preparing ${id.name}…');
  await FlutterGemma.initialize(
    inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
    embeddingBackends: const [LiteRtEmbeddingBackend()],
  );

  final filename = _filename(id);
  final documents = await getApplicationDocumentsDirectory();
  final file = File(p.join(documents.path, filename));

  final fixtureDirs = [
    if (_configuredTestModelDir.isNotEmpty) _configuredTestModelDir,
    kTestModelDir,
  ];
  File? fixture;
  for (final dir in fixtureDirs) {
    final candidate = File(p.join(dir, filename));
    if (candidate.existsSync()) {
      fixture = candidate;
      break;
    }
  }

  // Register from the file on each run: the plugin may retain the installed
  // flag while losing its active-model link after an app reinstall.
  if (fixture != null || file.existsSync()) {
    if (fixture != null &&
        (!file.existsSync() || file.lengthSync() != fixture.lengthSync())) {
      showTestScreen('UNIUN test starting — copying ${id.name} (one time)…');
      await fixture.copy(file.path);
    }
    await FlutterGemma.installModel(
      modelType: _modelType(id),
      fileType: filename.endsWith('.task')
          ? ModelFileType.task
          : ModelFileType.litertlm,
    ).fromFile(file.path).install();
  } else if (!await FlutterGemma.isModelInstalled(filename)) {
    showTestScreen('No ${id.name} model fixture is available');
    return false;
  }
  await AppSettingsStore(
    await SharedPreferences.getInstance(),
  ).setActiveModelId(id);
  showTestScreen('UNIUN test running — almost done when this closes');
  return true;
}

ModelType _modelType(AIModelId id) => switch (id) {
  AIModelId.qwen25_05b => ModelType.qwen3,
  AIModelId.deepseekR1 => ModelType.deepSeek,
  AIModelId.gemma4E2b || AIModelId.gemma4E4b => ModelType.gemma4,
};

/// Matches the basename of each model's `downloadUrl` in the catalog.
String _filename(AIModelId id) => switch (id) {
  AIModelId.qwen25_05b => 'Qwen3-0.6B.litertlm',
  AIModelId.deepseekR1 => 'deepseek_q8_ekv1280.task',
  AIModelId.gemma4E2b => 'gemma-4-E2B-it.litertlm',
  AIModelId.gemma4E4b => 'gemma-4-E4B-it.litertlm',
};
