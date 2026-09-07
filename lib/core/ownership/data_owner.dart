/// A5.5 — Local data ownership value object.
///
/// Distinguishes the two local ownership kinds the product supports today:
/// * guest/local owner — a device-scoped guest identity
///   ([LocalUserProfile.anonymousInstallId] or the persisted install id);
/// * authenticated user owner — always a Supabase `auth.users.id`
///   ([AuthSession.userId]).
///
/// Google provider ids are NEVER stored as ownership. Authenticated ownership
/// is exclusively the canonical Supabase auth user id.
enum LocalOwnerType {
  /// Device/guest-scoped ownership before any claim.
  guest,

  /// Authenticated account ownership (Supabase `auth.users.id`).
  user,
}

/// Immutable ownership stamp for one local record or whole store.
///
/// Serialized into the A5.5 ownership registry (`AppStorageKeys
/// .ownershipRegistry`) and never written into the user-data records
/// themselves, so the frozen on-disk contracts (projects, notes, saved
/// references, favorites) stay byte-identical.
class DataOwner {
  DataOwner._({required this.type, this.guestId, this.userId})
    : assert(
        (type == LocalOwnerType.guest && guestId != null && guestId.isNotEmpty) ||
            (type == LocalOwnerType.user && userId != null && userId.isNotEmpty),
        'A guest owner requires a non-empty guestId; a user owner requires a '
        'non-empty userId.',
      );

  /// Guest/device ownership anchored on a stable guest identity.
  DataOwner.guest({required String guestId})
    : this._(type: LocalOwnerType.guest, guestId: guestId, userId: null);

  /// Authenticated ownership anchored on the canonical Supabase user id.
  DataOwner.user({required String userId})
    : this._(type: LocalOwnerType.user, userId: userId, guestId: null);

  /// The ownership kind.
  final LocalOwnerType type;

  /// The guest identity when [type] is [LocalOwnerType.guest], else null.
  final String? guestId;

  /// The canonical Supabase `auth.users.id` when [type] is
  /// [LocalOwnerType.user], else null.
  final String? userId;

  bool get isGuest => type == LocalOwnerType.guest;

  bool get isUser => type == LocalOwnerType.user;

  /// Whether this stamp belongs to the authenticated user [userId].
  bool ownedBy(String userId) =>
      isUser && this.userId == userId && userId.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    if (guestId != null) 'guestId': guestId,
    if (userId != null) 'userId': userId,
  };

  /// Tolerant parse: returns null unless the map describes a valid owner.
  static DataOwner? tryFromMap(Map<String, dynamic> map) {
    try {
      final typeName = map['type'];
      if (typeName is! String) return null;
      final type = LocalOwnerType.values.asNameMap()[typeName];
      if (type == null) return null;
      if (type == LocalOwnerType.guest) {
        final guestId = map['guestId'] as String?;
        if (guestId == null || guestId.isEmpty) return null;
        return DataOwner.guest(guestId: guestId);
      }
      final userId = map['userId'] as String?;
      if (userId == null || userId.isEmpty) return null;
      return DataOwner.user(userId: userId);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is! DataOwner) return false;
    return other.type == type && other.guestId == guestId && other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(type, guestId, userId);

  @override
  String toString() => 'DataOwner(${type.name}'
      '${guestId != null ? ', guest=$guestId' : ''}'
      '${userId != null ? ', user=$userId' : ''})';
}