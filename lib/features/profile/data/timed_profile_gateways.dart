import '../../../core/network/remote_operation_policy.dart';
import 'cloud_profile.dart';
import 'personal_profile_remote_gateway.dart';
import 'region_preference_gateway.dart';

/// Applies V1-R09 operation deadlines to the existing authenticated-profile
/// gateway without changing its domain-specific exception contract.
class TimedPersonalProfileRemoteGateway
    implements
        PersonalProfileRemoteGateway,
        ProfileMutationSettlement,
        ConditionalProfileRetryGateway {
  TimedPersonalProfileRemoteGateway({
    required PersonalProfileRemoteGateway delegate,
    this.readTimeout = RemoteOperationPolicy.read,
    this.mutationTimeout = RemoteOperationPolicy.mutation,
  }) : _delegate = delegate;

  final PersonalProfileRemoteGateway _delegate;
  final Duration readTimeout;
  final Duration mutationTimeout;
  final Map<String, int> _pendingMutations = {};

  @override
  bool isProfileMutationPending(String userId) =>
      (_pendingMutations[userId] ?? 0) > 0;

  Future<void> _mutation(String userId, Future<void> raw) {
    _pendingMutations[userId] = (_pendingMutations[userId] ?? 0) + 1;
    final observed = raw.whenComplete(() {
      final remaining = _pendingMutations[userId]! - 1;
      if (remaining == 0) {
        _pendingMutations.remove(userId);
      } else {
        _pendingMutations[userId] = remaining;
      }
    });
    // Future.timeout observes late errors as well as late success. Its expiry
    // does not release the raw-work slot or claim the request was cancelled.
    return runWithRemoteDeadline(observed, timeout: mutationTimeout);
  }

  @override
  Future<CloudProfile?> fetchByUserId(String userId) {
    return runWithRemoteDeadline(
      _delegate.fetchByUserId(userId),
      timeout: readTimeout,
    );
  }

  @override
  Future<void> createProfile(CloudProfile profile) {
    return _mutation(profile.userId, _delegate.createProfile(profile));
  }

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) {
    return _mutation(
      userId,
      _delegate.updateRegionPreferenceId(
        userId: userId,
        regionPreferenceId: regionPreferenceId,
      ),
    );
  }

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) {
    return _mutation(
      userId,
      _delegate.saveEditableFields(
        userId: userId,
        roleCode: roleCode,
        regionPreferenceId: regionPreferenceId,
      ),
    );
  }

  @override
  Future<void> saveEditableFieldsIfRegionAbsent({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) {
    final delegate = _delegate;
    if (delegate is! ConditionalProfileRetryGateway) {
      throw const CloudProfileUnexpectedException();
    }
    return _mutation(
      userId,
      (delegate as ConditionalProfileRetryGateway)
          .saveEditableFieldsIfRegionAbsent(
            userId: userId,
            roleCode: roleCode,
            regionPreferenceId: regionPreferenceId,
          ),
    );
  }
}

/// Bounds the reference-data reads used by post-auth profile bootstrap.
class TimedRegionPreferenceGateway implements RegionPreferenceGateway {
  const TimedRegionPreferenceGateway({
    required RegionPreferenceGateway delegate,
    this.readTimeout = RemoteOperationPolicy.read,
  }) : _delegate = delegate;

  final RegionPreferenceGateway _delegate;
  final Duration readTimeout;

  @override
  Future<String?> resolveCodeById(String id) {
    return runWithRemoteDeadline(
      _delegate.resolveCodeById(id),
      timeout: readTimeout,
    );
  }

  @override
  Future<String?> resolvePreferenceIdByCode(String code) {
    return runWithRemoteDeadline(
      _delegate.resolvePreferenceIdByCode(code),
      timeout: readTimeout,
    );
  }
}
