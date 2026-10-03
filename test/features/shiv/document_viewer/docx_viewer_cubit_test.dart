import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/document_viewer/cubit/docx_viewer_cubit.dart';

import '../../../_helpers/fake_docx_text_source.dart';

/// Covers: DocxViewerCubit loading a Word file's sections, locating the cited
/// one, and failing cleanly on an unreadable, empty or throwing source.
void main() {
  late FakeDocxTextSource source;

  setUp(() => source = FakeDocxTextSource());

  blocTest<DocxViewerCubit, DocxViewerState>(
    'loads the sections and the index of the cited one',
    build: () {
      source.sections['/a.docx'] = [
        (label: 'Intro', text: 'Intro\n\nhello'),
        (label: 'Leave', text: 'Leave\n\nten days'),
      ];
      return DocxViewerCubit(source);
    },
    act: (c) => c.load('/a.docx', 'Leave', 'ten days'),
    expect: () => [
      isA<DocxViewerLoaded>()
          .having((s) => s.target, 'target', 1)
          .having((s) => s.sections, 'sections', hasLength(2)),
    ],
  );

  blocTest<DocxViewerCubit, DocxViewerState>(
    'a heading that cannot be placed still loads, with no target',
    build: () {
      source.sections['/a.docx'] = [(label: 'Intro', text: 'hello')];
      return DocxViewerCubit(source);
    },
    act: (c) => c.load('/a.docx', 'Gone', 'x'),
    expect: () => [
      isA<DocxViewerLoaded>().having((s) => s.target, 'target', isNull),
    ],
  );

  blocTest<DocxViewerCubit, DocxViewerState>(
    'an unreadable file fails',
    build: () => DocxViewerCubit(source),
    act: (c) => c.load('/missing.docx', 'x', 'x'),
    expect: () => [isA<DocxViewerFailed>()],
  );

  blocTest<DocxViewerCubit, DocxViewerState>(
    'a document with no sections fails',
    build: () {
      source.sections['/a.docx'] = [];
      return DocxViewerCubit(source);
    },
    act: (c) => c.load('/a.docx', 'x', 'x'),
    expect: () => [isA<DocxViewerFailed>()],
  );

  blocTest<DocxViewerCubit, DocxViewerState>(
    'a source that throws fails, never an exception',
    build: () {
      source.throwOnRead = StateError('boom');
      return DocxViewerCubit(source);
    },
    act: (c) => c.load('/a.docx', 'x', 'x'),
    expect: () => [isA<DocxViewerFailed>()],
  );

  test(
    'pictures are extracted into a folder that is removed on close',
    () async {
      source.sections['/a.docx'] = [(label: 'x', text: 'x')];
      final cubit = DocxViewerCubit(source);

      await cubit.load('/a.docx', 'x', 'x');
      final dir = Directory(source.imageDir!);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'pictures need somewhere to live',
      );

      await cubit.close();

      expect(dir.existsSync(), isFalse);
    },
  );
}
