// Civilpedia V1-R09Q-A — cross-feature smoke journeys.
//
// Frozen authority: V1-R09Q-CONTRACT-v1 section 9. ONE focused suite proving
// two ordering-critical journeys without duplicating provider unit tests or
// reproducing P2-G wholesale:
//
//   Journey A — RECOVERED AUTH CHAIN: a recovered session restores the correct
//   identity and the Profile bind/load, Business account-bound, and Staff
//   capability seams all stay bound to that same identity.
//
//   Journey B — TRANSPORT-FLIP COEXISTENCE: with one shared transport
//   authority, an unavailable -> available flip reconnects Directory exactly
//   once while Profile / Business / Staff / Encyclopedia perform no automatic
//   reconnect read.
//
//   Journey C (sign-out) is intentionally NOT added here: sign-out recovery is
//   already conclusively covered by C2, C3, and P2-G (section 9).
//
// Deterministic only: controllable fakes, no real network, no Supabase, no
// secrets, no timing sleeps.
import 'dart:async';

import 'package:civilpedia/core/di/staff_operations_scope.dart';
import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:civilpedia/features/business/domain/staff_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/staff_application_detail.dart';
import 'package:civilpedia/features/business/domain/staff_application_summary.dart';
import 'package:civilpedia/features/business/domain/staff_read_result.dart';
import 'package:civilpedia/features/business/presentation/providers/business_application_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/managed_businesses_provider.dart';
import 'package:civilpedia/features/directory/application/directory_refresh_controller.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/category_info.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/content_block.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/topic_section.dart';
import 'package:civilpedia/features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import 'package:civilpedia/features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_gateway.dart';
import 'fakes/fake_business_membership_gateway.dart';
import 'helpers/canonical_directory_test_helpers.dart';

Future<void> _settle([int rounds = 10]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource({bool available = false}) : _available = available;

  bool _available;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> checkAvailability() async => _available;

  @override
  Stream<bool> get availabilityChanges => _controller.stream;

  void setAvailable(bool value) {
    if (_available == value) return;
    _available = value;
    _controller.add(value);
  }

  Future<void> close() => _controller.close();
}

class _CountableCloudGateway implements PersonalProfileRemoteGateway {
  int fetchCalls = 0;
  int createCalls = 0;
  int updateRegionCalls = 0;
  int saveEditableCalls = 0;
  String? lastUserId;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) async {
    fetchCalls++;
    lastUserId = userId;
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

class _JourneyDirectoryRepository implements CloudDirectoryRepository {
  _JourneyDirectoryRepository({required this.cache});

  final DirectoryCachedData? cache;
  int refreshCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<DirectoryCachedData?> readCache() async => cache;

  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    return DirectoryRefreshResult(
      status: DirectoryRefreshStatus.network,
      entities: const [],
      refreshedAt: null,
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
      state: DirectoryLoadState.stale,
      entities: List.of(cache?.entities ?? const []),
      refreshedAt: cache?.refreshedAt,
    );
  }
}

class _JourneyBusinessGateway implements BusinessApplicationGateway {
  int listCalls = 0;
  int createNewCalls = 0;
  int createClaimCalls = 0;
  int submitCalls = 0;
  int resubmitCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    listCalls++;
    return [
      BusinessApplication(
        id: 'app-journey-1',
        applicantUserId: userId,
        type: BusinessApplicationType.newApplication,
        status: BusinessApplicationStatus.draft,
      ),
    ];
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
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

class _JourneyStaffGateway implements BusinessApplicationStaffGateway {
  _JourneyStaffGateway() {
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
    return const StaffReadUnavailable<StaffApplicationDetail>();
  }
}

class _JourneyEncyclopediaRepository implements EncyclopediaRepository {
  _JourneyEncyclopediaRepository({this.topics = const []});

  final List<EngineeringTopic> topics;
  int allTopicsCalls = 0;

  @override
  Future<List<EngineeringTopic>> getAllTopics() async {
    allTopicsCalls++;
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
  Future<Map<String, CategoryInfo>> getCategories() async => const {};

  @override
  Future<List<TopicSection>> getSectionsForTopic(String topicId) async =>
      const [];

  @override
  Future<List<ContentBlock>> getBlocksForSection(
    String topicId,
    String sectionId,
  ) async => const [];

  @override
  Future<List<EngineeringTopic>> searchTopics(String query) async => topics;
}

EngineeringTopic _journeyTopic(String id, String title) {
  return EngineeringTopic(
    id: id,
    titleAr: title,
    categoryId: 'concrete',
    summary: 'ملخص $id',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    tags: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R09Q cross-feature smoke journeys', () {
    test(
      'Journey A: recovered session restores the identity and binds the '
      'Profile, Business, and Staff seams to it', () async {
        final gateway = FakeAuthGateway(restoredSession: fakeSession);
        final auth = AuthProvider(gateway: gateway);
        await auth.restoreSession();

        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUserId, fakeSession.userId);
        expect(auth.currentUserId, isNot(fakeSessionOther.userId));

        final cloud = _CountableCloudGateway();
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: cloud,
          auth: auth,
        );
        await profile.ensureCloudProfileLoaded();
        expect(profile.authenticatedProfile, isNotNull);
        expect(profile.authenticatedProfile!.userId, fakeSession.userId);

        final businessGateway = _JourneyBusinessGateway();
        final business = BusinessApplicationProvider(
          gateway: businessGateway,
          auth: auth,
        );
        await business.loadApplications();
        expect(business.applications, isNotEmpty);

        final managed = ManagedBusinessesProvider(
          membershipGateway: FakeBusinessMembershipGateway(
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
          ),
          auth: auth,
        );
        await managed.load();
        expect(managed.items, isNotEmpty);

        final staffGateway = _JourneyStaffGateway();
        final scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
        await scope.access.load();
        await scope.queue.loadInitial();
        expect(scope.access.hasReadPermission, isTrue);
        expect(scope.queue.items, isNotEmpty);

        final boundIdentity = auth.currentUserId;
        expect(boundIdentity, fakeSession.userId);
        expect(boundIdentity, isNot(fakeSessionOther.userId));
        expect(profile.authenticatedProfile!.userId, boundIdentity);
        expect(cloud.lastUserId, boundIdentity,
            reason: 'the Profile read seam must query the recovered identity');
        for (final application in business.applications) {
          expect(application.applicantUserId, boundIdentity,
              reason: 'the Business list must only surface the recovered '
                  'identity account data');
        }
        expect(staffGateway.mutationCalls, 0);

        scope.access.dispose();
        scope.queue.dispose();
        scope.detail.dispose();
        managed.dispose();
        business.dispose();
        profile.dispose();
        auth.dispose();
        gateway.close();
      },
    );

    test(
      'Journey B: a transport flip under one authority reconnects Directory '
      'exactly once; Profile/Business/Staff/Encyclopedia stay read-inert',
      () async {
        final source = _FakeTransportSource(available: false);
        final connectivity = ConnectivityProvider(source: source);
        await connectivity.initialization;
        expect(connectivity.state, TransportState.unavailable);

        final directoryRepo = _JourneyDirectoryRepository(
          cache: DirectoryCachedData(
            entities: [fakeEntity(id: 'd1', name: 'Cached Co')],
            refreshedAt: DateTime.utc(2024, 1, 1),
          ),
        );
        final directory = DirectoryRefreshController(
          repository: directoryRepo,
          connectivity: connectivity,
        );
        await directory.initialize();
        expect(directory.loadState, DirectoryLoadState.stale);
        expect(directory.hasSnapshot, isTrue);
        expect(directory.cause, RemoteDataCause.offline);

        final authGateway = FakeAuthGateway(restoredSession: fakeSession);
        final auth = AuthProvider(gateway: authGateway);
        await auth.restoreSession();

        final cloud = _CountableCloudGateway();
        final profile = UserProfileProvider(
          repository: _MemoryProfileRepository(),
          cloudProfileGateway: cloud,
          auth: auth,
        );
        await profile.ensureCloudProfileLoaded();
        expect(profile.authenticatedProfile, isNotNull);

        final businessGateway = _JourneyBusinessGateway();
        final business = BusinessApplicationProvider(
          gateway: businessGateway,
          auth: auth,
        );
        await business.loadApplications();
        expect(business.applications, isNotEmpty);

        final staffGateway = _JourneyStaffGateway();
        final scope = StaffOperationsScope(gateway: staffGateway, auth: auth);
        await scope.access.load();
        await scope.queue.loadInitial();
        expect(scope.access.hasReadPermission, isTrue);

        final encyclopediaRepo = _JourneyEncyclopediaRepository(
          topics: [_journeyTopic('t1', 'موضوع أ')],
        );
        final encyclopedia = EncyclopediaProvider(repository: encyclopediaRepo);
        await encyclopedia.loadAllTopics();
        expect(encyclopedia.allTopics, hasLength(1));

        final directoryCallsBefore = directoryRepo.refreshCalls;
        final profileCallsBefore = cloud.fetchCalls;
        final businessCallsBefore = businessGateway.listCalls;
        final staffCapsBefore = staffGateway.capabilitiesCalls;
        final staffListBefore = staffGateway.listCalls;
        final encyclopediaCallsBefore = encyclopediaRepo.allTopicsCalls;

        source.setAvailable(true);
        await _settle();
        await _settle();
        await _settle();

        expect(connectivity.reconnectGeneration, greaterThan(0));
        expect(directoryRepo.refreshCalls, directoryCallsBefore + 1,
            reason: 'one eligible reconnect refresh per generation, claimed '
                'exactly once');
        expect(cloud.fetchCalls, profileCallsBefore,
            reason: 'Profile never auto-refreshes on transport recovery');
        expect(businessGateway.listCalls, businessCallsBefore,
            reason: 'Business never auto-refreshes on transport recovery');
        expect(staffGateway.capabilitiesCalls, staffCapsBefore,
            reason: 'Staff capability never auto-refreshes');
        expect(staffGateway.listCalls, staffListBefore,
            reason: 'Staff queue never auto-refreshes');
        expect(encyclopediaRepo.allTopicsCalls, encyclopediaCallsBefore,
            reason: 'Encyclopedia has no connectivity-driven read');
        expect(staffGateway.mutationCalls, 0,
            reason: 'recovery paths are read-only');
        expect(businessGateway.createNewCalls, 0);
        expect(businessGateway.createClaimCalls, 0);
        expect(businessGateway.submitCalls, 0);
        expect(businessGateway.resubmitCalls, 0);

        directory.dispose();
        scope.access.dispose();
        scope.queue.dispose();
        scope.detail.dispose();
        encyclopedia.dispose();
        business.dispose();
        profile.dispose();
        auth.dispose();
        authGateway.close();
        await source.close();
        connectivity.dispose();
      },
    );
  });
}