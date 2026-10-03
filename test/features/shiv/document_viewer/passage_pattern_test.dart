import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/document_viewer/utils/passage_pattern.dart';

/// Covers: passagePattern matching the start of a cited passage across line
/// breaks, case, regex characters, long passages, Devanagari, and empty input.
void main() {
  test('matches the passage across a changed line break', () {
    final p = passagePattern('network access to a shared \npool of resources')!;

    expect(p.hasMatch('network access to a shared pool of resources'), isTrue);
    expect(
      p.hasMatch('network   access to a\nshared   pool of resources'),
      isTrue,
    );
  });

  test('is case-insensitive', () {
    expect(
      passagePattern('Cloud Computing')!.hasMatch('cloud computing'),
      isTrue,
    );
  });

  test('regex characters in the passage are matched literally', () {
    final p = passagePattern('fee (Rs. 150) + tax [net]?')!;

    expect(p.hasMatch('fee (Rs. 150) + tax [net]?'), isTrue);
    expect(p.hasMatch('fee Rs 150 tax net'), isFalse);
  });

  test('only the first words are searched', () {
    final words = [for (var i = 0; i < 50; i++) 'w$i'];
    final p = passagePattern(words.join(' '))!;

    expect(p.hasMatch(words.take(kHighlightWords).join(' ')), isTrue);
    expect(p.pattern.contains('w${kHighlightWords + 1}'), isFalse);
  });

  test('a different passage does not match', () {
    expect(
      passagePattern('annual leave rules')!.hasMatch('travel rules'),
      isFalse,
    );
  });

  test('Devanagari words match', () {
    final p = passagePattern('निरीक्षण शुल्क प्रति खसरा')!;

    expect(p.hasMatch('निरीक्षण  शुल्क\nप्रति खसरा 20 रुपये'), isTrue);
  });

  test('empty or blank input has no pattern', () {
    expect(passagePattern(''), isNull);
    expect(passagePattern('  \n\t '), isNull);
  });
}
