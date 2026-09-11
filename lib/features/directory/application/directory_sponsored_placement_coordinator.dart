import '../../monetization/domain/entities/advertisement_campaign.dart';
import '../../monetization/domain/entities/sponsored_placement.dart';
import '../../monetization/domain/monetization_reference.dart';
import '../../monetization/domain/services/campaign_placement_resolver.dart';
import '../../monetization/domain/services/campaign_source.dart';
import '../../monetization/domain/value_objects/ad_placement_request.dart';
import '../../monetization/domain/value_objects/campaign_destination.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';
import '../domain/directory_placement_key.dart';

/// V1-R05 — The owning-surface result of a resolved Directory sponsored placement.
///
/// A pure, read-only pairing that references the W7.1 [SponsoredPlacement] AND
/// the real resolved canonical [CanonicalDirectoryEntity] it should present.
/// Never contains or copies a second entity: [entity] IS the real
/// Directory-owned entity.
class DirectorySponsoredPlacement {
  const DirectorySponsoredPlacement({
    required this.placement,
    required this.entity,
  });

  /// The Monetization-owned resolution.
  final SponsoredPlacement placement;

  /// The real canonical Directory entity the placement resolves to.
  final CanonicalDirectoryEntity entity;
}

/// V1-R05 — Directory owning-surface coordinator for the sponsored search slot.
///
/// V1-R05 adapted: resolves using [CloudDirectoryRepository] and
/// [CanonicalDirectoryEntity] instead of the legacy [DirectoryRepository] /
/// [ServiceBusinessProfile] pair. Rendering contract and fail-closed behavior
/// remain identical.
class DirectorySponsoredPlacementCoordinator {
  DirectorySponsoredPlacementCoordinator({
    required CampaignSource campaignSource,
    required CloudDirectoryRepository directoryRepository,
    CampaignPlacementResolver resolver = const CampaignPlacementResolver(),
  })  : _campaignSource = campaignSource,
        _directoryRepository = directoryRepository,
        _resolver = resolver;

  final CampaignSource _campaignSource;
  final CloudDirectoryRepository _directoryRepository;
  final CampaignPlacementResolver _resolver;

  /// Resolves the single presentation-ready sponsored placement at [at],
  /// or null when none is renderable. Fails closed on every error path.
  Future<DirectorySponsoredPlacement?> resolveFirstRenderable({
    required DateTime at,
    String placementKey = DirectoryPlacementKeys.directorySponsored,
  }) async {
    final List<AdvertisementCampaign> campaigns;
    try {
      campaigns = await _campaignSource.campaignsFor(placementKey);
    } catch (_) {
      return null;
    }

    final request = AdPlacementRequest(placementKey: placementKey);
    final eligible = _resolver.evaluateAll(request, campaigns, at: at);

    for (final placement in eligible) {
      final entity = await _resolveEntity(placement);
      if (entity != null) {
        return DirectorySponsoredPlacement(
          placement: placement,
          entity: entity,
        );
      }
    }
    return null;
  }

  Future<CanonicalDirectoryEntity?> _resolveEntity(
    SponsoredPlacement placement,
  ) async {
    if (placement.disclosureLabel.trim().isEmpty) return null;

    final destination = placement.destination;
    if (destination.kind != CampaignDestinationKind.internal) return null;

    final reference = destination.reference;
    if (reference == null) return null;
    if (!_isDirectoryProviderReference(reference)) return null;

    CanonicalDirectoryEntity? entity;
    try {
      entity = await _directoryRepository.loadByCanonicalId(reference.entityId);
    } catch (_) {
      return null;
    }
    return entity;
  }

  bool _isDirectoryProviderReference(MonetizationReference reference) {
    return reference.ownerDomain == MonetizationOwners.directory &&
        reference.entityType == DirectoryPlacementKeys.providerEntityType &&
        reference.entityId.isNotEmpty;
  }
}
