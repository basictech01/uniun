import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/text/bm25.dart';
import 'package:uniun/core/text/hybrid_ranker.dart';
import 'package:uniun/core/text/stopwords.dart';

/// Covers: HybridRanker fusing cosine with keyword strength — saturation,
/// stopwords, identifier boost — and BM25 term boost/stopword hooks.
void main() {
  const dims = 8;
  List<double> unit(int k) =>
      List<double>.generate(dims, (i) => i == k ? 1.0 : 0.0);

  /// A vector at cosine [c] to [unit]`(0)`.
  List<double> at(double c) => [
    c,
    (1 - c * c) > 0 ? _sqrt(1 - c * c) : 0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  /// 40 filler chunks: idf needs a corpus.
  void addFiller(HybridRanker r, {int from = 100}) {
    for (var i = 0; i < 40; i++) {
      r.add(from + i, unit(2 + i % 6), 'filler paragraph about nothing $i');
    }
  }

  List<int> rank(
    String query,
    Map<int, ({double cosine, String text})> chunks, {
    HybridConfig config = const HybridConfig(),
  }) {
    final r = HybridRanker(unit(0), queryText: query, config: config);
    chunks.forEach((id, c) => r.add(id, at(c.cosine), c.text));
    addFiller(r);
    return r.ranked().where((id) => id < 100).toList();
  }

  group('keyword strength', () {
    test(
      'a strong match on a rare word outranks a slightly closer meaning',
      () {
        final order = rank('zebra', {
          1: (cosine: 0.70, text: 'general information'),
          2: (cosine: 0.65, text: 'zebra crossing rules'),
        });

        expect(order.first, 2);
      },
    );

    test('a weak match on a common word does not', () {
      final order = rank('information', {
        1: (cosine: 0.70, text: 'general information'),
        // "information" is in many chunks below, so it is not rare.
        2: (cosine: 0.65, text: 'information about other things'),
        3: (cosine: 0.64, text: 'information information information'),
      }, config: const HybridConfig(dropStopwords: false));

      expect(order.first, 1);
    });

    test('the bonus never exceeds keywordWeight', () {
      final r = HybridRanker(
        unit(0),
        queryText: 'zebra',
        config: const HybridConfig(keywordWeight: 0.15),
      );
      r.add(1, at(0.5), 'zebra ' * 30);
      r.add(2, at(0.7), 'other text');
      addFiller(r);

      expect(r.ranked().first, 2, reason: '0.5 + at most 0.15 cannot pass 0.7');
    });

    test('weight zero is meaning-only', () {
      final order = rank('zebra', {
        1: (cosine: 0.70, text: 'general'),
        2: (cosine: 0.65, text: 'zebra zebra zebra'),
      }, config: HybridConfig.off);

      expect(order.first, 1);
    });
  });

  group('stopwords and identifiers', () {
    test('a question of only stopwords adds nothing', () {
      final order = rank('what is the', {
        1: (cosine: 0.70, text: 'general'),
        2: (cosine: 0.65, text: 'what is the answer to the question'),
      });

      expect(order.first, 1);
    });

    test('Hinglish and Hindi function words are ignored', () {
      final order = rank('kitna hai कितना है', {
        1: (cosine: 0.70, text: 'general'),
        2: (cosine: 0.65, text: 'kitna hai कितना है'),
      });

      expect(order.first, 1);
    });

    test('normalised Hindi stopwords are ignored', () {
      final order = rank('कहाँ है', {
        1: (cosine: 0.70, text: 'general'),
        2: (cosine: 0.65, text: 'कहां है'),
      });

      expect(order.first, 1);
    });

    test('an identifier outweighs an ordinary word of equal rarity', () {
      final order = rank('registration 2541', {
        1: (cosine: 0.66, text: 'registration ledger overview'),
        2: (cosine: 0.66, text: 'serial 2541 issued'),
      }, config: const HybridConfig(numberBoost: 3));

      expect(order.first, 2);
    });

    test('kStopwords has no accidental duplicates or empties', () {
      expect(
        kStopwords.every((w) => w.isNotEmpty && w == w.toLowerCase()),
        isTrue,
      );
    });
  });

  group('degenerate input', () {
    test('a vector of another dimension or all zeros is ignored', () {
      final r = HybridRanker(unit(0), queryText: 'x');
      r.add(1, [1, 0], 'x');
      r.add(2, List<double>.filled(dims, 0), 'x');
      r.add(3, null, 'x');
      r.add(4, unit(0), 'x');

      expect(r.ranked(), [4]);
    });

    test('an empty query vector ranks nothing', () {
      final r = HybridRanker(const [], queryText: 'x');
      r.add(1, const [], 'x');

      expect(r.ranked(), isEmpty);
    });

    test('a chunk below minScore with no keyword match is not a candidate', () {
      final r = HybridRanker(unit(0), queryText: 'zebra');
      r.add(1, at(0.1), 'unrelated');

      expect(r.ranked(), isEmpty);
    });
  });

  group('Bm25Scorer hooks', () {
    test('stopwords are dropped from the query', () {
      final s = Bm25Scorer('the zebra', stopwords: const {'the'});

      expect(s.terms, ['zebra']);
    });

    test('a term boost multiplies that word\'s contribution', () {
      double score(double boost) {
        final s = Bm25Scorer('zebra', termBoost: (_) => boost);
        s.add(1, 'zebra crossing');
        s.add(2, 'other');
        return s.scores()[1]!;
      }

      expect(score(2), closeTo(score(1) * 2, 1e-9));
    });

    test('isIdentifier: digits and length', () {
      expect(isIdentifier('2541'), isTrue);
      expect(isIdentifier('in26965323775594r'), isTrue);
      expect(isIdentifier('12'), isFalse, reason: 'too short to identify');
      expect(isIdentifier('word'), isFalse);
      expect(isIdentifier('०४२१'), isTrue, reason: 'Devanagari digits count');
    });
  });
}

double _sqrt(double v) {
  var x = v;
  for (var i = 0; i < 40; i++) {
    x = 0.5 * (x + v / x);
  }
  return x;
}
