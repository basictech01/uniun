import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/gana/utils/gana_formatters.dart';

/// [ganaSuccessPercent]: skipped runs never count, and no data is null.
void main() {
  group('ganaSuccessPercent', () {
    test('is null before the Gana has succeeded or failed', () {
      expect(ganaSuccessPercent(succeeded: 0, failed: 0), isNull);
    });

    test('rounds to a whole percent', () {
      expect(ganaSuccessPercent(succeeded: 1, failed: 2), 33);
      expect(ganaSuccessPercent(succeeded: 2, failed: 1), 67);
    });

    test('covers both ends', () {
      expect(ganaSuccessPercent(succeeded: 5, failed: 0), 100);
      expect(ganaSuccessPercent(succeeded: 0, failed: 3), 0);
    });

    test('handles large counts', () {
      expect(ganaSuccessPercent(succeeded: 999999, failed: 1), 100);
    });
  });
}
