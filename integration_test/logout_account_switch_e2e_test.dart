import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/feed_read_state_store.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/llm_credentials_data_source.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/data/datasources/media_cache_data_source.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/group_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/private_group_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/data/repositories/ai_model_repository_impl.dart';
import 'package:uniun/data/repositories/logout_session_repository_impl.dart';
import 'package:uniun/data/repositories/user_repository_impl.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/services/marmot_mls_service.dart';
import 'package:uniun/domain/services/marmot_transport_service.dart';
import 'package:uniun/domain/services/note_embedding_trigger.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';
import 'package:uniun/features/settings/services/logout_runtime_impl.dart';
import 'package:uniun/features/settings/widgets/logout_button.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_input_composer.dart';
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';
import 'package:uniun/gateway/gateway.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/fake_path_provider.dart';
import '../test/_helpers/isar_seeds.dart';
import '../test/_helpers/isar_test_harness.dart';
import 'support/test_model.dart';

/// Exercises real on-device storage isolation across logout and new sign-in.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final keepModels in [true, false]) {
    testWidgets('Account switch (keep models: $keepModels)', (tester) async {
      final root = await Directory.systemTemp.createTemp('uniun_logout_');
      final isar = await Isar.open(
        isarSchemas,
        directory: root.path,
        name: 'logout_account_switch_${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        await runLogoutAccountSwitchScenario(
          isar,
          root,
          keepModelFiles: keepModels,
        );
      } finally {
        await isar.close(deleteFromDisk: true);
        await root.delete(recursive: true);
      }
    });
  }

  testWidgets('checked logout keeps the real downloaded model visible in '
      'Account B chat picker', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    expect(
      await provisionTestModel(AIModelId.gemma4E2b),
      isTrue,
      reason: 'Provide a Gemma 4 E2B model fixture before this test runs',
    );
    final modelDocuments = await getApplicationDocumentsDirectory();
    final modelFile = File('${modelDocuments.path}/gemma-4-E2B-it.litertlm');
    expect(await modelFile.exists(), isTrue);

    final root = await Directory.systemTemp.createTemp('uniun_logout_ui_');
    final originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProviderPlatform(
      docs: modelDocuments.path,
      support: root.path,
    );
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettingsStore(prefs);
    final users = UserRepositoryImpl(UserKeyStore(prefs));
    final accountA = (await users.generateKey()).getOrElse(
      () => throw StateError('Account A login failed'),
    );
    await settings.setActiveModelId(AIModelId.gemma4E2b);
    final isar = await Isar.open(
      isarSchemas,
      directory: root.path,
      name: 'logout_ui_${DateTime.now().microsecondsSinceEpoch}',
    );
    final vectors = await NoteVectorStore.open('${root.path}/vectors');
    final gateway = FlutterGemmaGatewayImpl();
    final models = AIModelRepositoryImpl(
      isar,
      settings,
      AIModelRunner(InferenceScheduler(), settings, gateway),
      gateway,
    );
    expect(await models.getDownloadedModelIds(), contains(AIModelId.gemma4E2b));

    final uniun = _Uniun();
    final mls = _Mls();
    final marmot = _Marmot();
    final mesh = _Mesh();
    final gana = _Gana();
    final indexer = _Indexer();
    final embeddings = _Embeddings();
    final llm = _Llm();
    when(
      () => uniun.disconnect(confirm: true),
    ).thenAnswer((_) async => const Right(unit));
    when(() => uniun.isConnected()).thenAnswer((_) async => false);
    when(() => mls.resetForLogout()).thenAnswer((_) async {});
    when(() => marmot.stop()).thenAnswer((_) async {});
    when(() => mesh.stop()).thenAnswer((_) async {});
    when(() => gana.stop()).thenAnswer((_) async {});
    when(() => indexer.dispose()).thenAnswer((_) async {});
    when(() => embeddings.stop()).thenAnswer((_) async {});
    when(
      () => llm.preemptBackgroundWork(),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => llm.getActiveBackend(),
    ).thenAnswer((_) async => const Right(LlmBackendType.localGemma));
    when(() => llm.getActiveModel()).thenAnswer((_) async => const Right(null));

    final logout = LogoutUseCase(
      users,
      LogoutSessionRepositoryImpl(
        isar,
        models,
        uniun,
        LlmCredentialsDataSource(),
        LlmPreferencesDataSource(prefs),
        settings,
        UserServerListStore(prefs),
        FeedReadStateStore(prefs),
        SurroundingReadStateStore(prefs),
        MediaCacheDataSource(),
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
      ),
    );
    await getIt.reset();
    getIt.registerSingleton<LogoutUseCase>(logout);
    getIt.registerSingleton<GetAvailableAIModelsUseCase>(
      GetAvailableAIModelsUseCase(models),
    );
    getIt.registerSingleton<GetDownloadedModelIdsUseCase>(
      GetDownloadedModelIdsUseCase(models),
    );
    getIt.registerSingleton<GetActiveAIModelUseCase>(
      GetActiveAIModelUseCase(models),
    );
    getIt.registerSingleton<GetActiveLlmBackendUseCase>(
      GetActiveLlmBackendUseCase(llm),
    );
    getIt.registerSingleton<GetActiveLlmModelUseCase>(
      GetActiveLlmModelUseCase(llm),
    );
    getIt.registerSingleton<IsUniunCloudConnectedUseCase>(
      IsUniunCloudConnectedUseCase(uniun),
    );

    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: LogoutButton()),
        ),
        GoRoute(
          name: AppRoutes.welcome,
          path: '/welcome',
          builder: (_, __) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final accountB = (await users.generateKey()).getOrElse(
                    () => throw StateError('Account B login failed'),
                  );
                  expect(accountB.pubkeyHex, isNot(accountA.pubkeyHex));
                  router.go('/chat');
                },
                child: const Text('Sign in as Account B'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/chat',
          builder: (_, __) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ShivInputComposer(
                onSend: (_, __, ___) {},
                onStop: () {},
                isStreaming: false,
              ),
            ),
          ),
        ),
      ],
    );

    try {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      );
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await tester.tap(
        find.text('Keep downloaded AI models for another login'),
      );
      await tester.pump();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      await tester.tap(find.text('Log out').last);
      await tester.pumpAndSettle();
      expect(find.text('Sign in as Account B'), findsOneWidget);
      expect(await modelFile.exists(), isTrue);
      expect(settings.activeModelId, isNull);

      await tester.tap(find.text('Sign in as Account B'));
      await tester.pumpAndSettle();
      expect(
        (await users.getActiveUser()).getOrElse(() => throw 'No B').pubkeyHex,
        isNot(accountA.pubkeyHex),
      );
      expect(
        await models.getDownloadedModelIds(),
        contains(AIModelId.gemma4E2b),
      );
      await tester.tap(find.byTooltip('Pick model'));
      await tester.pumpAndSettle();
      expect(
        find.text('Gemma 4 E2B'),
        findsOneWidget,
        reason: 'A retained model must appear in the new account chat picker',
      );

      final activation = await models
          .downloadAndActivateModel(AIModelId.gemma4E2b)
          .toList();
      expect(
        activation.length,
        1,
        reason: 'An installed model must activate without download progress',
      );
      expect(
        activation.single.maybeWhen(complete: (_) => true, orElse: () => false),
        isTrue,
      );
      expect(settings.activeModelId, AIModelId.gemma4E2b);
      expect(await modelFile.exists(), isTrue);
    } finally {
      router.dispose();
      await getIt.reset();
      await vectors.close();
      await isar.close(deleteFromDisk: true);
      PathProviderPlatform.instance = originalPathProvider;
      await root.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 6)));

  testWidgets(
    'logout stops a running Gateway and allows a fresh start',
    (tester) async {
      final root = await Directory.systemTemp.createTemp(
        'uniun_gateway_logout_',
      );
      final originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProviderPlatform(
        docs: root.path,
        support: root.path,
      );
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final users = UserRepositoryImpl(UserKeyStore(prefs));
      expect((await users.generateKey()).isRight(), isTrue);
      await getIt.reset();
      getIt.registerSingleton<UserRepository>(users);
      getIt.registerSingleton<AppSettingsStore>(AppSettingsStore(prefs));

      try {
        await GatewayBootstrap.start();
        await GatewayBootstrap.start();
        await GatewayBootstrap.stop();
        await GatewayBootstrap.stop();
        await GatewayBootstrap.start();
        await GatewayBootstrap.stop();
      } finally {
        await GatewayBootstrap.stop();
        await getIt.reset();
        PathProviderPlatform.instance = originalPathProvider;
        await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class _Models extends Mock implements AIModelRepository {}

class _Uniun extends Mock implements UniunRepository {}

class _Mls extends Mock implements MarmotMlsService {}

class _Marmot extends Mock implements MarmotTransportService {}

class _Mesh extends Mock implements MeshService {}

class _Gana extends Mock implements GanaEngine {}

class _Indexer extends Mock implements DocumentIndexer {}

class _Embeddings extends Mock implements NoteEmbeddingTrigger {}

class _Llm extends Mock implements LlmRepository {}

/// Runs an isolated Account A → logout → Account B journey over the real
/// Isar, key repository, media cache, vector store, and logout use case.
Future<void> runLogoutAccountSwitchScenario(
  Isar isar,
  Directory root, {
  required bool keepModelFiles,
}) async {
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final originalPathProvider = PathProviderPlatform.instance;
  PathProviderPlatform.instance = FakePathProviderPlatform(
    docs: root.path,
    support: root.path,
  );
  final prefs = await SharedPreferences.getInstance();
  final users = UserRepositoryImpl(UserKeyStore(prefs));
  final models = _Models();
  final uniun = _Uniun();
  final mls = _Mls();
  final marmot = _Marmot();
  final mesh = _Mesh();
  final gana = _Gana();
  final indexer = _Indexer();
  final embeddings = _Embeddings();
  final llm = _Llm();
  final media = MediaCacheDataSource();
  final vectors = await NoteVectorStore.open('${root.path}/vectors');
  final credentials = LlmCredentialsDataSource();

  when(
    () => uniun.disconnect(confirm: true),
  ).thenAnswer((_) async => const Right(unit));
  when(() => mls.resetForLogout()).thenAnswer((_) async {});
  when(() => marmot.stop()).thenAnswer((_) async {});
  when(() => mesh.stop()).thenAnswer((_) async {});
  when(() => gana.stop()).thenAnswer((_) async {});
  when(() => indexer.dispose()).thenAnswer((_) async {});
  when(() => embeddings.stop()).thenAnswer((_) async {});
  when(
    () => llm.preemptBackgroundWork(),
  ).thenAnswer((_) async => const Right(unit));
  when(
    () => models.getDownloadedModelIds(),
  ).thenAnswer((_) async => {AIModelId.gemma4E2b});
  when(
    () => models.deleteModel(AIModelId.gemma4E2b),
  ).thenAnswer((_) async => const Right(unit));
  when(
    () => models.cleanupOrphanedModelFiles(),
  ).thenAnswer((_) async => const Right(0));

  final logout = LogoutUseCase(
    users,
    LogoutSessionRepositoryImpl(
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
    ),
  );

  try {
    final accountA = (await users.generateKey()).getOrElse(
      () => throw StateError('Account A key generation failed'),
    );
    await isar.writeTxn(() async {
      await isar.noteModels.put(
        noteRow('a-note', authorPubkey: accountA.pubkeyHex),
      );
      await isar.noteModels.put(noteRow('a-reply', rootEventId: 'a-note'));
      await isar.noteModels.put(noteRow('a-dm', kind: 14));
      await isar.noteModels.put(noteRow('a-group-note', groupId: 'a-group'));
      await isar.noteModels.put(
        noteRow('a-private-note', privateGroupId: 'a-private'),
      );
      await isar.profileModels.put(profileRow(accountA.pubkeyHex));
      await isar.followedUserModels.put(followedUserSeed('a-followed-user'));
      await isar.followedNoteModels.put(followedNoteSeed('a-followed-note'));
      await isar.groupModels.put(groupSeed('a-group'));
      await isar.privateGroupModels.put(privateGroupSeed('a-private'));
      await isar.dmConversationModels.put(dmConversationRow('a-peer'));
      await isar.shivConversationModels.put(shivConversationRow('a-chat'));
      await isar.shivMessageModels.put(
        shivMessageRow('a-message', conversationId: 'a-chat'),
      );
      await isar.savedNoteModels.put(savedNoteRow('a-saved'));
      await isar.eventQueueModels.put(eventQueueRow('a-queued'));
      await isar.unreadNoteModels.put(unreadRow('a-unread'));
      await isar.mediaCacheModels.put(mediaCacheRow('a-media'));
    });
    final mediaFile = await media.write(
      'a-media',
      'jpg',
      Uint8List.fromList([1, 2, 3]),
    );
    await vectors.upsert(
      'a-note',
      List<double>.filled(embeddingsDimensions, 0.1),
    );
    await credentials.setUniunApiKey('a-cloud-key');
    await credentials.setUniunKeyId('a-cloud-id');
    await UserServerListStore(prefs).setServers(['https://a.example']);
    await AppSettingsStore(prefs).setActiveModelId(AIModelId.gemma4E2b);
    await AppSettingsStore(prefs).setLocaleCode('hi');
    await AppSettingsStore(prefs).setMeshEnabled(true);
    await AppSettingsStore(prefs).setTranslationLanguage('hi');
    await LlmPreferencesDataSource(
      prefs,
    ).setActiveCloudModelId('a-cloud-model');

    expect(await isar.noteModels.count(), 5);
    expect(await isar.followedUserModels.count(), 1);
    expect(await isar.groupModels.count(), 1);
    expect(await isar.privateGroupModels.count(), 1);
    expect(await vectors.contains('a-note'), isTrue);
    expect(await mediaFile.exists(), isTrue);

    expect(
      (await logout.call(
        LogoutParams(keepModelFiles: keepModelFiles),
      )).isRight(),
      isTrue,
    );
    expect((await users.getActiveUser()).isLeft(), isTrue);
    expect(await credentials.getUniunApiKey(), isNull);
    expect(await credentials.getUniunKeyId(), isNull);
    expect(await vectors.contains('a-note'), isFalse);
    expect(await mediaFile.exists(), isFalse);
    expect(UserServerListStore(prefs).servers, isEmpty);
    expect(AppSettingsStore(prefs).activeModelId, isNull);
    expect(AppSettingsStore(prefs).translationLanguage, isNull);
    expect(AppSettingsStore(prefs).localeCode, 'hi');
    expect(AppSettingsStore(prefs).meshEnabled, isTrue);
    expect(LlmPreferencesDataSource(prefs).activeCloudModelId, isNull);

    final accountB = (await users.generateKey()).getOrElse(
      () => throw StateError('Account B key generation failed'),
    );
    expect(accountB.pubkeyHex, isNot(accountA.pubkeyHex));
    expect(
      (await users.getActiveUser()).getOrElse(() => throw 'No B').pubkeyHex,
      accountB.pubkeyHex,
    );
    await _expectAccountDataEmpty(isar);
    await isar.writeTxn(
      () => isar.noteModels.put(
        noteRow('b-note', authorPubkey: accountB.pubkeyHex),
      ),
    );
    expect((await isar.noteModels.where().findAll()).single.eventId, 'b-note');
    expect(await vectors.contains('a-note'), isFalse);

    if (keepModelFiles) {
      verifyNever(() => models.getDownloadedModelIds());
    } else {
      verify(() => models.deleteModel(AIModelId.gemma4E2b)).called(1);
      verify(() => models.cleanupOrphanedModelFiles()).called(1);
    }

    // The original account must also start clean when restored later.
    expect(
      (await logout.call(const LogoutParams(keepModelFiles: true))).isRight(),
      isTrue,
    );
    final restoredA = (await users.importKey(
      accountA.nsec,
    )).getOrElse(() => throw StateError('Account A restore failed'));
    expect(restoredA.pubkeyHex, accountA.pubkeyHex);
    await _expectAccountDataEmpty(isar);
    expect(await vectors.contains('a-note'), isFalse);
  } finally {
    await vectors.close();
    PathProviderPlatform.instance = originalPathProvider;
  }
}

Future<void> _expectAccountDataEmpty(Isar isar) async {
  final counts = <String, int>{
    'notes': await isar.noteModels.count(),
    'profiles': await isar.profileModels.count(),
    'followed users': await isar.followedUserModels.count(),
    'followed notes': await isar.followedNoteModels.count(),
    'groups': await isar.groupModels.count(),
    'private groups': await isar.privateGroupModels.count(),
    'DM conversations': await isar.dmConversationModels.count(),
    'AI conversations': await isar.shivConversationModels.count(),
    'AI messages': await isar.shivMessageModels.count(),
    'saved notes': await isar.savedNoteModels.count(),
    'queued events': await isar.eventQueueModels.count(),
    'unread notes': await isar.unreadNoteModels.count(),
    'media manifests': await isar.mediaCacheModels.count(),
  };
  for (final entry in counts.entries) {
    expect(entry.value, 0, reason: '${entry.key} leaked into Account B');
  }
}
