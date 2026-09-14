part of 'auth_recovery_library.dart';

/// Result of an owned recovery transaction.
///
/// `allowed` is true only when operation ownership and optional correlation
/// matched at the start of the serialized transaction.
class OwnedRecoveryResult<T> {
  const OwnedRecoveryResult._(this.allowed, this.value);

  const OwnedRecoveryResult.allowed(T? this.value) : allowed = true;

  const OwnedRecoveryResult.denied() : allowed = false, value = null;

  final bool allowed;
  final T? value;
}

/// Transient capability that lets the guarded SDK [LocalStorage] adapter
/// perform an inline delegate removal while an owned recovery transaction is
/// actively executing an SDK local cleanup.
///
/// It is tied to a specific operation id and correlation, cleared in a
/// finally block, and never persists across transactions.
class _OwnedSdkCleanupCapability {
  _OwnedSdkCleanupCapability(
    this.operationId,
    this.correlation,
    this.canRemove,
  );

  final String operationId;
  final SessionCorrelation correlation;
  final bool Function()? canRemove;
  bool active = true;

  bool matchesCurrentRecord(AuthRecoveryState state) {
    if (!active || (canRemove != null && !canRemove!())) return false;
    final record = state.record;
    if (record == null) return false;
    if (record.operationId != operationId) return false;
    final recordCorrelation = SessionCorrelation(
      userId: record.userId,
      expiresAt: record.expiresAt,
      sessionId: record.sessionId,
      projectIdentity: record.projectIdentity,
    );
    return recordCorrelation.matches(correlation);
  }
}

/// Non-secret inspection result; session material stays inside the transaction.
enum RecoverySnapshotState { absent, matching, blocked }

enum QuarantinedResetResult { applied, changed, denied, failed }

/// Narrow transaction surface exposed to closures running inside
/// [AuthRecoveryStorageCoordinator.runOwnedRecoveryOperation].
///
/// This is the ONLY way recovery code may inspect state and mutate storage
/// within a single queued ownership interval. It deliberately does NOT expose
/// the mutable journal or raw delegate directly.
///
/// The transaction captures the validated operation id and correlation at
/// creation and invalidates itself when the callback ends, so an escaped
/// transaction can never mutate a later operation.
abstract class AuthRecoveryTransaction {
  /// The recovery state observed at the start of the transaction.
  AuthRecoveryState get currentState;

  /// The current owned journal entry, if any.
  AuthRecoveryJournalEntry? get currentEntry;

  /// Updates the phase of the owned operation inside the current queue slot.
  Future<bool> updatePhase(AuthRecoveryPhase phase);

  /// Completes the owned operation inside the current queue slot.
  Future<bool> complete();

  /// Non-destructive, one-way upgrade of this captured C3 placeholder.
  /// Exact identity must come from the SDK exchange result, never inference.
  Future<bool> upgradeCredentialCorrelation(
    SessionCorrelation exact, {
    required AuthRecoveryPhase phase,
  });

  /// C3 Addendum A only: explicit device-local reset of unchanged bytes.
  /// This does not grant an SDK cleanup capability or clear the journal.
  Future<QuarantinedResetResult> resetQuarantinedSnapshot();

  /// Reads the underlying SDK persisted session snapshot.
  Future<String?> readRecoverySnapshot();

  Future<RecoverySnapshotState> inspectRecoverySnapshot();

  /// Deletes only a current SDK snapshot matching this active transaction's
  /// captured correlation and configured project. Journal ownership alone is
  /// insufficient. Returns false for missing correlation or invalid/foreign
  /// bytes; verified absence succeeds without invoking the storage delegate.
  Future<bool> removeMatchingRecoverySnapshot({bool Function()? canRemove});

  /// Runs an SDK local-cleanup callback while this transaction owns the queue.
  ///
  /// The guarded SDK [LocalStorage] adapter recognizes the active owned
  /// cleanup and performs the delegate removal inline, preventing the
  /// self-deadlock that would occur if the SDK tried to enqueue the same
  /// removal on the already-held recovery queue.
  ///
  /// Only available while the transaction is active and the captured
  /// operation/correlation still owns the current record.
  Future<T> runOwnedSdkLocalCleanup<T>(
    Future<T> Function() cleanup, {
    bool Function()? canRemove,
  });
}

/// Single recovery serialization boundary.
///
/// Owns the recovery journal privately and the exact guarded SDK
/// [LocalStorage] instance. All recovery-related journal transitions and SDK
/// persisted-session access/removal are serialized through one queue so later
/// C2/C3 recovery operations cannot bypass the adapter queue.
///
/// This coordinator does NOT implement logout/exchange semantics; it only
/// provides the controlled boundary.
class AuthRecoveryStorageCoordinator {
  AuthRecoveryStorageCoordinator._({
    required _AuthRecoveryJournal journal,
    required LocalStorage delegate,
    required String projectIdentity,
  }) : _journal = journal,
       _delegate = delegate,
       _projectIdentity = projectIdentity,
       _queue = RecoveryAsyncQueue();

  final _AuthRecoveryJournal _journal;
  final LocalStorage _delegate;
  final String _projectIdentity;
  final RecoveryAsyncQueue _queue;

  // V1-R09 C2 — transient owned SDK cleanup capability. Set only while an
  // active owned transaction is executing client.auth.signOut(scope: local).
  // Cleared in a finally block; never persists across transactions.
  _OwnedSdkCleanupCapability? _activeOwnedSdkCleanup;
  Future<bool>? _ownedSdkRemovalWork;

  late final _GuardedSupabaseLocalStorage _localStorage =
      _GuardedSupabaseLocalStorage(
        delegate: _delegate,
        journal: _journal,
        queue: _queue,
        coordinator: this,
      );

  /// Opens a coordinator scoped to a stable non-secret [projectIdentity].
  static Future<AuthRecoveryStorageCoordinator> open({
    required String projectIdentity,
    required LocalStorage delegate,
  }) async {
    final journal = await _AuthRecoveryJournal.open(
      projectIdentity: projectIdentity,
    );
    return AuthRecoveryStorageCoordinator._(
      journal: journal,
      delegate: delegate,
      projectIdentity: projectIdentity,
    );
  }

  /// Derives a stable non-secret project identity from the configured
  /// Supabase authority URL.
  ///
  /// Uses the normalized full origin (`scheme://host:port`). Malformed URLs
  /// throw so the caller can fail initialization safely instead of collapsing
  /// to a shared/global namespace.
  static String projectIdentityFromUrl(String url) {
    final uri = Uri.parse(url);
    if (uri.host.isEmpty) {
      throw FormatException('Supabase URL has no host: $url');
    }
    final origin = uri.origin;
    // Base64URL-encode so the box name stays safe and deterministic regardless
    // of scheme, host, or port characters.
    return _base64UrlNoPadding(base64Url.encode(utf8.encode(origin)));
  }

  static String _base64UrlNoPadding(String input) {
    var result = input;
    while (result.endsWith('=')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// The [LocalStorage] adapter that must be passed to the SDK during
  /// initialization.
  ///
  /// This is intentionally the ONLY public path that yields the guarded
  /// adapter, and it is used exactly once by [SupabaseService] to wire the
  /// SDK. Application recovery code must use owned transactions instead of
  /// calling LocalStorage methods directly.
  LocalStorage get sdkLocalStorage => _localStorage;

  void _activateOwnedSdkCleanup(
    String operationId,
    SessionCorrelation correlation,
    bool Function()? canRemove,
  ) {
    if (_activeOwnedSdkCleanup != null) {
      throw StateError('Nested SDK cleanup is not allowed');
    }
    _ownedSdkRemovalWork = null;
    _activeOwnedSdkCleanup = _OwnedSdkCleanupCapability(
      operationId,
      correlation,
      canRemove,
    );
  }

  void _deactivateOwnedSdkCleanup() {
    _activeOwnedSdkCleanup?.active = false;
    _activeOwnedSdkCleanup = null;
  }

  RecoverySnapshotState _inspectSnapshot(
    String? snapshot,
    SessionCorrelation expected,
  ) {
    if (!expected.isSufficientForDestructiveCleanup ||
        expected.projectIdentity != _projectIdentity) {
      return RecoverySnapshotState.blocked;
    }
    if (snapshot == null) return RecoverySnapshotState.absent;
    try {
      final json = jsonDecode(snapshot);
      if (json is! Map<String, dynamic>) return RecoverySnapshotState.blocked;
      final session = Session.fromJson(json);
      if (session == null || session.accessToken.isEmpty) {
        return RecoverySnapshotState.blocked;
      }
      final correlation = SessionCorrelation.fromSessionJson(
        snapshot,
        projectIdentity: _projectIdentity,
      );
      return correlation.matches(expected)
          ? RecoverySnapshotState.matching
          : RecoverySnapshotState.blocked;
    } catch (_) {
      // Never retain/log parser errors containing session material.
      return RecoverySnapshotState.blocked;
    }
  }

  Future<bool> _removeMatchingSnapshot(
    SessionCorrelation expected,
    bool Function() stillOwned,
  ) async {
    if (!stillOwned()) return false;
    final snapshot = await _delegate.accessToken();
    if (!stillOwned()) return false;
    final state = _inspectSnapshot(snapshot, expected);
    if (state == RecoverySnapshotState.blocked) return false;
    if (state == RecoverySnapshotState.absent) return true;
    await _delegate.removePersistedSession();
    return stillOwned();
  }

  Future<bool> _removeForSdk(_OwnedSdkCleanupCapability capability) {
    // The SDK's event listener does not await signOut's persistence. Retain its
    // work in the held transaction; concurrent removal notifications share it.
    return _ownedSdkRemovalWork ??= _observeSdkRemoval(capability);
  }

  Future<bool> _observeSdkRemoval(_OwnedSdkCleanupCapability capability) async {
    try {
      return await _removeMatchingSnapshot(
        capability.correlation,
        () =>
            identical(_activeOwnedSdkCleanup, capability) &&
            capability.matchesCurrentRecord(_journal.read()),
      );
    } catch (_) {
      return false;
    }
  }

  /// Current recovery state.
  AuthRecoveryState readRecoveryState() => _journal.read();

  /// Current recovery entry, if any.
  AuthRecoveryJournalEntry? readRecoveryEntry() => _journal.read().record;

  /// Begins a recoverable operation through the shared queue.
  Future<bool> beginOperation({
    required AuthRecoveryOperationType type,
    required AuthRecoveryPhase phase,
    required SessionCorrelation correlation,
  }) => _queue.run(
    () => _journal.beginOperation(
      type: type,
      phase: phase,
      correlation: correlation,
    ),
  );

  /// Updates the phase of the owned operation through the shared queue.
  Future<bool> updateOwnedOperation({
    required String expectedOperationId,
    required AuthRecoveryPhase phase,
    SessionCorrelation? expectedCorrelation,
  }) => _queue.run(
    () => _journal.updatePhase(
      expectedOperationId: expectedOperationId,
      phase: phase,
      expectedCorrelation: expectedCorrelation,
    ),
  );

  /// Completes the owned operation through the shared queue.
  Future<bool> completeOwnedOperation({
    required String expectedOperationId,
    SessionCorrelation? expectedCorrelation,
  }) => _queue.run(
    () => _journal.complete(
      expectedOperationId: expectedOperationId,
      expectedCorrelation: expectedCorrelation,
    ),
  );

  /// Marks recovery corrupt with a constrained reason code.
  Future<bool> markCorrupt(AuthRecoveryCorruptReason reason) =>
      _queue.run(() => _journal.markCorrupt(reason));

  /// Closes the underlying journal box.
  ///
  /// Intended for test harnesses that need to release the box so another
  /// coordinator can reopen it from the same persisted storage.
  Future<void> close() async {
    await _journal.close();
  }

  /// Runs an owned recovery storage action inside ONE queued ownership
  /// interval.
  ///
  /// The supplied [action] receives a narrow [AuthRecoveryTransaction]. It
  /// may inspect the owned entry and request journal/storage mutations, but
  /// it cannot escape the queue or access unrestricted storage directly.
  ///
  /// Returns [OwnedRecoveryResult.denied] if the current record is missing,
  /// operation id mismatches, or correlation does not match.
  Future<OwnedRecoveryResult<T>> runOwnedRecoveryOperation<T>({
    required String expectedOperationId,
    SessionCorrelation? expectedCorrelation,
    required Future<T?> Function(AuthRecoveryTransaction tx) action,
  }) => _queue.run(() async {
    final state = _journal.read();
    final record = state.record;
    if (record == null || record.operationId != expectedOperationId) {
      return const OwnedRecoveryResult<Never>.denied();
    }
    if (expectedCorrelation != null &&
        !_AuthRecoveryJournal._correlationMatches(
          record,
          expectedCorrelation,
        )) {
      return const OwnedRecoveryResult<Never>.denied();
    }
    final tx = _AuthRecoveryTransactionImpl._(
      this,
      expectedOperationId,
      expectedCorrelation,
      record,
    );
    try {
      final value = await action(tx);
      return OwnedRecoveryResult<T>.allowed(value);
    } finally {
      tx._invalidate();
    }
  });
}

class _AuthRecoveryTransactionImpl implements AuthRecoveryTransaction {
  _AuthRecoveryTransactionImpl._(
    this._coordinator,
    this._capturedOperationId,
    this._capturedCorrelation,
    this._capturedEntry,
  );

  final AuthRecoveryStorageCoordinator _coordinator;
  final String _capturedOperationId;
  final SessionCorrelation? _capturedCorrelation;
  final AuthRecoveryJournalEntry _capturedEntry;
  bool _active = true;

  void _invalidate() {
    _active = false;
  }

  void _requireActive() {
    if (!_active) {
      throw StateError('AuthRecoveryTransaction is no longer active');
    }
  }

  Future<bool> _verifyCurrentOwnership() async {
    return _ownsCurrentRecord();
  }

  bool _ownsCurrentRecord() {
    if (!_active) return false;
    final record = _coordinator._journal.read().record;
    if (record == null || record.operationId != _capturedOperationId) {
      return false;
    }
    if (_capturedCorrelation != null &&
        !_AuthRecoveryJournal._correlationMatches(
          record,
          _capturedCorrelation,
        )) {
      return false;
    }
    return true;
  }

  @override
  AuthRecoveryState get currentState {
    _requireActive();
    return _coordinator._journal.read();
  }

  @override
  AuthRecoveryJournalEntry? get currentEntry {
    _requireActive();
    return _coordinator._journal.read().record;
  }

  @override
  Future<bool> updatePhase(AuthRecoveryPhase phase) async {
    _requireActive();
    if (!await _verifyCurrentOwnership()) return false;
    return _coordinator._journal.updatePhase(
      expectedOperationId: _capturedOperationId,
      phase: phase,
    );
  }

  @override
  Future<bool> complete() async {
    _requireActive();
    if (!await _verifyCurrentOwnership()) return false;
    return _coordinator._journal.complete(
      expectedOperationId: _capturedOperationId,
    );
  }

  @override
  Future<bool> upgradeCredentialCorrelation(
    SessionCorrelation exact, {
    required AuthRecoveryPhase phase,
  }) async {
    _requireActive();
    if (!_ownsCurrentRecord() ||
        !exact.isSufficientForDestructiveCleanup ||
        exact.projectIdentity != _coordinator._projectIdentity ||
        (phase != AuthRecoveryPhase.committing &&
            phase != AuthRecoveryPhase.neutralizing))
      return false;
    final entry = currentEntry!;
    if (entry.operationType != AuthRecoveryOperationType.credentialExchange ||
        entry.operationType != _capturedEntry.operationType ||
        entry.createdAt != _capturedEntry.createdAt)
      return false;
    final established = SessionCorrelation(
      userId: entry.userId,
      projectIdentity: entry.projectIdentity,
      sessionId: entry.sessionId,
      expiresAt: entry.expiresAt,
    );
    if (established.isSufficientForDestructiveCleanup) {
      return established.matches(exact) && entry.phase == phase;
    }
    if ((entry.phase != AuthRecoveryPhase.active &&
            entry.phase != AuthRecoveryPhase.timedOutPending) ||
        entry.userId != _capturedEntry.userId ||
        entry.projectIdentity != _capturedEntry.projectIdentity ||
        entry.sessionId != _capturedEntry.sessionId ||
        entry.expiresAt != _capturedEntry.expiresAt ||
        entry.phase != _capturedEntry.phase ||
        entry.sessionId != null ||
        entry.projectIdentity != _coordinator._projectIdentity)
      return false;
    // One acknowledged same-key write. No complete/begin interval and no
    // destructive authority is added to this placeholder-owned transaction.
    final upgraded = AuthRecoveryJournalEntry(
      schemaVersion: entry.schemaVersion,
      operationId: entry.operationId,
      operationType: entry.operationType,
      phase: phase,
      userId: exact.userId,
      expiresAt: exact.expiresAt,
      sessionId: exact.sessionId,
      projectIdentity: exact.projectIdentity,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    return _coordinator._journal._persistEntry(upgraded);
  }

  bool _ownsUnattributed() {
    if (!_ownsCurrentRecord()) return false;
    final entry = currentEntry!;
    return entry.operationType ==
            AuthRecoveryOperationType.credentialExchange &&
        entry.phase == AuthRecoveryPhase.blockedUnattributed;
  }

  @override
  Future<QuarantinedResetResult> resetQuarantinedSnapshot() async {
    _requireActive();
    if (!_ownsUnattributed()) return QuarantinedResetResult.denied;
    try {
      final quarantined = await _coordinator._delegate.accessToken();
      if (!_ownsUnattributed()) return QuarantinedResetResult.denied;
      final current = await _coordinator._delegate.accessToken();
      if (!_ownsUnattributed()) return QuarantinedResetResult.denied;
      if (current != quarantined) return QuarantinedResetResult.changed;
      // No await between exact-byte/ownership validation and delegate removal.
      if (current != null) {
        await _coordinator._delegate.removePersistedSession();
      }
      if (!_ownsUnattributed()) return QuarantinedResetResult.denied;
      final after = await _coordinator._delegate.accessToken();
      if (!_ownsUnattributed() || after != null) {
        return QuarantinedResetResult.changed;
      }
      return await updatePhase(
            AuthRecoveryPhase.localResetAppliedRestartRequired,
          )
          ? QuarantinedResetResult.applied
          : QuarantinedResetResult.failed;
    } catch (_) {
      return QuarantinedResetResult.failed;
    }
  }

  @override
  Future<String?> readRecoverySnapshot() async {
    _requireActive();
    if (!await _verifyCurrentOwnership()) return null;
    return _coordinator._delegate.accessToken();
  }

  @override
  Future<RecoverySnapshotState> inspectRecoverySnapshot() async {
    _requireActive();
    final correlation = _capturedCorrelation;
    if (correlation == null || !_ownsCurrentRecord()) {
      return RecoverySnapshotState.blocked;
    }
    final snapshot = await _coordinator._delegate.accessToken();
    if (!_ownsCurrentRecord()) return RecoverySnapshotState.blocked;
    return _coordinator._inspectSnapshot(snapshot, correlation);
  }

  @override
  Future<bool> removeMatchingRecoverySnapshot({
    bool Function()? canRemove,
  }) async {
    _requireActive();
    final correlation = _capturedCorrelation;
    if (correlation == null) return false;
    return _coordinator._removeMatchingSnapshot(
      correlation,
      () => _ownsCurrentRecord() && (canRemove == null || canRemove()),
    );
  }

  @override
  Future<T> runOwnedSdkLocalCleanup<T>(
    Future<T> Function() cleanup, {
    bool Function()? canRemove,
  }) async {
    _requireActive();
    if (_capturedCorrelation == null) {
      throw StateError(
        'Owned SDK cleanup requires a captured SessionCorrelation',
      );
    }
    if (!_ownsCurrentRecord() ||
        !_capturedCorrelation!.isSufficientForDestructiveCleanup ||
        _capturedCorrelation!.projectIdentity !=
            _coordinator._projectIdentity) {
      throw StateError('Owned SDK cleanup rejected: ownership lost');
    }
    _coordinator._activateOwnedSdkCleanup(
      _capturedOperationId,
      _capturedCorrelation!,
      canRemove,
    );
    try {
      return await cleanup();
    } finally {
      _coordinator._deactivateOwnedSdkCleanup();
      // Invalidate permission before draining. Already-started delegate writes
      // must finish before another queue slot (or journal completion) can run.
      final removal = _coordinator._ownedSdkRemovalWork;
      if (removal != null) await removal;
      _coordinator._ownedSdkRemovalWork = null;
    }
  }
}
