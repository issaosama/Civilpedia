import '../domain/entities/advertisement_campaign.dart';
import '../domain/services/campaign_source.dart';

/// W7.2 — Production default [CampaignSource] that is HONEST-EMPTY.
///
/// With no configured campaign authority, this source reports no campaigns for
/// any placement. It exists so an unconfigured production build renders no
/// sponsored content (per M6 §27 "no active eligible campaign → NO
/// SponsoredPlacement") instead of fabricating or erroring.
///
/// Stateless and immutable; safe to use as a shared default.
///
/// A durable campaign authority (authoring, storage) is a future Monetization
/// responsibility and is NOT introduced in W7.2.
class EmptyCampaignSource implements CampaignSource {
  const EmptyCampaignSource();

  @override
  Future<List<AdvertisementCampaign>> campaignsFor(String placementKey) async {
    return const <AdvertisementCampaign>[];
  }
}
