import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';

/// Persists the user's choice of active LLM backend + currently-picked
/// cloud model id. Local model selection still lives in [AppSettingsStore]
/// to keep model-file management self-contained.
@singleton
class LlmPreferencesDataSource {
  static const _kActiveBackend = 'llm.active_backend';
  static const _kActiveCloudModelId = 'llm.active_cloud_model_id';

  final SharedPreferences _prefs;

  LlmPreferencesDataSource(this._prefs);

  LlmBackendType get activeBackend {
    final raw = _prefs.getString(_kActiveBackend);
    return LlmBackendType.fromName(raw) ?? LlmBackendType.localGemma;
  }

  Future<void> setActiveBackend(LlmBackendType backend) =>
      _prefs.setString(_kActiveBackend, backend.name);

  String? get activeCloudModelId => _prefs.getString(_kActiveCloudModelId);

  Future<void> setActiveCloudModelId(String? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveCloudModelId);
    } else {
      await _prefs.setString(_kActiveCloudModelId, id);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kActiveBackend);
    await _prefs.remove(_kActiveCloudModelId);
  }
}
