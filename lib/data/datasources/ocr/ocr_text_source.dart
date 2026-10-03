import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

/// Seam over on-device OCR, so callers can be tested without ML Kit — which
/// runs only on Android and iOS, never under `flutter test`.
abstract class OcrTextSource {
  /// The text read in the image at [path], one recognised block per paragraph
  /// (`''` when there is none), or `null` when the file cannot be read as an
  /// image.
  Future<String?> imageText(String path);
}

/// Reads text with ML Kit's bundled Latin and Devanagari recognisers.
///
/// Both run on every image. Google does not document whether the Devanagari
/// model also reads Latin script; on a device it does (a mixed notice keeps
/// both languages), but English-only pages still take the dedicated Latin
/// result — its result is used only when it found a real share of Devanagari. Each pass stands
/// alone, so a failing Devanagari recogniser still leaves English readable.
///
/// The recognisers load their models once and live as long as the app — this
/// is a singleton, and re-creating them per image doubled the cost of a
/// backlog.
@LazySingleton(as: OcrTextSource)
class MlKitOcrTextSource implements OcrTextSource {
  late final TextRecognizer _latin =
      TextRecognizer(script: TextRecognitionScript.latin);
  late final TextRecognizer _devanagari =
      TextRecognizer(script: TextRecognitionScript.devanagiri);

  @override
  Future<String?> imageText(String path) async {
    final InputImage image;
    try {
      image = InputImage.fromFilePath(path);
    } catch (_) {
      return null;
    }
    final english = await _read(_latin, image);
    final hindi = await _read(_devanagari, image);
    final best = hindi != null && isMostlyDevanagari(hindi.text)
        ? hindi
        : english ?? hindi;
    if (best == null) return null;
    return best.blocks
        .map((b) => b.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n\n');
  }

  static Future<RecognizedText?> _read(
    TextRecognizer recognizer,
    InputImage image,
  ) async {
    try {
      return await recognizer.processImage(image);
    } catch (_) {
      return null;
    }
  }
}

/// True when Devanagari is a real part of [text], not one misread glyph on an
/// English page: at least three Devanagari letters, and a tenth of all
/// letters.
@visibleForTesting
bool isMostlyDevanagari(String text) {
  final devanagari = _devanagariLetter.allMatches(text).length;
  final letters = _anyLetter.allMatches(text).length;
  return devanagari >= 3 && devanagari * 10 >= letters;
}

final RegExp _devanagariLetter = RegExp(r'[ऀ-ॿ]');
final RegExp _anyLetter = RegExp(r'\p{L}|\p{M}', unicode: true);
