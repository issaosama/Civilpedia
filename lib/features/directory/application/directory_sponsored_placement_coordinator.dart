import '../../monetization/domain/entities/advertisement_campaign.dart';
import '../../monetization/domain/entities/sponsored_placement.dart';
import '../../monetization/domain/monetization_reference.dart';
import '../../monetization/domain/services/campaign_placement_resolver.dart';
import '../../monetization/domain/services/campaign_source.dart';
import '../../monetization/domain/value_objects/ad_placement_request.dart';
import '../../monetization/domain/value_objects/campaign_destination.dart';
import '../../profile/domain/service_business_profile.dart';
import '../domain/directory_placement_key.dart';
import '../domain/directory_repository.dart';

/// W7.2 — The owning-surface result of a resolved Directory sponsored placement.
///
/// A pure, read-only pairing that references the W7.1 [SponsoredPlacement] AND
/// the real resolved Directory [ServiceBusinessProfile] it should present. It
/// never contains or copies a second provider entity (sponsored ≠ second
/// entity, M4 §10 / M6 §13): [profile] IS the real Directory-owned entity.
class DirectorySponsoredPlacement {
  const DirectorySponsoredPlacement({
    required this.placement,
    required this.profile,
  });

  /// The Monetization-owned resolution (disclosure, campaign identity, subject).
  final SponsoredPlacement placement;

  /// The real Directory provider the placement resolves to (never a clone).
  final ServiceBusinessProfile profile;
}

/// W7.2 — Directory owning-surface coordinator for the sponsored search slot.
///
/// Owning-surface bridge between Monetization (campaign/sponsorship) and
/// Directory (real provider entity). It turns candidate campaigns into the ONE
/// presentation-ready [DirectorySponsoredPlacement] shown above the organic
/// Directory search results.
///
/// Rendering contract (§GOAL):
///   campaign source → AdPlacementRequest(directory_sponsored)
///     → CampaignPlacementResolver.evaluateAll
///     → FIRST RENDERABLE eligible placement in source order
///     → resolve REAL Directory provider → presentation
///
/// Selection policy (W7.2 §6): with exactly ONE sponsored slot, the first
/// RENDERABLE eligible placement in campaign-source input order wins. The
/// [CampaignPlacementResolver] is FROZEN (W7.1) — no priority/bidding/random/
/// round-robin/campaign-score/paid-rank/first-match is added to it. This
/// selection policy belongs ONLY to this W7.2 Directory consumer.
///
/// "Renderable" means ALL of (W7.2 §6):
/// - placement remains W7.1-eligible (guaranteed by evaluateAll);
/// - disclosureLabel is non-empty after trim;
/// - CampaignDestination is INTERNAL;
/// - reference identifies ownerDomain=directory and entityType=provider;
/// - DirectoryRepository.loadById(entityId) returns a real profile.
///
/// If the first eligible campaign cannot be rendered, the coordinator continues
/// to the next eligible placement. If none are renderable it returns null → no
/// sponsored slot and no blank space.
///
/// FAIL CLOSED (W7.2 §6): a throwing source, malformed references, missing
/// providers, empty disclosure, external destinations — each skips the candidate
/// and never surfaces an exception to the caller. Organic Directory behavior is
/// never affected by a monetization failure.
class DirectorySponsoredPlacementCoordinator {
  DirectorySponsoredPlacementCoordinator({
    required CampaignSource campaignSource,
    required DirectoryRepository directoryRepository,
    CampaignPlacementResolver resolver = const CampaignPlacementResolver(),
  })  : _campaignSource = campaignSource,
        _directoryRepository = directoryRepository,
        _resolver = resolver;

  final CampaignSource _campaignSource;
  final DirectoryRepository _directoryRepository;
  final CampaignPlacementResolver _resolver;

  /// Resolves the single presentation-ready sponsored placement for the
  /// canonical Directory sponsored placement at [at], or null when none is
  /// renderable. [at] is injected (W7.1 determinism) so resolution is
  /// deterministic and fully testable.
  Future<DirectorySponsoredPlacement?> resolveFirstRenderable({
    required DateTime at,
    String placementKey = DirectoryPlacementKeys.directorySponsored,
  }) async {
    final List<AdvertisementCampaign> campaigns;
    try {
      campaigns = await _campaignSource.campaignsFor(placementKey);
    } catch (_) {
      // Source error → fail closed, no sponsored placement.
      return null;
    }

    final request = AdPlacementRequest(placementKey: placementKey);
    final eligible = _resolver.evaluateAll(request, campaigns, at: at);

    for (final placement in eligible) {
      final profile = await _resolveProfile(placement);
      if (profile != null) {
        return DirectorySponsoredPlacement(
          placement: placement,
          profile: profile,
        );
      }
    }
    return null;
  }

  /// Resolves the real Directory provider if [placement] is renderable, else
  /// null. Each renderability failure skips only this candidate (does not
  /// abort evaluation of later eligible candidates).
  Future<ServiceBusinessProfile?> _resolveProfile(
    SponsoredPlacement placement,
  ) async {
    if (placement.disclosureLabel.trim().isEmpty) return null;

    final destination = placement.destination;
    if (destination.kind != CampaignDestinationKind.internal) return null;

    final reference = destination.reference;
    if (reference == null) return null;
    if (!_isDirectoryProviderReference(reference)) return null;

    ServiceBusinessProfile? profile;
    try {
      profile = await _directoryRepository.loadById(reference.entityId);
    } catch (_) {
      return null;
    }
    if (profile == null) return null;
    return profile;
  }

  bool _isDirectoryProviderReference(MonetizationReference reference) {
    return reference.ownerDomain == MonetizationOwners.directory &&
        reference.entityType == DirectoryPlacementKeys.providerEntityType &&
        reference.entityId.isNotEmpty;
  }
}
