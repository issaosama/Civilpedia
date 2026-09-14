part of 'auth_recovery_library.dart';

/// A [LocalStorage] adapter that wraps the SDK's normal auth persistence
/// backend and gates normal session restoration on the auth recovery journal.
///
/// This adapter:
/// - preserves the SDK-owned session serialization and storage key;
/// - does NOT create a second token store;
/// - serializes storage operations through a shared queue so that a state
///   change cannot interleave with startup restoration or journal transitions;
/// - consults the recovery journal before returning a persisted session for
///   normal restoration;
/// - returns `null` (blocking restoration) when recovery is unresolved,
///   cleanup-required, or corrupt, while leaving the underlying snapshot intact
///   for later recovery operations.
class _GuardedSupabaseLocalStorage implements LocalStorage {
  _GuardedSupabaseLocalStorage({
    required LocalStorage delegate,
    required _AuthRecoveryJournal journal,
    RecoveryAsyncQueue? queue,
    required AuthRecoveryStorageCoordinator coordinator,
  }) : _delegate = delegate,
       _journal = journal,
       _queue = queue ?? RecoveryAsyncQueue(),
       _coordinator = coordinator;

  final LocalStorage _delegate;
  final _AuthRecoveryJournal _journal;
  final RecoveryAsyncQueue _queue;
  final AuthRecoveryStorageCoordinator _coordinator;

  @override
  Future<void> initialize() => _queue.run(() => _delegate.initialize());

  @override
  Future<bool> hasAccessToken() => _queue.run(() => _delegate.hasAccessToken());

  @override
  Future<String?> accessToken() => _queue.run(() async {
    final recovery = _journal.read();
    if (recovery.blocksNormalRestoration) {
      // The snapshot remains in the delegate for later recovery logic; it
      // is simply not admitted as normal application auth authority.
      return null;
    }
    return _delegate.accessToken();
  });

  @override
  Future<void> removePersistedSession() async {
    // V1-R09 C2 — when an owned recovery transaction is actively executing an
    // SDK local cleanup, the SDK's own removePersistedSession call must run
    // inline under the same queue ownership. Enqueuing it would deadlock
    // because the recovery queue is already held by that transaction.
    final capability = _coordinator._activeOwnedSdkCleanup;
    if (capability != null) {
      if (capability.matchesCurrentRecord(_journal.read())) {
        await _coordinator._removeForSdk(capability);
      }
      return;
    }
    // A delayed SDK callback never inherits new ownership after its original
    // capability expired. Unresolved recovery snapshots are preserved.
    final blockedAtRequest = _journal.read().blocksNormalRestoration;
    return _queue.run(() async {
      if (blockedAtRequest || _journal.read().blocksNormalRestoration) return;
      await _delegate.removePersistedSession();
    });
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _queue.run(() => _delegate.persistSession(persistSessionString));
}
