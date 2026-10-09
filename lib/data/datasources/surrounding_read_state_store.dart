import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Surrounding feed's read watermark — the `receivedAt` of the
/// newest surrounding note the user has read. A single scalar in
/// SharedPreferences (epoch millis). A surrounding note is unread iff its
/// `receivedAt` is strictly greater than this watermark.
///
/// A timestamp (not a `lastReadEventId`) is used because surrounding notes are
/// evicted daily — an eventId pointer could reference an evicted note, whereas a
/// timestamp watermark survives eviction. Mirrors [FeedReadStateStore].
@singleton
class SurroundingReadStateStore {
  static const _kLastReadMs = 'surrounding_read_state.last_read_received_at_ms';

  final SharedPreferences _prefs;

  SurroundingReadStateStore(this._prefs);

  /// Epoch (millis 0) when unset → every note is unread on first open.
  DateTime get lastReadReceivedAt {
    final ms = _prefs.getInt(_kLastReadMs) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Advances the watermark to max(current, [ts]). Never moves it backwards.
  Future<void> advanceTo(DateTime ts) async {
    final current = _prefs.getInt(_kLastReadMs) ?? 0;
    if (ts.millisecondsSinceEpoch <= current) return;
    await _prefs.setInt(_kLastReadMs, ts.millisecondsSinceEpoch);
  }

  Future<void> clear() => _prefs.remove(_kLastReadMs);
}
