import 'dart:ffi' as ffi;
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart' as pdfium;
import 'package:pdfrx/pdfrx.dart' show Pdfrx;
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';

/// Reads every page's [PdfPageSignals] of an open document.
///
/// Must run on pdfrx's own PDFium worker, via
/// `PdfrxEntryFunctions.instance.compute`: PDFium is not thread-safe, and the
/// worker serialises these calls with pdfrx's. pdfrx exposes none of these
/// signals itself; they come straight from the PDFium bindings.
List<PdfPageSignals> analysePdfPages(({int document, int pageCount}) m) {
  // The worker already loaded PDFium from this path; tests point it at a
  // downloaded binary.
  final p = _pdfium ??= pdfium.getPdfium(modulePath: Pdfrx.pdfiumModulePath);
  final doc = pdfium.FPDF_DOCUMENT.fromAddress(m.document);
  return [for (var i = 0; i < m.pageCount; i++) _analysePage(p, doc, i)];
}

pdfium.PDFium? _pdfium;

PdfPageSignals _analysePage(
  pdfium.PDFium p,
  pdfium.FPDF_DOCUMENT doc,
  int index,
) {
  final page = p.FPDF_LoadPage(doc, index);
  final text = p.FPDFText_LoadPage(page);
  final arena = Arena();
  try {
    final width = p.FPDF_GetPageWidthF(page);
    final height = p.FPDF_GetPageHeightF(page);
    final pageArea = width * height;

    // ── Images ─────────────────────────────────────────────────────────────
    final l = arena<ffi.Float>();
    final b = arena<ffi.Float>();
    final r = arena<ffi.Float>();
    final t = arena<ffi.Float>();
    var covered = 0.0;
    PdfBox? largest;
    var largestArea = 0.0;
    for (var i = 0; i < p.FPDFPage_CountObjects(page); i++) {
      final obj = p.FPDFPage_GetObject(page, i);
      if (!_isImage(p, obj, 0)) continue;
      if (p.FPDFPageObj_GetBounds(obj, l, b, r, t) == 0) continue;
      final box = (
        left: math.max(0.0, l.value),
        bottom: math.max(0.0, b.value),
        right: math.min(width, r.value),
        top: math.min(height, t.value),
      );
      final area =
          math.max(0.0, box.right - box.left) *
          math.max(0.0, box.top - box.bottom);
      covered += area;
      if (area > largestArea) {
        largestArea = area;
        largest = box;
      }
    }

    // ── Text ───────────────────────────────────────────────────────────────
    var chars = 0;
    var letters = 0;
    var unmapped = 0;
    var invisible = 0;
    var inLargest = 0;
    var legacyFont = false;
    final legacyByFont = <int, bool>{};
    final cl = arena<ffi.Double>();
    final cr = arena<ffi.Double>();
    final cb = arena<ffi.Double>();
    final ct = arena<ffi.Double>();
    final nameBuffer = arena<ffi.Char>(_fontNameBytes);
    final count = text == ffi.nullptr ? 0 : p.FPDFText_CountChars(text);
    for (var c = 0; c < count; c++) {
      final code = p.FPDFText_GetUnicode(text, c);
      if (code <= 0x20 || code == 0xA0) continue;
      chars++;
      if (_letter.hasMatch(String.fromCharCode(code))) letters++;
      if (p.FPDFText_HasUnicodeMapError(text, c) == 1) unmapped++;

      final obj = p.FPDFText_GetTextObject(text, c);
      if (obj != ffi.nullptr) {
        final mode = p.FPDFTextObj_GetTextRenderMode(obj);
        if (mode == pdfium.FPDF_TEXT_RENDERMODE.FPDF_TEXTRENDERMODE_INVISIBLE ||
            mode == pdfium.FPDF_TEXT_RENDERMODE.FPDF_TEXTRENDERMODE_CLIP) {
          invisible++;
        }
        if (!legacyFont) {
          final font = p.FPDFTextObj_GetFont(obj);
          if (font != ffi.nullptr) {
            legacyFont = legacyByFont.putIfAbsent(
              font.address,
              () => isLegacyHindiFont(_fontName(p, font, nameBuffer)),
            );
          }
        }
      }

      final box = largest;
      if (box != null && p.FPDFText_GetCharBox(text, c, cl, cr, cb, ct) == 1) {
        final x = (cl.value + cr.value) / 2;
        final y = (cb.value + ct.value) / 2;
        if (x >= box.left &&
            x <= box.right &&
            y >= box.bottom &&
            y <= box.top) {
          inLargest++;
        }
      }
    }

    return PdfPageSignals(
      width: width,
      height: height,
      rotation: p.FPDFPage_GetRotation(page),
      chars: chars,
      letters: letters,
      unmapped: unmapped,
      invisible: invisible,
      legacyFont: legacyFont,
      imageCoverage: pageArea <= 0 ? 0 : math.min(1.0, covered / pageArea),
      largestImage: largest,
      largestImageCoverage: pageArea <= 0 ? 0 : largestArea / pageArea,
      charsInLargestImage: inLargest,
    );
  } finally {
    if (text != ffi.nullptr) p.FPDFText_ClosePage(text);
    p.FPDF_ClosePage(page);
    arena.releaseAll();
  }
}

/// An image object, or a form XObject that draws one — PDF producers often
/// wrap a pasted picture in a form. Bounded: a malformed file can nest deeply.
bool _isImage(pdfium.PDFium p, pdfium.FPDF_PAGEOBJECT obj, int depth) {
  final type = p.FPDFPageObj_GetType(obj);
  if (type == pdfium.FPDF_PAGEOBJ_IMAGE) return true;
  if (type != pdfium.FPDF_PAGEOBJ_FORM || depth >= 3) return false;
  for (var i = 0; i < p.FPDFFormObj_CountObjects(obj); i++) {
    if (_isImage(p, p.FPDFFormObj_GetObject(obj, i), depth + 1)) return true;
  }
  return false;
}

const int _fontNameBytes = 256;

String _fontName(
  pdfium.PDFium p,
  pdfium.FPDF_FONT font,
  ffi.Pointer<ffi.Char> buffer,
) {
  final length = p.FPDFFont_GetBaseFontName(font, buffer, _fontNameBytes);
  if (length <= 0 || length > _fontNameBytes) return '';
  return buffer.cast<Utf8>().toDartString();
}

/// Pre-Unicode Hindi typing fonts. Text set in them extracts as Latin
/// gibberish that is mostly letters, so it slips past the letter-ratio gate;
/// the name is the only reliable tell. A subset prefix (`ABCDEF+KrutiDev010`)
/// still matches.
bool isLegacyHindiFont(String name) => _legacyFont.hasMatch(name);

final RegExp _legacyFont = RegExp(
  r'(^|[^a-z])(kruti|devlys|chanakya|shivaji|walkman|agra|shusha|kundli|akshar)',
  caseSensitive: false,
);

final RegExp _letter = RegExp(r'\p{L}|\p{M}', unicode: true);
