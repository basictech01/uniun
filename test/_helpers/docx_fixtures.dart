import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'pdf_fixtures.dart';

/// Absolute path to a committed DOCX fixture in `test/_helpers/fixtures/docx/`.
String docxFixture(String name) =>
    '${packageRoot()}/test/_helpers/fixtures/docx/$name';

/// The WordprocessingML namespace every `w:` element lives in.
const String wNs =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

String _esc(String s) => const HtmlEscape(HtmlEscapeMode.element).convert(s);

/// `word/document.xml` around [body], bound to [prefix] (normally `w`).
String wDocument(String body, {String prefix = 'w'}) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<$prefix:document xmlns:$prefix="$wNs"><$prefix:body>$body'
    '</$prefix:body></$prefix:document>';

/// One paragraph holding [text] in a single run, optionally styled and/or
/// carrying its own outline level.
String wP(String text, {String? style, int? outline}) {
  final pPr = [
    if (style != null) '<w:pStyle w:val="$style"/>',
    if (outline != null) '<w:outlineLvl w:val="$outline"/>',
  ].join();
  return '<w:p>${pPr.isEmpty ? '' : '<w:pPr>$pPr</w:pPr>'}'
      '<w:r><w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>';
}

/// A table of plain-text cells, one inner list per row.
String wTable(List<List<String>> rows) => '<w:tbl>${[
      for (final r in rows)
        '<w:tr>${[for (final c in r) '<w:tc>${wP(c)}</w:tc>'].join()}</w:tr>',
    ].join()}</w:tbl>';

/// A paragraph holding one picture drawn [cx] × [cy] EMU (914,400 per inch),
/// pointing at relationship [rId] — embedded, or with [linked] only linked.
String wDrawing(
  String rId, {
  int cx = 5486400,
  int cy = 3657600,
  bool linked = false,
}) =>
    '<w:p><w:r><w:drawing '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<wp:inline><wp:extent cx="$cx" cy="$cy"/><a:graphic><a:graphicData>'
    '<pic:pic><pic:blipFill><a:blip r:${linked ? 'link' : 'embed'}="$rId"/>'
    '</pic:blipFill></pic:pic></a:graphicData></a:graphic></wp:inline>'
    '</w:drawing></w:r></w:p>';

/// `word/_rels/document.xml.rels` mapping each id to a target under `word/`;
/// ids in [external] are marked `TargetMode="External"`.
String wRels(Map<String, String> targets, {Set<String> external = const {}}) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${[
      for (final e in targets.entries)
        '<Relationship Id="${e.key}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
            'Target="${e.value}"'
            '${external.contains(e.key) ? ' TargetMode="External"' : ''}/>',
    ].join()}</Relationships>';

/// `word/styles.xml` declaring paragraph styles as (id, name, basedOn, outline).
String wStyles(
  List<({String id, String name, String? basedOn, int? outline})> styles,
) =>
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:styles xmlns:w="$wNs">${[
      for (final s in styles)
        '<w:style w:type="paragraph" w:styleId="${s.id}">'
            '<w:name w:val="${s.name}"/>'
            '${s.basedOn == null ? '' : '<w:basedOn w:val="${s.basedOn}"/>'}'
            '${s.outline == null ? '' : '<w:pPr><w:outlineLvl w:val="${s.outline}"/></w:pPr>'}'
            '</w:style>',
    ].join()}</w:styles>';

/// Styles as Word writes them in English: `Heading1`/`Heading2`/`Title`.
final String englishHeadingStyles = wStyles([
  (id: 'Normal', name: 'Normal', basedOn: null, outline: null),
  (id: 'Title', name: 'Title', basedOn: 'Normal', outline: null),
  (id: 'Heading1', name: 'heading 1', basedOn: 'Normal', outline: 0),
  (id: 'Heading2', name: 'heading 2', basedOn: 'Normal', outline: 1),
]);

/// A zipped DOCX package. [document] is the full `word/document.xml` and
/// [styles] the full `word/styles.xml`; either is left out of the package when
/// null. [extra] adds or replaces any other part by name; [media] adds binary
/// parts such as `word/media/image1.png`.
Uint8List minimalDocx({
  required String? document,
  String? styles,
  Map<String, String> extra = const {},
  Map<String, List<int>> media = const {},
}) {
  final parts = <String, String>{
    '[Content_Types].xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>',
    '_rels/.rels':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>',
    if (document != null) 'word/document.xml': document,
    if (styles != null) 'word/styles.xml': styles,
    ...extra,
  };
  final archive = Archive();
  parts.forEach((name, xml) =>
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(xml))));
  media.forEach((name, bytes) => archive.addFile(ArchiveFile.bytes(name, bytes)));
  return ZipEncoder().encodeBytes(archive);
}

/// Rewrites the uncompressed size a zip *declares* for [entry], in both the
/// local header and the central directory, without touching its data — so a
/// size-cap test needs no 50 MB fixture.
Uint8List withDeclaredSize(Uint8List zip, String entry, int size) {
  final out = Uint8List.fromList(zip);
  final view = ByteData.sublistView(out);
  final name = utf8.encode(entry);

  bool nameAt(int at) {
    if (at + name.length > out.length) return false;
    for (var i = 0; i < name.length; i++) {
      if (out[at + i] != name[i]) return false;
    }
    return true;
  }

  var patched = 0;
  for (var i = 0; i + 46 <= out.length; i++) {
    final sig = view.getUint32(i, Endian.little);
    if (sig == 0x04034b50 && nameAt(i + 30)) {
      view.setUint32(i + 22, size, Endian.little); // local file header
      patched++;
    } else if (sig == 0x02014b50 && nameAt(i + 46)) {
      view.setUint32(i + 24, size, Endian.little); // central directory
      patched++;
    }
  }
  if (patched != 2) throw StateError('expected 2 headers for $entry, got $patched');
  return out;
}

/// Writes [bytes] to a fresh temp file and returns its path.
Future<String> writeTempDocx(List<int> bytes, [String name = 'doc.docx']) async {
  final dir = await Directory.systemTemp.createTemp('docx_test');
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes);
  return f.path;
}

/// Overwrites the start of [entry]'s compressed data with `0xFF` bytes — an
/// invalid deflate block — leaving every header intact, so the zip opens but
/// reading that one entry throws.
Uint8List withCorruptData(Uint8List zip, String entry) {
  final out = Uint8List.fromList(zip);
  final view = ByteData.sublistView(out);
  final name = utf8.encode(entry);
  for (var i = 0; i + 30 <= out.length; i++) {
    if (view.getUint32(i, Endian.little) != 0x04034b50) continue;
    final nameLen = view.getUint16(i + 26, Endian.little);
    final extraLen = view.getUint16(i + 28, Endian.little);
    if (nameLen != name.length ||
        utf8.decode(out.sublist(i + 30, i + 30 + nameLen)) != entry) {
      continue;
    }
    final data = i + 30 + nameLen + extraLen;
    for (var j = 0; j < 4; j++) {
      out[data + j] = 0xFF;
    }
    return out;
  }
  throw StateError('no local header for $entry');
}
