import 'package:injectable/injectable.dart';
import 'package:uniun/domain/services/logout_runtime.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart';
import 'package:uniun/features/shiv/gana/engine/gana_workmanager_bootstrap.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';
import 'package:uniun/gateway/gateway.dart';

/// Stops account-scoped workers before local storage is cleared.
@Injectable(as: LogoutRuntime)
class LogoutRuntimeImpl implements LogoutRuntime {
  LogoutRuntimeImpl(
    this._marmot,
    this._mesh,
    this._gana,
    this._indexer,
    this._noteEmbeddings,
    this._preempt,
  );

  final MarmotTransportService _marmot;
  final MeshService _mesh;
  final GanaEngine _gana;
  final DocumentIndexer _indexer;
  final NoteEmbeddingTrigger _noteEmbeddings;
  final PreemptBackgroundWorkUseCase _preempt;

  @override
  Future<void> stop() async {
    await GatewayBootstrap.stop();
    await ShivAIBloc.closeActiveSessionForLogout();
    await GanaWorkmanagerBootstrap.cancelBackground();
    await _preempt.call();
    await _gana.stop();
    await _mesh.stop();
    await _marmot.stop();
    await _indexer.dispose();
    await _noteEmbeddings.stop();
  }
}
