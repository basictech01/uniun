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
import 'package:uniun/data/datasources/isar_module.dart' as _i146;
import 'package:uniun/data/repositories/note_repository_impl.dart' as _i348;
import 'package:uniun/data/repositories/profile_repository_impl.dart' as _i484;
import 'package:uniun/data/repositories/user_repository_impl.dart' as _i582;
import 'package:uniun/domain/repositories/note_repository.dart' as _i47;
import 'package:uniun/domain/repositories/profile_repository.dart' as _i967;
import 'package:uniun/domain/repositories/user_repository.dart' as _i103;
import 'package:uniun/domain/usecases/get_feed_usecase.dart' as _i666;
import 'package:uniun/domain/usecases/get_note_by_id_usecase.dart' as _i1024;
import 'package:uniun/domain/usecases/get_replies_usecase.dart' as _i22;
import 'package:uniun/domain/usecases/mark_seen_usecase.dart' as _i871;
import 'package:uniun/domain/usecases/save_note_usecase.dart' as _i955;
import 'package:uniun/drawer/bloc/drawer_bloc.dart' as _i987;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final isarModule = _$IsarModule();
    gh.factory<_i987.DrawerBloc>(() => _i987.DrawerBloc());
    await gh.singletonAsync<_i214.Isar>(
      () => isarModule.createIsar(),
      preResolve: true,
    );
    gh.factory<_i47.NoteRepository>(
      () => _i348.NoteRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i967.ProfileRepository>(
      () => _i484.ProfileRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.factory<_i103.UserRepository>(
      () => _i582.UserRepositoryImpl(isar: gh<_i214.Isar>()),
    );
    gh.lazySingleton<_i666.GetFeedUseCase>(
      () => _i666.GetFeedUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i1024.GetNoteByIdUseCase>(
      () => _i1024.GetNoteByIdUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i22.GetRepliesUseCase>(
      () => _i22.GetRepliesUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i871.MarkSeenUseCase>(
      () => _i871.MarkSeenUseCase(gh<_i47.NoteRepository>()),
    );
    gh.lazySingleton<_i955.SaveNoteUseCase>(
      () => _i955.SaveNoteUseCase(gh<_i47.NoteRepository>()),
    );
    return this;
  }
}

class _$IsarModule extends _i146.IsarModule {}
