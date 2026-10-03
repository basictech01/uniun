import 'package:uniun/data/datasources/image_labels/image_label_source.dart';

/// Deterministic [ImageLabelSource]: returns preset labels per path, counts
/// reads. A missing key is an image with nothing recognisable (`[]`); a
/// `null` value is an unreadable file.
class FakeImageLabelSource implements ImageLabelSource {
  final Map<String, List<String>?> labels = {};
  int calls = 0;

  @override
  Future<List<String>?> imageLabels(String path) async {
    calls++;
    return labels.containsKey(path) ? labels[path] : const [];
  }
}
