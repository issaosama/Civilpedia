import 'data_owner.dart';

/// A5.5 — One claimed (guest → authenticated user) ownership transition.
///
/// Recorded in the registry journal for auditability and idempotency. The same
/// (guestId, userId) pair is never recorded twice.
class OwnershipClaimRecord {
  const OwnershipClaimRecord({
    required this.guestId,
    required this.userId,
    required this.claimedAt,
  });

  /// The device-scoped guest identity whose local data was claimed.
  final String guestId;

  /// The canonical Supabase `auth.users.id` that claimed the data.
  final String userId;

  /// When the claim was recorded (UTC).
  final DateTime claimedAt;

  Map<String, dynamic> toMap() => {
    'guestId': guestId,
    'userId': userId,
    'claimedAt': claimedAt.toUtc().toIso8601String(),
  };

  static OwnershipClaimRecord? tryFromMap(Map<String, dynamic> map) {
    try {
      final guestId = map['guestId'] as String?;
      final userId = map['userId'] as String?;
      final claimedAtRaw = map['claimedAt'] as String?;
      if (guestId == null || guestId.isEmpty) return null;
      if (userId == null || userId.isEmpty) return null;
      if (claimedAtRaw == null) return null;
      return OwnershipClaimRecord(
        guestId: guestId,
        userId: userId,
        claimedAt: DateTime.parse(claimedAtRaw).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! OwnershipClaimRecord) return false;
    return other.guestId == guestId &&
        other.userId == userId &&
        other.claimedAt == claimedAt;
  }

  @override
  int get hashCode => Object.hash(guestId, userId, claimedAt);
}

/// A5.5 — Thrown by [OwnershipRegistry.tryDecode] when the persisted registry
/// is structurally corrupt.
///
/// The registry is the ONLY persisted evidence that local records belong to a
/// particular account. Corruption is therefore treated as FAIL-CLOSED: the
/// claim is blocked, the corrupt payload is preserved untouched, and nothing
/// is re-bound — otherwise a later user could claim records whose true owner
/// can no longer be proven.
class OwnershipRegistryCorruptException implements Exception {
  const OwnershipRegistryCorruptException(this.reason);

  /// A generic, sanitized reason (never record contents or user identifiers).
  final String reason;

  @override
  String toString() => 'OwnershipRegistryCorruptException: $reason';
}

/// A5.5 — The durable local ownership registry.
///
/// A sidecar keyed by stable record identities. It NEVER rewrites the user
/// data itself (projects, notes, saved references, favorites stay byte-identical
/// on disk); it only records who owns each local record/store.
///
/// Guarantees:
/// * All operations are idempotent: running a claim twice yields the same
///   final registry.
/// * Records already owned by a different authenticated user are never
///   reassigned.
/// * [boundUserId] is the "first authenticated owner of this device". A
///   different account signing in on the same device never triggers a claim.
///
/// Immutable value object: each operation returns a new registry. The claim
/// coordinator rebuilds the full document in memory and persists it as a
/// single atomic JSON write, so an interrupted claim leaves either the old
/// registry or the new one — never a partial record.
class OwnershipRegistry {
  OwnershipRegistry({
    Map<String, DataOwner>? owners,
    List<OwnershipClaimRecord>? claims,
    this.boundUserId,
    this.boundGuestId,
  }) : owners = Map.of(owners ?? const {}),
       claims = List.of(claims ?? const []);

  /// Bumped only when the serialized shape changes.
  static const int schemaVersion = 1;

  /// recordKey → ownership stamp. A record without an entry is unowned.
  final Map<String, DataOwner> owners;

  /// Historical (guestId, userId) claim transitions, newest last.
  final List<OwnershipClaimRecord> claims;

  /// The single authenticated account bound to this device, or null before
  /// any claim. Ownership claims run only for this account.
  final String? boundUserId;

  /// The guest identity captured when [boundUserId] was bound.
  final String? boundGuestId;

  bool get isBound => boundUserId != null && boundUserId!.isNotEmpty;

  DataOwner? ownerOf(String recordKey) => owners[recordKey];

  bool isOwnedByUser(String recordKey, String userId) =>
      owners[recordKey]?.ownedBy(userId) ?? false;

  bool isGuestOwned(String recordKey) =>
      owners[recordKey]?.isGuest ?? false;

  /// True when [recordKey] is absent or still guest-owned and therefore
  /// safely claimable.
  bool isClaimable(String recordKey) {
    final owner = owners[recordKey];
    return owner == null || owner.isGuest;
  }

  /// Binds the device to an authenticated account. The first claimant wins:
  /// re-runs for the SAME account are no-ops (idempotent), and a different
  /// account is never allowed to re-bind (guarded by the coordinator).
  OwnershipRegistry copyWithBoundAccount({
    required String userId,
    required String guestId,
  }) {
    return OwnershipRegistry(
      owners: owners,
      claims: claims,
      boundUserId: boundUserId ?? userId,
      boundGuestId: boundGuestId ?? guestId,
    );
  }

  /// Marks [recordKey] as owned by [userId]. Idempotent: re-claiming an
  /// already-claimed record is a no-op with the original stamp preserved.
  OwnershipRegistry claimKey(String recordKey, String userId) {
    final snapshot = owners[recordKey];
    if (snapshot?.ownedBy(userId) ?? false) return this;
    return OwnershipRegistry(
      owners: {...owners, recordKey: DataOwner.user(userId: userId)},
      claims: claims,
      boundUserId: boundUserId,
      boundGuestId: boundGuestId,
    );
  }

  /// Records a (guestId, userId) claim transition once. Duplicate journal
  /// entries are never appended, keeping re-claims idempotent.
  OwnershipRegistry withClaimRecord(String guestId, String userId) {
    final already = claims.any(
      (c) => c.guestId == guestId && c.userId == userId,
    );
    if (already) return this;
    return OwnershipRegistry(
      owners: owners,
      claims: [
        ...claims,
        OwnershipClaimRecord(
          guestId: guestId,
          userId: userId,
          claimedAt: DateTime.now().toUtc(),
        ),
      ],
      boundUserId: boundUserId,
      boundGuestId: boundGuestId,
    );
  }

  /// Serializes the whole registry. [claimedAt] uses UTC ISO-8601.
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (boundUserId != null) 'boundUserId': boundUserId,
    if (boundGuestId != null) 'boundGuestId': boundGuestId,
    'owners': owners.map(
      (key, owner) => MapEntry(key, owner.toMap()),
    ),
    'claims': claims.map((c) => c.toMap()).toList(),
  };

  /// Strict, fail-closed parse of a decoded registry document.
  ///
  /// Distinguishes the three persisted states at the store boundary:
  ///
  /// * MISSING registry → `null`/absent key is handled by the store (an empty
  ///   unbound registry is the legitimate first-run state). `tryDecode` itself
  ///   receives a decoded JSON value and never invents ownership.
  /// * VALID registry → the decoded document is structurally sound.
  /// * CORRUPT registry → throws [OwnershipRegistryCorruptException]; the claim
  ///   must be blocked and the raw payload preserved, never silently replaced
  ///   with an empty registry.
  ///
  /// Fail-closed on ownership-critical structure:
  /// * wrong root type (not a JSON object);
  /// * invalid `boundUserId` / `boundGuestId` value;
  /// * a malformed `owners` map (non-map entry, unparseable owner, or invalid
  ///   record key) — an ambiguous entry makes that record unclaimable safely;
  /// * unknown/extra additive top-level fields and malformed journal entries
  ///   are tolerated when they do not change ownership meaning.
  factory OwnershipRegistry.tryDecode(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const OwnershipRegistryCorruptException(
        'expected a JSON object at the root',
      );
    }

    final rawBoundUserId = json['boundUserId'];
    if (rawBoundUserId != null &&
        (rawBoundUserId is! String || rawBoundUserId.isEmpty)) {
      throw const OwnershipRegistryCorruptException(
        'boundUserId is not a valid user id',
      );
    }
    final rawBoundGuestId = json['boundGuestId'];
    if (rawBoundGuestId != null &&
        (rawBoundGuestId is! String || rawBoundGuestId.isEmpty)) {
      throw const OwnershipRegistryCorruptException(
        'boundGuestId is not a valid guest identity',
      );
    }

    final owners = <String, DataOwner>{};
    final rawOwners = json['owners'];
    if (rawOwners != null) {
      if (rawOwners is! Map) {
        throw const OwnershipRegistryCorruptException(
          'owners is not a JSON object',
        );
      }
      rawOwners.forEach((key, value) {
        if (key is! String || key.isEmpty) {
          throw const OwnershipRegistryCorruptException(
            'owners contains an invalid record key',
          );
        }
        if (value is! Map) {
          throw const OwnershipRegistryCorruptException(
            'owners contains an entry that is not an owner object',
          );
        }
        final owner = DataOwner.tryFromMap(value.cast<String, dynamic>());
        if (owner == null) {
          throw const OwnershipRegistryCorruptException(
            'owners contains an unrecognized owner entry',
          );
        }
        owners[key] = owner;
      });
    }

    // Journal entries are dedup metadata only; malformed entries never change
    // ownership meaning and are skipped (tolerant, non-critical).
    final claims = <OwnershipClaimRecord>[];
    final rawClaims = json['claims'];
    if (rawClaims is List) {
      for (final item in rawClaims) {
        if (item is! Map) continue;
        final record = OwnershipClaimRecord.tryFromMap(
          item.cast<String, dynamic>(),
        );
        if (record != null) claims.add(record);
      }
    }

    return OwnershipRegistry(
      owners: owners,
      claims: claims,
      boundUserId: rawBoundUserId as String?,
      boundGuestId: rawBoundGuestId as String?,
    );
  }

  @override
  String toString() =>
      'OwnershipRegistry(bound=$boundUserId, owners=${owners.length}, '
      'claims=${claims.length})';
}