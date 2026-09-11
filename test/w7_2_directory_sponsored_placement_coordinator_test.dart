import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/directory/application/directory_sponsored_placement_coordinator.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/monetization/domain/entities/advertisement_campaign.dart';
import 'package:civilpedia/features/monetization/domain/monetization_reference.dart';
import 'package:civilpedia/features/monetization/domain/services/campaign_placement_resolver.dart';
import 'package:civilpedia/features/monetization/domain/services/campaign_source.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/campaign_destination.dart';

import 'helpers/canonical_directory_test_helpers.dart';

const _directorySponsored = 'directory_sponsored';

final _at = DateTime(2026, 3, 15, 12, 0, 0);

MonetizationReference _ref(String id) => MonetizationReference(
      ownerDomain: MonetizationOwners.directory,
      entityType: 'provider',
      entityId: id,
    );

AdvertisementCampaign _campaign({
  required String id,
  bool isEnabled = true,
  String placementKey = _directorySponsored,
  MonetizationReference? subject,
  CampaignDestination? destination,
  String disclosureLabel = 'Sponsored',
}) {
  final s = subject ?? _ref('p-1');
  return AdvertisementCampaign(
    id: id,
    isEnabled: isEnabled,
    placementKey: placementKey,
    subject: s,
    destination: destination ?? CampaignDestination.internal(s),
    disclosureLabel: disclosureLabel,
  );
}

class _FakeCampaignSource implements CampaignSource {
  _FakeCampaignSource(this.result);
  final Future<List<AdvertisementCampaign>> Function() result;

  @override
  Future<List<AdvertisementCampaign>> campaignsFor(String placementKey) {
    return result();
  }
}

class _ThrowingLoadCloudDirectoryRepository implements CloudDirectoryRepository {
  @override
  bool get isAvailable => true;

  @override
  Future<DirectoryCachedData?> readCache() async => null;

  @override
  Future<DirectoryRefreshResult> refresh() async =>
      const DirectoryRefreshResult(status: DirectoryRefreshStatus.failure);

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    throw Exception('loadByCanonicalId failed');
  }

  @override
  Future<DirectoryLoadResult> load() async =>
      const DirectoryLoadResult(state: DirectoryLoadState.empty);
}

void main() {
  DirectorySponsoredPlacementCoordinator coordinator(
    CampaignSource source,
    CloudDirectoryRepository repo,
  ) {
    return DirectorySponsoredPlacementCoordinator(
      campaignSource: source,
      directoryRepository: repo,
      resolver: const CampaignPlacementResolver(),
    );
  }

  group('W7.2 COORDINATOR — no sponsored placement', () {
    test('A: zero campaigns → null', () async {
      final c = coordinator(
        _FakeCampaignSource(() async => const []),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(
        await c.resolveFirstRenderable(at: _at),
        isNull,
      );
    });

    test('B: source throws → null (fail closed)', () async {
      final c = coordinator(
        _FakeCampaignSource(() async => throw Exception('source down')),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('C: inactive campaign → null', () async {
      final c = coordinator(
        _FakeCampaignSource(() async => [_campaign(id: 'c1', isEnabled: false)]),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('C2: campaign for another placement → null', () async {
      final c = coordinator(
        _FakeCampaignSource(
          () async => [_campaign(id: 'c1', placementKey: 'home_banner')],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });
  });

  group('W7.2 COORDINATOR — renderability gating', () {
    test('K: empty disclosure → candidate skipped', () async {
      final c = coordinator(
        _FakeCampaignSource(
          () async => [_campaign(id: 'c1', disclosureLabel: '   ')],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('L: external destination → candidate skipped', () async {
      final c = coordinator(
        _FakeCampaignSource(
          () async => [
            _campaign(
              id: 'c1',
              destination: CampaignDestination.external('https://example.com'),
            ),
          ],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('L2: non-Directory reference → candidate skipped', () async {
      final foreign = const MonetizationReference(
        ownerDomain: 'projects',
        entityType: 'project',
        entityId: 'x-1',
      );
      final c = coordinator(
        _FakeCampaignSource(
          () async => [
            _campaign(id: 'c1', subject: foreign, destination: CampaignDestination.internal(foreign)),
          ],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('J: missing entity (loadByCanonicalId null) → placement omitted', () async {
      final c = coordinator(
        _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-other')]),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
    });

    test('J2: loadByCanonicalId throws → placement omitted', () async {
      final throwing = FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]);
      // Force a throw via a repo whose loadByCanonicalId throws.
      final c = coordinator(
        _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
        _ThrowingLoadCloudDirectoryRepository(),
      );
      expect(await c.resolveFirstRenderable(at: _at), isNull);
      expect(throwing, isNotNull);
    });
  });

  group('W7.2 COORDINATOR — selection & pairing', () {
    test('D: one eligible + renderable → one placement pairing the real entity',
        () async {
      final repo = FakeCloudDirectoryRepository(
        [fakeEntity(id: 'p-1', name: 'Acme')],
      );
      final c = coordinator(
        _FakeCampaignSource(() async => [_campaign(id: 'c1')]),
        repo,
      );
      final result = await c.resolveFirstRenderable(at: _at);
      expect(result, isNotNull);
      expect(result!.placement.campaignId, 'c1');
      expect(result.placement.disclosureLabel, 'Sponsored');
      // Pairing references the REAL Directory-owned entity, never a clone.
      expect(result.entity, isA<CanonicalDirectoryEntity>());
      expect(result.entity.id, 'p-1');
      expect(result.entity.name, 'Acme');
    });

    test('M: first eligible unrenderable + second renderable → second renders',
        () async {
      final c = coordinator(
        _FakeCampaignSource(
          () async => [
            _campaign(id: 'c-empty', disclosureLabel: ' '),
            _campaign(id: 'c-missing', subject: _ref('p-nope')),
            _campaign(id: 'c-good'),
          ],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      final result = await c.resolveFirstRenderable(at: _at);
      expect(result, isNotNull);
      expect(result!.placement.campaignId, 'c-good');
    });

    test('N: two renderable eligible → exactly ONE, first source-order wins',
        () async {
      final c = coordinator(
        _FakeCampaignSource(
          () async => [_campaign(id: 'c-a'), _campaign(id: 'c-b')],
        ),
        FakeCloudDirectoryRepository([fakeEntity(id: 'p-1')]),
      );
      final result = await c.resolveFirstRenderable(at: _at);
      expect(result, isNotNull);
      // Exactly one result; source-order first wins.
      expect(result!.placement.campaignId, 'c-a');
    });

    test('F: resolves REAL CanonicalDirectoryEntity via loadByCanonicalId',
        () async {
      final repo = FakeCloudDirectoryRepository(
        [fakeEntity(id: 'p-7', name: 'RealCo')],
      );
      final c = coordinator(
        _FakeCampaignSource(
          () async => [
            _campaign(id: 'c1', subject: _ref('p-7'), destination: CampaignDestination.internal(_ref('p-7'))),
          ],
        ),
        repo,
      );
      final result = await c.resolveFirstRenderable(at: _at);
      expect(result!.entity.id, 'p-7');
      expect(result.entity.name, 'RealCo');
    });
  });
}