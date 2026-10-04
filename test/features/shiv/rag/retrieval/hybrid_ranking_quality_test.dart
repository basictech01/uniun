import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/text/bm25.dart';
import 'package:uniun/core/text/hybrid_ranker.dart';
import 'package:uniun/core/text/stopwords.dart';

import '../../../../_helpers/pdf_fixtures.dart';

/// Covers: retrieval quality, not just behaviour — Recall@1/3/5 and MRR of
/// meaning-only against hybrid ranking over real Gecko embeddings, plus Hindi
/// and Hinglish keyword normalisation over committed fictional fixtures.
void main() {
  final fixture =
      jsonDecode(
            File(
              '${packageRoot()}/test/_helpers/fixtures/pdf/'
              'aranya_land_records_review_q2_2026.retrieval.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final chunks = [
    for (final c in fixture['chunks'] as List)
      (
        label: c['label'] as String,
        text: c['text'] as String,
        vector: (c['vector'] as List)
            .cast<num>()
            .map((n) => n.toDouble())
            .toList(),
      ),
  ];
  final queries = [
    for (final q in fixture['queries'] as List)
      (
        text: q['q'] as String,
        pages: (q['pages'] as List).cast<String>(),
        phrases: (q['phrases'] as List).cast<String>(),
        vector: (q['vector'] as List)
            .cast<num>()
            .map((n) => n.toDouble())
            .toList(),
      ),
  ];

  /// Rank (1-based) of the first relevant chunk in the top 5, 0 when absent. A
  /// chunk is relevant on the right page or when it holds the answer text.
  int rankOf(
    ({
      String text,
      List<String> pages,
      List<String> phrases,
      List<double> vector,
    })
    q,
    HybridConfig config,
  ) {
    final ranker = HybridRanker(
      q.vector,
      queryText: q.text,
      config: config,
      minScore: 0,
    );
    for (var i = 0; i < chunks.length; i++) {
      ranker.add(i, chunks[i].vector, chunks[i].text);
    }
    final order = ranker.ranked().take(5).toList();
    final i = order.indexWhere(
      (id) =>
          q.pages.contains(chunks[id].label) ||
          q.phrases.any(
            (p) => chunks[id].text.toLowerCase().contains(p.toLowerCase()),
          ),
    );
    return i < 0 ? 0 : i + 1;
  }

  ({int r1, int r3, int r5, double mrr}) evaluate(HybridConfig config) {
    var r1 = 0, r3 = 0, r5 = 0;
    var mrr = 0.0;
    for (final q in queries) {
      final r = rankOf(q, config);
      if (r == 1) r1++;
      if (r > 0 && r <= 3) r3++;
      if (r > 0) {
        r5++;
        mrr += 1 / r;
      }
    }
    return (r1: r1, r3: r3, r5: r5, mrr: mrr / queries.length);
  }

  final meaning = evaluate(HybridConfig.off);
  final hybrid = evaluate(const HybridConfig());
  final n = queries.length;

  // ignore: avoid_print
  print('''

Retrieval quality — ${chunks.length} chunks, $n questions (Gecko embeddings)
                 Recall@1   Recall@3   Recall@5     MRR
  meaning only    ${_cell(meaning.r1, n)}   ${_cell(meaning.r3, n)}   ${_cell(meaning.r5, n)}    ${meaning.mrr.toStringAsFixed(3)}
  hybrid          ${_cell(hybrid.r1, n)}   ${_cell(hybrid.r3, n)}   ${_cell(hybrid.r5, n)}    ${hybrid.mrr.toStringAsFixed(3)}
''');

  test('the fixture is what the tests below assume', () {
    expect(chunks, hasLength(10));
    expect(queries, hasLength(23));
    expect(chunks.every((c) => c.vector.length == 768), isTrue);
  });

  test(
    'hybrid ranking finds the answer first more often than meaning alone',
    () {
      expect(hybrid.r1, greaterThan(meaning.r1));
      expect(hybrid.mrr, greaterThan(meaning.mrr));
    },
  );

  test('hybrid ranking never drops a question out of the top 5 that meaning '
      'alone found', () {
    expect(hybrid.r5, greaterThanOrEqualTo(meaning.r5));
  });

  test(
    'quality floors: a ranker change may not quietly make retrieval worse',
    () {
      // Measured 21/22/23 and MRR 0.94 when set; a little slack for a
      // deliberate trade-off, none for an accident.
      expect(hybrid.r1, greaterThanOrEqualTo(19));
      expect(hybrid.r3, greaterThanOrEqualTo(21));
      expect(hybrid.r5, greaterThanOrEqualTo(22));
      expect(hybrid.mrr, greaterThanOrEqualTo(0.88));
    },
  );

  test('meaning-only ranking is unchanged by the keyword code (baseline)', () {
    expect(meaning.r1, greaterThanOrEqualTo(20));
    expect(meaning.r5, greaterThanOrEqualTo(22));
  });

  final keywordFixture =
      jsonDecode(
            File(
              '${packageRoot()}/test/_helpers/fixtures/pdf/'
              'aranya_hindi_hinglish_keyword.retrieval.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final keywordChunks = [
    for (final c in keywordFixture['chunks'] as List)
      (id: c['id'] as String, text: c['text'] as String),
  ];
  final keywordQueries = [
    for (final q in keywordFixture['queries'] as List)
      (text: q['q'] as String, chunk: q['chunk'] as String),
  ];

  int keywordRankOf(({String text, String chunk}) query) {
    final scorer = Bm25Scorer(
      query.text,
      stopwords: kStopwords,
      termBoost: (term) => isIdentifier(term) ? 2 : 1,
    );
    for (var i = 0; i < keywordChunks.length; i++) {
      scorer.add(i, keywordChunks[i].text);
    }
    final order = scorer.scores().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final i = order
        .take(5)
        .toList()
        .indexWhere((entry) => keywordChunks[entry.key].id == query.chunk);
    return i < 0 ? 0 : i + 1;
  }

  ({int r1, int r3, int r5, double mrr}) evaluateKeywords() {
    var r1 = 0, r3 = 0, r5 = 0;
    var mrr = 0.0;
    for (final query in keywordQueries) {
      final rank = keywordRankOf(query);
      if (rank == 1) r1++;
      if (rank > 0 && rank <= 3) r3++;
      if (rank > 0) {
        r5++;
        mrr += 1 / rank;
      }
    }
    return (r1: r1, r3: r3, r5: r5, mrr: mrr / keywordQueries.length);
  }

  final legacy = keywordFixture['legacy'] as Map<String, dynamic>;
  final normalised = evaluateKeywords();
  final keywordN = keywordQueries.length;

  // ignore: avoid_print
  print('''

Hindi/Hinglish keyword quality — ${keywordChunks.length} fictional chunks, $keywordN questions
                 Recall@1   Recall@3   Recall@5     MRR
  legacy exact    ${_cell(legacy['r1'] as int, keywordN)}   ${_cell(legacy['r3'] as int, keywordN)}   ${_cell(legacy['r5'] as int, keywordN)}    ${(legacy['mrr'] as num).toStringAsFixed(3)}
  normalised      ${_cell(normalised.r1, keywordN)}   ${_cell(normalised.r3, keywordN)}   ${_cell(normalised.r5, keywordN)}    ${normalised.mrr.toStringAsFixed(3)}
''');

  test('Hindi and Hinglish fixture shape is stable', () {
    expect(keywordChunks, hasLength(6));
    expect(keywordQueries, hasLength(12));
  });

  test('keyword normalisation improves Hindi and Hinglish retrieval', () {
    expect(normalised.r1, greaterThan(legacy['r1'] as int));
    expect(normalised.r3, greaterThan(legacy['r3'] as int));
    expect(normalised.r5, greaterThan(legacy['r5'] as int));
    expect(normalised.mrr, greaterThan(legacy['mrr'] as num));
  });

  test('normalised keyword quality floors', () {
    expect(normalised.r1, greaterThanOrEqualTo(12));
    expect(normalised.r3, greaterThanOrEqualTo(12));
    expect(normalised.r5, greaterThanOrEqualTo(12));
    expect(normalised.mrr, greaterThanOrEqualTo(1));
  });
}

String _cell(int hit, int n) => '$hit/$n'.padLeft(5).padRight(7);
