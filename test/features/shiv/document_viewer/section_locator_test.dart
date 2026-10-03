import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/document_viewer/utils/section_locator.dart';

/// Covers: locateSection placing a cited chunk in its Word section by heading,
/// repeated headings, whitespace differences, passages above the first
/// heading, and no match.
void main() {
  const sections = [
    (label: '', text: 'Preamble text above any heading.'),
    (label: 'Scope', text: 'Scope\n\nThis policy covers staff in Dehradun.'),
    (label: 'Leave', text: 'Leave\n\nTen days may be carried forward.'),
    (label: 'Scope', text: 'Scope\n\nThis annex covers contractors only.'),
  ];

  test('a unique heading finds its section', () {
    expect(locateSection(sections, 'Leave', 'Ten days may be carried'), 2);
  });

  test('a repeated heading is told apart by the cited passage', () {
    expect(
      locateSection(sections, 'Scope', 'This annex covers contractors'),
      3,
    );
    expect(locateSection(sections, 'Scope', 'This policy covers staff'), 1);
  });

  test('a repeated heading with an unfindable passage takes the first', () {
    expect(locateSection(sections, 'Scope', 'something else entirely'), 1);
  });

  test('whitespace and line breaks in the passage do not matter', () {
    expect(
      locateSection(sections, 'Scope', 'This   annex\ncovers   contractors'),
      3,
    );
  });

  test('a passage above the first heading is the unlabelled section', () {
    expect(locateSection(sections, '', 'Preamble text'), 0);
  });

  test('a heading that is not in the file finds nothing', () {
    expect(locateSection(sections, 'Travel', 'x'), isNull);
  });

  test('an empty snippet falls back to the first section with the label', () {
    expect(locateSection(sections, 'Scope', ''), 1);
  });

  test('no sections finds nothing', () {
    expect(locateSection(const [], 'Scope', 'x'), isNull);
  });

  test('Devanagari headings match exactly', () {
    const hi = [(label: 'अवकाश', text: 'अवकाश\n\nदस दिन आगे ले जा सकते हैं।')];
    expect(locateSection(hi, 'अवकाश', 'दस दिन आगे'), 0);
  });
}
