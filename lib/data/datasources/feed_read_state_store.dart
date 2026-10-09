import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Vishnu feed's "you are here" anchor (`feedLoadedAt`). A single
/// scalar — stored in SharedPreferences (as epoch millis) rather than Isar.
@singleton
class FeedReadStateStore {
  static const _kLoadedAtMs = 'feed_read_state.loaded_at_ms';

  final SharedPreferences _prefs;

  FeedReadStateStore(this._prefs);

  DateTime? get loadedAt {
    final ms = _prefs.getInt(_kLoadedAtMs);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLoadedAt(DateTime ts) =>
      _prefs.setInt(_kLoadedAtMs, ts.millisecondsSinceEpoch);

  Future<void> clear() => _prefs.remove(_kLoadedAtMs);
}
