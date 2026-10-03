import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/features/shiv/document_viewer/utils/section_locator.dart';

sealed class DocxViewerState {
  const DocxViewerState();
}

final class DocxViewerLoading extends DocxViewerState {
  const DocxViewerLoading();
}

/// [target] is the index of the cited section in [sections], or `null` when it
/// could not be placed (the view then opens at the top).
final class DocxViewerLoaded extends DocxViewerState {
  const DocxViewerLoaded(this.sections, this.target);

  final List<DocxSection> sections;
  final int? target;
}

final class DocxViewerFailed extends DocxViewerState {
  const DocxViewerFailed();
}

/// Reads a cited Word file's sections and finds the cited one.
class DocxViewerCubit extends Cubit<DocxViewerState> {
  DocxViewerCubit(this._source) : super(const DocxViewerLoading());

  final DocxTextSource _source;

  /// Holds the pictures pulled out of the file, for as long as the view is open.
  Directory? _pictures;

  Future<void> load(String path, String label, String snippet) async {
    try {
      _pictures = await Directory.systemTemp.createTemp('uniun_docx_view_');
      final sections = await _source.sectionsText(
        path,
        imageDir: _pictures!.path,
      );
      if (sections == null || sections.isEmpty) {
        emit(const DocxViewerFailed());
        return;
      }
      emit(DocxViewerLoaded(sections, locateSection(sections, label, snippet)));
    } catch (_) {
      emit(const DocxViewerFailed());
    }
  }

  @override
  Future<void> close() async {
    try {
      await _pictures?.delete(recursive: true);
    } catch (_) {}
    return super.close();
  }
}
