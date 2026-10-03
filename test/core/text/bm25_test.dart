import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/text/bm25.dart';

/// Covers: tokenize on punctuation, numbers, Devanagari and emoji; Bm25Scorer
/// weighting rare words over common ones, ignoring non-matches, length
/// normalisation and degenerate queries.
void main() {
  group('tokenize', () {
    test('splits on punctuation and lower-cases', () {
      expect(tokenize('Helpline: 1800-233-0421!'), [
        'helpline',
        '1800',
        '233',
        '0421',
      ]);
    });

    test('keeps Devanagari words whole, vowel signs included', () {
      expect(tokenize('निरीक्षण शुल्क, बुधवार'), [
        'निरीक्षण',
        'शुल्क',
        'बुधवार',
      ]);
    });

    test('an empty or symbol-only string has no tokens', () {
      expect(tokenize(''), isEmpty);
      expect(tokenize('!!! --- ###'), isEmpty);
    });

    test('an emoji is not a token but does not break its neighbours', () {
      expect(tokenize('camp 🎉 fee'), ['camp', 'fee']);
    });
  });

  group('Bm25Scorer', () {
    Map<int, double> score(String query, List<String> docs) {
      final s = Bm25Scorer(query);
      for (var i = 0; i < docs.length; i++) {
        s.add(i, docs[i]);
      }
      return s.scores();
    }

    test('only chunks containing a query word are scored', () {
      final r = score('helpline', ['the helpline is open', 'nothing here']);

      expect(r.keys, [0]);
    });

    test('a rare word outweighs a common one', () {
      final docs = [
        'the office is open',
        'the office is closed',
        'the office moved',
        'the office has a helpline',
      ];

      final r = score('the helpline', docs);

      expect(
        r[3]!,
        greaterThan(r[0]!),
        reason: '"helpline" is in one chunk, "the" in all',
      );
    });

    test('repeating a word helps, but with diminishing returns', () {
      final r = score('fee', ['fee', 'fee fee', 'fee fee fee fee fee fee']);

      expect(r[1]!, greaterThan(r[0]!));
      // Going from 2 to 6 occurrences adds less than 4x what 1 to 2 added.
      expect(r[2]! - r[1]!, lessThan((r[1]! - r[0]!) * 4));
    });

    test('a match in a short chunk beats the same match in a long one', () {
      final r = score('fee', [
        'fee',
        'fee ${List.filled(60, 'filler').join(' ')}',
      ]);

      expect(r[0]!, greaterThan(r[1]!));
    });

    test('a word used twice in the query is counted once', () {
      final a = score('fee fee', ['fee here', 'other text']);
      final b = score('fee', ['fee here', 'other text']);

      expect(a[0], b[0]);
    });

    test('numbers match number tokens', () {
      final r = score('2541', ['registration 2541 year 2019', 'year 2019']);

      expect(r.keys, [0]);
    });

    test('a Devanagari word matches its exact form', () {
      final r = score('बुधवार', ['हर बुधवार को', 'हर शनिवार को']);

      expect(r.keys, [0]);
    });

    test('scores are positive even when every chunk has the word', () {
      final r = score('the', ['the a', 'the b']);

      expect(r.values.every((v) => v > 0), isTrue);
    });

    test('an empty query or corpus scores nothing', () {
      expect(score('', ['some text']), isEmpty);
      expect(score('!!!', ['some text']), isEmpty);
      expect(score('word', const []), isEmpty);
    });

    test('an empty chunk is fine', () {
      expect(score('word', ['', 'word']).keys, [1]);
    });
  });
}
