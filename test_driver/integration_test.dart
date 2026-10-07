// Host side of `flutter drive`, for device tests that must run in profile or
// release mode (a debug build skews timing-sensitive tests).
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
