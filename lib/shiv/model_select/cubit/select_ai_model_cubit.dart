import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';

part 'select_ai_model_state.dart';
part 'select_ai_model_cubit.freezed.dart';

@injectable
class SelectAIModelCubit extends Cubit<SelectAIModelState> {
  final GetAvailableAIModelsUseCase _getAvailable;
  final GetActiveAIModelUseCase _getActive;
  final DownloadAndActivateAIModelUseCase _download;

  StreamSubscription<AIModelDownloadEvent>? _downloadSub;

  SelectAIModelCubit(
    this._getAvailable,
    this._getActive,
    this._download,
  ) : super(const SelectAIModelState()) {
    _init();
  }

  Future<void> _init() async {
    final models = _getAvailable.call();
    final activeResult = await _getActive.call();
    final activeId = activeResult.fold((_) => null, (m) => m?.modelId);

    emit(state.copyWith(
      models: models,
      activeModelId: activeId,
      selectedModelId: activeId ??
          models.where((m) => m.isRecommended).firstOrNull?.modelId ??
          models.firstOrNull?.modelId,
    ));
  }

  Future<void> refresh() => _init();

  void selectModel(AIModelId modelId) {
    if (state.status == SelectAIModelStatus.downloading) return;
    emit(state.copyWith(selectedModelId: modelId));
  }

  Future<void> downloadAndActivate() async {
    final modelId = state.selectedModelId;
    if (modelId == null) return;
    if (state.status == SelectAIModelStatus.downloading) return;

    if (modelId == state.activeModelId) {
      emit(state.copyWith(status: SelectAIModelStatus.done));
      return;
    }

    emit(state.copyWith(
      status: SelectAIModelStatus.downloading,
      downloadProgress: 0.0,
      errorMessage: null,
    ));

    _downloadSub?.cancel();
    _downloadSub = _download.call(modelId).listen(
      (event) {
        event.when(
          progress: (value) =>
              emit(state.copyWith(downloadProgress: value)),
          complete: (id) => emit(state.copyWith(
            status: SelectAIModelStatus.done,
            activeModelId: id,
            downloadProgress: 1.0,
          )),
          failed: (msg) => emit(state.copyWith(
            status: SelectAIModelStatus.error,
            errorMessage: msg,
          )),
        );
      },
      onError: (e) => emit(state.copyWith(
        status: SelectAIModelStatus.error,
        errorMessage: e.toString(),
      )),
    );
  }

  @override
  Future<void> close() {
    _downloadSub?.cancel();
    return super.close();
  }
}
