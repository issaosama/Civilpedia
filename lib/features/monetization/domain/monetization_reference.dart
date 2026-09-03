/// W7.1 — Domain-neutral reference to a sponsored subject.
///
/// Monetization is the sole owner of sponsorship/campaign. The single most
/// important W7.1 boundary is **sponsored ≠ second entity** (M4 §10, M6 §13):
/// a SponsoredPlacement is a projection/relationship, never a duplicate of a
/// Directory provider. This file provides the smallest stable reference shape a
/// campaign uses to point at the real sponsored subject.
///
/// The shape mirrors the documented cross-domain stable-identity contract used
/// elsewhere (M4 §16/§19, M7 §12): `ownerDomain` + `entityType` + `entityId`,
/// with a deterministic composite id. It NEVER copies the referenced entity —
/// the authoritative profile data stays in the owning domain.
///
/// No persistence, no storage, no Flutter, no Home/Directory presentation
/// dependency. Pure domain value.
class MonetizationReference {
  const MonetizationReference({
    required this.ownerDomain,
    required this.entityType,
    required this.entityId,
  });

  /// Owning domain of the referenced sponsored subject (e.g. `directory`).
  final String ownerDomain;

  /// Entity kind within the owning domain (e.g. `provider`).
  final String entityType;

  /// Stable source identity of the referenced subject. Never a label/route.
  final String entityId;

  /// Deterministic composite id, e.g. `directory:provider:<providerId>`.
  String get id => '$ownerDomain:$entityType:$entityId';

  /// True when all three identity fields carry a non-empty stable value.
  bool get isValid =>
      ownerDomain.isNotEmpty && entityType.isNotEmpty && entityId.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is MonetizationReference &&
      other.ownerDomain == ownerDomain &&
      other.entityType == entityType &&
      other.entityId == entityId;

  @override
  int get hashCode => Object.hash(ownerDomain, entityType, entityId);

  @override
  String toString() => 'MonetizationReference($id)';
}

/// Owning-domain vocabulary used by Monetization references (M6 §13, M4 §10).
abstract final class MonetizationOwners {
  /// Directory domain (service-business providers) — sponsored » same entity.
  static const String directory = 'directory';
}
