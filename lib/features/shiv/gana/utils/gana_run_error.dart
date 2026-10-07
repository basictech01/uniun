import 'package:uniun/l10n/app_localizations.dart';

/// What kind of problem a failed Gana run hit, so the UI can say it in plain
/// words. The run log stores one raw message, written by the engine as
/// `<stage>: <exception>` (`cloud:`, `inference:`, `publish:`) or the bare
/// `no active user`. Rows written before the stage tags have none. The kind is
/// a best-effort reading of that text; anything unrecognised is [other].
enum GanaRunErrorKind { noIdentity, publish, network, model, other }

class GanaRunError {
  const GanaRunError(this.kind, this.raw);

  final GanaRunErrorKind kind;

  /// Exactly what the run log holds — stage tag and exception text included —
  /// so a developer can paste it into a search or an issue unchanged.
  final String raw;

  factory GanaRunError.parse(String raw) {
    final text = raw.trim();
    if (text == 'no active user') {
      return GanaRunError(GanaRunErrorKind.noIdentity, text);
    }
    if (text.startsWith('publish:')) {
      return GanaRunError(GanaRunErrorKind.publish, text);
    }

    final staged = _stage.hasMatch(text);
    final lower = _unwrap(text).toLowerCase();
    if (_network.hasMatch(lower)) {
      return GanaRunError(GanaRunErrorKind.network, text);
    }
    // A failure in the model stage is a model problem even when its text names
    // nothing recognisable; untagged older rows have to be told by keyword.
    if (staged || _model.hasMatch(lower)) {
      return GanaRunError(GanaRunErrorKind.model, text);
    }
    return GanaRunError(GanaRunErrorKind.other, text);
  }

  String title(AppLocalizations l10n) => switch (kind) {
        GanaRunErrorKind.noIdentity => l10n.ganaErrNoIdentityTitle,
        GanaRunErrorKind.publish => l10n.ganaErrPublishTitle,
        GanaRunErrorKind.network => l10n.ganaErrNetworkTitle,
        GanaRunErrorKind.model => l10n.ganaErrModelTitle,
        GanaRunErrorKind.other => l10n.ganaErrOtherTitle,
      };

  String hint(AppLocalizations l10n) => switch (kind) {
        GanaRunErrorKind.noIdentity => l10n.ganaErrNoIdentityHint,
        GanaRunErrorKind.publish => l10n.ganaErrPublishHint,
        GanaRunErrorKind.network => l10n.ganaErrNetworkHint,
        GanaRunErrorKind.model => l10n.ganaErrModelHint,
        GanaRunErrorKind.other => l10n.ganaErrOtherHint,
      };
}

final RegExp _stage = RegExp(r'^(cloud|inference):');

final RegExp _network = RegExp(
  r'socketexception|timeoutexception|timed out|failed host lookup|'
  r'connection (refused|reset|closed|failed)|handshakeexception|'
  r'clientexception|network is unreachable',
);

final RegExp _model = RegExp(
  r'litert|native|engine|inference|gemma|model|out of memory|session|'
  r'chat is closed|gpu',
);

final RegExp _failureWrapper = RegExp(r'^Failure\.\w+\((?:message: )?(.*)\)$');

/// Drops the stage tag and the Failure / Exception wrappers, for matching only.
String _unwrap(String s) {
  var out = s.replaceFirst(_stage, '').trim();
  final failure = _failureWrapper.firstMatch(out);
  if (failure != null) out = failure.group(1)!.trim();
  if (out.startsWith('Exception: ')) out = out.substring(11).trim();
  return out;
}
