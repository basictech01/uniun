import 'dart:math' as math;

/// Normalises spelling and OCR variants that should carry the same keyword
/// evidence, without changing the text sent to the embedder.
String _normalizeForKeywordSearch(String text) {
  final runes = text.toLowerCase().runes.toList();
  final out = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    final rune = runes[i];
    if (rune >= 0x0966 && rune <= 0x096f) {
      out.writeCharCode(0x30 + rune - 0x0966); // Devanagari digits.
    } else if (rune >= 0x09e6 && rune <= 0x09ef) {
      out.writeCharCode(0x30 + rune - 0x09e6); // Bengali OCR look-alikes.
    } else if (rune == 0x093c) {
      // Hindi commonly omits nukta.
      continue;
    } else if (rune == 0x200c || rune == 0x200d) {
      if (_isBetweenDevanagari(runes, i)) continue;
      // Joiners are meaningful word boundaries in scripts such as Persian.
      out.write(' ');
    } else {
      out.writeCharCode(_nuktaBase[rune] ?? rune);
    }
  }
  return out.toString();
}

bool _isBetweenDevanagari(List<int> runes, int index) =>
    index > 0 &&
    index + 1 < runes.length &&
    _isDevanagari(runes[index - 1]) &&
    _isDevanagari(runes[index + 1]);

bool _isDevanagari(int rune) => rune >= 0x0900 && rune <= 0x097f;

const Map<int, int> _nuktaBase = {
  0x0929: 0x0928, // ऩ → न
  0x0931: 0x0930, // ऱ → र
  0x0934: 0x0933, // ऴ → ळ
  0x0958: 0x0915, // क़ → क
  0x0959: 0x0916, // ख़ → ख
  0x095a: 0x0917, // ग़ → ग
  0x095b: 0x091c, // ज़ → ज
  0x095c: 0x0921, // ड़ → ड
  0x095d: 0x0922, // ढ़ → ढ
  0x095e: 0x092b, // फ़ → फ
  0x095f: 0x092f, // य़ → य
};

// Keep this deliberately narrow: a global chandrabindu → anusvara fold would
// collapse distinct words such as हँस (laugh) and हंस (swan). Only vetted,
// whole-word pairs are folded; inflections are not inferred from these stems.
const Map<String, String> _spellingVariants = {
  'कहाँ': 'कहां',
  'आँख': 'आंख',
  'माँ': 'मां',
  'गाँव': 'गांव',
  'चाँद': 'चांद',
};

/// Lower-cased, keyword-normalised words, numbers and combining marks of
/// [text], as separate tokens. Unicode-aware, so Devanagari words and their
/// vowel signs stay whole; punctuation splits (`1800-233-0421` → `1800`,
/// `233`, `0421`).
List<String> tokenize(String text) => [
  for (final m in _word.allMatches(_normalizeForKeywordSearch(text)))
    _spellingVariants[m.group(0)!] ?? m.group(0)!,
];

final RegExp _word = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

List<String> _queryTerms(String query, Set<String> stopwords) {
  final normalisedStopwords = <String>{
    for (final stopword in stopwords) ...tokenize(stopword),
  };
  return tokenize(
    query,
  ).where((term) => !normalisedStopwords.contains(term)).toSet().toList();
}

/// Keyword relevance (Okapi BM25) of a corpus for one query, in a single pass.
///
/// Meaning-based search blurs exact things — a helpline number, a
/// registration number, a name — because such tokens look alike to an
/// embedder. This scores by the query's actual words instead, weighting the
/// rare ones: a word found in one chunk of a hundred counts far more than one
/// found in most of them.
///
/// Only the query's words are counted, so a pass over thousands of chunks
/// keeps a few numbers per chunk, not its text.
class Bm25Scorer {
  /// [stopwords] are dropped from the query — they say nothing about what is
  /// being asked. [termBoost] multiplies a word's weight, to favour the ones
  /// that identify something (see [isIdentifier]).
  Bm25Scorer(
    String query, {
    this.k1 = 1.2,
    this.b = 0.75,
    Set<String> stopwords = const {},
    double Function(String term)? termBoost,
  }) : terms = _queryTerms(query, stopwords),
       _boost = termBoost;

  final double Function(String term)? _boost;

  final double k1;
  final double b;

  /// The distinct query words.
  final List<String> terms;

  final Map<int, List<int>> _tf = {};
  final Map<int, int> _length = {};
  final List<int> _df = [];
  var _docs = 0;
  var _totalLength = 0;

  /// Feeds one chunk. [key] identifies it in [scores]'s result.
  void add(int key, String text) {
    _docs++;
    final words = tokenize(text);
    _totalLength += words.length;
    if (terms.isEmpty) return;
    if (_df.isEmpty) _df.addAll(List<int>.filled(terms.length, 0));
    final counts = List<int>.filled(terms.length, 0);
    var any = false;
    for (final w in words) {
      final i = terms.indexOf(w);
      if (i >= 0) {
        counts[i]++;
        any = true;
      }
    }
    if (!any) return;
    _length[key] = words.length;
    _tf[key] = counts;
    for (var i = 0; i < counts.length; i++) {
      if (counts[i] > 0) _df[i]++;
    }
  }

  /// Score per chunk that contains at least one query word; absent means no
  /// match. Higher is more relevant, on no fixed scale.
  Map<int, double> scores() {
    if (_tf.isEmpty || _docs == 0) return const {};
    final avgLength = _totalLength / _docs;
    final out = <int, double>{};
    _tf.forEach((key, counts) {
      final length = _length[key]!;
      var sum = 0.0;
      for (var i = 0; i < counts.length; i++) {
        final f = counts[i];
        if (f == 0) continue;
        final idf = math.log(1 + (_docs - _df[i] + 0.5) / (_df[i] + 0.5));
        sum +=
            (_boost?.call(terms[i]) ?? 1) *
            idf *
            f *
            (k1 + 1) /
            (f + k1 * (1 - b + b * length / (avgLength == 0 ? 1 : avgLength)));
      }
      out[key] = sum;
    });
    return out;
  }
}

/// Whether [token] identifies something — a number, a code, a serial such as
/// `2541` or `in26965323775594r` — rather than being an ordinary word: three or
/// more characters, at least one a digit.
bool isIdentifier(String token) =>
    token.length >= 3 && token.contains(RegExp(r'\p{N}', unicode: true));
