import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

part 'brahma_create_event.dart';
part 'brahma_create_state.dart';

@injectable
class BrahmaCreateBloc extends Bloc<BrahmaCreateEvent, BrahmaCreateState> {
  final GetActiveUserKeysUseCase _getActiveUserKeys;
  final PublishNoteUseCase _publishUseCase;

  BrahmaCreateBloc(this._getActiveUserKeys, this._publishUseCase)
      : super(const BrahmaCreateState()) {
    on<SubmitNoteEvent>(_onSubmitNote, transformer: droppable());
    on<ResetBrahmaEvent>(_onReset);
  }

  Future<void> _onSubmitNote(
    SubmitNoteEvent event,
    Emitter<BrahmaCreateState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) return;
    emit(state.copyWith(status: BrahmaCreateStatus.submitting));

    // 1. Get signing keys
    final keysResult = await _getActiveUserKeys.call();
    if (keysResult.isLeft()) {
      emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: keysResult.fold((f) => f.toMessage(), (_) => ''),
      ));
      return;
    }
    final keys = keysResult.getOrElse(() => throw StateError('unreachable'));
    final privkeyHex = keys.privkeyHex;
    final pubkeyHex = keys.pubkeyHex;

    // 2. Build NIP-10 tags + hashtags
    final extractedTags = _extractHashtags(content);
    final tags = <List<String>>[];
    if (event.rootEventId != null) {
      tags.add(['e', event.rootEventId!, '', 'root']);
    }
    if (event.replyToEventId != null) {
      tags.add(['e', event.replyToEventId!, '', 'reply']);
    }
    for (final h in extractedTags) {
      tags.add(['t', h]);
    }

    // 3. Sign with nostr_core_dart
    late final Event signedEvent;
    try {
      signedEvent = Event.from(
        kind: 1, // Kind 1 = Short Text Note (NIP-01)
        tags: tags,
        content: content,
        privkey: privkeyHex,
      );
    } catch (e) {
      emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: 'Signing failed: $e',
      ));
      return;
    }

    // 4. Build NoteEntity
    final eTagRefs = [
      if (event.rootEventId != null) event.rootEventId!,
      if (event.replyToEventId != null) event.replyToEventId!,
    ];

    final note = NoteEntity(
      id: signedEvent.id,
      sig: signedEvent.sig,
      authorPubkey: pubkeyHex,
      content: signedEvent.content,
      type: NoteType.text,
      eTagRefs: eTagRefs,
      pTagRefs: const [],
      tTags: extractedTags,
      created: DateTime.fromMillisecondsSinceEpoch(signedEvent.createdAt * 1000),
      isSeen: true,
      rootEventId: event.rootEventId,
      replyToEventId: event.replyToEventId,
    );

    // 5. Publish: save locally + enqueue for relay
    final result = await _publishUseCase.call(note);
    result.fold(
      (f) => emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: f.toMessage(),
      )),
      (_) => emit(state.copyWith(status: BrahmaCreateStatus.success)),
    );
  }

  void _onReset(ResetBrahmaEvent event, Emitter<BrahmaCreateState> emit) {
    emit(const BrahmaCreateState());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _extractHashtags(String content) {
    final matches = RegExp(r'#(\w+)').allMatches(content);
    return matches
        .map((m) => m.group(1)!)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }
}
