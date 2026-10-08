/// Wakes whatever embeds the notes waiting in the pending-embeddings queue.
abstract class NoteEmbeddingTrigger {
  void nudge();
}
