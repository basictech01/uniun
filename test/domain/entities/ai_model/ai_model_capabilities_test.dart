import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

/// Covers: which catalog models can take an image as input, and that the answer
/// is decided for every model (a new one cannot be added without choosing).
void main() {
  test('only the Gemma 4 models take images', () {
    expect(AIModelId.gemma4E2b.supportsImages, isTrue);
    expect(AIModelId.gemma4E4b.supportsImages, isTrue);
    expect(AIModelId.qwen25_05b.supportsImages, isFalse);
    expect(AIModelId.deepseekR1.supportsImages, isFalse);
  });

  test('every model has an answer, and at least one is text-only', () {
    final answers = {for (final id in AIModelId.values) id: id.supportsImages};

    expect(answers, hasLength(AIModelId.values.length));
    expect(answers.values, contains(false));
    expect(answers.values, contains(true));
  });
}
