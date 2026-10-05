// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:isar_community/isar.dart' as _i214;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:tostore/tostore.dart' as _i789;
import 'package:uniun/common/widgets/composer/cubit/reference_picker_cubit.dart'
    as _i734;
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart'
    as _i226;
import 'package:uniun/core/share_intent/share_intent_service.dart' as _i794;
import 'package:uniun/data/datasources/app_settings_store.dart' as _i107;
import 'package:uniun/data/datasources/blossom_client.dart' as _i706;
import 'package:uniun/data/datasources/cloud/uniun_gateway_client.dart' as _i83;
import 'package:uniun/data/datasources/docx/docx_text_source.dart' as _i729;
import 'package:uniun/data/datasources/feed_read_state_store.dart' as _i752;
import 'package:uniun/data/datasources/image_labels/image_label_source.dart'
    as _i35;
import 'package:uniun/data/datasources/isar_module.dart' as _i146;
import 'package:uniun/data/datasources/llm/embedding_queue.dart' as _i1031;
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart' as _i93;
import 'package:uniun/data/datasources/llm/inference_scheduler.dart' as _i552;
import 'package:uniun/data/datasources/llm/llm_credentials_data_source.dart'
    as _i981;
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart'
    as _i634;
import 'package:uniun/data/datasources/llm/local_llm_data_source.dart' as _i937;
import 'package:uniun/data/datasources/llm/local_llm_runner.dart' as _i937;
import 'package:uniun/data/datasources/llm/remote_llm_data_source.dart'
    as _i141;
import 'package:uniun/data/datasources/media_cache_data_source.dart' as _i366;
import 'package:uniun/data/datasources/ocr/ocr_text_source.dart' as _i787;
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart' as _i623;
import 'package:uniun/data/datasources/surrounding_read_state_store.dart'
    as _i156;
import 'package:uniun/data/datasources/tostore_module.dart' as _i740;
import 'package:uniun/data/repositories/ai_model_repository_impl.dart' as _i72;
import 'package:uniun/data/repositories/app_settings_repository_impl.dart'
    as _i913;
import 'package:uniun/data/repositories/blocked_user_repository_impl.dart'
    as _i877;
import 'package:uniun/data/repositories/deleted_note_repository_impl.dart'
    as _i438;
import 'package:uniun/data/repositories/dm_conversation_repository_impl.dart'
    as _i1011;
import 'package:uniun/data/repositories/dm_message_repository_impl.dart'
    as _i398;
import 'package:uniun/data/repositories/document_source_repository_impl.dart'
    as _i1015;
import 'package:uniun/data/repositories/draft_repository_impl.dart' as _i640;
import 'package:uniun/data/repositories/e2ee_group_repository_impl.dart'
    as _i896;
import 'package:uniun/data/repositories/event_queue_repository_impl.dart'
    as _i116;
import 'package:uniun/data/repositories/feed_repository_impl.dart' as _i689;
import 'package:uniun/data/repositories/followed_note_repository_impl.dart'
    as _i107;
import 'package:uniun/data/repositories/followed_user_repository_impl.dart'
    as _i791;
import 'package:uniun/data/repositories/gana_repository_impl.dart' as _i899;
import 'package:uniun/data/repositories/gana_run_repository_impl.dart' as _i678;
import 'package:uniun/data/repositories/graph_repository_impl.dart' as _i250;
import 'package:uniun/data/repositories/group_message_repository_impl.dart'
    as _i828;
import 'package:uniun/data/repositories/group_repository_impl.dart' as _i632;
import 'package:uniun/data/repositories/isar_document_vector_repository_impl.dart'
    as _i362;
import 'package:uniun/data/repositories/llm_repository_impl.dart' as _i19;
import 'package:uniun/data/repositories/manas_repository_impl.dart' as _i395;
import 'package:uniun/data/repositories/media_repository_impl.dart' as _i980;
import 'package:uniun/data/repositories/memory_repository_impl.dart' as _i849;
import 'package:uniun/data/repositories/nataraj_repository_impl.dart' as _i455;
import 'package:uniun/data/repositories/note_attachments_enricher.dart'
    as _i182;
import 'package:uniun/data/repositories/note_relation_repository_impl.dart'
    as _i126;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i348;
import 'package:uniun/data/repositories/note_resolver_repository_impl.dart'
    as _i526;
import 'package:uniun/data/repositories/pending_extraction_repository_impl.dart'
    as _i754;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/relay_repository_impl.dart' as _i542;
import 'package:uniun/data/repositories/report_repository_impl.dart' as _i488;
import 'package:uniun/data/repositories/saved_note_repository_impl.dart'
    as _i669;
import 'package:uniun/data/repositories/scheduler_coordinator_impl.dart'
    as _i289;
import 'package:uniun/data/repositories/share_repository_impl.dart' as _i593;
import 'package:uniun/data/repositories/shiv_repository_impl.dart' as _i412;
import 'package:uniun/data/repositories/source_label_repository_impl.dart'
    as _i395;
import 'package:uniun/data/repositories/storage_repository_impl.dart' as _i209;
import 'package:uniun/data/repositories/surrounding_note_repository_impl.dart'
    as _i670;
import 'package:uniun/data/repositories/tostore_vector_repository_impl.dart'
    as _i831;
import 'package:uniun/data/repositories/uniun_repository_impl.dart' as _i307;
import 'package:uniun/data/repositories/unread_repository_impl.dart' as _i1024;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;
import 'package:uniun/data/repositories/user_server_list_repository_impl.dart'
    as _i745;
import 'package:uniun/domain/entities/note/note_entity.dart' as _i697;
import 'package:uniun/domain/repositories/ai_model_repository.dart' as _i646;
import 'package:uniun/domain/repositories/app_settings_repository.dart'
    as _i117;
import 'package:uniun/domain/repositories/blocked_user_repository.dart'
    as _i756;
import 'package:uniun/domain/repositories/deleted_note_repository.dart'
    as _i775;
import 'package:uniun/domain/repositories/dm_conversation_repository.dart'
    as _i189;
import 'package:uniun/domain/repositories/dm_message_repository.dart' as _i551;
import 'package:uniun/domain/repositories/document_source_repository.dart'
    as _i572;
import 'package:uniun/domain/repositories/document_vector_repository.dart'
    as _i179;
import 'package:uniun/domain/repositories/draft_repository.dart' as _i170;
import 'package:uniun/domain/repositories/e2ee_group_repository.dart' as _i635;
import 'package:uniun/domain/repositories/event_queue_repository.dart'
    as _i1039;
import 'package:uniun/domain/repositories/feed_repository.dart' as _i250;
import 'package:uniun/domain/repositories/followed_note_repository.dart'
    as _i836;
import 'package:uniun/domain/repositories/followed_user_repository.dart'
    as _i849;
import 'package:uniun/domain/repositories/gana_repository.dart' as _i160;
import 'package:uniun/domain/repositories/gana_run_repository.dart' as _i534;
import 'package:uniun/domain/repositories/graph_repository.dart' as _i649;
import 'package:uniun/domain/repositories/group_message_repository.dart'
    as _i546;
import 'package:uniun/domain/repositories/group_repository.dart' as _i582;
import 'package:uniun/domain/repositories/llm_repository.dart' as _i205;
import 'package:uniun/domain/repositories/manas_repository.dart' as _i699;
import 'package:uniun/domain/repositories/media_repository.dart' as _i683;
import 'package:uniun/domain/repositories/memory_repository.dart' as _i331;
import 'package:uniun/domain/repositories/nataraj_repository.dart' as _i125;
import 'package:uniun/domain/repositories/note_relation_repository.dart'
    as _i1017;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/note_resolver_repository.dart'
    as _i789;
import 'package:uniun/domain/repositories/pending_extraction_repository.dart'
    as _i1000;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/relay_repository.dart' as _i993;
import 'package:uniun/domain/repositories/report_repository.dart' as _i469;
import 'package:uniun/domain/repositories/saved_note_repository.dart' as _i43;
import 'package:uniun/domain/repositories/scheduler_coordinator.dart' as _i537;
import 'package:uniun/domain/repositories/share_repository.dart' as _i1019;
import 'package:uniun/domain/repositories/shiv_repository.dart' as _i266;
import 'package:uniun/domain/repositories/source_label_repository.dart'
    as _i633;
import 'package:uniun/domain/repositories/storage_repository.dart' as _i240;
import 'package:uniun/domain/repositories/surrounding_note_repository.dart'
    as _i956;
import 'package:uniun/domain/repositories/uniun_repository.dart' as _i880;
import 'package:uniun/domain/repositories/unread_repository.dart' as _i497;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;
import 'package:uniun/domain/repositories/user_server_list_repository.dart'
    as _i930;
import 'package:uniun/domain/repositories/vector_repository.dart' as _i739;
import 'package:uniun/domain/services/marmot_mls_service.dart' as _i168;
import 'package:uniun/domain/services/marmot_transport_service.dart' as _i761;
import 'package:uniun/domain/usecases/ai_model_usecases.dart' as _i894;
import 'package:uniun/domain/usecases/app_settings_usecases.dart' as _i907;
import 'package:uniun/domain/usecases/blocked_user_usecases.dart' as _i278;
import 'package:uniun/domain/usecases/create_group_message_usecase.dart'
    as _i815;
import 'package:uniun/domain/usecases/create_group_usecase.dart' as _i890;
import 'package:uniun/domain/usecases/delete_relay_usecase.dart' as _i700;
import 'package:uniun/domain/usecases/deleted_note_usecases.dart' as _i232;
import 'package:uniun/domain/usecases/dm_usecases.dart' as _i1023;
import 'package:uniun/domain/usecases/draft_usecases.dart' as _i537;
import 'package:uniun/domain/usecases/feed_usecases.dart' as _i837;
import 'package:uniun/domain/usecases/followed_note_usecases.dart' as _i561;
import 'package:uniun/domain/usecases/followed_user_usecases.dart' as _i63;
import 'package:uniun/domain/usecases/gana_usecases.dart' as _i219;
import 'package:uniun/domain/usecases/get_group_by_id_usecase.dart' as _i690;
import 'package:uniun/domain/usecases/get_group_messages_usecase.dart' as _i932;
import 'package:uniun/domain/usecases/get_groups_usecase.dart' as _i879;
import 'package:uniun/domain/usecases/get_relays_usecase.dart' as _i985;
import 'package:uniun/domain/usecases/knowledge_usecases.dart' as _i179;
import 'package:uniun/domain/usecases/llm_usecases.dart' as _i918;
import 'package:uniun/domain/usecases/manas_usecases.dart' as _i977;
import 'package:uniun/domain/usecases/media_usecases.dart' as _i629;
import 'package:uniun/domain/usecases/nataraj_usecases.dart' as _i812;
import 'package:uniun/domain/usecases/note_usecases.dart' as _i475;
import 'package:uniun/domain/usecases/onboarding_usecases.dart' as _i747;
import 'package:uniun/domain/usecases/post_reply_usecase.dart' as _i924;
import 'package:uniun/domain/usecases/private_group_usecases.dart' as _i1055;
import 'package:uniun/domain/usecases/profile_usecases.dart' as _i391;
import 'package:uniun/domain/usecases/report_usecases.dart' as _i27;
import 'package:uniun/domain/usecases/save_group_usecase.dart' as _i511;
import 'package:uniun/domain/usecases/save_relay_usecase.dart' as _i433;
import 'package:uniun/domain/usecases/saved_note_usecases.dart' as _i858;
import 'package:uniun/domain/usecases/scheduler_usecases.dart' as _i1012;
import 'package:uniun/domain/usecases/share_usecases.dart' as _i1;
import 'package:uniun/domain/usecases/shiv_usecases.dart' as _i604;
import 'package:uniun/domain/usecases/source_label_usecases.dart' as _i978;
import 'package:uniun/domain/usecases/storage_usecases.dart' as _i58;
import 'package:uniun/domain/usecases/surrounding_usecases.dart' as _i303;
import 'package:uniun/domain/usecases/unread_usecases.dart' as _i719;
import 'package:uniun/domain/usecases/user_usecases.dart' as _i799;
import 'package:uniun/domain/usecases/vector_usecases.dart' as _i756;
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart' as _i886;
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart' as _i830;
import 'package:uniun/features/brahma/manas/bloc/manas_form_bloc.dart' as _i630;
import 'package:uniun/features/brahma/manas/bloc/manas_list_bloc.dart' as _i437;
import 'package:uniun/features/dm/chat/bloc/dm_chat_bloc.dart' as _i60;
import 'package:uniun/features/dm/create/bloc/create_dm_bloc.dart' as _i399;
import 'package:uniun/features/groups/create/bloc/create_group_bloc.dart'
    as _i968;
import 'package:uniun/features/groups/join/bloc/join_group_bloc.dart' as _i574;
import 'package:uniun/features/mesh/service/mesh_service.dart' as _i421;
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart' as _i558;
import 'package:uniun/features/private_groups/create/bloc/create_private_group_bloc.dart'
    as _i985;
import 'package:uniun/features/private_groups/detail/bloc/private_group_detail_bloc.dart'
    as _i548;
import 'package:uniun/features/private_groups/join/bloc/join_private_group_bloc.dart'
    as _i425;
import 'package:uniun/features/profile/bloc/user_profile_bloc.dart' as _i959;
import 'package:uniun/features/receive_share/bloc/receive_share_bloc.dart'
    as _i939;
import 'package:uniun/features/settings/cubit/edit_profile_cubit.dart' as _i859;
import 'package:uniun/features/settings/cubit/settings_cubit.dart' as _i331;
import 'package:uniun/features/settings/cubit/storage_cubit.dart' as _i13;
import 'package:uniun/features/share/bloc/share_sheet_bloc.dart' as _i574;
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart' as _i190;
import 'package:uniun/features/shiv/chat/cubit/chat_image_support_cubit.dart'
    as _i269;
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_cubit.dart'
    as _i526;
import 'package:uniun/features/shiv/gana/engine/gana_engine.dart' as _i426;
import 'package:uniun/features/shiv/gana/form/bloc/gana_form_bloc.dart'
    as _i942;
import 'package:uniun/features/shiv/gana/list/bloc/gana_list_bloc.dart'
    as _i174;
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart'
    as _i651;
import 'package:uniun/features/shiv/model_select/cubit/select_ai_model_cubit.dart'
    as _i687;
import 'package:uniun/features/shiv/nataraj/bloc/nataraj_bloc.dart' as _i395;
import 'package:uniun/features/shiv/nataraj/engine/nataraj_generator.dart'
    as _i638;
import 'package:uniun/features/shiv/rag/embedding/embedding_model_downloader.dart'
    as _i850;
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart'
    as _i587;
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart'
    as _i139;
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart'
    as _i1026;
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart' as _i681;
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart' as _i207;
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart'
    as _i961;
import 'package:uniun/features/thread/bloc/thread_bloc.dart' as _i807;
import 'package:uniun/features/vishnu/bloc/vishnu_feed_bloc.dart' as _i1039;
import 'package:uniun/features/vishnu/drawer/bloc/drawer_bloc.dart' as _i666;
import 'package:uniun/features/vishnu/drawer/bloc/drawer_data_source.dart'
    as _i733;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final sharedPreferencesModule = _$SharedPreferencesModule();
    final isarModule = _$IsarModule();
    final tostoreModule = _$TostoreModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => sharedPreferencesModule.sharedPreferences(),
      preResolve: true,
    );
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );
    gh.singleton<_i981.LlmCredentialsDataSource>(
      () => _i981.LlmCredentialsDataSource(),
    );
    await gh.singletonAsync<_i789.ToStore>(
      () => tostoreModule.createTostore(),
      preResolve: true,
    );
    gh.lazySingleton<_i794.ShareIntentService>(
      () => _i794.ShareIntentService(),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i706.BlossomClient>(() => _i706.BlossomClient());
    gh.lazySingleton<_i83.UniunGatewayClient>(() => _i83.UniunGatewayClient());
    gh.lazySingleton<_i1031.EmbeddingQueue>(() => _i1031.EmbeddingQueue());
    gh.lazySingleton<_i552.InferenceScheduler>(
      () => _i552.InferenceScheduler(),
    );
    gh.lazySingleton<_i366.MediaCacheDataSource>(
      () => _i366.MediaCacheDataSource(),
    );
    gh.lazySingleton<_i168.MarmotMlsService>(() => _i168.MarmotMlsService());
    gh.lazySingleton<_i207.PromptBuilder>(() => const _i207.PromptBuilder());
    gh.lazySingleton<_i179.DocumentVectorRepository>(
      () => _i362.IsarDocumentVectorRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i787.OcrTextSource>(() => _i787.MlKitOcrTextSource());
    gh.lazySingleton<_i739.VectorRepository>(
      () => _i831.TostoreVectorRepositoryImpl(
        gh<_i789.ToStore>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.factory<_i733.DrawerDataSource>(
      () => _i733.DrawerDataSource(gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i756.SearchDocumentChunksUseCase>(
      () => _i756.SearchDocumentChunksUseCase(
        gh<_i179.DocumentVectorRepository>(),
      ),
    );
    gh.lazySingleton<_i35.ImageLabelSource>(() => _i35.MlKitImageLabelSource());
    gh.factory<_i93.FlutterGemmaGateway>(() => _i93.FlutterGemmaGatewayImpl());
    gh.lazySingleton<_i623.PdfTextSource>(() => _i623.PdfrxTextSource());
    gh.factory<_i266.ShivRepository>(
      () => _i412.ShivRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i729.DocxTextSource>(() => _i729.ArchiveDocxTextSource());
    gh.factory<_i633.SourceLabelRepository>(
      () => _i395.SourceLabelRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1017.NoteRelationRepository>(
      () => _i126.NoteRelationRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1000.PendingExtractionRepository>(
      () => _i754.PendingExtractionRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i572.DocumentSourceRepository>(
      () => _i1015.DocumentSourceRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i649.GraphRepository>(
      () => _i250.GraphRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.singleton<_i107.AppSettingsStore>(
      () => _i107.AppSettingsStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i107.UserKeyStore>(
      () => _i107.UserKeyStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i107.UserServerListStore>(
      () => _i107.UserServerListStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i752.FeedReadStateStore>(
      () => _i752.FeedReadStateStore(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i634.LlmPreferencesDataSource>(
      () => _i634.LlmPreferencesDataSource(gh<_i460.SharedPreferences>()),
    );
    gh.singleton<_i156.SurroundingReadStateStore>(
      () => _i156.SurroundingReadStateStore(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i475.GetNoteRelationCountsUseCase>(
      () => _i475.GetNoteRelationCountsUseCase(
        gh<_i1017.NoteRelationRepository>(),
      ),
    );
    gh.factory<_i534.GanaRunRepository>(
      () => _i678.GanaRunRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i775.DeletedNoteRepository>(
      () => _i438.DeletedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i125.NatarajRepository>(
      () => _i455.NatarajRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i182.NoteAttachmentsEnricher>(
      () => _i182.NoteAttachmentsEnricher(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i1039.EventQueueRepository>(
      () => _i116.EventQueueRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(gh<_i107.UserKeyStore>()),
    );
    gh.lazySingleton<_i219.LogGanaRunUseCase>(
      () => _i219.LogGanaRunUseCase(gh<_i534.GanaRunRepository>()),
    );
    gh.lazySingleton<_i219.GetGanaRunsUseCase>(
      () => _i219.GetGanaRunsUseCase(gh<_i534.GanaRunRepository>()),
    );
    gh.lazySingleton<_i219.GetGanaOutputEventIdsUseCase>(
      () => _i219.GetGanaOutputEventIdsUseCase(gh<_i534.GanaRunRepository>()),
    );
    gh.lazySingleton<_i219.PruneGanaRunsUseCase>(
      () => _i219.PruneGanaRunsUseCase(gh<_i534.GanaRunRepository>()),
    );
    gh.factory<_i537.SchedulerCoordinator>(
      () => _i289.SchedulerCoordinatorImpl(gh<_i552.InferenceScheduler>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i635.E2EEGroupRepository>(
      () => _i896.E2EEGroupRepositoryImpl(
        gh<_i214.Isar>(),
        gh<_i182.NoteAttachmentsEnricher>(),
      ),
    );
    gh.lazySingleton<_i1012.SetForegroundKindUseCase>(
      () => _i1012.SetForegroundKindUseCase(gh<_i537.SchedulerCoordinator>()),
    );
    gh.factory<_i993.RelayRepository>(
      () => _i542.RelayRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i799.GetActiveUserProfileUseCase>(
      () => _i799.GetActiveUserProfileUseCase(
        gh<_i103.UserRepository>(),
        gh<_i967.ProfileRepository>(),
      ),
    );
    gh.factory<_i469.ReportRepository>(
      () => _i488.ReportRepositoryImpl(
        isar: gh<_i214.Isar>(),
        eventQueueRepository: gh<_i1039.EventQueueRepository>(),
        userRepository: gh<_i103.UserRepository>(),
      ),
    );
    gh.lazySingleton<_i978.ResolveSourceLabelsUseCase>(
      () => _i978.ResolveSourceLabelsUseCase(gh<_i633.SourceLabelRepository>()),
    );
    gh.factory<_i331.MemoryRepository>(
      () => _i849.MemoryRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i497.UnreadRepository>(
      () => _i1024.UnreadRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i604.GetConversationsUseCase>(
      () => _i604.GetConversationsUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.WatchConversationsUseCase>(
      () => _i604.WatchConversationsUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.CreateConversationUseCase>(
      () => _i604.CreateConversationUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.DeleteConversationUseCase>(
      () => _i604.DeleteConversationUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.GetMessagesUseCase>(
      () => _i604.GetMessagesUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.SaveMessageUseCase>(
      () => _i604.SaveMessageUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateMessageContentUseCase>(
      () => _i604.UpdateMessageContentUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateConversationTitleUseCase>(
      () => _i604.UpdateConversationTitleUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i604.UpdateActiveLeafUseCase>(
      () => _i604.UpdateActiveLeafUseCase(gh<_i266.ShivRepository>()),
    );
    gh.lazySingleton<_i391.GetProfileUseCase>(
      () => _i391.GetProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.GetOwnProfileUseCase>(
      () => _i391.GetOwnProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.SaveProfileUseCase>(
      () => _i391.SaveProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.WatchProfileUseCase>(
      () => _i391.WatchProfileUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i391.RequestProfileFetchUseCase>(
      () => _i391.RequestProfileFetchUseCase(gh<_i967.ProfileRepository>()),
    );
    gh.lazySingleton<_i421.MeshService>(
      () => _i421.MeshService(
        gh<_i214.Isar>(),
        gh<_i103.UserRepository>(),
        gh<_i107.AppSettingsStore>(),
      ),
    );
    gh.factory<_i240.StorageRepository>(
      () => _i209.StorageRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i558.MeshEventSigner>(
      () => _i558.MeshEventSigner(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i179.GetGraphNeighboursUseCase>(
      () => _i179.GetGraphNeighboursUseCase(gh<_i649.GraphRepository>()),
    );
    gh.lazySingleton<_i179.GetGraphNodesByKeysUseCase>(
      () => _i179.GetGraphNodesByKeysUseCase(gh<_i649.GraphRepository>()),
    );
    gh.lazySingleton<_i756.SearchVectorNotesUseCase>(
      () => _i756.SearchVectorNotesUseCase(gh<_i739.VectorRepository>()),
    );
    gh.lazySingleton<_i799.GetActiveUserUseCase>(
      () => _i799.GetActiveUserUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i799.GetActiveUserKeysUseCase>(
      () => _i799.GetActiveUserKeysUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i799.ImportKeyUseCase>(
      () => _i799.ImportKeyUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i799.LogoutUseCase>(
      () => _i799.LogoutUseCase(gh<_i103.UserRepository>()),
    );
    gh.lazySingleton<_i179.DeleteKnowledgeForNoteUseCase>(
      () => _i179.DeleteKnowledgeForNoteUseCase(
        gh<_i649.GraphRepository>(),
        gh<_i331.MemoryRepository>(),
      ),
    );
    gh.lazySingleton<_i139.DocumentExtractionService>(
      () => _i139.DocumentExtractionService(
        gh<_i623.PdfTextSource>(),
        gh<_i729.DocxTextSource>(),
        gh<_i787.OcrTextSource>(),
        gh<_i35.ImageLabelSource>(),
      ),
    );
    gh.factory<_i160.GanaRepository>(
      () => _i899.GanaRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.lazySingleton<_i1055.GetPrivateGroupsUsecase>(
      () => _i1055.GetPrivateGroupsUsecase(gh<_i635.E2EEGroupRepository>()),
    );
    gh.lazySingleton<_i1055.GetPrivateGroupEntityUsecase>(
      () =>
          _i1055.GetPrivateGroupEntityUsecase(gh<_i635.E2EEGroupRepository>()),
    );
    gh.lazySingleton<_i1055.GetPrivateGroupMessagesUsecase>(
      () => _i1055.GetPrivateGroupMessagesUsecase(
        gh<_i635.E2EEGroupRepository>(),
      ),
    );
    gh.lazySingleton<_i1055.GetPrivateGroupJoinRequestsUsecase>(
      () => _i1055.GetPrivateGroupJoinRequestsUsecase(
        gh<_i635.E2EEGroupRepository>(),
      ),
    );
    gh.lazySingleton<_i58.GetStorageStatsUseCase>(
      () => _i58.GetStorageStatsUseCase(gh<_i240.StorageRepository>()),
    );
    gh.lazySingleton<_i58.DeleteFeedNotesUseCase>(
      () => _i58.DeleteFeedNotesUseCase(gh<_i240.StorageRepository>()),
    );
    gh.lazySingleton<_i58.DeleteAllChatHistoryUseCase>(
      () => _i58.DeleteAllChatHistoryUseCase(gh<_i240.StorageRepository>()),
    );
    gh.factory<_i789.NoteResolverRepository>(
      () => _i526.NoteResolverRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        attachments: gh<_i182.NoteAttachmentsEnricher>(),
      ),
    );
    gh.factory<_i170.DraftRepository>(
      () => _i640.DraftRepositoryImpl(
        isar: gh<_i214.Isar>(),
        eventQueue: gh<_i1039.EventQueueRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
        attachments: gh<_i182.NoteAttachmentsEnricher>(),
      ),
    );
    gh.lazySingleton<_i232.DeleteNoteUseCase>(
      () => _i232.DeleteNoteUseCase(gh<_i775.DeletedNoteRepository>()),
    );
    gh.factory<_i880.UniunRepository>(
      () => _i307.UniunRepositoryImpl(
        gh<_i83.UniunGatewayClient>(),
        gh<_i981.LlmCredentialsDataSource>(),
        gh<_i103.UserRepository>(),
        gh<_i391.GetOwnProfileUseCase>(),
      ),
    );
    gh.lazySingleton<_i587.EmbeddingService>(
      () => _i587.EmbeddingService(gh<_i93.FlutterGemmaGateway>()),
    );
    gh.factory<_i699.ManasRepository>(
      () => _i395.ManasRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.factory<_i849.FollowedUserRepository>(
      () => _i791.FollowedUserRepositoryImpl(
        isar: gh<_i214.Isar>(),
        eventQueue: gh<_i1039.EventQueueRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i858.ResolveDocumentCitationsUseCase>(
      () => _i858.ResolveDocumentCitationsUseCase(
        gh<_i572.DocumentSourceRepository>(),
      ),
    );
    gh.factory<_i756.BlockedUserRepository>(
      () => _i877.BlockedUserRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.lazySingleton<_i977.UpsertManasUseCase>(
      () => _i977.UpsertManasUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.GetManasListUseCase>(
      () => _i977.GetManasListUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.GetManasByIdUseCase>(
      () => _i977.GetManasByIdUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.DeleteManasUseCase>(
      () => _i977.DeleteManasUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.AddNoteToManasUseCase>(
      () => _i977.AddNoteToManasUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.RemoveNoteFromManasUseCase>(
      () => _i977.RemoveNoteFromManasUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.GetNoteIdsForManasUseCase>(
      () => _i977.GetNoteIdsForManasUseCase(gh<_i699.ManasRepository>()),
    );
    gh.lazySingleton<_i977.GetManasIdsForNoteUseCase>(
      () => _i977.GetManasIdsForNoteUseCase(gh<_i699.ManasRepository>()),
    );
    gh.factory<_i836.FollowedNoteRepository>(
      () => _i107.FollowedNoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.factory<_i956.SurroundingNoteRepository>(
      () => _i670.SurroundingNoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        readStore: gh<_i156.SurroundingReadStateStore>(),
      ),
    );
    gh.lazySingleton<_i27.ReportNoteUseCase>(
      () => _i27.ReportNoteUseCase(gh<_i469.ReportRepository>()),
    );
    gh.lazySingleton<_i27.ReportUserUseCase>(
      () => _i27.ReportUserUseCase(gh<_i469.ReportRepository>()),
    );
    gh.factory<_i117.AppSettingsRepository>(
      () => _i913.AppSettingsRepositoryImpl(gh<_i107.AppSettingsStore>()),
    );
    gh.lazySingleton<_i812.GetNextNatarajCardUseCase>(
      () => _i812.GetNextNatarajCardUseCase(gh<_i125.NatarajRepository>()),
    );
    gh.lazySingleton<_i812.RecordNatarajSwipeUseCase>(
      () => _i812.RecordNatarajSwipeUseCase(gh<_i125.NatarajRepository>()),
    );
    gh.lazySingleton<_i812.CountBufferedNatarajCardsUseCase>(
      () =>
          _i812.CountBufferedNatarajCardsUseCase(gh<_i125.NatarajRepository>()),
    );
    gh.lazySingleton<_i278.GetBlockedUsersUseCase>(
      () => _i278.GetBlockedUsersUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.lazySingleton<_i278.BlockUserUseCase>(
      () => _i278.BlockUserUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.lazySingleton<_i278.UnblockUserUseCase>(
      () => _i278.UnblockUserUseCase(gh<_i756.BlockedUserRepository>()),
    );
    gh.factory<_i582.GroupRepository>(
      () => _i632.GroupRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.factory<_i189.DmConversationRepository>(
      () => _i1011.DmConversationRepositoryImpl(
        isar: gh<_i214.Isar>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.lazySingleton<_i937.AIModelRunner>(
      () => _i937.AIModelRunner(
        gh<_i552.InferenceScheduler>(),
        gh<_i107.AppSettingsStore>(),
        gh<_i93.FlutterGemmaGateway>(),
      ),
    );
    gh.lazySingleton<_i700.DeleteRelayUseCase>(
      () => _i700.DeleteRelayUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i985.GetRelaysUseCase>(
      () => _i985.GetRelaysUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i433.SaveRelayUseCase>(
      () => _i433.SaveRelayUseCase(gh<_i993.RelayRepository>()),
    );
    gh.lazySingleton<_i719.MarkUnreadSeenUseCase>(
      () => _i719.MarkUnreadSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkGroupSeenUseCase>(
      () => _i719.MarkGroupSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkPrivateGroupSeenUseCase>(
      () => _i719.MarkPrivateGroupSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.MarkConversationSeenUseCase>(
      () => _i719.MarkConversationSeenUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i719.GetGroupOldestUnreadTimeUseCase>(
      () => _i719.GetGroupOldestUnreadTimeUseCase(gh<_i497.UnreadRepository>()),
    );
    gh.lazySingleton<_i690.GetGroupByIdUseCase>(
      () => _i690.GetGroupByIdUseCase(gh<_i582.GroupRepository>()),
    );
    gh.lazySingleton<_i879.GetGroupsUseCase>(
      () => _i879.GetGroupsUseCase(gh<_i582.GroupRepository>()),
    );
    gh.lazySingleton<_i511.SaveGroupUseCase>(
      () => _i511.SaveGroupUseCase(gh<_i582.GroupRepository>()),
    );
    gh.factory<_i930.UserServerListRepository>(
      () => _i745.UserServerListRepositoryImpl(
        store: gh<_i107.UserServerListStore>(),
        eventQueue: gh<_i1039.EventQueueRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i646.AIModelRepository>(
      () => _i72.AIModelRepositoryImpl(
        gh<_i214.Isar>(),
        gh<_i107.AppSettingsStore>(),
        gh<_i937.AIModelRunner>(),
        gh<_i93.FlutterGemmaGateway>(),
      ),
    );
    gh.factory<_i574.JoinGroupBloc>(
      () => _i574.JoinGroupBloc(
        gh<_i433.SaveRelayUseCase>(),
        gh<_i511.SaveGroupUseCase>(),
      ),
    );
    gh.factory<_i551.DmMessageRepository>(
      () => _i398.DmMessageRepositoryImpl(
        isar: gh<_i214.Isar>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i961.VectorSearchService>(
      () => _i961.VectorSearchService(
        gh<_i756.SearchVectorNotesUseCase>(),
        gh<_i756.SearchDocumentChunksUseCase>(),
      ),
    );
    gh.lazySingleton<_i761.MarmotTransportService>(
      () => _i761.MarmotTransportService(
        gh<_i214.Isar>(),
        gh<_i168.MarmotMlsService>(),
        gh<_i1017.NoteRelationRepository>(),
        gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.factory<_i331.SettingsCubit>(
      () => _i331.SettingsCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
      ),
    );
    gh.factory<_i546.GroupMessageRepository>(
      () => _i828.GroupMessageRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i537.SaveDraftUseCase>(
      () => _i537.SaveDraftUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.GetDraftsUseCase>(
      () => _i537.GetDraftsUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.GetDraftByIdUseCase>(
      () => _i537.GetDraftByIdUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.DeleteDraftUseCase>(
      () => _i537.DeleteDraftUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i537.MarkDraftPublishedUseCase>(
      () => _i537.MarkDraftPublishedUseCase(gh<_i170.DraftRepository>()),
    );
    gh.lazySingleton<_i1023.SendDmUseCase>(
      () => _i1023.SendDmUseCase(
        gh<_i214.Isar>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.lazySingleton<_i918.ConnectUniunCloudUseCase>(
      () => _i918.ConnectUniunCloudUseCase(gh<_i880.UniunRepository>()),
    );
    gh.lazySingleton<_i918.DisconnectUniunCloudUseCase>(
      () => _i918.DisconnectUniunCloudUseCase(gh<_i880.UniunRepository>()),
    );
    gh.lazySingleton<_i918.IsUniunCloudConnectedUseCase>(
      () => _i918.IsUniunCloudConnectedUseCase(gh<_i880.UniunRepository>()),
    );
    gh.lazySingleton<_i918.GetUniunCloudStatusUseCase>(
      () => _i918.GetUniunCloudStatusUseCase(gh<_i880.UniunRepository>()),
    );
    gh.lazySingleton<_i747.GetOnboardingInterestsUseCase>(
      () => _i747.GetOnboardingInterestsUseCase(gh<_i880.UniunRepository>()),
    );
    gh.lazySingleton<_i219.UpsertGanaUseCase>(
      () => _i219.UpsertGanaUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.GetGanasUseCase>(
      () => _i219.GetGanasUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.GetEnabledGanasUseCase>(
      () => _i219.GetEnabledGanasUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.GetGanaByIdUseCase>(
      () => _i219.GetGanaByIdUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.DeleteGanaUseCase>(
      () => _i219.DeleteGanaUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.SetGanaEnabledUseCase>(
      () => _i219.SetGanaEnabledUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i219.AdvanceGanaCursorUseCase>(
      () => _i219.AdvanceGanaCursorUseCase(gh<_i160.GanaRepository>()),
    );
    gh.lazySingleton<_i179.GetMemoriesByNoteIdsUseCase>(
      () => _i179.GetMemoriesByNoteIdsUseCase(gh<_i331.MemoryRepository>()),
    );
    gh.lazySingleton<_i1023.GetDmConversationsUseCase>(
      () => _i1023.GetDmConversationsUseCase(
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.lazySingleton<_i1023.CreateDmConversationUseCase>(
      () => _i1023.CreateDmConversationUseCase(
        gh<_i189.DmConversationRepository>(),
      ),
    );
    gh.lazySingleton<_i391.PublishProfileMetadataUseCase>(
      () => _i391.PublishProfileMetadataUseCase(
        gh<_i1039.EventQueueRepository>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i1023.GetDmUseCase>(
      () => _i1023.GetDmUseCase(
        gh<_i214.Isar>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i561.GetAllFollowedNotesUseCase>(
      () =>
          _i561.GetAllFollowedNotesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.FollowNoteUseCase>(
      () => _i561.FollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.UnfollowNoteUseCase>(
      () => _i561.UnfollowNoteUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.WatchIsFollowedUseCase>(
      () => _i561.WatchIsFollowedUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i561.ClearNewReferencesUseCase>(
      () => _i561.ClearNewReferencesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.factory<_i43.SavedNoteRepository>(
      () => _i669.SavedNoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        attachments: gh<_i182.NoteAttachmentsEnricher>(),
        signer: gh<_i558.MeshEventSigner>(),
      ),
    );
    gh.lazySingleton<_i858.IsSavedNoteUseCase>(
      () => _i858.IsSavedNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetAllSavedNotesUseCase>(
      () => _i858.GetAllSavedNotesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetSavedReplyCountUseCase>(
      () => _i858.GetSavedReplyCountUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetSavedRepliesUseCase>(
      () => _i858.GetSavedRepliesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetSavedReferencesUseCase>(
      () => _i858.GetSavedReferencesUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i756.EmbedAndStoreChunkUseCase>(
      () => _i756.EmbedAndStoreChunkUseCase(
        gh<_i587.EmbeddingService>(),
        gh<_i179.DocumentVectorRepository>(),
        gh<_i1031.EmbeddingQueue>(),
      ),
    );
    gh.factory<_i250.FeedRepository>(
      () => _i689.FeedRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        sourceLabels: gh<_i633.SourceLabelRepository>(),
        follows: gh<_i849.FollowedUserRepository>(),
        users: gh<_i103.UserRepository>(),
        feedReadState: gh<_i752.FeedReadStateStore>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i1023.FetchDmUseCase>(
      () => _i1023.FetchDmUseCase(
        gh<_i189.DmConversationRepository>(),
        gh<_i551.DmMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i1055.CreatePrivateGroupUsecase>(
      () =>
          _i1055.CreatePrivateGroupUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.lazySingleton<_i1055.SendPrivateGroupMessageUsecase>(
      () => _i1055.SendPrivateGroupMessageUsecase(
        gh<_i761.MarmotTransportService>(),
      ),
    );
    gh.lazySingleton<_i1055.JoinPrivateGroupUsecase>(
      () => _i1055.JoinPrivateGroupUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.lazySingleton<_i1055.ApprovePrivateGroupJoinUsecase>(
      () => _i1055.ApprovePrivateGroupJoinUsecase(
        gh<_i761.MarmotTransportService>(),
      ),
    );
    gh.lazySingleton<_i1055.LeavePrivateGroupUsecase>(
      () => _i1055.LeavePrivateGroupUsecase(gh<_i761.MarmotTransportService>()),
    );
    gh.factory<_i47.NoteRepository>(
      () => _i348.NoteRepositoryImpl(
        isar: gh<_i214.Isar>(),
        relations: gh<_i1017.NoteRelationRepository>(),
        resolver: gh<_i789.NoteResolverRepository>(),
      ),
    );
    gh.lazySingleton<_i475.GetFeedUseCase>(
      () => _i475.GetFeedUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetNoteByIdUseCase>(
      () => _i475.GetNoteByIdUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetRepliesUseCase>(
      () => _i475.GetRepliesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.SaveNoteUseCase>(
      () => _i475.SaveNoteUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadUseCase>(
      () => _i475.GetThreadUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i850.EmbeddingModelDownloader>(
      () => _i850.EmbeddingModelDownloader(
        gh<_i93.FlutterGemmaGateway>(),
        gh<_i587.EmbeddingService>(),
      ),
    );
    gh.lazySingleton<_i141.RemoteLlmDataSource>(
      () => _i141.RemoteLlmDataSource(
        gh<_i880.UniunRepository>(),
        gh<_i634.LlmPreferencesDataSource>(),
      ),
    );
    gh.lazySingleton<_i629.PublishMediaNoteUseCase>(
      () => _i629.PublishMediaNoteUseCase(
        gh<_i47.NoteRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i1026.DocumentIndexer>(
      () => _i1026.DocumentIndexer(
        gh<_i214.Isar>(),
        gh<_i139.DocumentExtractionService>(),
        gh<_i756.EmbedAndStoreChunkUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
      ),
    );
    gh.lazySingleton<_i303.DeleteSurroundingNoteUseCase>(
      () => _i303.DeleteSurroundingNoteUseCase(
        gh<_i956.SurroundingNoteRepository>(),
      ),
    );
    gh.factory<_i60.DmChatBloc>(
      () => _i60.DmChatBloc(
        gh<_i1023.FetchDmUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i1023.GetDmUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i799.GetActiveUserProfileUseCase>(),
        gh<_i719.MarkUnreadSeenUseCase>(),
        gh<_i719.MarkConversationSeenUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.lazySingleton<_i651.ManasContextLoader>(
      () => _i651.ManasContextLoader(
        gh<_i214.Isar>(),
        gh<_i587.EmbeddingService>(),
        gh<_i961.VectorSearchService>(),
      ),
    );
    gh.lazySingleton<_i63.FollowUserUseCase>(
      () => _i63.FollowUserUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.FollowUsersUseCase>(
      () => _i63.FollowUsersUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.UnfollowUserUseCase>(
      () => _i63.UnfollowUserUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.IsFollowingUseCase>(
      () => _i63.IsFollowingUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.GetFollowedUsersUseCase>(
      () => _i63.GetFollowedUsersUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.GetFollowedPubkeysUseCase>(
      () => _i63.GetFollowedPubkeysUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i63.WatchFollowedUsersUseCase>(
      () => _i63.WatchFollowedUsersUseCase(gh<_i849.FollowedUserRepository>()),
    );
    gh.lazySingleton<_i894.GetAvailableAIModelsUseCase>(
      () => _i894.GetAvailableAIModelsUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.GetActiveAIModelUseCase>(
      () => _i894.GetActiveAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.DownloadAndActivateAIModelUseCase>(
      () => _i894.DownloadAndActivateAIModelUseCase(
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.lazySingleton<_i894.ClearActiveAIModelUseCase>(
      () => _i894.ClearActiveAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.GetDownloadedModelIdsUseCase>(
      () => _i894.GetDownloadedModelIdsUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.DeleteAIModelUseCase>(
      () => _i894.DeleteAIModelUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i894.GetOrphanedModelFilesSizeBytesUseCase>(
      () => _i894.GetOrphanedModelFilesSizeBytesUseCase(
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.lazySingleton<_i894.CleanupOrphanedModelFilesUseCase>(
      () =>
          _i894.CleanupOrphanedModelFilesUseCase(gh<_i646.AIModelRepository>()),
    );
    gh.lazySingleton<_i890.CreateGroupUseCase>(
      () => _i890.CreateGroupUseCase(
        gh<_i582.GroupRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.factory<_i437.ManasListBloc>(
      () => _i437.ManasListBloc(
        gh<_i977.GetManasListUseCase>(),
        gh<_i977.DeleteManasUseCase>(),
      ),
    );
    gh.lazySingleton<_i907.GetNatarajCoachSeenUseCase>(
      () => _i907.GetNatarajCoachSeenUseCase(gh<_i117.AppSettingsRepository>()),
    );
    gh.lazySingleton<_i907.SetNatarajCoachSeenUseCase>(
      () => _i907.SetNatarajCoachSeenUseCase(gh<_i117.AppSettingsRepository>()),
    );
    gh.lazySingleton<_i907.GetAutoDeleteOldNotesDaysUseCase>(
      () => _i907.GetAutoDeleteOldNotesDaysUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i907.SetAutoDeleteOldNotesDaysUseCase>(
      () => _i907.SetAutoDeleteOldNotesDaysUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i907.GetRecentSyncWindowDaysUseCase>(
      () => _i907.GetRecentSyncWindowDaysUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i907.SetRecentSyncWindowDaysUseCase>(
      () => _i907.SetRecentSyncWindowDaysUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i907.SetAppLocaleUseCase>(
      () => _i907.SetAppLocaleUseCase(gh<_i117.AppSettingsRepository>()),
    );
    gh.lazySingleton<_i907.SetThemeModeUseCase>(
      () => _i907.SetThemeModeUseCase(gh<_i117.AppSettingsRepository>()),
    );
    gh.lazySingleton<_i907.GetTranslationLanguageUseCase>(
      () => _i907.GetTranslationLanguageUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i907.SetTranslationLanguageUseCase>(
      () => _i907.SetTranslationLanguageUseCase(
        gh<_i117.AppSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i858.UnsaveNoteUseCase>(
      () => _i858.UnsaveNoteUseCase(
        gh<_i43.SavedNoteRepository>(),
        gh<_i179.DeleteKnowledgeForNoteUseCase>(),
      ),
    );
    gh.factory<_i942.GanaFormBloc>(
      () => _i942.GanaFormBloc(
        gh<_i219.UpsertGanaUseCase>(),
        gh<_i219.GetGanaByIdUseCase>(),
        gh<_i219.DeleteGanaUseCase>(),
        gh<_i977.GetManasListUseCase>(),
        gh<_i879.GetGroupsUseCase>(),
        gh<_i1055.GetPrivateGroupsUsecase>(),
        gh<_i1023.GetDmConversationsUseCase>(),
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
      ),
    );
    gh.factory<_i859.EditProfileCubit>(
      () => _i859.EditProfileCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i391.SaveProfileUseCase>(),
        gh<_i391.PublishProfileMetadataUseCase>(),
      ),
    );
    gh.lazySingleton<_i937.LocalLlmDataSource>(
      () => _i937.LocalLlmDataSource(
        gh<_i937.AIModelRunner>(),
        gh<_i552.InferenceScheduler>(),
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.factory<_i399.CreateDmBloc>(
      () => _i399.CreateDmBloc(
        gh<_i993.RelayRepository>(),
        gh<_i1023.CreateDmConversationUseCase>(),
      ),
    );
    gh.factory<_i683.MediaRepository>(
      () => _i980.MediaRepositoryImpl(
        isar: gh<_i214.Isar>(),
        blossom: gh<_i706.BlossomClient>(),
        cache: gh<_i366.MediaCacheDataSource>(),
        serverList: gh<_i930.UserServerListRepository>(),
        getActiveUserKeys: gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i475.PublishNoteUseCase>(
      () => _i475.PublishNoteUseCase(
        gh<_i47.NoteRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i475.GetReplyCountUseCase>(
      () => _i475.GetReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadReplyCountUseCase>(
      () => _i475.GetThreadReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetOwnNotesUseCase>(
      () => _i475.GetOwnNotesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.SearchNotesUseCase>(
      () => _i475.SearchNotesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.factory<_i985.CreatePrivateGroupBloc>(
      () => _i985.CreatePrivateGroupBloc(
        gh<_i1055.CreatePrivateGroupUsecase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i858.ResolveNotesByIdsUseCase>(
      () => _i858.ResolveNotesByIdsUseCase(
        gh<_i789.NoteResolverRepository>(),
        gh<_i43.SavedNoteRepository>(),
      ),
    );
    gh.factory<_i734.ReferencePickerCubit>(
      () => _i734.ReferencePickerCubit(
        gh<_i475.GetFeedUseCase>(),
        gh<_i475.SearchNotesUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factoryParam<_i548.PrivateGroupDetailBloc, String, dynamic>(
      (groupId, _) => _i548.PrivateGroupDetailBloc(
        gh<_i1055.GetPrivateGroupEntityUsecase>(),
        gh<_i1055.GetPrivateGroupMessagesUsecase>(),
        gh<_i1055.GetPrivateGroupJoinRequestsUsecase>(),
        gh<_i1055.SendPrivateGroupMessageUsecase>(),
        gh<_i1055.ApprovePrivateGroupJoinUsecase>(),
        gh<_i1055.LeavePrivateGroupUsecase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i719.MarkUnreadSeenUseCase>(),
        gh<_i719.MarkPrivateGroupSeenUseCase>(),
        groupId,
      ),
    );
    gh.factory<_i666.DrawerBloc>(
      () => _i666.DrawerBloc(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i879.GetGroupsUseCase>(),
        gh<_i1055.GetPrivateGroupsUsecase>(),
        gh<_i63.GetFollowedUsersUseCase>(),
        gh<_i985.GetRelaysUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
        gh<_i733.DrawerDataSource>(),
      ),
    );
    gh.factory<_i968.CreateGroupBloc>(
      () => _i968.CreateGroupBloc(
        gh<_i985.GetRelaysUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i890.CreateGroupUseCase>(),
      ),
    );
    gh.factory<_i205.LlmRepository>(
      () => _i19.LlmRepositoryImpl(
        gh<_i937.LocalLlmDataSource>(),
        gh<_i141.RemoteLlmDataSource>(),
        gh<_i634.LlmPreferencesDataSource>(),
        gh<_i880.UniunRepository>(),
        gh<_i107.AppSettingsStore>(),
        gh<_i646.AIModelRepository>(),
      ),
    );
    gh.lazySingleton<_i932.GetGroupMessagesUseCase>(
      () => _i932.GetGroupMessagesUseCase(gh<_i546.GroupMessageRepository>()),
    );
    gh.lazySingleton<_i932.GetGroupMessagesAfterUseCase>(
      () => _i932.GetGroupMessagesAfterUseCase(
        gh<_i546.GroupMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i932.GetGroupMessageByIdUseCase>(
      () =>
          _i932.GetGroupMessageByIdUseCase(gh<_i546.GroupMessageRepository>()),
    );
    gh.lazySingleton<_i932.GetGroupMessageRepliesUseCase>(
      () => _i932.GetGroupMessageRepliesUseCase(
        gh<_i546.GroupMessageRepository>(),
      ),
    );
    gh.lazySingleton<_i932.GetGroupMessageReplyCountUseCase>(
      () => _i932.GetGroupMessageReplyCountUseCase(
        gh<_i546.GroupMessageRepository>(),
      ),
    );
    gh.factory<_i174.GanaListBloc>(
      () => _i174.GanaListBloc(
        gh<_i219.GetGanasUseCase>(),
        gh<_i219.GetGanaRunsUseCase>(),
        gh<_i219.SetGanaEnabledUseCase>(),
        gh<_i219.DeleteGanaUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.factory<_i425.JoinPrivateGroupBloc>(
      () => _i425.JoinPrivateGroupBloc(
        gh<_i1055.JoinPrivateGroupUsecase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.lazySingleton<_i837.GetOrInitFeedLoadedAtUseCase>(
      () => _i837.GetOrInitFeedLoadedAtUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.SetFeedLoadedAtUseCase>(
      () => _i837.SetFeedLoadedAtUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.GetUnreadPageUseCase>(
      () => _i837.GetUnreadPageUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.GetSeenPageUseCase>(
      () => _i837.GetSeenPageUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.WatchNewBufferCountUseCase>(
      () => _i837.WatchNewBufferCountUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i837.MarkFeedItemSeenUseCase>(
      () => _i837.MarkFeedItemSeenUseCase(gh<_i250.FeedRepository>()),
    );
    gh.lazySingleton<_i815.CreateGroupMessageUseCase>(
      () => _i815.CreateGroupMessageUseCase(
        gh<_i546.GroupMessageRepository>(),
        gh<_i1039.EventQueueRepository>(),
      ),
    );
    gh.factory<_i959.UserProfileBloc>(
      () => _i959.UserProfileBloc(
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i63.IsFollowingUseCase>(),
        gh<_i63.FollowUserUseCase>(),
        gh<_i63.UnfollowUserUseCase>(),
        gh<_i391.WatchProfileUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
      ),
    );
    gh.factory<_i13.StorageCubit>(
      () => _i13.StorageCubit(
        gh<_i58.GetStorageStatsUseCase>(),
        gh<_i58.DeleteFeedNotesUseCase>(),
        gh<_i58.DeleteAllChatHistoryUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i907.GetAutoDeleteOldNotesDaysUseCase>(),
        gh<_i907.SetAutoDeleteOldNotesDaysUseCase>(),
        gh<_i907.GetRecentSyncWindowDaysUseCase>(),
        gh<_i907.SetRecentSyncWindowDaysUseCase>(),
      ),
    );
    gh.factory<_i630.ManasFormBloc>(
      () => _i630.ManasFormBloc(
        gh<_i977.UpsertManasUseCase>(),
        gh<_i977.GetManasByIdUseCase>(),
        gh<_i977.DeleteManasUseCase>(),
        gh<_i977.AddNoteToManasUseCase>(),
        gh<_i977.RemoveNoteFromManasUseCase>(),
        gh<_i977.GetNoteIdsForManasUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
      ),
    );
    gh.lazySingleton<_i629.UploadMediaUseCase>(
      () => _i629.UploadMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.lazySingleton<_i629.SaveLocalMediaUseCase>(
      () => _i629.SaveLocalMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.lazySingleton<_i629.ReadLocalMediaUseCase>(
      () => _i629.ReadLocalMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.lazySingleton<_i629.DownloadMediaUseCase>(
      () => _i629.DownloadMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.lazySingleton<_i629.WatchMediaUseCase>(
      () => _i629.WatchMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.lazySingleton<_i629.RemoveLocalMediaUseCase>(
      () => _i629.RemoveLocalMediaUseCase(gh<_i683.MediaRepository>()),
    );
    gh.factory<_i830.GraphBloc>(
      () => _i830.GraphBloc(
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i475.GetOwnNotesUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i799.GetActiveUserProfileUseCase>(),
        gh<_i537.DeleteDraftUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i977.GetNoteIdsForManasUseCase>(),
        gh<_i977.GetManasByIdUseCase>(),
        gh<_i475.GetNoteRelationCountsUseCase>(),
        gh<_i214.Isar>(),
      ),
    );
    gh.lazySingleton<_i918.HasActiveLlmModelUseCase>(
      () => _i918.HasActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.OpenLlmConversationUseCase>(
      () => _i918.OpenLlmConversationUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.CloseLlmConversationUseCase>(
      () => _i918.CloseLlmConversationUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SendChatStreamUseCase>(
      () => _i918.SendChatStreamUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GenerateOneShotUseCase>(
      () => _i918.GenerateOneShotUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.PreemptBackgroundWorkUseCase>(
      () => _i918.PreemptBackgroundWorkUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.ResumeBackgroundWorkUseCase>(
      () => _i918.ResumeBackgroundWorkUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GetActiveLlmBackendUseCase>(
      () => _i918.GetActiveLlmBackendUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SetActiveLlmBackendUseCase>(
      () => _i918.SetActiveLlmBackendUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.ListAvailableLlmModelsUseCase>(
      () => _i918.ListAvailableLlmModelsUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.ListCloudLlmModelsUseCase>(
      () => _i918.ListCloudLlmModelsUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.SetActiveLlmModelUseCase>(
      () => _i918.SetActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.GetActiveLlmModelUseCase>(
      () => _i918.GetActiveLlmModelUseCase(gh<_i205.LlmRepository>()),
    );
    gh.lazySingleton<_i918.TranslateNoteUseCase>(
      () => _i918.TranslateNoteUseCase(gh<_i205.LlmRepository>()),
    );
    gh.factory<_i526.ComposerChatCubit>(
      () => _i526.ComposerChatCubit(
        gh<_i918.SendChatStreamUseCase>(),
        gh<_i651.ManasContextLoader>(),
        gh<_i918.HasActiveLlmModelUseCase>(),
      ),
    );
    gh.factory<_i1019.ShareRepository>(
      () => _i593.ShareRepositoryImpl(
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i629.PublishMediaNoteUseCase>(),
        gh<_i815.CreateGroupMessageUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i1055.SendPrivateGroupMessageUsecase>(),
      ),
    );
    gh.factory<_i687.SelectAIModelCubit>(
      () => _i687.SelectAIModelCubit(
        gh<_i894.GetAvailableAIModelsUseCase>(),
        gh<_i894.GetActiveAIModelUseCase>(),
        gh<_i894.GetDownloadedModelIdsUseCase>(),
        gh<_i894.DownloadAndActivateAIModelUseCase>(),
        gh<_i894.DeleteAIModelUseCase>(),
        gh<_i850.EmbeddingModelDownloader>(),
        gh<_i918.ConnectUniunCloudUseCase>(),
        gh<_i918.IsUniunCloudConnectedUseCase>(),
        gh<_i918.ListCloudLlmModelsUseCase>(),
        gh<_i918.SetActiveLlmBackendUseCase>(),
        gh<_i918.SetActiveLlmModelUseCase>(),
        gh<_i918.GetActiveLlmModelUseCase>(),
        gh<_i918.GetActiveLlmBackendUseCase>(),
        gh<_i894.GetOrphanedModelFilesSizeBytesUseCase>(),
        gh<_i894.CleanupOrphanedModelFilesUseCase>(),
      ),
    );
    gh.factory<_i269.ChatImageSupportCubit>(
      () => _i269.ChatImageSupportCubit(gh<_i918.GetActiveLlmModelUseCase>()),
    );
    gh.lazySingleton<_i1.ShareNoteUseCase>(
      () => _i1.ShareNoteUseCase(gh<_i1019.ShareRepository>()),
    );
    gh.lazySingleton<_i638.NatarajGenerator>(
      () => _i638.NatarajGenerator(
        gh<_i214.Isar>(),
        gh<_i125.NatarajRepository>(),
        gh<_i918.GenerateOneShotUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i939.ReceiveShareBloc>(
      () => _i939.ReceiveShareBloc(
        gh<_i879.GetGroupsUseCase>(),
        gh<_i1055.GetPrivateGroupsUsecase>(),
        gh<_i1023.GetDmConversationsUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i629.UploadMediaUseCase>(),
        gh<_i629.SaveLocalMediaUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i629.PublishMediaNoteUseCase>(),
        gh<_i815.CreateGroupMessageUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i1055.SendPrivateGroupMessageUsecase>(),
        gh<_i537.SaveDraftUseCase>(),
      ),
    );
    gh.factory<_i574.ShareSheetBloc>(
      () => _i574.ShareSheetBloc(
        gh<_i879.GetGroupsUseCase>(),
        gh<_i1055.GetPrivateGroupsUsecase>(),
        gh<_i1023.GetDmConversationsUseCase>(),
        gh<_i1.ShareNoteUseCase>(),
        gh<_i629.UploadMediaUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
      ),
    );
    gh.lazySingleton<_i858.SaveNoteUseCase>(
      () => _i858.SaveNoteUseCase(
        gh<_i43.SavedNoteRepository>(),
        gh<_i629.DownloadMediaUseCase>(),
      ),
    );
    gh.factory<_i395.NatarajBloc>(
      () => _i395.NatarajBloc(
        gh<_i638.NatarajGenerator>(),
        gh<_i812.GetNextNatarajCardUseCase>(),
        gh<_i812.RecordNatarajSwipeUseCase>(),
        gh<_i977.GetManasListUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i537.SaveDraftUseCase>(),
      ),
    );
    gh.lazySingleton<_i681.RagPipeline>(
      () => _i681.RagPipeline(
        gh<_i587.EmbeddingService>(),
        gh<_i961.VectorSearchService>(),
        gh<_i207.PromptBuilder>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i179.GetMemoriesByNoteIdsUseCase>(),
        gh<_i179.GetGraphNeighboursUseCase>(),
        gh<_i179.GetGraphNodesByKeysUseCase>(),
        gh<_i918.GetActiveLlmModelUseCase>(),
        gh<_i651.ManasContextLoader>(),
      ),
    );
    gh.lazySingleton<_i179.ExtractKnowledgeUseCase>(
      () => _i179.ExtractKnowledgeUseCase(
        gh<_i918.HasActiveLlmModelUseCase>(),
        gh<_i918.GenerateOneShotUseCase>(),
        gh<_i207.PromptBuilder>(),
        gh<_i756.SearchVectorNotesUseCase>(),
        gh<_i649.GraphRepository>(),
        gh<_i331.MemoryRepository>(),
        gh<_i1000.PendingExtractionRepository>(),
      ),
    );
    gh.lazySingleton<_i756.EmbedAndStoreNoteUseCase>(
      () => _i756.EmbedAndStoreNoteUseCase(
        gh<_i587.EmbeddingService>(),
        gh<_i739.VectorRepository>(),
        gh<_i179.ExtractKnowledgeUseCase>(),
      ),
    );
    gh.factory<_i1039.VishnuFeedBloc>(
      () => _i1039.VishnuFeedBloc(
        gh<_i837.GetOrInitFeedLoadedAtUseCase>(),
        gh<_i837.SetFeedLoadedAtUseCase>(),
        gh<_i837.GetUnreadPageUseCase>(),
        gh<_i837.GetSeenPageUseCase>(),
        gh<_i837.WatchNewBufferCountUseCase>(),
        gh<_i837.MarkFeedItemSeenUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i63.WatchFollowedUsersUseCase>(),
      ),
    );
    gh.lazySingleton<_i179.DrainPendingExtractionsUseCase>(
      () => _i179.DrainPendingExtractionsUseCase(
        gh<_i1000.PendingExtractionRepository>(),
        gh<_i179.ExtractKnowledgeUseCase>(),
      ),
    );
    gh.lazySingleton<_i426.GanaEngine>(
      () => _i426.GanaEngine(
        gh<_i214.Isar>(),
        gh<_i937.AIModelRunner>(),
        gh<_i107.AppSettingsStore>(),
        gh<_i103.UserRepository>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i815.CreateGroupMessageUseCase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i1055.SendPrivateGroupMessageUsecase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i651.ManasContextLoader>(),
        gh<_i558.MeshEventSigner>(),
        gh<_i918.GenerateOneShotUseCase>(),
        gh<_i918.IsUniunCloudConnectedUseCase>(),
        gh<_i918.GetActiveLlmModelUseCase>(),
        gh<_i93.FlutterGemmaGateway>(),
      ),
    );
    gh.factoryParam<_i226.NoteCardCubit, _i697.NoteEntity, dynamic>(
      (note, _) => _i226.NoteCardCubit(
        gh<_i391.WatchProfileUseCase>(),
        gh<_i391.RequestProfileFetchUseCase>(),
        gh<_i858.IsSavedNoteUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i561.WatchIsFollowedUseCase>(),
        gh<_i561.FollowNoteUseCase>(),
        gh<_i561.UnfollowNoteUseCase>(),
        gh<_i278.BlockUserUseCase>(),
        gh<_i232.DeleteNoteUseCase>(),
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i977.GetManasIdsForNoteUseCase>(),
        gh<_i977.GetManasListUseCase>(),
        gh<_i977.RemoveNoteFromManasUseCase>(),
        gh<_i918.TranslateNoteUseCase>(),
        note,
      ),
    );
    gh.factory<_i886.BrahmaCreateBloc>(
      () => _i886.BrahmaCreateBloc(
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i629.PublishMediaNoteUseCase>(),
        gh<_i629.UploadMediaUseCase>(),
        gh<_i629.SaveLocalMediaUseCase>(),
        gh<_i629.ReadLocalMediaUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
        gh<_i537.SaveDraftUseCase>(),
        gh<_i537.GetDraftsUseCase>(),
        gh<_i537.GetDraftByIdUseCase>(),
        gh<_i537.DeleteDraftUseCase>(),
        gh<_i537.MarkDraftPublishedUseCase>(),
        gh<_i475.SearchNotesUseCase>(),
        gh<_i475.GetNoteByIdUseCase>(),
      ),
    );
    gh.lazySingleton<_i924.PostReplyUseCase>(
      () => _i924.PostReplyUseCase(
        gh<_i475.PublishNoteUseCase>(),
        gh<_i629.PublishMediaNoteUseCase>(),
        gh<_i815.CreateGroupMessageUseCase>(),
        gh<_i1055.SendPrivateGroupMessageUsecase>(),
        gh<_i1023.SendDmUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i756.EmbedAndStoreNoteUseCase>(),
      ),
    );
    gh.factory<_i190.ShivAIBloc>(
      () => _i190.ShivAIBloc(
        gh<_i604.GetConversationsUseCase>(),
        gh<_i604.WatchConversationsUseCase>(),
        gh<_i604.CreateConversationUseCase>(),
        gh<_i604.DeleteConversationUseCase>(),
        gh<_i604.GetMessagesUseCase>(),
        gh<_i604.SaveMessageUseCase>(),
        gh<_i604.UpdateMessageContentUseCase>(),
        gh<_i604.UpdateConversationTitleUseCase>(),
        gh<_i604.UpdateActiveLeafUseCase>(),
        gh<_i918.HasActiveLlmModelUseCase>(),
        gh<_i918.OpenLlmConversationUseCase>(),
        gh<_i918.CloseLlmConversationUseCase>(),
        gh<_i918.SendChatStreamUseCase>(),
        gh<_i918.PreemptBackgroundWorkUseCase>(),
        gh<_i918.ResumeBackgroundWorkUseCase>(),
        gh<_i681.RagPipeline>(),
        gh<_i179.DrainPendingExtractionsUseCase>(),
      ),
    );
    gh.factory<_i807.ThreadBloc>(
      () => _i807.ThreadBloc(
        gh<_i789.NoteResolverRepository>(),
        gh<_i924.PostReplyUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.GetSavedRepliesUseCase>(),
        gh<_i858.GetSavedReferencesUseCase>(),
      ),
    );
    return this;
  }
}

class _$SharedPreferencesModule extends _i107.SharedPreferencesModule {}

class _$IsarModule extends _i146.IsarModule {}

class _$TostoreModule extends _i740.TostoreModule {}
