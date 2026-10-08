import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/domain/repositories/followed_note_repository.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';

class _MockFollowedNoteRepository extends Mock
    implements FollowedNoteRepository {}

FollowedNoteEntity _aFollowedNote() => FollowedNoteEntity(
  eventId: 'n1',
  contentPreview: 'preview',
  followedAt: DateTime(2026, 1, 1),
  newReferenceCount: 0,
);

void main() {
  late _MockFollowedNoteRepository repo;

  setUp(() {
    repo = _MockFollowedNoteRepository();
  });

  test('GetAllFollowedNotesUseCase delegates to getAll', () async {
    when(
      () => repo.getAll(),
    ).thenAnswer((_) async => Right([_aFollowedNote()]));

    final result = await GetAllFollowedNotesUseCase(repo).call();

    expect(result.getOrElse(() => []), hasLength(1));
  });

  test('FollowNoteUseCase forwards eventId + contentPreview', () async {
    when(
      () => repo.followNote('n1', 'preview'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await FollowNoteUseCase(
      repo,
    ).call(const FollowNoteInput(eventId: 'n1', contentPreview: 'preview'));

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repo.followNote('n1', 'preview')).called(1);
  });

  test('UnfollowNoteUseCase delegates to unfollowNote', () async {
    when(
      () => repo.unfollowNote('n1'),
    ).thenAnswer((_) async => const Right(unit));

    final result = await UnfollowNoteUseCase(repo).call('n1');

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('WatchIsFollowedUseCase forwards to watchIsFollowed', () {
    when(
      () => repo.watchIsFollowed('n1'),
    ).thenAnswer((_) => Stream.value(true));

    final stream = WatchIsFollowedUseCase(repo).call('n1');

    expect(stream, isA<Stream<bool>>());
    verify(() => repo.watchIsFollowed('n1')).called(1);
  });

  test(
    'WatchThreadUnreadMarkersUseCase streams the repository markers',
    () async {
      const marker = ThreadUnreadMarker(unread: true, unreadInside: false);
      when(
        () => repo.watchThreadUnreadMarkers(['n1']),
      ).thenAnswer((_) => Stream.value({'n1': marker}));

      final out = await WatchThreadUnreadMarkersUseCase(
        repo,
      ).call(['n1']).first;

      expect(out, {'n1': marker});
    },
  );
}
