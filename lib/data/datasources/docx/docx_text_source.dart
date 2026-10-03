import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:xml/xml.dart';

/// One heading-started stretch of a Word document: [label] is the heading's
/// text, `''` for anything above the first heading.
typedef DocxSection = ({String label, String text});

/// Refuse a `word/document.xml` over this uncompressed. These files arrive
/// from other users over relays, so a zip bomb is a real input — and the parsed
/// DOM costs ~10x the XML (measured), shared with the app's heap because
/// [Isolate.run] stays in its isolate group. 10 MB is a several-hundred-page
/// text document; typical files are well under 1 MB.
const int kMaxDocxXmlBytes = 10 * 1024 * 1024;

/// The same guard for `word/styles.xml`, which is normally tens of KB.
const int kMaxDocxStylesBytes = 2 * 1024 * 1024;

/// An embedded picture is worth OCR only when it is drawn at least this wide
/// — 2.5 in (6.35 cm) in EMU, 914,400 per inch — and this large in area
/// (about 5 × 4 in). Logos, signatures and icons fall below it. Unmeasured.
const int kMinDocxImageWidthEmu = 2286000;
const double kMinDocxImageAreaEmu2 = 3.34e12;

/// ...and has at least this many pixels: a small bitmap stretched to fill the
/// page holds too little detail for OCR to read.
const int kMinDocxImagePixelsWide = 500;
const int kMinDocxImagePixelsHigh = 100;

/// Pictures read per document, and the largest one extracted. Each costs
/// about a second of OCR, and the file came from another user. Unmeasured.
const int kMaxDocxImages = 20;
const int kMaxDocxImageBytes = 15 * 1024 * 1024;

const int _maxLabelChars = 100;
const String _w =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const String _wp =
    'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing';
const String _a = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const String _r =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// Marks where an extracted picture sat in a section's text: its file path
/// between two U+FFFC OBJECT REPLACEMENT CHARACTERs, which never occur in
/// real text.
String docxImageMarker(String path) => '\uFFFC$path\uFFFC';

/// Matches a [docxImageMarker]; group 1 is the path.
final RegExp docxImageMarkerPattern = RegExp('\uFFFC([^\uFFFC]*)\uFFFC');

/// Seam over the DOCX reader, so callers can be tested without real files.
abstract class DocxTextSource {
  /// Sections in reading order, or `null` when the file cannot be read as a
  /// Word document.
  ///
  /// With [imageDir], each embedded picture large enough to hold text is
  /// written there and left in its section's text as a [docxImageMarker];
  /// the caller reads and deletes them. Without it pictures are ignored.
  Future<List<DocxSection>?> sectionsText(String path, {String? imageDir});
}

/// Reads `word/document.xml` straight out of the zip.
///
/// Parsing runs in [Isolate.run]: unlike PDFium's async FFI, XML parsing is
/// synchronous Dart and would stall the UI on a large document.
@LazySingleton(as: DocxTextSource)
class ArchiveDocxTextSource implements DocxTextSource {
  @override
  Future<List<DocxSection>?> sectionsText(
    String path, {
    String? imageDir,
  }) async {
    try {
      return await Isolate.run(
        () => _parse(File(path).readAsBytesSync(), imageDir),
      );
    } catch (_) {
      return null;
    }
  }
}

List<DocxSection>? _parse(List<int> bytes, String? imageDir) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final doc = zip.findFile('word/document.xml');
  // The declared size stops an honest bomb before inflating anything; a header
  // that lies is only caught after inflation, at the cost of the memory spent.
  if (doc == null || doc.size > kMaxDocxXmlBytes) return null;
  final raw = doc.readBytes();
  if (raw == null || raw.length > kMaxDocxXmlBytes) return null;

  final body = XmlDocument.parse(
    utf8.decode(raw),
  ).descendantElements.where((e) => _isW(e, 'body')).firstOrNull;
  if (body == null) return null;

  final headings = _headingStyles(zip.findFile('word/styles.xml'));
  final pictures = imageDir == null
      ? null
      : _Pictures(zip, _imageTargets(zip), imageDir);
  final sections = <DocxSection>[];
  var label = '';
  var buf = StringBuffer();
  // Whether the open section has anything besides headings. A heading with no
  // body of its own ("Chapter 3" straight above "3.1 Scope") folds into the
  // next section instead of becoming a chunk that is only a title.
  var hasBody = false;

  void flush() {
    final text = buf.toString().trim();
    if (text.isNotEmpty) sections.add((label: label, text: text));
    buf = StringBuffer();
    hasBody = false;
  }

  void walk(XmlElement container) {
    for (final el in container.childElements) {
      if (_isW(el, 'p')) {
        final text = _paragraphText(el, pictures);
        if (text.trim().isEmpty) continue;
        final heading = _isHeading(el, headings);
        if (heading) {
          if (hasBody) flush();
          label = _cap(_collapse(text.replaceAll(docxImageMarkerPattern, '')));
        }
        buf.write('$text\n\n');
        if (!heading) hasBody = true;
      } else if (_isW(el, 'tbl')) {
        final text = _tableText(el, pictures);
        if (text.isEmpty) continue;
        buf.write('$text\n\n');
        hasBody = true;
      } else if (_isW(el, 'sdt') ||
          _isW(el, 'sdtContent') ||
          _isW(el, 'customXml')) {
        // Content controls wrap whole paragraphs; Word templates put section
        // headers in them, so skipping these would drop real text.
        walk(el);
      }
    }
  }

  walk(body);
  flush();
  return sections;
}

bool _isW(XmlElement e, String local) =>
    e.name.local == local && e.name.namespaceUri == _w;

String? _val(XmlElement e) => e.getAttribute('val', namespace: _w);

XmlElement? _child(XmlElement e, String local) =>
    e.childElements.where((c) => _isW(c, local)).firstOrNull;

/// `w:t` text, tabs and breaks, in order. Deleted text (`w:delText`) and field
/// codes (`w:instrText`) are different elements and so never match; text
/// boxes are skipped because their `mc:Fallback` copy would repeat them.
String _paragraphText(XmlElement p, [_Pictures? pictures]) {
  final out = StringBuffer();
  void walk(XmlElement e) {
    for (final c in e.childElements) {
      // A text move keeps its old copy in `w:moveFrom` as ordinary `w:t`, so
      // reading it would index the moved text twice.
      if (_isW(c, 'txbxContent') || _isW(c, 'moveFrom')) continue;
      if (_isW(c, 'drawing')) {
        final path = pictures?.extract(c);
        if (path != null) out.write('\n${docxImageMarker(path)}\n');
      } else if (_isW(c, 't')) {
        out.write(c.innerText);
      } else if (_isW(c, 'tab')) {
        out.write('\t');
      } else if (_isW(c, 'br') || _isW(c, 'cr')) {
        out.write('\n');
      } else {
        walk(c);
      }
    }
  }

  walk(p);
  return out.toString();
}

String _tableText(XmlElement tbl, [_Pictures? pictures]) => tbl.childElements
    .where((r) => _isW(r, 'tr'))
    .map(
      (row) => row.childElements
          .where((c) => _isW(c, 'tc'))
          .map(
            (cell) => _collapse(
              _paragraphsIn(
                cell,
              ).map((p) => _paragraphText(p, pictures)).join(' '),
            ),
          )
          .join(' | '),
    )
    .where((line) => line.replaceAll('|', '').trim().isNotEmpty)
    .join('\n');

/// Paragraphs under [e] (nested tables included), skipping text boxes for the
/// same reason [_paragraphText] does.
Iterable<XmlElement> _paragraphsIn(XmlElement e) sync* {
  for (final c in e.childElements) {
    if (_isW(c, 'txbxContent')) continue;
    if (_isW(c, 'p')) {
      yield c;
    } else {
      yield* _paragraphsIn(c);
    }
  }
}

bool _isHeading(XmlElement p, Set<String> headingStyles) {
  final pPr = _child(p, 'pPr');
  if (pPr == null) return false;
  if (_isOutline(_child(pPr, 'outlineLvl'))) return true;
  final style = _child(pPr, 'pStyle');
  return style != null && headingStyles.contains(_val(style));
}

/// `outlineLvl` 0–8 is a heading level; 9 means body text.
bool _isOutline(XmlElement? lvl) {
  final n = lvl == null ? null : int.tryParse(_val(lvl) ?? '');
  return n != null && n >= 0 && n <= 8;
}

/// Ids of paragraph styles that are headings, judged by *name* — built-in
/// names stay English in every Word locale while ids do not (German Word:
/// `berschrift1`) — or by an outline level, following `basedOn`.
///
/// An unreadable styles part costs only name-based detection: the body is
/// still worth indexing, and outline levels set on paragraphs still work.
Set<String> _headingStyles(ArchiveFile? file) {
  final XmlDocument styles;
  try {
    if (file == null || file.size > kMaxDocxStylesBytes) return const {};
    final raw = file.readBytes();
    if (raw == null || raw.length > kMaxDocxStylesBytes) return const {};
    styles = XmlDocument.parse(utf8.decode(raw));
  } catch (_) {
    return const {};
  }

  final byId = <String, XmlElement>{};
  for (final s in styles.descendantElements.where((e) => _isW(e, 'style'))) {
    final id = s.getAttribute('styleId', namespace: _w);
    if (id != null) byId[id] = s;
  }

  bool own(XmlElement s) {
    final nameEl = _child(s, 'name');
    final name = (nameEl == null ? null : _val(nameEl))?.toLowerCase() ?? '';
    if (name == 'title' || RegExp(r'^heading [1-9]$').hasMatch(name)) {
      return true;
    }
    final pPr = _child(s, 'pPr');
    return pPr != null && _isOutline(_child(pPr, 'outlineLvl'));
  }

  bool isHeading(String id) {
    var cur = byId[id];
    // Bounded: a malformed file can make `basedOn` loop.
    for (var depth = 0; cur != null && depth < 10; depth++) {
      if (own(cur)) return true;
      final base = _child(cur, 'basedOn');
      cur = base == null ? null : byId[_val(base)];
    }
    return false;
  }

  return {
    for (final id in byId.keys)
      if (isHeading(id)) id,
  };
}

String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String _cap(String s) {
  if (s.length <= _maxLabelChars) return s;
  var end = _maxLabelChars - 1;
  // Never end on a high surrogate: that would split an emoji in two.
  final last = s.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return '${s.substring(0, end)}…';
}

/// Relationship id → zip entry for every target of `word/document.xml`. A
/// linked picture's URL names no entry, so it is never found in the zip.
Map<String, String> _imageTargets(Archive zip) {
  final file = zip.findFile('word/_rels/document.xml.rels');
  if (file == null || file.size > kMaxDocxStylesBytes) return const {};
  try {
    final raw = file.readBytes();
    if (raw == null) return const {};
    final rels = XmlDocument.parse(utf8.decode(raw));
    return {
      for (final r in rels.descendantElements.where(
        (e) => e.name.local == 'Relationship',
      ))
        if (r.getAttribute('Id') != null && r.getAttribute('Target') != null)
          r.getAttribute('Id')!: _resolve(r.getAttribute('Target')!),
    };
  } catch (_) {
    return const {};
  }
}

/// A target is relative to `word/`, or absolute from the package root.
String _resolve(String target) =>
    target.startsWith('/') ? target.substring(1) : 'word/$target';

/// Writes the pictures worth reading to [dir], each at most once.
class _Pictures {
  _Pictures(this._zip, this._targets, this._dir);

  final Archive _zip;
  final Map<String, String> _targets;
  final String _dir;
  final Set<String> _seen = {};
  var _written = 0;

  /// The file [drawing]'s picture was written to, or `null` when it is too
  /// small, not a bitmap OCR reads, linked rather than embedded, or already
  /// read at an earlier position.
  String? extract(XmlElement drawing) {
    // A malformed picture costs only itself, never the document's text.
    try {
      return _extract(drawing);
    } catch (_) {
      return null;
    }
  }

  String? _extract(XmlElement drawing) {
    if (_written >= kMaxDocxImages) return null;
    final extent = drawing.descendantElements
        .where((e) => e.name.local == 'extent' && e.name.namespaceUri == _wp)
        .firstOrNull;
    final cx = int.tryParse(extent?.getAttribute('cx') ?? '') ?? 0;
    final cy = int.tryParse(extent?.getAttribute('cy') ?? '') ?? 0;
    if (cx < kMinDocxImageWidthEmu ||
        cx.toDouble() * cy < kMinDocxImageAreaEmu2) {
      return null;
    }

    final blip = drawing.descendantElements
        .where((e) => e.name.local == 'blip' && e.name.namespaceUri == _a)
        .firstOrNull;
    final entry = _targets[blip?.getAttribute('embed', namespace: _r)];
    // A picture pasted twice holds the same text twice.
    if (entry == null || !_seen.add(entry)) return null;

    final file = _zip.findFile(entry);
    if (file == null || file.size > kMaxDocxImageBytes) return null;
    final bytes = file.readBytes();
    if (bytes == null || bytes.length > kMaxDocxImageBytes) return null;
    // EMF, WMF and SVG are vector drawings with no decoder, and nothing to
    // OCR.
    final info = img.findDecoderForData(bytes)?.startDecode(bytes);
    if (info == null ||
        info.width < kMinDocxImagePixelsWide ||
        info.height < kMinDocxImagePixelsHigh) {
      return null;
    }

    final out = '$_dir/image_${_written++}.${entry.split('.').last}';
    File(out).writeAsBytesSync(bytes);
    return out;
  }
}
