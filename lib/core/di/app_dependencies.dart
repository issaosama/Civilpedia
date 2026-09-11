import 'package:path_provider/path_provider.dart';

import '../../features/directory/data/sb_profiles_directory_repository.dart';
import '../../features/directory/domain/directory_repository.dart';
import '../../features/monetization/data/empty_campaign_source.dart';
import '../../features/monetization/domain/services/campaign_source.dart';
import '../../features/encyclopedia/data/datasources/encyclopedia_json_datasource.dart';
import '../../features/encyclopedia/data/datasources/encyclopedia_local_datasource.dart';
import '../../features/encyclopedia/data/repositories/encyclopedia_repository_impl.dart';
import '../../features/encyclopedia/domain/repositories/encyclopedia_repository.dart';
import '../../features/profile/data/local_user_profile_data_source.dart';
import '../../features/profile/data/local_user_profile_repository.dart';
import '../../features/profile/data/local_service_business_repository.dart';
import '../../features/profile/data/personal_profile_bootstrap_coordinator.dart';
import '../../features/profile/data/personal_profile_remote_gateway.dart';
import '../../features/profile/data/region_preference_gateway.dart';
import '../../features/profile/data/service_business_data_source.dart';
import '../../features/profile/data/supabase_personal_profile_remote_gateway.dart';
import '../../features/profile/data/supabase_region_preference_gateway.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/profile/domain/service_business_repository.dart';
import '../../features/saved/data/hive_saved_reference_store.dart';
import '../../features/saved/domain/saved_reference_store.dart';
import '../../features/tools/data/checklist/checklist_local_data_source.dart';
import '../../features/tools/data/checklist/local_checklist_repository.dart';
import '../../features/tools/data/checklist/local_project_repository.dart';
import '../../features/tools/data/checklist/project_local_data_source.dart';
import '../../features/tools/domain/checklist/checklist_repository.dart';
import '../../features/tools/domain/checklist/project_repository.dart';
import '../backup/backup_file_service.dart';
import '../backup/backup_service.dart';
import '../backend/supabase_service.dart';
import '../ownership/guest_install_identity.dart';
import '../ownership/local_data_claim_coordinator.dart';
import '../ownership/local_favorites_gateway.dart';
import '../ownership/ownership_registry_store.dart';
import '../../features/auth/data/supabase_auth_gateway.dart';
import '../../features/auth/domain/repositories/auth_gateway.dart';
import '../../features/business/data/supabase_business_application_gateway.dart';
import '../../features/business/data/supabase_business_application_staff_gateway.dart';
import '../../features/business/data/supabase_business_membership_gateway.dart';
import '../../features/business/domain/business_application_gateway.dart';
import '../../features/business/domain/business_application_staff_gateway.dart';
import '../../features/business/domain/business_membership_gateway.dart';
import '../../features/projects/data/project_persistence_gateway.dart';

class AppDependencies {
  AppDependencies._();

  static late final EncyclopediaLocalDataSource _encyclopediaDataSource;
  static late final EncyclopediaJsonDataSource _encyclopediaJsonDataSource;
  static late final EncyclopediaRepository _encyclopediaRepo;

  static late final LocalUserProfileDataSource _userProfileDataSource;
  static late final UserProfileRepository _userProfileRepo;

  static late final ServiceBusinessDataSource _businessDataSource;
  static late final ServiceBusinessRepository _businessRepo;
  static late final DirectoryRepository _directoryRepo;

  static late final SavedReferenceStore _savedReferenceStore;

  static late final ChecklistLocalDataSource _checklistDataSource;
  static late final ChecklistRepository _checklistRepo;

  static late final ProjectLocalDataSource _projectDataSource;
  static late final ProjectRepository _projectRepo;

  static late final BackupFileService _backupFileService;
  static late final BackupService _backupService;

  static late final SupabaseService _supabaseService;

  static late final AuthGateway _authGateway;

  static late final OwnershipRegistryStore _ownershipRegistryStore;
  static late final GuestInstallIdentity _guestInstallIdentity;
  static late final LocalDataClaimCoordinator _ownershipClaimCoordinator;

  static late final PersonalProfileRemoteGateway _personalProfileRemoteGateway;
  static late final PersonalProfileBootstrapCoordinator
      _personalProfileBootstrapCoordinator;
  static late final RegionPreferenceGateway _regionPreferenceGateway;

  static late final BusinessMembershipGateway _businessMembershipGateway;
  static late final BusinessApplicationGateway _businessApplicationGateway;
  static late final BusinessApplicationStaffGateway
      _businessApplicationStaffGateway;

  static Future<void> init() async {
    _encyclopediaDataSource = EncyclopediaLocalDataSource();
    _encyclopediaJsonDataSource = EncyclopediaJsonDataSource();
    _encyclopediaRepo = EncyclopediaRepositoryImpl(
      _encyclopediaJsonDataSource,
      _encyclopediaDataSource,
    );

    _userProfileDataSource = LocalUserProfileDataSource();
    _userProfileRepo = LocalUserProfileRepository(_userProfileDataSource);

    _businessDataSource = ServiceBusinessDataSource();
    _businessRepo = LocalServiceBusinessRepository(_businessDataSource);
    _directoryRepo = SbProfilesDirectoryRepository(businessRepo: _businessRepo);

    _savedReferenceStore = const HiveSavedReferenceStore();

    _checklistDataSource = ChecklistLocalDataSource();
    _checklistRepo = LocalChecklistRepository(_checklistDataSource);

    _projectDataSource = ProjectLocalDataSource();
    _projectRepo = LocalProjectRepository(_projectDataSource);

    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = '${docsDir.path}/backups';
    _backupFileService = BackupFileService(backupDir);
    _backupService = BackupService(
      userProfileRepo: _userProfileRepo,
      checklistRepo: _checklistRepo,
      projectRepo: _projectRepo,
      fileService: _backupFileService,
    );

    // A5.1 — backend initialization boundary. Reads the compile-time
    // environment configuration and initializes Supabase only when it is
    // fully configured. Absent configuration keeps the service unavailable
    // without affecting current guest/local behavior.
    _supabaseService = SupabaseService();
    await _supabaseService.init();

    // A5.4 — auth boundary. Wires the Supabase-backed gateway; when the
    // backend is unconfigured the gateway stays unavailable and the app runs
    // fully in guest mode.
    _authGateway = SupabaseAuthGateway(service: _supabaseService);

    // A5.5 — ownership boundary. The claim coordinator never moves or rewrites
    // user data; it only records ownership in a single sidecar registry key.
    _ownershipRegistryStore = const SharedPreferencesOwnershipRegistryStore();
    _guestInstallIdentity = GuestInstallIdentity(
      userProfileRepository: _userProfileRepo,
    );
    _ownershipClaimCoordinator = LocalDataClaimCoordinator(
      registryStore: _ownershipRegistryStore,
      guestIdentity: _guestInstallIdentity,
      projectGateway: ProjectPersistenceGateway(),
      savedReferenceStore: _savedReferenceStore,
      favoritesGateway: const HiveLocalFavoritesGateway(),
    );

    // A5.6/A5.7/A5.8 — personal-profile ownership boundary. The bootstrap
    // coordinator only associates the local personal profile with the
    // canonical auth.users.id after a real authenticated session; it never
    // syncs or overwrites cloud values blindly. Region Preference (the frozen
    // six-zone contract, migration 00013) is a SEPARATE concept from the
    // physical regions taxonomy; the preference gateway resolves zone codes →
    // ids for A5.8 persistence (create + safe fill), and legacy BaghdadArea is
    // Directory geography, never mapped to a preference.
    _regionPreferenceGateway = SupabaseRegionPreferenceGateway();
    _personalProfileRemoteGateway =
        SupabasePersonalProfileRemoteGateway();
    _personalProfileBootstrapCoordinator = PersonalProfileBootstrapCoordinator(
      localRepository: _userProfileRepo,
      remoteGateway: _personalProfileRemoteGateway,
      regionPreferenceGateway: _regionPreferenceGateway,
    );

    // A6.1/V1-R03 — ownership and management read foundation. Direct table
    // access remains own-membership SELECT only; management projection/roster
    // reads use the narrow server-authorized RPCs from migration 00019. The
    // gateway exposes no membership mutation surface.
    _businessMembershipGateway = SupabaseBusinessMembershipGateway(
      service: _supabaseService,
    );

    // A6.3.1 — business application boundary. Reads remain own-row only;
    // creation and lifecycle mutations use narrow server-authorized RPCs
    // (00016/00017). The client has no generic table INSERT/UPDATE/DELETE and
    // no ownership side effects. Claim safety uses the read-only membership
    // gateway above plus the authoritative 00014/00015 database backstops.
    _businessApplicationGateway = SupabaseBusinessApplicationGateway(
      service: _supabaseService,
      membershipGateway: _businessMembershipGateway,
    );
    _businessApplicationStaffGateway = SupabaseBusinessApplicationStaffGateway(
      service: _supabaseService,
    );
  }

  static EncyclopediaRepository get encyclopediaRepo => _encyclopediaRepo;

  static UserProfileRepository get userProfileRepo => _userProfileRepo;

  static ServiceBusinessRepository get businessRepo => _businessRepo;

  static DirectoryRepository get directoryRepo => _directoryRepo;

  /// W7.2 — Production campaign source. HONEST-EMPTY: with no configured
  /// campaign authority it yields no candidates, so an unconfigured build
  /// renders no sponsored content. Stateless; safe as a shared const default.
  static const CampaignSource campaignSource = EmptyCampaignSource();

  static SavedReferenceStore get savedReferenceStore => _savedReferenceStore;

  static ChecklistRepository get checklistRepo => _checklistRepo;

  static ProjectRepository get projectRepo => _projectRepo;

  static BackupService get backupService => _backupService;

  static BackupFileService get backupFileService => _backupFileService;

  /// A5.1 — Supabase initialization/service boundary. Feature code in later
  /// phases consumes this through a repository/data-source chain, never by
  /// calling the global Supabase API directly.
  static SupabaseService get supabaseService => _supabaseService;

  /// A5.4 — production [AuthGateway] consumed by [AuthProvider]. Never
  /// accessed by widgets directly.
  static AuthGateway get authGateway => _authGateway;

  /// A5.5 — production local-data claim coordinator, invoked through the
  /// [AuthProvider] `onAuthenticated` seam.
  static LocalDataClaimCoordinator get ownershipClaimCoordinator =>
      _ownershipClaimCoordinator;

  /// A5.6/A5.7 — production personal-profile bootstrap coordinator, invoked
  /// through the same `onAuthenticated` seam after the A5.5 claim.
  static PersonalProfileBootstrapCoordinator get
      personalProfileBootstrapCoordinator =>
          _personalProfileBootstrapCoordinator;

  /// A5.7/A5.8 — production Region Preference gateway (stable zone code →
  /// `region_preferences.id`). The six frozen zones are a SEPARATE concept
  /// from `public.regions` physical geography; this resolves preference codes
  /// only and is consumed by the profile bootstrap. Never called from widgets.
  static RegionPreferenceGateway get regionPreferenceGateway =>
      _regionPreferenceGateway;

  /// A6.1/V1-R03 — production [BusinessMembershipGateway]. Own-membership,
  /// My Businesses, and authorized roster reads remain strictly read-only and
  /// feed the centralized domain capability resolver.
  static BusinessMembershipGateway get businessMembershipGateway =>
      _businessMembershipGateway;

  /// A6.3.1 — production [BusinessApplicationGateway]. Read-own plus narrow
  /// server-authorized creation/lifecycle RPCs; never a generic table mutation
  /// and never called from widgets.
  static BusinessApplicationGateway get businessApplicationGateway =>
      _businessApplicationGateway;

  /// A6.4 — production staff application RPC boundary. Activation derives the
  /// actor from the authenticated session and provisions ownership server-side.
  static BusinessApplicationStaffGateway get businessApplicationStaffGateway =>
      _businessApplicationStaffGateway;
}
