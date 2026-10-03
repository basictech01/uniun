import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_resolver_repository.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/media_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';

import '../../_helpers/fixtures.dart';

class _MockSavedNoteRepository extends Mock implements SavedNoteRepository {}

class _MockNoteResolverRepository extends Mock
    implements NoteResolverRepository {}

class _MockDeleteKnowledge extends Mock
    implements DeleteKnowledgeForNoteUseCase {}

class _MockDownloadMedia extends Mock implements DownloadMediaUseCase {}

void main() {
  late _MockSavedNoteRepository repo;
  late _MockNoteResolverRepository resolver;
  late _MockDeleteKnowledge deleteKnowledge;
  late _MockDownloadMedia download;

  setUpAll(() {
    registerFallbackValue(aNote());
    registerFallbackValue(
        const DownloadMediaInput(sha256: '', url: '', mime: ''));
  });

  setUp(() {
    repo = _MockSavedNoteRepository();
    resolver = _MockNoteResolverRepository();
    deleteKnowledge = _MockDeleteKnowledge();
    download = _MockDownloadMedia();
    when(() => download.call(any()))
        .thenAnswer((_) async => Right(aMediaBlob()));
  });

  test('SaveNoteUseCase delegates to saveNote', () async {
    when(() => repo.saveNote(any())).thenAnswer((_) async => Right(aSavedNote()));

    final result = await SaveNoteUseCase(repo, download).call(aNote());

    expect(result.isRight(), isTrue);
    verify(() => repo.saveNote(any())).called(1);
  });

  group('SaveNoteUseCase fetches documents for Shiv', () {
    const docx = DocumentKind.docx;

    Future<void> save(NoteEntity note) async {
      await SaveNoteUseCase(repo, download).call(note);
      await Future<void>.delayed(Duration.zero);
    }

    setUp(() => when(() => repo.saveNote(any()))
        .thenAnswer((_) async => Right(aSavedNote())));

    test('an unopened PDF or DOCX on a saved note is downloaded', () async {
      await save(aNote(attachments: [
        aMediaBlob(sha256: 'p', mime: 'application/pdf',
            serverUrls: ['https://s/p', 'https://mirror/p']),
        aMediaBlob(sha256: 'w', mime: docx.mime, serverUrls: ['https://s/w']),
      ]));

      final inputs = verify(() => download.call(captureAny()))
          .captured
          .cast<DownloadMediaInput>();
      expect([for (final i in inputs) (i.sha256, i.url, i.mime)], [
        ('p', 'https://s/p', 'application/pdf'),
        ('w', 'https://s/w', docx.mime),
      ]);
    });

    test('a document already on the device is not downloaded again', () async {
      await save(aNote(attachments: [
        aMediaBlob(mime: 'application/pdf', localPath: '/cache/p.pdf'),
      ]));

      verifyNever(() => download.call(any()));
    });

    test('an unopened image is downloaded, for its text', () async {
      await save(aNote(attachments: [
        aMediaBlob(sha256: 'img', mime: 'image/png',
            serverUrls: ['https://s/img']),
      ]));

      final input = verify(() => download.call(captureAny()))
          .captured
          .single as DownloadMediaInput;
      expect((input.sha256, input.mime), ('img', 'image/png'));
    });

    test('videos, audio and other files are left alone', () async {
      await save(aNote(attachments: [
        aMediaBlob(mime: 'video/mp4'),
        aMediaBlob(mime: 'audio/ogg'),
        aMediaBlob(mime: 'application/msword'),
      ]));

      verifyNever(() => download.call(any()));
    });

    test('an attachment with no server to fetch from is skipped', () async {
      await save(aNote(attachments: [
        aMediaBlob(mime: 'application/pdf', serverUrls: const []),
      ]));

      verifyNever(() => download.call(any()));
    });

    test('nothing is downloaded when the save itself fails', () async {
      when(() => repo.saveNote(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('disk full')));

      await save(aNote(attachments: [aMediaBlob(mime: 'application/pdf')]));

      verifyNever(() => download.call(any()));
    });

    test('a failed download does not fail the save', () async {
      when(() => download.call(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('offline')));

      final result = await SaveNoteUseCase(repo, download)
          .call(aNote(attachments: [aMediaBlob(mime: 'application/pdf')]));

      expect(result.isRight(), isTrue);
    });
  });

  group('UnsaveNoteUseCase', () {
    test('unsaves then fires knowledge cleanup (fire-and-forget)', () async {
      when(() => repo.unsaveNote('n1')).thenAnswer((_) async => const Right(unit));
      when(() => deleteKnowledge.call('n1')).thenAnswer((_) async => const Right(unit));

      final result = await UnsaveNoteUseCase(repo, deleteKnowledge).call('n1');

      expect(result, const Right<Failure, Unit>(unit));
      await Future<void>.delayed(Duration.zero);
      verify(() => deleteKnowledge.call('n1')).called(1);
    });

    test('a repository failure still returns Left', () async {
      const failure = Failure.errorFailure('not found');
      when(() => repo.unsaveNote('n1')).thenAnswer((_) async => const Left(failure));
      when(() => deleteKnowledge.call(any())).thenAnswer((_) async => const Right(unit));

      final result = await UnsaveNoteUseCase(repo, deleteKnowledge).call('n1');

      expect(result, const Left<Failure, Unit>(failure));
    });
  });

  test('IsSavedNoteUseCase delegates to isSaved', () async {
    when(() => repo.isSaved('n1')).thenAnswer((_) async => const Right(true));

    final result = await IsSavedNoteUseCase(repo).call('n1');

    expect(result, const Right<Failure, bool>(true));
  });

  test('GetAllSavedNotesUseCase delegates to getAll', () async {
    when(() => repo.getAll()).thenAnswer((_) async => Right([aSavedNote()]));

    final result = await GetAllSavedNotesUseCase(repo).call();

    expect(result.getOrElse(() => []), hasLength(1));
  });

  test('GetSavedReplyCountUseCase delegates', () async {
    when(() => repo.getSavedReplyCount('n1')).thenAnswer((_) async => const Right(2));

    final result = await GetSavedReplyCountUseCase(repo).call('n1');

    expect(result, const Right<Failure, int>(2));
  });

  test('GetSavedRepliesUseCase delegates', () async {
    when(() => repo.getSavedReplies('parent')).thenAnswer((_) async => Right([aSavedNote()]));

    await GetSavedRepliesUseCase(repo).call('parent');

    verify(() => repo.getSavedReplies('parent')).called(1);
  });

  test('GetSavedReferencesUseCase delegates', () async {
    when(() => repo.getSavedReferences('child')).thenAnswer((_) async => Right([aSavedNote()]));

    await GetSavedReferencesUseCase(repo).call('child');

    verify(() => repo.getSavedReferences('child')).called(1);
  });

  group('ResolveNotesByIdsUseCase', () {
    test('returns empty right away for an empty id list without touching '
        'either repository', () async {
      final result = await ResolveNotesByIdsUseCase(resolver, repo).call([]);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => [aNote()]), isEmpty);
      verifyZeroInteractions(resolver);
      verifyZeroInteractions(repo);
    });

    test('resolves everything from the Note collection, preserving input '
        'order', () async {
      when(() => resolver.resolveMany(['b', 'a'])).thenAnswer(
          (_) async => Right([aNote(id: 'a'), aNote(id: 'b')]));

      final result = await ResolveNotesByIdsUseCase(resolver, repo).call(['b', 'a']);

      final ids = result.getOrElse(() => []).map((n) => n.id).toList();
      expect(ids, ['b', 'a']);
      verifyZeroInteractions(repo);
    });

    test('falls back to SavedNoteRepository for ids missing from the '
        'resolver', () async {
      when(() => resolver.resolveMany(['a', 'evicted']))
          .thenAnswer((_) async => Right([aNote(id: 'a')]));
      when(() => repo.getAll()).thenAnswer(
          (_) async => Right([aSavedNote(eventId: 'evicted')]));

      final result =
          await ResolveNotesByIdsUseCase(resolver, repo).call(['a', 'evicted']);

      final ids = result.getOrElse(() => []).map((n) => n.id).toList();
      expect(ids, ['a', 'evicted']);
    });

    test('drops ids that resolve nowhere, degrading to a partial list',
        () async {
      when(() => resolver.resolveMany(['a', 'gone']))
          .thenAnswer((_) async => Right([aNote(id: 'a')]));
      when(() => repo.getAll()).thenAnswer((_) async => const Right([]));

      final result =
          await ResolveNotesByIdsUseCase(resolver, repo).call(['a', 'gone']);

      final ids = result.getOrElse(() => []).map((n) => n.id).toList();
      expect(ids, ['a']);
    });

    test('a resolver failure degrades to treating everything as missing, '
        'not a Left', () async {
      when(() => resolver.resolveMany(['a']))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      when(() => repo.getAll()).thenAnswer((_) async => const Right([]));

      final result = await ResolveNotesByIdsUseCase(resolver, repo).call(['a']);

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => []), isEmpty);
    });
  });
}
