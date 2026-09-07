/// A5.5 — Result of a local-data claim run.
///
/// `executed` is false when the claim was refused by the one-account-per-device
/// boundary (a different authenticated user signed in on an already-bound
/// device). In that case NO record was reassigned.
class ClaimOutcome {
  const ClaimOutcome._({
    required this.userId,
    required this.executed,
    required this.guestId,
    this.boundUserId,
    this.blockedCorruptRegistry = false,
    this.claimedRecordCount = 0,
    this.alreadyOwnedCount = 0,
    this.preservedOwnedByOtherCount = 0,
    this.claimedKeys = const [],
  });

  /// The claimant account (`auth.users.id`) that triggered this run.
  final String userId;

  /// Whether the claim took effect on this run.
  final bool executed;

  /// The guest identity used / recorded by this run.
  final String guestId;

  /// The device-bound account when the run was refused, else null.
  final String? boundUserId;

  /// True when the run was blocked because the persisted ownership registry is
  /// corrupt. Fail-closed: nothing was enumerated or claimed, no registry was
  /// written, the corrupt payload is preserved, and the device is not re-bound.
  final bool blockedCorruptRegistry;

  /// Records newly associated with [userId] on this run.
  final int claimedRecordCount;

  /// Records already owned by [userId] (idempotent re-claim path).
  final int alreadyOwnedCount;

  /// Records owned by a different account that were preserved untouched.
  final int preservedOwnedByOtherCount;

  /// The stable record keys claimed on this run (diagnostics/tests).
  final List<String> claimedKeys;

  /// A completed, executed claim.
  factory ClaimOutcome.completed({
    required String userId,
    required String guestId,
    required int claimedRecordCount,
    required int alreadyOwnedCount,
    required int preservedOwnedByOtherCount,
    required List<String> claimedKeys,
  }) {
    return ClaimOutcome._(
      userId: userId,
      executed: true,
      guestId: guestId,
      claimedRecordCount: claimedRecordCount,
      alreadyOwnedCount: alreadyOwnedCount,
      preservedOwnedByOtherCount: preservedOwnedByOtherCount,
      claimedKeys: claimedKeys,
    );
  }

  /// A claim refused by the one-account-per-device boundary. Nothing changed.
  factory ClaimOutcome.refusedBoundToOther({
    required String userId,
    required String guestId,
    required String boundUserId,
  }) {
    return ClaimOutcome._(
      userId: userId,
      executed: false,
      guestId: guestId,
      boundUserId: boundUserId,
    );
  }

  /// The claim is BLOCKED because the persisted ownership registry is corrupt.
  ///
  /// Auth itself succeeded; only the local ownership claim is blocked. The
  /// registry's true owner can no longer be proven, so nothing is claimed,
  /// nothing is overwritten, and the device is never re-bound. The corrupt
  /// payload is left untouched for diagnosis.
  factory ClaimOutcome.registryCorrupt({required String userId}) {
    return ClaimOutcome._(
      userId: userId,
      executed: false,
      guestId: '',
      blockedCorruptRegistry: true,
    );
  }

  @override
  String toString() {
    if (blockedCorruptRegistry) {
      return 'ClaimOutcome(blocked, corruptRegistry)';
    }
    return executed
        ? 'ClaimOutcome(executed, claimed=$claimedRecordCount, '
            'alreadyOwned=$alreadyOwnedCount, '
            'preservedOther=$preservedOwnedByOtherCount)'
        : 'ClaimOutcome(refused, boundToOther=$boundUserId)';
  }
}