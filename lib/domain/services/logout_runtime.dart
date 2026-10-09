/// Stops work that may still read or write the current account's data.
abstract class LogoutRuntime {
  Future<void> stop();
}
