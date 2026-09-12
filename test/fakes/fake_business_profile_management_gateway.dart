import 'package:civilpedia/features/business/domain/business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile_draft.dart';
import 'package:civilpedia/features/business/domain/managed_selectable_options.dart';

/// Test fake for [BusinessProfileManagementGateway].
///
/// Scripts read/update/taxonomy results and records calls so tests can assert
/// RPC contract details (entity id, expected updated_at, payload shape).
class FakeBusinessProfileManagementGateway
    implements BusinessProfileManagementGateway {
  FakeBusinessProfileManagementGateway({
    this.available = true,
    ManagedProfileReadResult? readResult,
    ManagedProfileUpdateResult? updateResult,
    List<ManagedSelectableCategory>? categories,
    List<ManagedSelectableRegion>? regions,
  })  : _readResult = readResult ?? const ManagedProfileReadUnavailable(),
        _updateResult = updateResult ??
            const ManagedProfileUpdateDenied(
              BusinessProfileManagementCause.unexpected,
            ),
        _categories = categories ?? const [],
        _regions = regions ?? const [];

  final bool available;
  ManagedProfileReadResult _readResult;
  ManagedProfileUpdateResult _updateResult;
  List<ManagedSelectableCategory> _categories;
  List<ManagedSelectableRegion> _regions;

  int readCalls = 0;
  int updateCalls = 0;
  int categoriesCalls = 0;
  int regionsCalls = 0;

  String? lastReadEntityId;
  String? lastUpdateEntityId;
  DateTime? lastExpectedUpdatedAt;
  ManagedBusinessProfileDraft? lastUpdateDraft;

  set readResult(ManagedProfileReadResult value) => _readResult = value;
  set updateResult(ManagedProfileUpdateResult value) => _updateResult = value;
  set categories(List<ManagedSelectableCategory> value) => _categories = value;
  set regions(List<ManagedSelectableRegion> value) => _regions = value;

  @override
  bool get isAvailable => available;

  @override
  Future<ManagedProfileReadResult> readManagedProfile(String entityId) async {
    readCalls++;
    lastReadEntityId = entityId;
    return _readResult;
  }

  @override
  Future<ManagedProfileUpdateResult> updateManagedProfile({
    required String entityId,
    required DateTime expectedUpdatedAt,
    required ManagedBusinessProfileDraft draft,
  }) async {
    updateCalls++;
    lastUpdateEntityId = entityId;
    lastExpectedUpdatedAt = expectedUpdatedAt;
    lastUpdateDraft = draft;
    return _updateResult;
  }

  @override
  Future<List<ManagedSelectableCategory>> loadActiveCategories() async {
    categoriesCalls++;
    if (_categories.isEmpty) return const [];
    return _categories;
  }

  @override
  Future<List<ManagedSelectableRegion>> loadActiveRegions() async {
    regionsCalls++;
    if (_regions.isEmpty) return const [];
    return _regions;
  }
}
