import 'package:uniun/data/datasources/docx/docx_text_source.dart';

/// Index of the section a cited chunk came from, or `null` when none matches.
///
/// A chunk's label is the heading text, and headings repeat ("Scope" in two
/// chapters), so among sections with that label the one that contains the
/// start of the cited passage wins; failing that, the first with the label.
/// An empty label means the passage sat above the first heading.
int? locateSection(List<DocxSection> sections, String label, String snippet) {
  final matches = [
    for (var i = 0; i < sections.length; i++)
      if (sections[i].label == label) i,
  ];
  if (matches.isEmpty) return null;
  final probe = _squash(snippet);
  final head = probe.length > 40 ? probe.substring(0, 40) : probe;
  if (head.isNotEmpty) {
    for (final i in matches) {
      if (_squash(sections[i].text).contains(head)) return i;
    }
  }
  return matches.first;
}

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
