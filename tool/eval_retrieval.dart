// Offline ranking experiments over a dump written by the device test
// (tool/rag_docs_e2e.sh pulls it to /tmp/rag_dump.json):
//
//   flutter pub run tool/eval_retrieval.dart [dump.json]
//
// Ranks every question against every chunk with HybridRanker for a grid of
// settings and prints Recall@1/3/5 and MRR against meaning-only search. The
// dump holds document text — keep it out of the repo.
import 'dart:convert';
import 'dart:io';

import 'package:uniun/core/text/hybrid_ranker.dart';

class _Chunk {
  _Chunk(this.doc, this.label, this.text, this.vector);
  final String doc;
  final String label;
  final String text;
  final List<double> vector;
}

class _Query {
  _Query(this.text, this.doc, this.pages, this.phrases, this.vector);
  final String text;
  final String doc;
  final List<String> pages;
  final List<String> phrases;
  final List<double> vector;
}

void main(List<String> args) {
  final path = args.isEmpty ? '/tmp/rag_dump.json' : args.first;
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final chunks = [
    for (final c in json['chunks'] as List)
      _Chunk(
        c['doc'] as String,
        c['label'] as String,
        c['text'] as String,
        (c['vector'] as List).cast<num>().map((n) => n.toDouble()).toList(),
      ),
  ];
  final queries = [
    for (final q in json['queries'] as List)
      if (q['doc'] != 'none')
        _Query(
          q['q'] as String,
          q['doc'] as String,
          (q['pages'] as List).cast<String>(),
          (q['phrases'] as List).cast<String>(),
          (q['vector'] as List).cast<num>().map((n) => n.toDouble()).toList(),
        ),
  ];
  stdout.writeln(
    '${chunks.length} chunks, ${queries.length} answerable questions',
  );

  bool relevant(_Query q, _Chunk c) =>
      (q.doc == 'any' || c.doc == q.doc) &&
      (q.pages.contains(c.label) ||
          q.phrases.any((p) => c.text.toLowerCase().contains(p.toLowerCase())));

  /// Rank of the first relevant chunk (1-based), 0 when not in the top 5.
  int rankOf(_Query q, HybridConfig config) {
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
    final i = order.indexWhere((id) => relevant(q, chunks[id]));
    return i < 0 ? 0 : i + 1;
  }

  ({int r1, int r3, int r5, double mrr}) score(
    HybridConfig config, {
    bool Function(_Query)? only,
  }) {
    var r1 = 0, r3 = 0, r5 = 0;
    var mrr = 0.0;
    var n = 0;
    for (final q in queries) {
      if (only != null && !only(q)) continue;
      n++;
      final r = rankOf(q, config);
      if (r == 1) r1++;
      if (r > 0 && r <= 3) r3++;
      if (r > 0) r5++;
      if (r > 0) mrr += 1 / r;
    }
    return (r1: r1, r3: r3, r5: r5, mrr: n == 0 ? 0 : mrr / n);
  }

  String fmt(({int r1, int r3, int r5, double mrr}) s, int n) =>
      'R@1 ${s.r1}/$n  R@3 ${s.r3}/$n  R@5 ${s.r5}/$n  MRR ${s.mrr.toStringAsFixed(3)}';

  final n = queries.length;
  final base = score(HybridConfig.off);
  stdout.writeln('\nmeaning only            ${fmt(base, n)}');
  stdout.writeln(
    'app default             ${fmt(score(const HybridConfig()), n)}',
  );

  final results = <(HybridConfig, ({int r1, int r3, int r5, double mrr}))>[];
  for (final w in [0.05, 0.1, 0.15, 0.2, 0.3, 0.4]) {
    for (final sat in [0.5, 1.0, 2.0, 4.0, 8.0]) {
      for (final nb in [1.0, 2.0, 3.0]) {
        for (final stop in [false, true]) {
          final cfg = HybridConfig(
            keywordWeight: w,
            saturation: sat,
            numberBoost: nb,
            dropStopwords: stop,
          );
          results.add((cfg, score(cfg)));
        }
      }
    }
  }
  results.sort((a, b) {
    final byMrr = b.$2.mrr.compareTo(a.$2.mrr);
    return byMrr != 0 ? byMrr : b.$2.r1.compareTo(a.$2.r1);
  });
  stdout.writeln('\nbest of ${results.length} settings (by MRR):');
  for (final r in results.take(12)) {
    final c = r.$1;
    stdout.writeln(
      'w${c.keywordWeight} sat${c.saturation} num${c.numberBoost} '
      'stop${c.dropStopwords ? 'Y' : 'N'}  ${fmt(r.$2, n)}',
    );
  }

  // Overfitting check: the best setting, per document, against the baseline.
  final best = results.first.$1;
  stdout.writeln('\nper document (meaning only -> best):');
  for (final doc in queries.map((q) => q.doc).toSet()) {
    final m = queries.where((q) => q.doc == doc).length;
    bool only(_Query q) => q.doc == doc;
    stdout.writeln(
      '$doc ($m): ${fmt(score(HybridConfig.off, only: only), m)}  ->  '
      '${fmt(score(best, only: only), m)}',
    );
  }

  // How flat is the surface around the default? A setting on a plateau is safer
  // than the single best point, which may just fit these questions.
  stdout.writeln(
    '\nkeyword weight sweep (saturation 2, number boost 2, stopwords on):',
  );
  for (final w in [0.0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 1.0]) {
    final cfg = HybridConfig(keywordWeight: w);
    stdout.writeln('w$w  ${fmt(score(cfg), n)}');
  }
  stdout.writeln('\nwithout stopword removal (same otherwise):');
  for (final w in [0.1, 0.15, 0.3]) {
    final cfg = HybridConfig(keywordWeight: w, dropStopwords: false);
    stdout.writeln('w$w  ${fmt(score(cfg), n)}');
  }
  stdout.writeln('\nper document, app default:');
  for (final doc in queries.map((q) => q.doc).toSet()) {
    final m = queries.where((q) => q.doc == doc).length;
    bool only(_Query q) => q.doc == doc;
    stdout.writeln(
      '$doc ($m): ${fmt(score(const HybridConfig(), only: only), m)}',
    );
  }
}
