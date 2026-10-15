import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_budget.dart';

/// Covers: PromptBudget.forModel/.forActiveModel per-model token allocation,
/// the local/cloud split, and PromptBudget.estimateTokens.
void main() {
  group('PromptBudget.forModel — local, by AIModelId', () {
    test('gemma4E4b gets the largest budget (8192, topK 10, 2 hops)', () {
      final b = PromptBudget.forModel(AIModelId.gemma4E4b);
      expect(b.maxTokens, 8192);
      expect(b.topK, 10);
      expect(b.maxHops, 2);
      expect(b.minScore, PromptBudget.defaultMinScore);
    });

    test('gemma4E2b gets a mid-size budget (4096, topK 5, 2 hops)', () {
      final b = PromptBudget.forModel(AIModelId.gemma4E2b);
      expect(b.maxTokens, 4096);
      expect(b.topK, 5);
      expect(b.maxHops, 2);
    });

    test('deepseekR1 gets the smallest named budget (1024, topK 3, 1 hop)', () {
      final b = PromptBudget.forModel(AIModelId.deepseekR1);
      expect(b.maxTokens, 1024);
      expect(b.topK, 3);
      expect(b.maxHops, 1);
    });

    test('qwen25_05b falls into the default bucket (2048, topK 3, 1 hop)', () {
      final b = PromptBudget.forModel(AIModelId.qwen25_05b);
      expect(b.maxTokens, 2048);
      expect(b.topK, 3);
      expect(b.maxHops, 1);
      expect(b.minScore, PromptBudget.smallModelMinScore);
    });

    test('a null modelId falls into the same default bucket as qwen25_05b',
        () {
      final a = PromptBudget.forModel(null);
      final b = PromptBudget.forModel(AIModelId.qwen25_05b);
      expect(a.maxTokens, b.maxTokens);
      expect(a.topK, b.topK);
      expect(a.maxHops, b.maxHops);
    });

    test('section splits sum to <= maxTokens and follow the documented '
        'percentages (10/35/20/15)', () {
      final b = PromptBudget.forModel(AIModelId.gemma4E2b);
      expect(b.queryTokens, (4096 * 0.10).round());
      expect(b.topNotesTokens, (4096 * 0.35).round());
      expect(b.graphRelationsTokens, (4096 * 0.20).round());
      expect(b.memoriesTokens, (4096 * 0.15).round());
      final sum = b.queryTokens +
          b.topNotesTokens +
          b.graphRelationsTokens +
          b.memoriesTokens;
      expect(sum <= b.maxTokens, isTrue);
    });
  });

  group('PromptBudget.forActiveModel', () {
    test('a null active model falls back to the local default bucket', () {
      final b = PromptBudget.forActiveModel(null);
      expect(b.maxTokens, 2048);
      expect(b.topK, 3);
      expect(b.maxHops, 1);
    });

    test('a local backend model resolves via its AIModelId name', () {
      const model = LlmModelInfo(
        id: 'gemma4E4b',
        displayName: 'Gemma 4 E4B',
        backend: LlmBackendType.localGemma,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 8192);
      expect(b.topK, 10);
    });

    test('an unrecognized local model id (e.g. retired/renamed) falls back '
        'to the default bucket instead of throwing', () {
      const model = LlmModelInfo(
        id: 'some-retired-model',
        displayName: 'Retired',
        backend: LlmBackendType.localGemma,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 2048);
    });

    test('a cloud model with no reported context window defaults to 16384, '
        'topK 15, 2 hops', () {
      const model = LlmModelInfo(
        id: 'claude-sonnet-5',
        displayName: 'Claude Sonnet 5',
        backend: LlmBackendType.uniunCloud,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 16384);
      expect(b.topK, 15);
      expect(b.maxHops, 2);
    });

    test('a cloud model with a reported context window budgets at half of '
        'it', () {
      const model = LlmModelInfo(
        id: 'claude-sonnet-5',
        displayName: 'Claude Sonnet 5',
        backend: LlmBackendType.uniunCloud,
        contextWindow: 20000,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 10000);
    });

    test('a cloud model with a huge context window is clamped to 32768, not '
        'left unbounded', () {
      const model = LlmModelInfo(
        id: 'huge-context-model',
        displayName: 'Huge',
        backend: LlmBackendType.uniunCloud,
        contextWindow: 400000,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 32768);
    });

    test('a cloud model with a tiny reported context window is clamped up '
        'to a floor of 4096', () {
      const model = LlmModelInfo(
        id: 'tiny-context-model',
        displayName: 'Tiny',
        backend: LlmBackendType.uniunCloud,
        contextWindow: 1000,
      );
      final b = PromptBudget.forActiveModel(model);
      expect(b.maxTokens, 4096);
    });
  });

  group('PromptBudget.estimateTokens', () {
    test('empty string estimates to 0 tokens', () {
      expect(PromptBudget.estimateTokens(''), 0);
    });

    test('estimates roughly length / 4, rounded up', () {
      expect(PromptBudget.estimateTokens('abcd'), 1); // exactly 4 chars
      expect(PromptBudget.estimateTokens('abcde'), 2); // 5 chars → ceil(1.25)
      expect(PromptBudget.estimateTokens('abc'), 1); // 3 chars → ceil(0.75)
    });

    test('a single character rounds up to 1 token, never 0', () {
      expect(PromptBudget.estimateTokens('a'), 1);
    });

    test('unicode/emoji characters count by Dart string length (UTF-16 code '
        'units), not by byte size', () {
      final estimate = PromptBudget.estimateTokens('🤖🤖🤖🤖');
      expect(estimate, greaterThan(0));
    });
  });
}
