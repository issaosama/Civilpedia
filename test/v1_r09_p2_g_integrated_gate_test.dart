import 'dart:async';
import 'dart:convert';

import 'package:civilpedia/core/di/staff_operations_scope.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/core/widgets/transport_status_banner.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_claim_target.dart';
import 'package:civilpedia/features/business/domain/business_claim_target_gateway.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:civilpedia/features/business/domain/staff_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/staff_application_detail.dart';
import 'package:civilpedia/features/business/domain/staff_application_summary.dart';
import 'package:civilpedia/features/business/domain/staff_read_result.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_claim_target_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/business_profile_editor_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/managed_businesses_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/staff_access_provider.dart';
import 'package:civilpedia/features/directory/application/directory_refresh_controller.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/encyclopedia_content_notice.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_gateway.dart';
import 'fakes/fake_business_membership_gateway.dart';
import 'fakes/fake_business_profile_management_gateway.dart';
import 'helpers/canonical_directory_test_helpers.dart';

Future<void> _settle([int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void _noop() {}

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource({bool available = false}) : _available = available;

  bool _available;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  int checkCalls = 0;

  @override
  Future<bool> checkAvailability() async {
    checkCalls++;
    return _available;
  }

  @override
  Stream<bool> get availabilityChanges => _controller.stream;

  void setAvailable(bool value) {
    if (_available == value) return;
    _available = value;
    _controller.add(value);
  }

  Future<void> close() => _controller.close();
}

class _PendingTransportSource implements TransportSource {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  final Completer<bool> _completer = Completer<bool>();

  @override
  Future<bool> checkAvailability() => _completer.future;

  @override
  Stream<bool> get availabilityChanges => _controller.stream;

  Future<void> close() => _controller.close();
}

Future<ConnectivityProvider> _offlineConnectivity() async {
  final connectivity = ConnectivityProvider(
    source: _FakeTransportSource(available: false),
  );
  await connectivity.initialization;
  return connectivity;
}

Future<ConnectivityProvider> _onlineConnectivity() async {
  final connectivity = ConnectivityProvider(
    source: _FakeTransportSource(available: true),
  );
  await connectivity.initialization;
  return connectivity;
}

class _ScriptedDirectoryRepository implements CloudDirectoryRepository {
  _ScriptedDirectoryRepository({this.cache});

  DirectoryCachedData? cache;
  DirectoryRefreshStatus refreshStatus = DirectoryRefreshStatus.success;
  List<CanonicalDirectoryEntity> entities = const [];
  DateTime? refreshedAt;
  int refreshCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<DirectoryCachedData?> readCache() async => cache;

  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    return DirectoryRefreshResult(
      status: refreshStatus,
      entities: (refreshStatus == DirectoryRefreshStatus.success ||
              refreshStatus == DirectoryRefreshStatus.authoritativeEmpty)
          ? List.of(entities)
          : const [],
      refreshedAt: refreshedAt,
    );
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    final cached = cache;
    if (cached == null) return null;
    for (final entity in cached.entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  @override
  Future<DirectoryLoadResult> load() async {
    return DirectoryLoadResult(
      state: refreshStatus == DirectoryRefreshStatus.success
          ? DirectoryLoadState.fresh
          : DirectoryLoadState.stale,
      entities: List.of(entities),
      refreshedAt: refreshedAt,
    );
  }
}

class _MemoryProfileRepository implements UserProfileRepository {
  LocalUserProfile? _profile;

  @override
  Future<LocalUserProfile?> loadProfile() async => _profile;

  @override
  Future<void> saveProfile(LocalUserProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> clearProfile() async {
    _profile = null;
  }
}

class _CloudOnlyA implements PersonalProfileRemoteGateway {
  int fetchCalls = 0;
  int createCalls = 0;
  int updateRegionCalls = 0;
  int saveEditableCalls = 0;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    return CloudProfile(
      userId: userId,
      displayName: 'Engineer A',
      roleCode: 'site_engineer',
    );
  }

  @override
  Future<void> createProfile(CloudProfile profile) async {
    createCalls++;
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {
    updateRegionCalls++;
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {
    saveEditableCalls++;
  }
}

class _ScriptedBusinessGateway implements BusinessApplicationGateway {
  @override
  bool get isAvailable => true;

  int listCalls = 0;
  int getCalls = 0;
  int createNewCalls = 0;
  int createClaimCalls = 0;
  int submitCalls = 0;
  int resubmitCalls = 0;

  late final List<BusinessApplication> applications = [
    BusinessApplication(
      id: 'app-A-1',
      applicantUserId: 'uuid-0000-0000',
      type: BusinessApplicationType.newApplication,
      status: BusinessApplicationStatus.draft,
    ),
  ];

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    listCalls++;
    return applications;
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    getCalls++;
    return null;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    createNewCalls++;
    return const BusinessApplicationCreateDenied(
      BusinessApplicationRejectionCause.guestUser,
    );
  }

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async {
    createClaimCalls++;
    return const BusinessApplicationCreateDenied(
      BusinessApplicationRejectionCause.guestUser,
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) async {
    submitCalls++;
    return const BusinessApplicationSubmitDenied(
      BusinessApplicationSubmitCause.unauthenticated,
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) async {
    resubmitCalls++;
    return const BusinessApplicationSubmitDenied(
      BusinessApplicationSubmitCause.unauthenticated,
    );
  }
}

class _ScriptedClaimGateway implements BusinessClaimTargetGateway {
  @override
  bool get isAvailable => true;

  int listCalls = 0;
  List<BusinessClaimTarget> targets = const [
    BusinessClaimTarget(
      id: '11111111-1111-4111-8111-111111111111',
      name: 'Claim Target A',
      entityType: 'company',
      claimStatus: 'unclaimed',
    ),
  ];

  @override
  Future<List<BusinessClaimTarget>> listUnclaimedTargets() async {
    listCalls++;
    return targets;
  }
}

class _ScriptedStaffGateway implements BusinessApplicationStaffGateway {
  _ScriptedStaffGateway() {
    capabilities = StaffReadSuccess(
      StaffApplicationCapabilities.tryFromJson({
        'permissions': [StaffApplicationPermission.read],
      })!,
    );
    queue = StaffReadSuccess(
      StaffApplicationPage(
        items: [
          StaffApplicationSummary(
            id: 'app-staff-1',
            type: BusinessApplicationType.newApplication,
            status: BusinessApplicationStatus.submitted,
            createdAt: DateTime.utc(2024, 1, 1),
            updatedAt: DateTime.utc(2024, 1, 1),
          ),
        ],
      ),
    );
  }

  @override
  bool get isAvailable => true;

  int capabilitiesCalls = 0;
  int listCalls = 0;
  int detailCalls = 0;
  int mutationCalls = 0;

  late StaffReadResult<StaffApplicationCapabilities> capabilities;
  late StaffReadResult<StaffApplicationPage> queue;

  int _countMutation() {
    mutationCalls++;
    return mutationCalls;
  }

  @override
  Future<BusinessApplicationStaffResult> beginReview(String applicationId) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) async {
    _countMutation();
    return const BusinessApplicationStaffDenied(
      BusinessApplicationStaffCause.unexpected,
    );
  }

  @override
  Future<StaffReadResult<StaffApplicationCapabilities>> getCapabilities() async {
    capabilitiesCalls++;
    return capabilities;
  }

  @override
  Future<StaffReadResult<StaffApplicationPage>> listApplications({
    BusinessApplicationStatus? statusFilter,
    BusinessApplicationType? typeFilter,
    int limit = 20,
    StaffApplicationCursor? cursor,
  }) async {
    listCalls++;
    return queue;
  }

  @override
  Future<StaffReadResult<StaffApplicationDetail>> getApplicationDetail(
    String applicationId,
  ) async {
    detailCalls++;
    return const StaffReadUnavailable<StaffApplicationDetail>();
  }
}

final _managedProfileFixture = ManagedBusinessProfile(
  id: '22222222-2222-4222-8222-222222222222',
  entityType: 'company',
  name: 'Public Biz A',
  lifecycleStatus: 'active',
  verificationStatus: VerificationStatus.unverified,
  claimStatus: 'claimed',
  createdAt: DateTime.utc(2024, 1, 1),
  updatedAt: DateTime.utc(2024, 1, 1),
);

/// Mirrors production main.dart `resetAccountBoundState()` wiring: every wired
/// account-bound provider is the reset authority for its identity scoped state
/// (V1-R08 final pass, finding 1; V1-R09 P2-G §8).
class _SixProviderResetHarness {
  _SixProviderResetHarness() {
    gateway = FakeAuthGateway(restoredSession: fakeSession);
    auth = AuthProvider(gateway: gateway, onAccountBoundReset: resetAccountBoundState);
    profile = UserProfileProvider(
      repository: _MemoryProfileRepository(),
      cloudProfileGateway: _CloudOnlyA(),
      auth: auth,
    );
    business = BusinessApplicationProvider(gateway: businessGateway, auth: auth);
    claims = BusinessClaimTargetProvider(gateway: claimGateway, auth: auth);
    managed = ManagedBusinessesProvider(
      membershipGateway: membershipGateway,
      auth: auth,
    );
    editor = BusinessProfileEditorProvider(
      gateway: managementGateway,
      directoryRepository: directoryRepo,
      auth: auth,
    );
    scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
  }

  late final FakeAuthGateway gateway;
  late final AuthProvider auth;
  late final UserProfileProvider profile;
  late final BusinessApplicationProvider business;
  late final BusinessClaimTargetProvider claims;
  late final ManagedBusinessesProvider managed;
  late final BusinessProfileEditorProvider editor;
  late final StaffOperationsScope scope;

  final _ScriptedBusinessGateway businessGateway = _ScriptedBusinessGateway();
  final _ScriptedClaimGateway claimGateway = _ScriptedClaimGateway();
  final FakeBusinessMembershipGateway membershipGateway =
      FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable(const [
          ManagedBusinessSummary(
            entityId: '99999999-9999-4999-8999-999999999999',
            name: 'Managed Biz A',
            entityType: 'company',
            membershipRole: BusinessRole.owner,
            claimStatus: 'claimed',
            verificationStatus: 'unverified',
          ),
        ]),
      );
  final FakeBusinessProfileManagementGateway managementGateway =
      FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_managedProfileFixture),
      );
  final _ScriptedStaffGateway staffGateway = _ScriptedStaffGateway();
  final _ScriptedDirectoryRepository directoryRepo = _ScriptedDirectoryRepository(
    cache: DirectoryCachedData(
      entities: [
        fakeEntity(id: 'dir-reset-kept', name: 'Public Biz Keep'),
      ],
      refreshedAt: DateTime.utc(2024, 1, 1),
    ),
  );

  int resetCount = 0;

  void resetAccountBoundState() {
    resetCount++;
    profile.resetForIdentityChange();
    business.resetForIdentityChange();
    claims.resetForIdentityChange();
    managed.reset();
    editor.reset();
    scope.resetForAuthChange();
  }

  Future<void> authenticateAndLoad() async {
    await auth.restoreSession();
    await _settle();
    await profile.ensureCloudProfileLoaded();
    await business.loadApplications();
    await claims.reload();
    await managed.load();
    await editor.load(_managedProfileFixture.id);
    await scope.access.load();
    await scope.queue.loadInitial();
  }

  void dispose() {
    scope.access.dispose();
    scope.queue.dispose();
    scope.detail.dispose();
    editor.dispose();
    managed.dispose();
    claims.dispose();
    business.dispose();
    profile.dispose();
    auth.dispose();
    gateway.close();
  }
}

class _FakeFavoritesStore implements EncyclopediaFavoritesStore {
  final List<String> _ids = [];

  @override
  Future<List<String>> read() async => List.unmodifiable(_ids);

  @override
  Future<void> add(String topicId) async => _ids.add(topicId);

  @override
  Future<void> remove(String topicId) async => _ids.remove(topicId);
}

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final data = assets[key];
    if (data == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(utf8.encode(data));
  }
}

EngineeringTopic _topicFixture(String id, String title, {String categoryId = 'concrete'}) {
  return EngineeringTopic(
    id: id,
    titleAr: title,
    categoryId: categoryId,
    summary: 'ملخص $id',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    tags: const [],
  );
}

class _FakeEncyclopediaRepository implements EncyclopediaRepository {
  _FakeEncyclopediaRepository({this.topics = const [], this.categories = const {}});

  final List<EngineeringTopic> topics;
  final Map<String, CategoryInfo> categories;

  Object? allTopicsError;

  int allTopicsCalls = 0;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    allTopicsCalls++;
    final e = allTopicsError;
    if (e != null) throw e;
    return topics;
  }

  @override
  Future<EngineeringTopic?> getTopicById(String id) async {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  @override
  Future<List<EngineeringTopic>> getTopicsByCategory(String categoryId) async {
    return topics.where((t) => t.categoryId == categoryId).toList();
  }

  @override
  Future<Map<String, CategoryInfo>> getCategories() async => categories;

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async => const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------
  // §5 Transport policy parity: Directory reconnects on a real
  // unavailable->available transition (exactly once per generation, no storm);
  // Profile/Business/Staff/Encyclopedia never auto-refresh from connectivity.
  // ------------------------------------------------------------------
  group('P2-G §5 connectivity policy parity', () {
    test('directory reconnect generation is claimed exactly once and never '
        'storms', () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      )..refreshStatus = DirectoryRefreshStatus.network;

      final connectivity = await _offlineConnectivity();
      final controller = DirectoryRefreshController(
        repository: repository,
        connectivity: connectivity,
      );
      await controller.initialize();

      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.cause, RemoteDataCause.offline);
      expect(controller.hasSnapshot, isTrue);
      expect(controller.entities.single.id, 'd1');
      final refreshCallsAfterInit = repository.refreshCalls;
      expect(refreshCallsAfterInit, 1);

      await _settle();
      expect(repository.refreshCalls, refreshCallsAfterInit,
          reason: 'no connectivity transition means no reconnect');

      controller.dispose();
      connectivity.dispose();
    });

    test('directory recovery refresh is read-only and bounded by the '
        'generation gate', () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      )..refreshStatus = DirectoryRefreshStatus.network;

      final source = _FakeTransportSource(available: false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;

      final controller = DirectoryRefreshController(
        repository: repository,
        connectivity: connectivity,
      );
      await controller.initialize();
      expect(controller.cause, RemoteDataCause.offline);
      final before = repository.refreshCalls;

      source.setAvailable(true);
      await _settle();
      await _settle();

      expect(repository.refreshCalls, before + 1, reason: 'one reconnect per '
          'generation');

      await _settle();
      expect(repository.refreshCalls, before + 1, reason: 'no storm after '
          'generation consumed');

      final manualBefore = repository.refreshCalls;
      repository.refreshStatus = DirectoryRefreshStatus.success;
      repository.entities = [fakeEntity(id: 'd1', name: 'Cached Co')];
      await controller.refresh(userInitiated: true);
      expect(repository.refreshCalls, manualBefore + 1);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.cause, isNull);

      controller.dispose();
      await source.close();
      connectivity.dispose();
    });

    test('profile does not auto-refresh on connectivity recovery; manual '
        'retry still reads', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final cloud = _CloudOnlyA();
      final profile = UserProfileProvider(
        repository: _MemoryProfileRepository(),
        cloudProfileGateway: cloud,
        auth: auth,
      );
      await profile.ensureCloudProfileLoaded();
      expect(profile.authenticatedProfile, isNotNull);
      final before = cloud.fetchCalls;
      expect(before, greaterThanOrEqualTo(1));

      final source = _FakeTransportSource(available: false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;
      source.setAvailable(true);
      await _settle();

      expect(connectivity.reconnectGeneration, greaterThan(0));
      expect(cloud.fetchCalls, before, reason: 'profile never listens to '
          'connectivity');

      await profile.ensureCloudProfileLoaded();
      expect(cloud.fetchCalls, greaterThan(before), reason: 'manual retry '
          're-reads');

      profile.dispose();
      auth.dispose();
      await source.close();
      connectivity.dispose();
    });

    test('business application list does not auto-refresh on connectivity '
        'recovery', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final businessGateway = _ScriptedBusinessGateway();
      final business = BusinessApplicationProvider(
        gateway: businessGateway,
        auth: auth,
      );
      await business.loadApplications();
      expect(business.applications, isNotEmpty);
      final before = businessGateway.listCalls;

      final source = _FakeTransportSource(available: false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;
      source.setAvailable(true);
      await _settle();

      expect(businessGateway.listCalls, before, reason: 'no connectivity-driven '
          'list read');

      await business.loadApplications();
      expect(businessGateway.listCalls, greaterThan(before), reason: 'manual '
          'retry still reads');

      business.dispose();
      auth.dispose();
      await source.close();
      connectivity.dispose();
    });

    test('staff capability + queue do not auto-refresh on connectivity '
        'recovery', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final staffGateway = _ScriptedStaffGateway();
      final scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
      await scope.access.load();
      await scope.queue.loadInitial();
      expect(scope.access.hasReadPermission, isTrue);
      expect(scope.queue.items, isNotEmpty);
      final capsBefore = staffGateway.capabilitiesCalls;
      final listBefore = staffGateway.listCalls;

      final source = _FakeTransportSource(available: false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;
      source.setAvailable(true);
      await _settle();

      expect(staffGateway.capabilitiesCalls, capsBefore);
      expect(staffGateway.listCalls, listBefore);

      await scope.access.load();
      await scope.queue.loadInitial();
      expect(staffGateway.capabilitiesCalls, greaterThan(capsBefore));
      expect(staffGateway.listCalls, greaterThan(listBefore));
      expect(staffGateway.mutationCalls, 0);

      scope.access.dispose();
      scope.queue.dispose();
      scope.detail.dispose();
      auth.dispose();
      await source.close();
      connectivity.dispose();
    });

    test('encyclopedia never consults connectivity; flips do not change read '
        'counts', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('t1', 'موضوع أ')],
      );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();
      expect(provider.allTopics, hasLength(1));
      final before = repo.allTopicsCalls;

      final source = _FakeTransportSource(available: false);
      final connectivity = ConnectivityProvider(source: source);
      await connectivity.initialization;
      source.setAvailable(true);
      await _settle();

      expect(repo.allTopicsCalls, before, reason: 'encyclopedia has no '
          'connectivity lane');

      await provider.loadAllTopics();
      expect(repo.allTopicsCalls, greaterThan(before));

      provider.dispose();
      await source.close();
      connectivity.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §6 Offline classification parity: `offline` is possible ONLY when the
  // canonical transport authority is confirmed unavailable and never from the
  // local encyclopedia lane.
  // ------------------------------------------------------------------
  group('P2-G §6 offline classification parity', () {
    test('directory network failure + transport unavailable -> offline',
        () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      )..refreshStatus = DirectoryRefreshStatus.network;

      final connectivity = await _offlineConnectivity();
      final controller = DirectoryRefreshController(
        repository: repository,
        connectivity: connectivity,
      );
      await controller.initialize();

      expect(controller.cause, RemoteDataCause.offline);

      controller.dispose();
      connectivity.dispose();
    });

    test('directory network failure + transport available -> network',
        () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      )..refreshStatus = DirectoryRefreshStatus.network;

      final connectivity = await _onlineConnectivity();
      final controller = DirectoryRefreshController(
        repository: repository,
        connectivity: connectivity,
      );
      await controller.initialize();

      expect(controller.cause, RemoteDataCause.network);

      controller.dispose();
      connectivity.dispose();
    });

    test('directory network failure + transport unknown -> network', () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      )..refreshStatus = DirectoryRefreshStatus.network;

      final pending = ConnectivityProvider(
        source: _PendingTransportSource(),
        initialCheckTimeout: const Duration(milliseconds: 50),
      );
      await pending.initialization;
      expect(pending.state, TransportState.unknown);

      final controller = DirectoryRefreshController(
        repository: repository,
        connectivity: pending,
      );
      await controller.initialize();

      expect(controller.cause, RemoteDataCause.network);

      controller.dispose();
      pending.dispose();
    });

    test('encyclopedia local content failure never becomes offline/network '
        'even while transport is unavailable', () async {
      final repo = _FakeEncyclopediaRepository()
        ..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.assetUnavailable,
        );
      final provider = EncyclopediaProvider(repository: repo);

      final connectivity = await _offlineConnectivity();
      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      final kind = provider.contentFailure!.kind;
      expect(
        kind,
        anyOf(
          EncyclopediaContentFailureKind.assetUnavailable,
          EncyclopediaContentFailureKind.malformedContent,
          EncyclopediaContentFailureKind.unexpected,
        ),
        reason: 'the packaged-catalog authority has no remote cause surface',
      );

      provider.dispose();
      connectivity.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §7 App-shell coexistence: ONE canonical transport authority; the global
  // banner is transport-lane while the encyclopedia notice stays local.
  // ------------------------------------------------------------------
  group('P2-G §7 shell coexistence', () {
    testWidgets('banner + local encyclopedia notice coexist with one '
        'transport authority', (tester) async {
      final connectivity = await _offlineConnectivity();
      final repo = _FakeEncyclopediaRepository()
        ..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.malformedContent,
        );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: connectivity),
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: const Scaffold(
              body: Column(
                children: [
                  TransportStatusBanner(),
                  EncyclopediaContentNotice(
                    message: 'local',
                    onRetry: _noop,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransportStatusBanner), findsOneWidget);
      expect(find.text(Ar.transportUnavailableTitle), findsOneWidget,
          reason: 'banner is the transport-lane authority');
      expect(find.text('local'), findsOneWidget);
      expect(find.byType(RemoteDataNotice), findsNothing,
          reason: 'the encyclopedia local lane never renders a RemoteDataNotice');
      expect(find.text(Ar.noticeOffline), findsNothing);
      expect(find.text(En.noticeOffline), findsNothing);
      expect(find.text(Ar.transportUnavailableTitle), findsOneWidget);

      provider.dispose();
      connectivity.dispose();
    });

    testWidgets('encyclopedia notice behavior is identical without any '
        'connectivity provider', (tester) async {
      final repo = _FakeEncyclopediaRepository()
        ..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.assetUnavailable,
        );
      final provider = EncyclopediaProvider(repository: repo);
      await provider.loadAllTopics();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: const Scaffold(
              body: EncyclopediaContentNotice(
                message: 'local',
                onRetry: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('local'), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.byType(TransportStatusBanner), findsNothing);
      expect(provider.hasContentFailure, isTrue);

      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §8 Coordinated account-bound reset: every wired provider is cleared on a
  // canonical identity change; public Directory cache and Encyclopedia
  // favorites are NOT part of the reset.
  // ------------------------------------------------------------------
  group('P2-G §8 coordinated account-bound reset', () {
    test('sign-out resets all six account-bound providers', () async {
      final harness = _SixProviderResetHarness();
      await harness.authenticateAndLoad();

      expect(harness.auth.isLoggedIn, isTrue);
      expect(harness.profile.authenticatedProfile, isNotNull);
      expect(harness.business.applications, isNotEmpty);
      expect(harness.claims.targets, isNotEmpty);
      expect(harness.managed.items, isNotEmpty);
      expect(harness.editor.profile, isNotNull);
      expect(harness.scope.access.hasReadPermission, isTrue);
      expect(harness.scope.queue.items, isNotEmpty);

      harness.gateway.emit(
        const AuthEvent(type: AuthEventType.signedOut, session: null),
      );
      await _settle();

      expect(harness.auth.isLoggedIn, isFalse);
      expect(harness.resetCount, greaterThanOrEqualTo(1));
      expect(harness.profile.authenticatedProfile, isNull);
      expect(harness.business.applications, isEmpty);
      expect(harness.business.currentApplicationId, isNull);
      expect(harness.claims.targets, isEmpty);
      expect(harness.managed.items, isEmpty);
      expect(harness.managed.state, isNot(ManagedBusinessesState.data));
      expect(harness.editor.profile, isNull);
      expect(
        harness.editor.state,
        isNot(BusinessProfileEditorState.data),
      );
      expect(harness.scope.access.capabilities, isNull);
      expect(harness.scope.access.hasReadPermission, isFalse);
      expect(harness.scope.queue.items, isEmpty);

      harness.dispose();
    });

    test('directory cache and encyclopedia favorites survive identity reset',
        () async {
      final harness = _SixProviderResetHarness();
      final favorites = EncyclopediaFavoritesProvider(store: _FakeFavoritesStore());
      await favorites.load();
      await favorites.save('t1');
      expect(favorites.isFavorite('t1'), isTrue);

      await harness.authenticateAndLoad();
      final cachedAfterLoad = harness.directoryRepo.readCache();
      expect((await cachedAfterLoad)!.entities, isNotEmpty);

      harness.gateway.emit(
        const AuthEvent(type: AuthEventType.signedOut, session: null),
      );
      await _settle();

      expect(harness.resetCount, greaterThanOrEqualTo(1));
      final cached = await harness.directoryRepo.readCache();
      expect(cached, isNotNull);
      expect(cached!.entities, isNotEmpty,
          reason: 'the public Directory cache is not account-bound');

      expect(favorites.isFavorite('t1'), isTrue,
          reason: 'Encyclopedia favorites are not account-bound');

      final controller = DirectoryRefreshController(
        repository: harness.directoryRepo,
        connectivity: null,
      );
      await controller.initialize();
      expect(controller.hasSnapshot, isTrue);

      controller.dispose();
      favorites.dispose();
      harness.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §9 Retry/mutation safety: manual retry and available data re-reads are
  // READ lanes; no mutation RPC is ever issued by a retry path.
  // ------------------------------------------------------------------
  group('P2-G §9 retry/mutation safety', () {
    test('profile manual retry is read-only', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final cloud = _CloudOnlyA();
      final profile = UserProfileProvider(
        repository: _MemoryProfileRepository(),
        cloudProfileGateway: cloud,
        auth: auth,
      );
      await profile.ensureCloudProfileLoaded();
      final before = cloud.fetchCalls;
      await profile.ensureCloudProfileLoaded();
      expect(cloud.fetchCalls, greaterThan(before));

      expect(cloud.createCalls, 0);
      expect(cloud.updateRegionCalls, 0);
      expect(cloud.saveEditableCalls, 0);

      profile.dispose();
      auth.dispose();
    });

    test('business manual retry is read-only', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final businessGateway = _ScriptedBusinessGateway();
      final business = BusinessApplicationProvider(
        gateway: businessGateway,
        auth: auth,
      );
      await business.loadApplications();
      final before = businessGateway.listCalls;
      await business.loadApplications();
      expect(businessGateway.listCalls, greaterThan(before));

      expect(businessGateway.createNewCalls, 0);
      expect(businessGateway.createClaimCalls, 0);
      expect(businessGateway.submitCalls, 0);
      expect(businessGateway.resubmitCalls, 0);
      expect(businessGateway.getCalls, greaterThanOrEqualTo(0));

      business.dispose();
      auth.dispose();
    });

    test('staff retry is read-only (no review mutations)', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final staffGateway = _ScriptedStaffGateway();
      final scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
      await scope.access.load();
      await scope.queue.loadInitial();
      final capsBefore = staffGateway.capabilitiesCalls;
      final listBefore = staffGateway.listCalls;

      await scope.access.load();
      await scope.queue.loadInitial();
      await scope.queue.loadInitial();
      expect(staffGateway.capabilitiesCalls, greaterThan(capsBefore));
      expect(staffGateway.listCalls, greaterThan(listBefore));

      expect(staffGateway.mutationCalls, 0);

      scope.access.dispose();
      scope.queue.dispose();
      scope.detail.dispose();
      auth.dispose();
    });

    test('encyclopedia manual retry reuses the same authoritative lane and '
        'never invents a remote cause', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('t1', 'موضوع أ')],
      )..allTopicsError = const EncyclopediaContentException(
          EncyclopediaContentFailureKind.assetUnavailable,
        );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.hasContentFailure, isTrue);
      final firstCalls = repo.allTopicsCalls;

      repo.allTopicsError = null;
      await provider.loadAllTopics();

      expect(repo.allTopicsCalls, greaterThan(firstCalls));
      expect(provider.hasContentFailure, isFalse);
      expect(provider.allTopics.single.id, 't1');

      provider.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §10 Known-good priority and access loss: last valid data survives a failed
  // refresh; an authoritative permission loss clears privileged staff data.
  // ------------------------------------------------------------------
  group('P2-G §10 known-good priority + access loss', () {
    test('directory keeps the cached snapshot on refresh failure and restores '
        'fresh', () async {
      final repository = _ScriptedDirectoryRepository(
        cache: DirectoryCachedData(
          entities: [fakeEntity(id: 'kt1', name: 'Known Good Co')],
          refreshedAt: DateTime.utc(2024, 1, 1),
        ),
      );
      repository.refreshStatus = DirectoryRefreshStatus.network;
      repository.entities = [
        fakeEntity(id: 'fresh-ent', name: 'Fresh Co'),
      ];

      final controller = DirectoryRefreshController(repository: repository);
      await controller.initialize();

      expect(controller.loadState, DirectoryLoadState.stale);
      expect(controller.hasSnapshot, isTrue);
      expect(controller.entities.single.id, 'kt1',
          reason: 'cache-first snapshot must survive the failed cloud refresh');
      expect(controller.cause, RemoteDataCause.network);

      repository.refreshStatus = DirectoryRefreshStatus.success;
      await controller.refresh(userInitiated: true);

      expect(controller.cause, isNull);
      expect(controller.loadState, DirectoryLoadState.fresh);
      expect(controller.entities.single.id, 'fresh-ent');

      controller.dispose();
    });

    test('encyclopedia known-good catalog reload failure preserves the '
        'successfully loaded content', () async {
      final repo = _FakeEncyclopediaRepository(
        topics: [_topicFixture('k1', 'موضوع كامل أ')],
        categories: const {
          'concrete': CategoryInfo(
            id: 'concrete',
            titleAr: 'خرسانة',
            titleEn: 'Concrete',
          ),
        },
      );
      final provider = EncyclopediaProvider(repository: repo);

      await provider.loadAllTopics();
      expect(provider.allTopics.single.id, 'k1');
      expect(provider.categories.keys, contains('concrete'));

      repo.allTopicsError = const EncyclopediaContentException(
        EncyclopediaContentFailureKind.malformedContent,
      );
      await provider.loadAllTopics();

      expect(provider.hasContentFailure, isTrue);
      expect(provider.allTopics.single.id, 'k1');
      expect(provider.categories.keys, contains('concrete'));

      provider.dispose();
    });

    test('authoritative staff permission loss clears privileged queue data '
        'immediately', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(gateway: gateway);
      await auth.restoreSession();

      final staffGateway = _ScriptedStaffGateway();
      final scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
      await scope.access.load();
      await scope.queue.loadInitial();

      expect(scope.access.hasReadPermission, isTrue);
      expect(scope.queue.items, isNotEmpty);

      staffGateway.capabilities = const StaffReadDenied(
        BusinessApplicationStaffCause.staffPermissionDenied,
      );
      await scope.access.load();

      expect(scope.access.state, StaffAccessState.noReadPermission);
      expect(scope.access.hasReadPermission, isFalse);
      expect(scope.queue.items, isEmpty,
          reason: 'privileged review state must not survive permission loss');

      scope.access.dispose();
      scope.queue.dispose();
      scope.detail.dispose();
      auth.dispose();
    });
  });

  // ------------------------------------------------------------------
  // §11 P2-G retry action label localization: the retry label follows the
  // ambient locale while the notice message stays caller-controlled.
  // ------------------------------------------------------------------
  group('P2-G §11 retry label follows ambient locale', () {
    testWidgets('EN locale renders En.retry and never Ar.retry',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: EncyclopediaContentNotice(
              message: 'content down',
              onRetry: () => tapped++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(En.retry), findsOneWidget);
      expect(find.text(Ar.retry), findsNothing);
      expect(find.text('content down'), findsOneWidget);

      await tester.tap(find.text(En.retry));
      expect(tapped, 1);
    });

    testWidgets('AR locale renders Ar.retry and never En.retry',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const Scaffold(
            body: EncyclopediaContentNotice(
              message: 'المحتوى غير متاح',
              onRetry: _noop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text(En.retry), findsNothing);
      expect(find.text('المحتوى غير متاح'), findsOneWidget);
    });
  });
}