import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';

/// Whether the active AI model can take an image with a chat message — what
/// decides if Shiv's input offers the attach button at all.
///
/// Unknown (no model chosen, or the lookup failed) counts as no: a button that
/// might fail is worse than one that is missing.
@injectable
class ChatImageSupportCubit extends Cubit<bool> {
  ChatImageSupportCubit(this._activeModel) : super(false);

  final GetActiveLlmModelUseCase _activeModel;

  /// Re-reads the active model. Call it when the model may have changed.
  Future<void> refresh() async {
    final result = await _activeModel.call();
    if (isClosed) return;
    emit(result.fold((_) => false, (model) => model?.supportsImages ?? false));
  }
}
