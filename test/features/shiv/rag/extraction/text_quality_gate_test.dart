import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/rag/extraction/text_quality_gate.dart';

/// Covers: looksLikeProse length and letter-ratio thresholds at/below/above,
/// mojibake and emoji rejection, Devanagari and RTL acceptance.
void main() {
  const prose = 'The quarterly leave policy has been revised. ';

  group('thresholds', () {
    test('ordinary prose passes', () {
      expect(looksLikeProse(prose * 6), isTrue);
    });

    test('exactly 200 characters passes; 199 fails', () {
      expect(looksLikeProse('a' * 200), isTrue);
      expect(looksLikeProse('a' * 199), isFalse);
    });

    test('exactly 15% letters passes; just under fails', () {
      expect(looksLikeProse('${'a' * 30}${'.' * 170}'), isTrue);
      expect(looksLikeProse('${'a' * 29}${'.' * 171}'), isFalse);
    });

    test('surrounding whitespace does not count toward length', () {
      expect(looksLikeProse('   ${'a' * 199}   '), isFalse);
    });
  });

  group('rejects what is not prose', () {
    test('a broken font encoding (mojibake) fails on letter ratio', () {
      expect(looksLikeProse('!" #\$%\$ &\'()' * 40), isFalse);
    });

    test('empty and whitespace-only input fail', () {
      expect(looksLikeProse(''), isFalse);
      expect(looksLikeProse('   \t\n  '), isFalse);
    });

    test('digits and punctuation alone fail', () {
      expect(looksLikeProse('1234567890 .,;:!? ' * 20), isFalse);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('unicode scripts count as letters', () {
    test('Devanagari passes', () {
      const hindi =
          'भारत सरकार के कर्मचारियों के लिए अवकाश नीति में संशोधन किया गया है। ';
      expect(looksLikeProse(hindi * 5), isTrue);
    });

    test('RTL passes', () {
      expect(looksLikeProse('مرحبا بالعالم هذه سياسة الإجازات المعدلة ' * 6),
          isTrue);
    });

    test('CJK passes', () {
      expect(looksLikeProse('这是一份关于云计算定义的政府文件。' * 20), isTrue);
    });

    test('emoji are not letters', () {
      expect(looksLikeProse('😀' * 300), isFalse);
    });
  });

  group('custom minimum length', () {
    test('a lower minimum admits short genuine text', () {
      expect(looksLikeProse('PLATFORM 3 → DELHI 14:20', minChars: 16), isTrue);
      expect(looksLikeProse('PLATFORM 3 → DELHI 14:20'), isFalse,
          reason: 'the default stays the PDF-calibrated 200');
    });

    test('the letter ratio still applies at a lower minimum', () {
      expect(looksLikeProse('|| ;; 1 / . - = ~ 42', minChars: 16), isFalse);
    });

    test('exactly at the minimum passes; one below fails', () {
      expect(looksLikeProse('a' * 16, minChars: 16), isTrue);
      expect(looksLikeProse('a' * 15, minChars: 16), isFalse);
    });
  });
}
