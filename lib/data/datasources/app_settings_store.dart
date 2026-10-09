import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniun/core/theme/app_theme_mode.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

@module
abstract class SharedPreferencesModule {
  @singleton
  @preResolve
  Future<SharedPreferences> sharedPreferences() =>
      SharedPreferences.getInstance();
}

@singleton
class AppSettingsStore {
  static const _kActiveModelId = 'app_settings.active_model_id';
  static const _kAutoDeleteOldNotesDays =
      'app_settings.auto_delete_old_notes_days';
  static const _kRecentSyncWindowDays = 'app_settings.recent_sync_window_days';
  static const _kNatarajCoachSeen = 'app_settings.nataraj_coach_seen';
  static const _kLocaleCode = 'app_settings.locale_code';
  static const _kThemeMode = 'app_settings.theme_mode';
  static const _kMeshEnabled = 'app_settings.mesh_enabled';
  static const _kTranslationLanguage = 'app_settings.translation_language';

  final SharedPreferences _prefs;

  AppSettingsStore(this._prefs);

  AIModelId? get activeModelId {
    final raw = _prefs.getString(_kActiveModelId);
    if (raw == null) return null;
    for (final id in AIModelId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }

  Future<void> setActiveModelId(AIModelId? id) async {
    if (id == null) {
      await _prefs.remove(_kActiveModelId);
    } else {
      await _prefs.setString(_kActiveModelId, id.name);
    }
  }

  /// Identity-specific choices; locale, theme and device policy remain shared.
  Future<void> clearAccountChoices() async {
    await setActiveModelId(null);
    await setTranslationLanguage(null);
  }

  /// Days after which short-lived public notes (Kind 1 / Kind 42) get
  /// evicted by `CleanupManager`. `null` = disabled (the default — nothing
  /// auto-deletes). Saved / own / followed / DM / private-group notes
  /// are never affected by this setting.
  int? get autoDeleteOldNotesDays {
    if (!_prefs.containsKey(_kAutoDeleteOldNotesDays)) return null;
    final v = _prefs.getInt(_kAutoDeleteOldNotesDays);
    return (v != null && v > 0) ? v : null;
  }

  Future<void> setAutoDeleteOldNotesDays(int? days) async {
    if (days == null || days <= 0) {
      await _prefs.remove(_kAutoDeleteOldNotesDays);
    } else {
      await _prefs.setInt(_kAutoDeleteOldNotesDays, days);
    }
  }

  /// Days of history the capped sync surfaces (feed / group / private-group
  /// messages) pull. Defaults to 7 when unset. Followed notes, DMs, and the MLS
  /// control plane ignore this — they always pull full history.
  int get recentSyncWindowDays {
    final v = _prefs.getInt(_kRecentSyncWindowDays);
    return (v != null && v > 0) ? v : 7;
  }

  Future<void> setRecentSyncWindowDays(int days) =>
      _prefs.setInt(_kRecentSyncWindowDays, days);

  /// Whether the offline Bluetooth/Wi-Fi mesh is enabled. Default off — opt-in for
  /// privacy and battery.
  bool get meshEnabled => _prefs.getBool(_kMeshEnabled) ?? false;

  Future<void> setMeshEnabled(bool enabled) =>
      _prefs.setBool(_kMeshEnabled, enabled);

  /// Whether the Nataraj first-run coach overlay ("Swipe to explore ideas")
  /// has been dismissed. Shown only once, ever — persists across launches.
  bool get natarajCoachSeen => _prefs.getBool(_kNatarajCoachSeen) ?? false;

  Future<void> setNatarajCoachSeen(bool seen) =>
      _prefs.setBool(_kNatarajCoachSeen, seen);

  /// The user's explicitly-chosen app language code (e.g. `'en'`, `'hi'`), or
  /// `null` when they've never picked one (⇒ fall back to the system locale).
  /// Read synchronously at startup to seed `LocaleCubit` without a first-frame
  /// flicker.
  String? get localeCode => _prefs.getString(_kLocaleCode);

  Future<void> setLocaleCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_kLocaleCode);
    } else {
      await _prefs.setString(_kLocaleCode, code);
    }
  }

  /// Target language for note translation (BCP-47 primary subtag), or `null`
  /// until the user picks one — the picker seeds itself from the app locale on
  /// that first run, and every translation after reuses this value.
  String? get translationLanguage => _prefs.getString(_kTranslationLanguage);

  Future<void> setTranslationLanguage(String? code) async {
    if (code == null) {
      await _prefs.remove(_kTranslationLanguage);
    } else {
      await _prefs.setString(_kTranslationLanguage, code);
    }
  }

  /// The user's chosen theme mode (system / light / dark). `null` means
  /// they've never picked one — treat as `AppThemeMode.system`. Read
  /// synchronously at startup so `MaterialApp.themeMode` is right on the
  /// first frame.
  AppThemeMode? get themeMode =>
      AppThemeMode.fromName(_prefs.getString(_kThemeMode));

  Future<void> setThemeMode(AppThemeMode? mode) async {
    if (mode == null) {
      await _prefs.remove(_kThemeMode);
    } else {
      await _prefs.setString(_kThemeMode, mode.name);
    }
  }
}

/// Holds the logged-in user's public identity (pubkeyHex, npub, createdAt).
/// The private key (nsec) is NEVER stored here — it lives in
/// flutter_secure_storage (Android Keystore / iOS Keychain).
@singleton
class UserKeyStore {
  static const _kPubkeyHex = 'user_key.pubkey_hex';
  static const _kNpub = 'user_key.npub';
  static const _kCreatedAt = 'user_key.created_at_ms';

  final SharedPreferences _prefs;

  UserKeyStore(this._prefs);

  String? get pubkeyHex => _prefs.getString(_kPubkeyHex);
  String? get npub => _prefs.getString(_kNpub);
  DateTime? get createdAt {
    final ms = _prefs.getInt(_kCreatedAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get hasKey => _prefs.containsKey(_kPubkeyHex);

  Future<void> save({
    required String pubkeyHex,
    required String npub,
    required DateTime createdAt,
  }) async {
    await _prefs.setString(_kPubkeyHex, pubkeyHex);
    await _prefs.setString(_kNpub, npub);
    await _prefs.setInt(_kCreatedAt, createdAt.millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    await _prefs.remove(_kPubkeyHex);
    await _prefs.remove(_kNpub);
    await _prefs.remove(_kCreatedAt);
  }
}

/// User's preferred Blossom servers (BUD-03 / Kind 10063). Single value, per
/// device. Stored in SharedPreferences instead of Isar — it's pure
/// configuration, not Nostr data we need to query.
///
/// Cross-device sync via inbound Kind 10063 is intentionally not done: the
/// Gateway isolate can't access SharedPreferences, and the value is
/// low-stakes enough that "configure once per device" is fine.
@singleton
class UserServerListStore {
  static const _kServers = 'user_server_list.urls';

  final SharedPreferences _prefs;

  UserServerListStore(this._prefs);

  List<String> get servers => _prefs.getStringList(_kServers) ?? const [];

  Future<void> setServers(List<String> urls) async {
    await _prefs.setStringList(_kServers, urls);
  }

  Future<void> clear() async {
    await _prefs.remove(_kServers);
  }
}
