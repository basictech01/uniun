import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/feed_read_state_store.dart';
import 'package:uniun/data/datasources/llm/llm_credentials_data_source.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/data/datasources/media_cache_data_source.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:uniun/domain/repositories/logout_session_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/services/logout_runtime.dart';
import 'package:uniun/domain/services/marmot_mls_service.dart';

/// Clears all state tied to one identity while preserving device-wide settings.
@Injectable(as: LogoutSessionRepository)
class LogoutSessionRepositoryImpl implements LogoutSessionRepository {
  LogoutSessionRepositoryImpl(
    this._isar,
    this._models,
    this._uniun,
    this._credentials,
    this._llmPreferences,
    this._settings,
    this._servers,
    this._feedRead,
    this._surroundingRead,
    this._media,
    this._vectors,
    this._mls,
    this._runtime,
  );

  final Isar _isar;
  final AIModelRepository _models;
  final UniunRepository _uniun;
  final LlmCredentialsDataSource _credentials;
  final LlmPreferencesDataSource _llmPreferences;
  final AppSettingsStore _settings;
  final UserServerListStore _servers;
  final FeedReadStateStore _feedRead;
  final SurroundingReadStateStore _surroundingRead;
  final MediaCacheDataSource _media;
  final NoteVectorStore _vectors;
  final MarmotMlsService _mls;
  final LogoutRuntime _runtime;

  @override
  Future<Either<Failure, Unit>> clear({required bool keepModelFiles}) async {
    try {
      await _clear(keepModelFiles: keepModelFiles);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  Future<void> _clear({required bool keepModelFiles}) async {
    await _runtime.stop();

    // Local credentials must go even if the remote gateway is unreachable.
    await _uniun.disconnect(confirm: true);
    await _credentials.clearUniunApiKey();
    await _credentials.clearUniunKeyId();

    if (!keepModelFiles) {
      for (final id in await _models.getDownloadedModelIds()) {
        final result = await _models.deleteModel(id);
        if (result.isLeft()) {
          throw StateError('Could not remove downloaded model $id');
        }
      }
      final orphaned = await _models.cleanupOrphanedModelFiles();
      if (orphaned.isLeft()) {
        throw StateError('Could not remove partial model downloads');
      }
    }

    await _mls.resetForLogout();
    await _vectors.clear();
    await _isar.writeTxn(() => _isar.clear());
    await _media.clear();
    await _servers.clear();
    await _feedRead.clear();
    await _surroundingRead.clear();
    await _llmPreferences.clear();
    await _settings.clearAccountChoices();
  }
}
