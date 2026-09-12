import 'package:civilpedia/features/business/domain/business_membership.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';

/// Test fake for [BusinessMembershipGateway].
///
/// Only [listMyBusinesses] is scripted for V1-R06 list tests.
class FakeBusinessMembershipGateway implements BusinessMembershipGateway {
  FakeBusinessMembershipGateway({
    this.available = true,
    ManagedBusinessListResult? listResult,
  }) : _listResult = listResult ??
            const ManagedBusinessListAvailable([]);

  final bool available;
  ManagedBusinessListResult _listResult;

  int listMyBusinessesCalls = 0;

  /// Scriptable in-flight hook. When set, [listMyBusinesses] suspends until the
  /// hook's future completes, letting tests race a reset against an in-flight
  /// load (V1-R08 final pass, finding 1).
  Future<ManagedBusinessListResult> Function()? onListMyBusinesses;

  set listResult(ManagedBusinessListResult value) => _listResult = value;

  @override
  bool get isAvailable => available;

  @override
  Future<List<BusinessMembership>> listOwnMemberships(String userId) async =>
      const [];

  @override
  Future<ManagedBusinessListResult> listMyBusinesses() async {
    listMyBusinessesCalls++;
    final hook = onListMyBusinesses;
    if (hook != null) return hook();
    return _listResult;
  }

  @override
  Future<BusinessMembershipListResult> listMembersForEntity(
    String entityId,
  ) async {
    return const BusinessMembershipListUnavailable();
  }
}
