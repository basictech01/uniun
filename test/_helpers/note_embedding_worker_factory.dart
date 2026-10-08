import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/domain/repositories/pending_embedding_repository.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/indexing/note_embedding_worker.dart';

/// A [NoteEmbeddingWorker] wired to the given repositories through the real
/// use cases, so tests keep faking the repositories.
NoteEmbeddingWorker aNoteEmbeddingWorker({
  required PendingEmbeddingRepository pending,
  required EmbeddingService embedding,
  required VectorRepository vector,
  required ExtractKnowledgeUseCase extract,
  required InferenceScheduler scheduler,
}) => NoteEmbeddingWorker(
  NextPendingEmbeddingUseCase(pending),
  RecordEmbeddingFailureUseCase(pending),
  RemovePendingEmbeddingUseCase(pending),
  embedding,
  StoreNoteVectorUseCase(vector),
  extract,
  scheduler,
);
