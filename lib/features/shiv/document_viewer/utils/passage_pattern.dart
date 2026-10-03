/// How many leading words of a cited passage are searched for. Long enough to
/// be unique, short enough to survive the places where the viewer's text and
/// the extracted text drift apart (hyphenation, ligatures, column breaks).
const int kHighlightWords = 12;

/// A pattern matching the start of [snippet] however the page breaks its
/// lines, or `null` when the snippet has no words to search for.
///
/// The viewer searches its own re-flowed text, whose line breaks differ from the
/// text the chunk was cut from, so the words are joined by any whitespace
/// rather than copied verbatim.
RegExp? passagePattern(String snippet) {
  final words = snippet
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(kHighlightWords)
      .map(RegExp.escape)
      .toList();
  if (words.isEmpty) return null;
  return RegExp(words.join(r'\s+'), caseSensitive: false, unicode: true);
}
