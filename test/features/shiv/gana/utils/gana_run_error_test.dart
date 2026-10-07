import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/gana/utils/gana_run_error.dart';

/// [GanaRunError.parse]: the raw run-log message becomes a kind plus a cleaned
/// detail; anything unrecognised is `other` and keeps its text.
void main() {
  GanaRunError parse(String raw) => GanaRunError.parse(raw);

  group('kind', () {
    test('no active user is a missing identity', () {
      expect(parse('no active user').kind, GanaRunErrorKind.noIdentity);
    });

    test('a publish: tag is a publish failure, whatever follows', () {
      final e = parse('publish: SocketException: Failed host lookup');
      expect(e.kind, GanaRunErrorKind.publish);
    });

    test('connection and timeout errors are network problems', () {
      for (final raw in [
        'SocketException: Connection refused',
        'TimeoutException after 0:00:30',
        'ClientException: Failed host lookup: api.uniun.in',
        'HandshakeException: Connection terminated',
        'request timed out',
        'cloud: ClientException: Failed host lookup',
        'inference: TimeoutException after 0:01:00',
      ]) {
        expect(parse(raw).kind, GanaRunErrorKind.network, reason: raw);
      }
    });

    test('a model-stage failure is a model problem whatever it says', () {
      expect(parse('inference: something odd').kind, GanaRunErrorKind.model);
      expect(
        parse('cloud: Failure.errorFailure(message: HTTP 500)').kind,
        GanaRunErrorKind.model,
      );
    });

    test('untagged older rows are told by keyword', () {
      for (final raw in [
        'LiteRT engine failed to create',
        'Bad state: model is closed',
        'native runtime degraded',
        'Out of memory',
      ]) {
        expect(parse(raw).kind, GanaRunErrorKind.model, reason: raw);
      }
    });

    test('anything else is other', () {
      expect(
        parse('FormatException: bad bracket').kind,
        GanaRunErrorKind.other,
      );
    });

    test('matching ignores case', () {
      expect(parse('SOCKETEXCEPTION').kind, GanaRunErrorKind.network);
    });

    test('a word that only looks like a stage tag is not one', () {
      expect(parse('cloudy: nothing').kind, GanaRunErrorKind.other);
    });
  });

  group('raw', () {
    test('is exactly what the log holds, wrappers and stage tag included', () {
      const raw = 'publish: Failure.errorFailure(message: relay said no)';
      expect(parse(raw).raw, raw);
      expect(parse('cloud: Exception: boom').raw, 'cloud: Exception: boom');
    });

    test('keeps unicode, emoji and newlines intact', () {
      const raw = 'inference: त्रुटि ❌\nline two';
      expect(parse(raw).raw, raw);
    });

    test('trims surrounding whitespace only', () {
      expect(parse('  oops  ').raw, 'oops');
    });

    test('an empty message is other with an empty raw', () {
      final e = parse('');
      expect((e.kind, e.raw), (GanaRunErrorKind.other, ''));
    });

    test('a very long message is kept whole', () {
      final raw = 'x' * 20000;
      expect(parse(raw).raw, hasLength(20000));
    });
  });
}
