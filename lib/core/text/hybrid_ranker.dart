import 'dart:math' as math;

import 'package:uniun/core/text/bm25.dart';
import 'package:uniun/core/text/stopwords.dart';

/// How keyword evidence is added to meaning similarity.
class HybridConfig {
  const HybridConfig({
    this.keywordWeight = 0.3,
    this.saturation = 2.0,
    this.numberBoost = 2.0,
    this.dropStopwords = true,
  });

  /// The most a keyword match can add to a chunk's cosine similarity.
  final double keywordWeight;

  /// How much keyword strength earns the full weight: a chunk with BM25 score
  /// `s` gets `keywordWeight * s / (s + saturation)`, so a weak match on a
  /// common word adds little and a strong match on rare words nearly all of it.
  final double saturation;

  /// Multiplier for identifier-like words (numbers, codes) in the question.
  final double numberBoost;

  /// Ignore words like "the", "and", "kya", "है" in the question.
  final bool dropStopwords;

  /// Meaning-only ranking.
  static const HybridConfig off = HybridConfig(keywordWeight: 0);
}

/// Ranks chunks for one question by meaning (cosine) plus keyword evidence.
///
/// Feed every chunk with [add], then read the order with [ranked]. Only ids and
/// numbers are kept per chunk, so a pass over thousands of chunks stays small.
class HybridRanker {
  HybridRanker(
    this.queryVector, {
    String? queryText,
    this.config = const HybridConfig(),
    this.minScore = 0.3,
    this.candidates = 20,
  }) : _queryNorm = _norm(queryVector),
       _keywords = queryText == null || config.keywordWeight == 0
           ? null
           : Bm25Scorer(
               queryText,
               stopwords: config.dropStopwords ? kStopwords : const {},
               termBoost: (t) => isIdentifier(t) ? config.numberBoost : 1,
             );

  final List<double> queryVector;
  final HybridConfig config;
  final double minScore;

  /// How many chunks each of meaning and keywords contributes to the final
  /// ranking.
  final int candidates;

  final double _queryNorm;
  final Bm25Scorer? _keywords;
  final Map<int, double> _cosine = {};

  /// Cosine similarity of every chunk added, by id.
  Map<int, double> get cosines => _cosine;

  /// Feeds one chunk. A vector that cannot be compared (another dimension, all
  /// zeros) is ignored entirely.
  void add(int id, List<double>? vector, String text) {
    if (vector == null ||
        _queryNorm == 0 ||
        vector.length != queryVector.length) {
      return;
    }
    final norm = _norm(vector);
    if (norm == 0) return;
    _cosine[id] = _dot(queryVector, vector) / (_queryNorm * norm);
    _keywords?.add(id, text);
  }

  /// Chunk ids, best first.
  List<int> ranked() {
    final byMeaning =
        (_cosine.entries.where((e) => e.value >= minScore).toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(candidates)
            .map((e) => e.key);
    final keywordScores = _keywords?.scores() ?? const <int, double>{};
    final byKeyword =
        (keywordScores.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(candidates)
            .map((e) => e.key);

    double fused(int id) {
      final s = keywordScores[id] ?? 0;
      return _cosine[id]! +
          (s == 0 ? 0 : config.keywordWeight * s / (s + config.saturation));
    }

    return {...byMeaning, ...byKeyword}.toList()
      ..sort((a, b) => fused(b).compareTo(fused(a)));
  }

  static double _norm(List<double> v) => math.sqrt(_dot(v, v));

  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
