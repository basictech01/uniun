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
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart' as _i787;
import 'package:uniun/core/isolate/embedded_server_bridge.dart' as _i717;
import 'package:uniun/data/datasources/isar_module.dart' as _i146;
import 'package:uniun/data/repositories/ai_model_repository_impl.dart' as _i72;
import 'package:uniun/data/repositories/followed_note_repository_impl.dart'
    as _i107;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i348;
import 'package:uniun/data/repositories/outbound_event_repository_impl.dart'
    as _i694;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/saved_note_repository_impl.dart'
    as _i669;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;
import 'package:uniun/domain/repositories/ai_model_repository.dart' as _i646;
import 'package:uniun/domain/repositories/followed_note_repository.dart'
    as _i836;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/outbound_event_repository.dart'
    as _i218;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/saved_note_repository.dart' as _i43;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;
import 'package:uniun/domain/usecases/ai_model_usecases.dart' as _i894;
import 'package:uniun/domain/usecases/followed_note_usecases.dart' as _i561;
import 'package:uniun/domain/usecases/note_usecases.dart' as _i475;
import 'package:uniun/domain/usecases/profile_usecases.dart' as _i391;
import 'package:uniun/domain/usecases/saved_note_usecases.dart' as _i858;
import 'package:uniun/domain/usecases/user_usecases.dart' as _i799;
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart' as _i97;
import 'package:uniun/followed_notes/followed_note_detail/cubit/followed_note_detail_cubit.dart'
    as _i464;
import 'package:uniun/home/bloc/drawer_bloc.dart' as _i111;
import 'package:uniun/settings/cubit/edit_profile_cubit.dart' as _i195;
import 'package:uniun/settings/cubit/settings_cubit.dart' as _i731;
import 'package:uniun/shiv/model_select/cubit/select_ai_model_cubit.dart'
    as _i53;
import 'package:uniun/thread/bloc/thread_bloc.dart' as _i118;
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart' as _i558;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final isarModule = _$IsarModule();
    gh.singleton<_i717.EmbeddedServerBridge>(
      () => _i717.EmbeddedServerBridge(),
    );
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );
    gh.factory<_i646.AIModelRepository>(
      () => _i72.AIModelRepositoryImpl(gh<_i214.Isar>()),
    );
    gh.factory<_i47.NoteRepository>(
      () => _i348.NoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i836.FollowedNoteRepository>(
      () => _i107.FollowedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i218.OutboundEventRepository>(
      () => _i694.OutboundEventRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i43.SavedNoteRepository>(
      () => _i669.SavedNoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
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
    gh.lazySingleton<_i561.ClearNewReferencesUseCase>(
      () => _i561.ClearNewReferencesUseCase(gh<_i836.FollowedNoteRepository>()),
    );
    gh.lazySingleton<_i475.PublishNoteUseCase>(
      () => _i475.PublishNoteUseCase(
        gh<_i47.NoteRepository>(),
        gh<_i218.OutboundEventRepository>(),
        gh<_i717.EmbeddedServerBridge>(),
      ),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(isar: gh<_i214.Isar>()),
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
    gh.lazySingleton<_i858.SaveNoteUseCase>(
      () => _i858.SaveNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.UnsaveNoteUseCase>(
      () => _i858.UnsaveNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.IsSavedNoteUseCase>(
      () => _i858.IsSavedNoteUseCase(gh<_i43.SavedNoteRepository>()),
    );
    gh.lazySingleton<_i858.GetAllSavedNotesUseCase>(
      () => _i858.GetAllSavedNotesUseCase(gh<_i43.SavedNoteRepository>()),
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
    gh.lazySingleton<_i475.MarkSeenUseCase>(
      () => _i475.MarkSeenUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadUseCase>(
      () => _i475.GetThreadUseCase(gh<_i47.NoteRepository>()),
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
    gh.factory<_i787.BrahmaCreateBloc>(
      () => _i787.BrahmaCreateBloc(
        gh<_i799.GetActiveUserKeysUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
      ),
    );
    gh.factory<_i464.FollowedNoteDetailCubit>(
      () => _i464.FollowedNoteDetailCubit(
        gh<_i475.GetNoteByIdUseCase>(),
        gh<_i475.GetRepliesUseCase>(),
        gh<_i391.GetProfileUseCase>(),
      ),
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
    gh.lazySingleton<_i475.GetReplyCountUseCase>(
      () => _i475.GetReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i475.GetThreadReplyCountUseCase>(
      () => _i475.GetThreadReplyCountUseCase(gh<_i47.NoteRepository>()),
    );
    gh.factory<_i97.FollowedNotesCubit>(
      () => _i97.FollowedNotesCubit(
        gh<_i561.GetAllFollowedNotesUseCase>(),
        gh<_i561.FollowNoteUseCase>(),
        gh<_i561.UnfollowNoteUseCase>(),
        gh<_i561.ClearNewReferencesUseCase>(),
      ),
    );
    gh.factory<_i195.EditProfileCubit>(
      () => _i195.EditProfileCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i391.SaveProfileUseCase>(),
      ),
    );
    gh.factory<_i731.SettingsCubit>(
      () => _i731.SettingsCubit(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
      ),
    );
    gh.lazySingleton<_i799.GetActiveUserProfileUseCase>(
      () => _i799.GetActiveUserProfileUseCase(
        gh<_i103.UserRepository>(),
        gh<_i967.ProfileRepository>(),
      ),
    );
    gh.factory<_i53.SelectAIModelCubit>(
      () => _i53.SelectAIModelCubit(
        gh<_i894.GetAvailableAIModelsUseCase>(),
        gh<_i894.GetActiveAIModelUseCase>(),
        gh<_i894.DownloadAndActivateAIModelUseCase>(),
      ),
    );
    gh.factory<_i111.DrawerBloc>(
      () => _i111.DrawerBloc(
        gh<_i799.GetActiveUserUseCase>(),
        gh<_i391.GetOwnProfileUseCase>(),
        gh<_i561.GetAllFollowedNotesUseCase>(),
      ),
    );
    gh.factory<_i118.ThreadBloc>(
      () => _i118.ThreadBloc(
        gh<_i475.GetNoteByIdUseCase>(),
        gh<_i475.GetRepliesUseCase>(),
        gh<_i475.PublishNoteUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i475.GetReplyCountUseCase>(),
        gh<_i799.GetActiveUserKeysUseCase>(),
      ),
    );
    gh.factory<_i558.VishnuFeedBloc>(
      () => _i558.VishnuFeedBloc(
        gh<_i475.GetFeedUseCase>(),
        gh<_i391.GetProfileUseCase>(),
        gh<_i475.GetThreadReplyCountUseCase>(),
        gh<_i858.GetAllSavedNotesUseCase>(),
        gh<_i858.SaveNoteUseCase>(),
        gh<_i858.UnsaveNoteUseCase>(),
      ),
    );
    return this;
  }
}

class _$IsarModule extends _i146.IsarModule {}
