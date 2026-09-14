part of 'auth_recovery_library.dart';

/// The startup-visible recovery condition.
enum AuthRecoveryStartupStatus {
  /// No recovery record exists; normal auth restoration may proceed.
  none,

  /// A recovery record exists for an in-flight operation that has not yet been
  /// safely finalized. Persisted auth snapshots must not become application
  /// authority until the operation completes or is neutralized.
  unresolved,

  /// The previous auth operation reached a point where local cleanup is known
  /// to be required. Account access remains blocked until cleanup succeeds.
  cleanupRequired,

  /// The recovery record itself is unreadable or schema-incompatible. Account
  /// access fails closed; local app functionality remains available.
  corrupt,
}

/// Typed recovery operation kinds.
enum AuthRecoveryOperationType {
  /// Authoritative sign-out with remote-first revocation.
  signOut,

  /// Native Google credential exchange with Supabase.
  credentialExchange,
}

/// Typed phases of a recovery operation.
///
/// Unknown or persisted values outside this closed set are treated as corrupt.
enum AuthRecoveryPhase {
  /// Operation has started but not reached a decisive point.
  active,

  /// Sign-out: remote revocation is in flight.
  remotePending,

  /// Cleanup is known to be required before normal authority can resume.
  cleanupRequired,

  /// A timed-out/stale exchange is being neutralized.
  neutralizing,

  /// Cleanup/neutralization reached a failure state that must block authority.
  blockedCleanupFailure,

  /// Credential exchange has received credentials and is committing.
  committing,
  timedOutPending,
  blockedUnattributed,
  localResetAppliedRestartRequired,
}

/// Constrained, non-secret reason codes for a corruption marker.
///
/// Callers cannot persist arbitrary text, stack traces, tokens, or backend
/// bodies through this API.
enum AuthRecoveryCorruptReason {
  unreadableJournal,
  schemaMismatch,
  malformedMarker,
  writeFailure,
  ownershipViolation,
  staleOperation,
}

/// Typed startup recovery state exposed by the auth recovery foundation.
class AuthRecoveryState {
  const AuthRecoveryState._(this.status, this.record);

  const AuthRecoveryState.none()
    : status = AuthRecoveryStartupStatus.none,
      record = null;

  const AuthRecoveryState.unresolved(this.record)
    : status = AuthRecoveryStartupStatus.unresolved;

  const AuthRecoveryState.cleanupRequired(this.record)
    : status = AuthRecoveryStartupStatus.cleanupRequired;

  const AuthRecoveryState.corrupt()
    : status = AuthRecoveryStartupStatus.corrupt,
      record = null;

  final AuthRecoveryStartupStatus status;
  final AuthRecoveryJournalEntry? record;

  /// Whether normal Supabase SDK auth restoration must be suppressed.
  bool get blocksNormalRestoration =>
      status == AuthRecoveryStartupStatus.unresolved ||
      status == AuthRecoveryStartupStatus.cleanupRequired ||
      status == AuthRecoveryStartupStatus.corrupt;

  /// Whether application account authority may be granted.
  ///
  /// While a recovery record is unresolved, cleanup-required, or corrupt,
  /// no identity-bearing path may establish normal application authority.
  bool get blocksAccountAuthority => blocksNormalRestoration;
}

/// A single recovery journal entry.
///
/// Contains only non-secret metadata. No access token, refresh token, id token,
/// Google token, or OAuth credential is ever stored here.
class AuthRecoveryJournalEntry {
  const AuthRecoveryJournalEntry({
    required this.schemaVersion,
    required this.operationId,
    required this.operationType,
    required this.phase,
    required this.userId,
    this.expiresAt,
    this.sessionId,
    this.projectIdentity,
    required this.createdAt,
    required this.updatedAt,
  });

  final int schemaVersion;
  final String operationId;
  final AuthRecoveryOperationType operationType;
  final AuthRecoveryPhase phase;
  final String userId;
  final int? expiresAt;
  final String? sessionId;
  final String? projectIdentity;
  final DateTime createdAt;
  final DateTime updatedAt;

  AuthRecoveryState toRecoveryState() {
    switch (phase) {
      case AuthRecoveryPhase.cleanupRequired:
        return AuthRecoveryState.cleanupRequired(this);
      default:
        // Any persisted record that is not cleanup-required is still an
        // in-flight/unresolved operation. Idle-like strings are no longer
        // recognized and will have failed parsing, yielding corrupt.
        return AuthRecoveryState.unresolved(this);
    }
  }

  AuthRecoveryJournalEntry copyWith({
    AuthRecoveryPhase? phase,
    DateTime? updatedAt,
  }) => AuthRecoveryJournalEntry(
    schemaVersion: schemaVersion,
    operationId: operationId,
    operationType: operationType,
    phase: phase ?? this.phase,
    userId: userId,
    expiresAt: expiresAt,
    sessionId: sessionId,
    projectIdentity: projectIdentity,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'schemaVersion': schemaVersion,
    'operationId': operationId,
    'operationType': operationType.name,
    'phase': phase.name,
    'userId': userId,
    if (expiresAt != null) 'expiresAt': expiresAt,
    if (sessionId != null) 'sessionId': sessionId,
    if (projectIdentity != null) 'projectIdentity': projectIdentity,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory AuthRecoveryJournalEntry.fromMap(Map<String, dynamic> map) {
    final schemaVersion = map['schemaVersion'] as int?;
    final operationId = map['operationId'] as String?;
    final operationTypeName = map['operationType'] as String?;
    final phaseName = map['phase'] as String?;
    final userId = map['userId'] as String?;
    if (schemaVersion == null ||
        operationId == null ||
        operationId.isEmpty ||
        operationTypeName == null ||
        phaseName == null ||
        userId == null ||
        userId.isEmpty) {
      throw const FormatException(
        'Recovery journal entry missing required fields',
      );
    }

    final createdAtRaw = map['createdAt'] as String?;
    final updatedAtRaw = map['updatedAt'] as String?;
    if (createdAtRaw == null || updatedAtRaw == null) {
      throw const FormatException('Recovery journal entry missing timestamps');
    }

    final operationType = _parseOperationType(operationTypeName);
    final phase = _parsePhase(phaseName);

    return AuthRecoveryJournalEntry(
      schemaVersion: schemaVersion,
      operationId: operationId,
      operationType: operationType,
      phase: phase,
      userId: userId,
      expiresAt: map['expiresAt'] as int?,
      sessionId: map['sessionId'] as String?,
      projectIdentity: map['projectIdentity'] as String?,
      createdAt: DateTime.parse(createdAtRaw),
      updatedAt: DateTime.parse(updatedAtRaw),
    );
  }

  static AuthRecoveryOperationType _parseOperationType(String name) {
    return AuthRecoveryOperationType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => throw FormatException('Unknown operationType: $name'),
    );
  }

  static AuthRecoveryPhase _parsePhase(String name) {
    return AuthRecoveryPhase.values.firstWhere(
      (p) => p.name == name,
      orElse: () => throw FormatException('Unknown phase: $name'),
    );
  }
}

/// Persistent auth recovery journal.
///
/// Stores recovery metadata only. Token safety is enforced by the typed entry
/// model: no token fields exist, and callers cannot accidentally persist a
/// session string through this API.
///
/// This class is library-private; production code must access recovery state
/// through [AuthRecoveryStorageCoordinator].
class _AuthRecoveryJournal extends ChangeNotifier {
  _AuthRecoveryJournal._(this._box) : super();

  static const int _schemaVersion = 1;
  static const String _corruptFlagKey =
      '${AppStorageKeys.authRecoveryJournalEntry}_corrupt';

  final Box _box;
  bool _inMemoryCorrupt = false;

  /// Opens the journal using an existing [box], or by opening the dedicated
  /// recovery journal box.
  ///
  /// When [projectIdentity] is supplied the box name is scoped to that
  /// non-secret project authority, so different Supabase projects cannot
  /// block one another.
  static Future<_AuthRecoveryJournal> open({
    Box? box,
    String? projectIdentity,
    String? boxName,
  }) async {
    if (box != null) return _AuthRecoveryJournal._(box);
    final effectiveBoxName =
        boxName ??
        (projectIdentity != null && projectIdentity.isNotEmpty
            ? '${AppStorageKeys.authRecoveryJournalBox}_$projectIdentity'
            : AppStorageKeys.authRecoveryJournalBox);
    final opened = await Hive.openBox(effectiveBoxName);
    return _AuthRecoveryJournal._(opened);
  }

  /// Reads the current recovery state from storage.
  ///
  /// Never throws; unreadable or schema-incompatible data yields
  /// [AuthRecoveryState.corrupt].
  AuthRecoveryState read() {
    if (_inMemoryCorrupt) return const AuthRecoveryState.corrupt();

    try {
      final corruptRaw = _box.get(_corruptFlagKey);
      if (corruptRaw != null) {
        // Any non-null value at the corrupt flag key blocks authority. The
        // marker is internal; malformed presence is treated as corrupt.
        return const AuthRecoveryState.corrupt();
      }

      final raw = _box.get(AppStorageKeys.authRecoveryJournalEntry);
      if (raw == null) return const AuthRecoveryState.none();

      final map = Map<String, dynamic>.from(raw as Map);
      final entry = AuthRecoveryJournalEntry.fromMap(map);
      if (entry.schemaVersion != _schemaVersion) {
        return const AuthRecoveryState.corrupt();
      }
      return entry.toRecoveryState();
    } catch (_) {
      return const AuthRecoveryState.corrupt();
    }
  }

  /// Begins a recoverable operation.
  ///
  /// Returns `true` once the entry is durably persisted. A `false` return means
  /// the write failed or an existing unresolved/cleanup/corrupt record already
  /// exists; the risky mutation that depended on it must NOT proceed.
  Future<bool> beginOperation({
    required AuthRecoveryOperationType type,
    required AuthRecoveryPhase phase,
    required SessionCorrelation correlation,
  }) async {
    final current = read();
    if (current.blocksNormalRestoration) {
      // Do not overwrite an existing unresolved/cleanup/corrupt record.
      return false;
    }

    final entry = AuthRecoveryJournalEntry(
      schemaVersion: _schemaVersion,
      operationId: _generateOperationId(),
      operationType: type,
      phase: phase,
      userId: correlation.userId,
      expiresAt: correlation.expiresAt,
      sessionId: correlation.sessionId,
      projectIdentity: correlation.projectIdentity,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    final ok = await _persistEntry(entry);
    if (ok) notifyListeners();
    return ok;
  }

  /// Updates the phase of the current operation.
  ///
  /// Returns `false` when there is no current record, the write fails, or
  /// [expectedOperationId] does not own the current record.
  Future<bool> updatePhase({
    required String expectedOperationId,
    required AuthRecoveryPhase phase,
    SessionCorrelation? expectedCorrelation,
  }) async {
    final current = read();
    final record = current.record;
    if (record == null || record.operationId != expectedOperationId) {
      return false;
    }
    if (expectedCorrelation != null &&
        !_correlationMatches(record, expectedCorrelation)) {
      return false;
    }

    final updated = record.copyWith(
      phase: phase,
      updatedAt: DateTime.now().toUtc(),
    );
    final ok = await _persistEntry(updated);
    if (ok) notifyListeners();
    return ok;
  }

  /// Completes recovery by removing the journal entry.
  ///
  /// Returns `false` if there is no record, ownership does not match, or the
  /// durable delete fails.
  Future<bool> complete({
    required String expectedOperationId,
    SessionCorrelation? expectedCorrelation,
  }) async {
    final current = read();
    final record = current.record;
    if (record == null || record.operationId != expectedOperationId) {
      return false;
    }
    if (expectedCorrelation != null &&
        !_correlationMatches(record, expectedCorrelation)) {
      return false;
    }

    try {
      await _box.delete(AppStorageKeys.authRecoveryJournalEntry);
      await _box.delete(_corruptFlagKey);
      notifyListeners();
      return true;
    } catch (_) {
      // Delete failed: the record still exists. Leave in-memory state alone so
      // the caller can observe the failure.
      return false;
    }
  }

  /// Marks the journal as corrupt using a constrained reason code.
  ///
  /// Returns `true` when the marker is durably persisted. If persistence fails,
  /// an in-memory corrupt latch is set for the current process and `false` is
  /// returned; account authority remains blocked even though disk durability
  /// could not be achieved.
  Future<bool> markCorrupt(AuthRecoveryCorruptReason reason) async {
    try {
      await _box.put(_corruptFlagKey, {
        'corrupt': true,
        'reason': reason.name,
        'markedAt': DateTime.now().toUtc().toIso8601String(),
      });
      notifyListeners();
      return true;
    } catch (_) {
      _inMemoryCorrupt = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _persistEntry(AuthRecoveryJournalEntry entry) async {
    try {
      await _box.put(AppStorageKeys.authRecoveryJournalEntry, entry.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _correlationMatches(
    AuthRecoveryJournalEntry record,
    SessionCorrelation correlation,
  ) {
    final recordCorrelation = SessionCorrelation(
      userId: record.userId,
      expiresAt: record.expiresAt,
      sessionId: record.sessionId,
      projectIdentity: record.projectIdentity,
    );
    return recordCorrelation.matches(correlation);
  }

  String _generateOperationId() {
    final now = DateTime.now().toUtc();
    final rand = Random.secure().nextInt(0x7fffffff);
    return '${now.millisecondsSinceEpoch}_$rand';
  }

  /// Closes the underlying Hive box.
  ///
  /// Intended for test harnesses that need to release the box so another
  /// instance can reopen it from the same persisted storage.
  Future<void> close() async {
    try {
      await _box.close();
    } catch (_) {
      // Already closed or Hive disposed.
    }
  }
}
