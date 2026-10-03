import 'dart:math' as math;

/// One embeddable piece of a document.
///
/// [label] says where it came from: the 1-based page for a PDF, the heading
/// above it for a DOCX, `''` when there is none. It is a first-class field
/// because a citation cannot be verified if its location was discarded during
/// splitting.
class Chunk {
  const Chunk({required this.text, required this.ordinal, required this.label});

  final String text;

  /// Position across the whole document, `0..n-1`.
  final int ordinal;
  final String label;

  @override
  String toString() => 'Chunk("$label" #$ordinal, ${text.length} chars)';
}

/// Upper bound on a chunk's length.
///
/// `PromptBudget` gives the smallest local model 1024 tokens in total, and
/// `buildUserMessage` drops a whole section that would overshoot `maxTokens`.
/// The document section's share for that model is `1024 * 0.35 / 2 = 179`
/// tokens ≈ 716 characters at the app's 4-chars-per-token estimate, so a
/// page-sized chunk would make the document vanish from the prompt with no
/// error. 700 keeps a chunk inside that share and well inside one embedder
/// input.
const int kMaxChunkChars = 700;

/// Splits PDF [pages] into chunks labelled with their 1-based page number.
///
/// Whitespace-only pages are skipped without shifting the labels of later ones.
List<Chunk> chunkPages(List<String> pages, {int maxChars = kMaxChunkChars}) =>
    chunkSections([
      for (var i = 0; i < pages.length; i++)
        (label: '${i + 1}', text: pages[i]),
    ], maxChars: maxChars);

/// Splits labelled [sections] into chunks no longer than [maxChars], never
/// packing across a section boundary so each chunk's label stays true.
List<Chunk> chunkSections(
  List<({String label, String text})> sections, {
  int maxChars = kMaxChunkChars,
}) {
  if (maxChars < 2) {
    throw ArgumentError.value(
      maxChars,
      'maxChars',
      'must fit a surrogate pair',
    );
  }
  final out = <Chunk>[];
  for (final s in sections) {
    for (final piece in _pieces(s.text, maxChars)) {
      out.add(Chunk(text: piece, ordinal: out.length, label: s.label));
    }
  }
  return out;
}

/// One page or section → its chunks: split into paragraphs, break any that are too long,
/// then pack neighbours back together up to the cap.
List<String> _pieces(String page, int maxChars) {
  final atoms = <String>[];
  for (final para in page.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'))) {
    final p = para.trim();
    if (p.isEmpty) continue;
    atoms.addAll(p.length <= maxChars ? [p] : _splitLong(p, maxChars));
  }

  final packed = <String>[];
  var cur = StringBuffer();
  for (final a in atoms) {
    if (cur.isNotEmpty && cur.length + 2 + a.length > maxChars) {
      packed.add(cur.toString());
      cur = StringBuffer();
    }
    if (cur.isNotEmpty) cur.write('\n\n');
    cur.write(a);
  }
  if (cur.isNotEmpty) packed.add(cur.toString());
  return packed;
}

/// Sentence-packs an over-long paragraph; a single sentence still over the cap
/// is hard-cut. Terminators include the Devanagari danda (।).
List<String> _splitLong(String text, int maxChars) {
  final out = <String>[];
  var cur = '';
  for (final s in text.split(RegExp(r'(?<=[.?!।])\s+'))) {
    final sentence = s.trim();
    if (sentence.isEmpty) continue;
    if (sentence.length > maxChars) {
      if (cur.isNotEmpty) {
        out.add(cur);
        cur = '';
      }
      var start = 0;
      while (start < sentence.length) {
        final end = _safeEnd(
          sentence,
          math.min(start + maxChars, sentence.length),
        );
        out.add(sentence.substring(start, end));
        start = end;
      }
      continue;
    }
    if (cur.isNotEmpty && cur.length + 1 + sentence.length > maxChars) {
      out.add(cur);
      cur = '';
    }
    cur = cur.isEmpty ? sentence : '$cur $sentence';
  }
  if (cur.isNotEmpty) out.add(cur);
  return out;
}

/// Backs a cut off by one code unit when it would land between a surrogate
/// pair, so a hard cut never splits an emoji or an astral-plane character.
int _safeEnd(String s, int end) {
  if (end >= s.length) return s.length;
  final unit = s.codeUnitAt(end - 1);
  return (unit >= 0xD800 && unit <= 0xDBFF) ? end - 1 : end;
}
