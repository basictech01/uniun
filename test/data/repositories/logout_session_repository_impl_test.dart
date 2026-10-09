import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/feed_read_state_store.dart';
import 'package:uniun/data/datasources/llm/llm_credentials_data_source.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/data/datasources/media_cache_data_source.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/repositories/logout_session_repository_impl.dart';
import 'package:uniun/data/repositories/user_repository_impl.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/services/marmot_mls_service.dart';
import 'package:uniun/features/settings/services/logout_runtime_impl.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';

import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

class _Models extends Mock implements AIModelRepository {}

class _Uniun extends Mock implements UniunRepository {}

class _Vectors extends Mock implements NoteVectorStore {}

class _Mls extends Mock implements MarmotMlsService {}

class _Marmot extends Mock implements MarmotTransportService {}

class _Mesh extends Mock implements MeshService {}

class _Gana extends Mock implements GanaEngine {}

class _Indexer extends Mock implements DocumentIndexer {}

class _Embeddings extends Mock implements NoteEmbeddingTrigger {}

class _Media extends Mock implements MediaCacheDataSource {}

class _LlmRepository extends Mock implements LlmRepository {}

/// Logout clears the shared database and account credentials while honoring
/// the downloaded-model choice.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late SharedPreferences prefs;
  late _Models models;
  late _Uniun uniun;
  late _Vectors vectors;
  late LlmCredentialsDataSource credentials;
  late LogoutSessionRepositoryImpl cleanup;

  setUp(() async {
    isar = await openTestIsar();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    models = _Models();
    uniun = _Uniun();
    credentials = LlmCredentialsDataSource();
    vectors = _Vectors();
    final mls = _Mls();
    final mesh = _Mesh();
    final gana = _Gana();
    final indexer = _Indexer();
    final embeddings = _Embeddings();
    final media = _Media();
    final marmot = _Marmot();
    final llm = _LlmRepository();

    when(
      () => uniun.disconnect(confirm: true),
    ).thenAnswer((_) async => const Right(unit));
    when(() => vectors.clear()).thenAnswer((_) async {});
    when(() => mls.resetForLogout()).thenAnswer((_) async {});
    when(() => mesh.stop()).thenAnswer((_) async {});
    when(() => gana.stop()).thenAnswer((_) async {});
    when(() => indexer.dispose()).thenAnswer((_) async {});
    when(() => embeddings.stop()).thenAnswer((_) async {});
    when(() => media.clear()).thenAnswer((_) async {});
    when(() => marmot.stop()).thenAnswer((_) async {});
    when(
      () => llm.preemptBackgroundWork(),
    ).thenAnswer((_) async => const Right(unit));

    cleanup = LogoutSessionRepositoryImpl(
      isar,
      models,
      uniun,
      credentials,
      LlmPreferencesDataSource(prefs),
      AppSettingsStore(prefs),
      UserServerListStore(prefs),
      FeedReadStateStore(prefs),
      SurroundingReadStateStore(prefs),
      media,
      vectors,
      mls,
      LogoutRuntimeImpl(
        marmot,
        mesh,
        gana,
        indexer,
        embeddings,
        PreemptBackgroundWorkUseCase(llm),
      ),
    );

    await isar.writeTxn(() async {
      await isar.noteModels.put(noteRow('a-note'));
      await isar.noteModels.put(noteRow('a-dm', kind: 14));
      await isar.dmConversationModels.put(dmConversationRow('a-peer'));
      await isar.shivConversationModels.put(shivConversationRow('a-chat'));
    });
    await credentials.setUniunApiKey('old-key');
    await credentials.setUniunKeyId('old-id');
    await AppSettingsStore(prefs).setActiveModelId(AIModelId.gemma4E2b);
    await LlmPreferencesDataSource(prefs).setActiveCloudModelId('old-cloud');
    await UserServerListStore(prefs).setServers(['https://old.example']);
    await FeedReadStateStore(prefs).setLoadedAt(DateTime(2026));
    await SurroundingReadStateStore(prefs).advanceTo(DateTime(2026));
  });

  tearDown(() async => isar.close(deleteFromDisk: true));

  test('keeps model files but removes Account A data and sessions', () async {
    expect((await cleanup.clear(keepModelFiles: true)).isRight(), isTrue);

    expect(await isar.noteModels.count(), 0);
    expect(await isar.dmConversationModels.count(), 0);
    expect(await isar.shivConversationModels.count(), 0);
    expect(await credentials.getUniunApiKey(), isNull);
    expect(await credentials.getUniunKeyId(), isNull);
    expect(AppSettingsStore(prefs).activeModelId, isNull);
    expect(LlmPreferencesDataSource(prefs).activeCloudModelId, isNull);
    expect(UserServerListStore(prefs).servers, isEmpty);
    expect(FeedReadStateStore(prefs).loadedAt, isNull);
    expect(
      SurroundingReadStateStore(
        prefs,
      ).lastReadReceivedAt.millisecondsSinceEpoch,
      0,
    );
    verifyNever(() => models.getDownloadedModelIds());
  });

  test('removes downloaded models when checkbox is off', () async {
    when(
      () => models.getDownloadedModelIds(),
    ).thenAnswer((_) async => {AIModelId.gemma4E2b});
    when(
      () => models.deleteModel(AIModelId.gemma4E2b),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => models.cleanupOrphanedModelFiles(),
    ).thenAnswer((_) async => const Right(0));

    expect((await cleanup.clear(keepModelFiles: false)).isRight(), isTrue);

    verify(() => models.deleteModel(AIModelId.gemma4E2b)).called(1);
    expect(await isar.noteModels.count(), 0);
  });

  test('model deletion failure keeps the login and account database', () async {
    final users = UserRepositoryImpl(UserKeyStore(prefs));
    final account = (await users.generateKey()).getOrElse(() => throw 'key');
    when(
      () => models.getDownloadedModelIds(),
    ).thenAnswer((_) async => {AIModelId.gemma4E2b});
    when(
      () => models.deleteModel(AIModelId.gemma4E2b),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('disk error')));

    final result = await LogoutUseCase(
      users,
      cleanup,
    ).call(const LogoutParams());

    expect(result.isLeft(), isTrue);
    expect(
      (await users.getActiveUser()).getOrElse(() => throw 'key').pubkeyHex,
      account.pubkeyHex,
    );
    expect(await isar.noteModels.count(), 2);
  });

  test(
    'partial model download cleanup failure keeps the login and data',
    () async {
      final users = UserRepositoryImpl(UserKeyStore(prefs));
      final account = (await users.generateKey()).getOrElse(() => throw 'key');
      when(() => models.getDownloadedModelIds()).thenAnswer((_) async => {});
      when(() => models.cleanupOrphanedModelFiles()).thenAnswer(
        (_) async => const Left(Failure.errorFailure('partial file locked')),
      );

      final result = await LogoutUseCase(
        users,
        cleanup,
      ).call(const LogoutParams());

      expect(result.isLeft(), isTrue);
      expect(
        (await users.getActiveUser()).getOrElse(() => throw 'key').pubkeyHex,
        account.pubkeyHex,
      );
      expect(await isar.noteModels.count(), 2);
    },
  );

  test('vector cleanup failure keeps the login and account database', () async {
    final users = UserRepositoryImpl(UserKeyStore(prefs));
    final account = (await users.generateKey()).getOrElse(() => throw 'key');
    when(() => vectors.clear()).thenThrow(StateError('vector disk error'));
    final result = await LogoutUseCase(
      users,
      cleanup,
    ).call(const LogoutParams(keepModelFiles: true));

    expect(result.isLeft(), isTrue);
    expect(
      (await users.getActiveUser()).getOrElse(() => throw 'key').pubkeyHex,
      account.pubkeyHex,
    );
    expect(await isar.noteModels.count(), 2);
  });

  test(
    'remote disconnect failure still removes local cloud credentials',
    () async {
      when(
        () => uniun.disconnect(confirm: true),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('offline')));

      expect((await cleanup.clear(keepModelFiles: true)).isRight(), isTrue);

      expect(await credentials.getUniunApiKey(), isNull);
      expect(await credentials.getUniunKeyId(), isNull);
      expect(await isar.noteModels.count(), 0);
    },
  );
}
