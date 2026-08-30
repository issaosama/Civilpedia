/// W3.1 — Canonical Saved-reference model (M7 §12, M8 W3.1).
///
/// A Saved item is a small reference into a domain-owned entity, never a copy
/// of the entity itself. Identity is a deterministic composite of
/// `ownerDomain` + `entityType` + `entityId`, so the same raw id living in
/// different namespaces stays distinct (M7 §13/§29).
///
/// `savedAt` is optional: the current legacy stores (`favorites`,
/// `encyclopediaFavorites`) persist bare id lists with no timestamps, so
/// legacy-derived references always carry `savedAt == null` instead of
/// invented history (owner-approved W3.1 compatibility decision). W3.1 is
/// READ-ONLY: nothing here writes storage or introduces keys.
class SavedItemReference {
  const SavedItemReference({
    required this.ownerDomain,
    required this.entityType,
    required this.entityId,
    this.savedAt,
  });

  /// Owning domain of the referenced entity (currently `knowledge`).
  final String ownerDomain;

  /// Entity kind within the owning domain (`article` / `topic`).
  final String entityType;

  /// Stable source id of the referenced entity. Never a title/label/route.
  final String entityId;

  /// When the reference was saved. Null when the legacy store recorded no
  /// timestamp (today's `favorites` / `encyclopediaFavorites` always do).
  final DateTime? savedAt;

  /// Deterministic composite saved id, e.g. `knowledge:article:<articleId>`.
  String get id => '$ownerDomain:$entityType:$entityId';

  @override
  bool operator ==(Object other) {
    if (other is! SavedItemReference) return false;
    return other.ownerDomain == ownerDomain &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.savedAt == savedAt;
  }

  @override
  int get hashCode => Object.hash(ownerDomain, entityType, entityId, savedAt);

  @override
  String toString() => 'SavedItemReference($id)';
}

/// Owning-domain vocabulary used by Saved references today (M7 §13/§29).
abstract final class SavedReferenceOwners {
  /// Knowledge domain (articles + encyclopedia topics).
  static const String knowledge = 'knowledge';
}

/// Entity-type vocabulary used by Saved references today (M7 §12 table).
abstract final class SavedReferenceEntityTypes {
  /// Legacy article favorites.
  static const String article = 'article';

  /// Encyclopedia topic favorites.
  static const String topic = 'topic';
}