import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:injectable/injectable.dart';

/// Labels below this are too often wrong to put in front of Shiv.
const double kMinLabelConfidence = 0.6;

/// Enough to say what a photo is of without listing every texture in it.
const int kMaxImageLabels = 6;

/// Seam over on-device image labeling, so callers can be tested without ML
/// Kit — which runs only on Android and iOS, never under `flutter test`.
abstract class ImageLabelSource {
  /// What is in the image at [path] (e.g. `Dog`, `Beach`), most confident
  /// first; `[]` when nothing clears [kMinLabelConfidence], `null` when the
  /// file cannot be read. Never throws.
  Future<List<String>?> imageLabels(String path);
}

/// ML Kit's bundled base labeler — 400+ general categories, fully on device.
///
/// The labeler loads its model once and lives as long as the app.
@LazySingleton(as: ImageLabelSource)
class MlKitImageLabelSource implements ImageLabelSource {
  late final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: kMinLabelConfidence),
  );

  @override
  Future<List<String>?> imageLabels(String path) async {
    try {
      final labels =
          await _labeler.processImage(InputImage.fromFilePath(path));
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      return [for (final l in labels.take(kMaxImageLabels)) l.label];
    } catch (_) {
      return null;
    }
  }
}
