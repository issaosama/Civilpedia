part of 'auth_recovery_library.dart';

/// A minimal sequential Future queue used by the recovery storage boundary.
///
/// Operations are run one at a time in submission order. A failure in one
/// operation does not prevent the next queued operation from running, so a
/// transient delegate failure cannot permanently poison serialization.
class RecoveryAsyncQueue {
  Future<dynamic> _pending = Future<dynamic>.value(null);

  Future<T> run<T>(Future<T> Function() action) {
    final previous = _pending;
    final current = previous.then(
      (_) => action(),
      onError: (_) => action(),
    );
    _pending = current;
    return current;
  }
}
