import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';

/// Covers: the rule choosing the Devanagari recogniser's result over the
/// Latin one. ML Kit itself runs only on a device — see integration_test/.
void main() {
  test('a Hindi notice is read with the Devanagari recogniser', () {
    expect(isMostlyDevanagari('कार्यालय आदेश। सभी कर्मचारियों के लिए'), isTrue);
  });

  test('a mixed Hindi and English notice counts as Devanagari', () {
    expect(
      isMostlyDevanagari('सूचना / NOTICE\nआवेदन शुल्क 50 रुपये\n'
          'Applications are accepted only on the online portal.'),
      isTrue,
    );
  });

  test('plain English is not', () {
    expect(isMostlyDevanagari('OFFICE ORDER leave rules 2026'), isFalse);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  test('one stray Devanagari glyph on an English page does not flip it', () {
    expect(
      isMostlyDevanagari('Audit review meeting is moved to Friday at 3:00 PM '
          'in Room 204 — please bring the Q3 folder क'),
      isFalse,
    );
  });

  test('a single Hindi word in a long English page does not flip it', () {
    expect(
      isMostlyDevanagari('${'The district record room opens at nine. ' * 6}'
          'धन्यवाद'),
      isFalse,
    );
  });

  test('fewer than three Devanagari letters never counts', () {
    expect(isMostlyDevanagari('कि'), isFalse);
  });

  test('empty text and digits only are not Devanagari', () {
    expect(isMostlyDevanagari(''), isFalse);
    expect(isMostlyDevanagari('1800 425 7788'), isFalse);
  });

  test('Devanagari digits alone are not enough letters', () {
    expect(isMostlyDevanagari('१२'), isFalse);
  });
}
