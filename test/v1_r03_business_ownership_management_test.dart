import 'dart:io';

import 'package:civilpedia/features/business/domain/business_membership.dart';
import 'package:civilpedia/features/business/domain/business_membership_capabilities.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const _userA = '10000000-0000-0000-0000-000000000001';
const _userB = '10000000-0000-0000-0000-000000000002';
const _entityA = '20000000-0000-0000-0000-000000000001';
const _entityB = '20000000-0000-0000-0000-000000000002';

class _Entity {
  const _Entity({
    required this.id,
    required this.name,
    required this.entityType,
  });

  final String id;
  final String name;
  final String entityType;
  final String claimStatus = 'claimed';
  final String verificationStatus = 'unverified';
}

class _ManagementHarness {
  const _ManagementHarness({
    required this.actor,
    required this.memberships,
    required this.entities,
  });

  final String? actor;
  final List<BusinessMembership> memberships;
  final Map<String, _Entity> entities;

  ManagedBusinessListResult listMyBusinesses() {
    final userId = actor;
    if (userId == null) {
      return const ManagedBusinessListDenied(
        BusinessManagementReadCause.unauthenticated,
      );
    }
    final results = <ManagedBusinessSummary>[];
    for (final membership in memberships) {
      if (membership.userId != userId || !membership.role.isKnown) continue;
      final entity = entities[membership.entityId];
      if (entity == null) continue;
      results.add(
        ManagedBusinessSummary(
          entityId: entity.id,
          name: entity.name,
          entityType: entity.entityType,
          membershipRole: membership.role,
          claimStatus: entity.claimStatus,
          verificationStatus: entity.verificationStatus,
        ),
      );
    }
    return ManagedBusinessListAvailable(results);
  }

  BusinessMembershipListResult listBusinessMembers(String entityId) {
    final userId = actor;
    if (userId == null) {
      return const BusinessMembershipListDenied(
        BusinessManagementReadCause.unauthenticated,
      );
    }
    final actorMembership = memberships.where(
      (membership) =>
          membership.userId == userId && membership.entityId == entityId,
    );
    final allowed = actorMembership.any(
      (membership) =>
          membership.role == BusinessRole.owner ||
          membership.role == BusinessRole.admin,
    );
    if (!allowed) {
      return const BusinessMembershipListDenied(
        BusinessManagementReadCause.permissionDenied,
      );
    }
    return BusinessMembershipListAvailable(
      memberships
          .where(
            (membership) =>
                membership.entityId == entityId && membership.role.isKnown,
          )
          .toList(),
    );
  }
}

BusinessMembership _membership(
  String userId,
  String entityId,
  BusinessRole role,
) => BusinessMembership(userId: userId, entityId: entityId, role: role);

ManagedBusinessListAvailable _businesses(ManagedBusinessListResult result) =>
    result as ManagedBusinessListAvailable;

BusinessMembershipListAvailable _roster(BusinessMembershipListResult result) =>
    result as BusinessMembershipListAvailable;

void main() {
  const entities = <String, _Entity>{
    _entityA: _Entity(id: _entityA, name: 'Alpha', entityType: 'company'),
    _entityB: _Entity(id: _entityB, name: 'Beta', entityType: 'supplier'),
  };

  group('V1-R03 My Businesses', () {
    test('1. guest is denied', () {
      const harness = _ManagementHarness(
        actor: null,
        memberships: [],
        entities: entities,
      );
      final result = harness.listMyBusinesses() as ManagedBusinessListDenied;
      expect(result.cause, BusinessManagementReadCause.unauthenticated);
    });

    test('2. authenticated actor with zero memberships gets empty success', () {
      const harness = _ManagementHarness(
        actor: _userA,
        memberships: [],
        entities: entities,
      );
      expect(_businesses(harness.listMyBusinesses()).businesses, isEmpty);
    });

    test('3. OWNER association is returned with owner capabilities', () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: [_membership(_userA, _entityA, BusinessRole.owner)],
        entities: entities,
      );
      final business = _businesses(
        harness.listMyBusinesses(),
      ).businesses.single;
      expect(business.membershipRole, BusinessRole.owner);
      expect(business.capabilities.isOwner, isTrue);
      expect(business.capabilities.canManageEntity, isTrue);
    });

    test('4. ADMIN association is returned with management capability', () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: [_membership(_userA, _entityA, BusinessRole.admin)],
        entities: entities,
      );
      final business = _businesses(
        harness.listMyBusinesses(),
      ).businesses.single;
      expect(business.membershipRole, BusinessRole.admin);
      expect(business.capabilities.isOwner, isFalse);
      expect(business.capabilities.canManageEntity, isTrue);
    });

    test('5. MEMBER association is returned but remains non-managing', () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: [_membership(_userA, _entityA, BusinessRole.member)],
        entities: entities,
      );
      final business = _businesses(
        harness.listMyBusinesses(),
      ).businesses.single;
      expect(business.membershipRole, BusinessRole.member);
      expect(business.capabilities.isOwner, isFalse);
      expect(business.capabilities.canManageEntity, isFalse);
    });

    test('6. multiple associations return without depending on row order', () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: [
          _membership(_userA, _entityB, BusinessRole.member),
          _membership(_userA, _entityA, BusinessRole.owner),
        ],
        entities: entities,
      );
      final ids = _businesses(
        harness.listMyBusinesses(),
      ).businesses.map((business) => business.entityId);
      expect(ids, unorderedEquals([_entityA, _entityB]));
    });

    test("7. another user's entity is not leaked", () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: [
          _membership(_userA, _entityA, BusinessRole.member),
          _membership(_userB, _entityB, BusinessRole.owner),
        ],
        entities: entities,
      );
      final result = _businesses(harness.listMyBusinesses()).businesses;
      expect(result.map((business) => business.entityId), [_entityA]);
    });

    test('8. unknown role fails closed to no management capability', () {
      final summary = ManagedBusinessSummary.tryFromRow({
        'entity_id': _entityA,
        'name': 'Alpha',
        'entity_type': 'company',
        'membership_role': 'SUPER_OWNER',
        'claim_status': 'claimed',
        'verification_status': 'verified',
      })!;
      expect(summary.membershipRole, BusinessRole.unknown);
      expect(summary.capabilities.isOwner, isFalse);
      expect(summary.capabilities.canManageEntity, isFalse);
    });
  });

  group('V1-R03 membership roster', () {
    final rows = <BusinessMembership>[
      _membership(_userA, _entityA, BusinessRole.owner),
      _membership(_userB, _entityA, BusinessRole.member),
    ];

    test('9. OWNER can list entity members', () {
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: rows,
        entities: entities,
      );
      expect(_roster(harness.listBusinessMembers(_entityA)).memberships, rows);
    });

    test('10. ADMIN can list entity members', () {
      final adminRows = <BusinessMembership>[
        _membership(_userA, _entityA, BusinessRole.admin),
        _membership(_userB, _entityA, BusinessRole.member),
      ];
      final harness = _ManagementHarness(
        actor: _userA,
        memberships: adminRows,
        entities: entities,
      );
      expect(
        _roster(harness.listBusinessMembers(_entityA)).memberships,
        adminRows,
      );
    });

    test('11. MEMBER cannot list the full roster', () {
      final harness = _ManagementHarness(
        actor: _userB,
        memberships: rows,
        entities: entities,
      );
      final result =
          harness.listBusinessMembers(_entityA) as BusinessMembershipListDenied;
      expect(result.cause, BusinessManagementReadCause.permissionDenied);
    });

    test('12. non-member cannot list the roster', () {
      final harness = _ManagementHarness(
        actor: 'outsider',
        memberships: rows,
        entities: entities,
      );
      final result =
          harness.listBusinessMembers(_entityA) as BusinessMembershipListDenied;
      expect(result.cause, BusinessManagementReadCause.permissionDenied);
    });
  });

  group('V1-R03 source and security contract', () {
    late String migration;
    late String gateway;
    late String gatewayContract;
    late String summaryModel;

    setUpAll(() {
      migration = File(
        'supabase/migrations/00019_business_ownership_management_foundation.sql',
      ).readAsStringSync();
      gateway = File(
        'lib/features/business/data/supabase_business_membership_gateway.dart',
      ).readAsStringSync();
      gatewayContract = File(
        'lib/features/business/domain/business_membership_gateway.dart',
      ).readAsStringSync();
      summaryModel = File(
        'lib/features/business/domain/managed_business_summary.dart',
      ).readAsStringSync();
    });

    test('13. list_my_businesses accepts no spoofable actor identity', () {
      expect(migration, contains('list_my_businesses()'));
      expect(gateway, contains("_client.rpc('list_my_businesses')"));
      expect(gateway, isNot(contains("'p_user_id'")));
      expect(migration, isNot(contains('p_user_id')));
    });

    test('14. no email or provider identity ownership path exists', () {
      expect(migration, isNot(contains('email')));
      expect(migration, isNot(contains('provider_id')));
      expect(summaryModel, isNot(contains('email')));
      expect(summaryModel, isNot(contains('providerId')));
    });

    test('15. legacy futureOwnerUserId grants no canonical authority', () {
      expect(migration, isNot(contains('futureOwnerUserId')));
      expect(gateway, isNot(contains('futureOwnerUserId')));
    });

    test('16. existing own-membership direct read remains compatible', () {
      expect(gatewayContract, contains('listOwnMemberships(String userId)'));
      expect(gateway, contains("from(_table).select().eq('user_id', userId)"));
    });

    test('17. no direct client membership mutation API is introduced', () {
      expect(gatewayContract, isNot(contains('insertMembership')));
      expect(gatewayContract, isNot(contains('updateMembership')));
      expect(gatewayContract, isNot(contains('deleteMembership')));
      expect(gateway, isNot(contains('.insert(')));
      expect(gateway, isNot(contains('.update(')));
      expect(gateway, isNot(contains('.delete(')));
    });

    test('18. My Businesses projection contains only six frozen fields', () {
      final start = migration.indexOf(
        'CREATE OR REPLACE FUNCTION public.list_my_businesses',
      );
      final end = migration.indexOf('LANGUAGE plpgsql', start);
      final signature = migration.substring(start, end);
      for (final field in [
        'entity_id uuid',
        'name text',
        'entity_type text',
        'membership_role text',
        'claim_status text',
        'verification_status text',
      ]) {
        expect(signature, contains(field));
      }
      expect(signature, isNot(contains('description')));
      expect(signature, isNot(contains('contact')));
      expect(signature, isNot(contains('subscription')));
    });

    test('19. roster result contains no private profile/contact fields', () {
      final start = migration.indexOf(
        'CREATE OR REPLACE FUNCTION public.list_business_members',
      );
      final end = migration.indexOf('LANGUAGE plpgsql', start);
      final signature = migration.substring(start, end);
      expect(signature, contains('user_id uuid'));
      expect(signature, contains('entity_id uuid'));
      expect(signature, contains('role text'));
      expect(signature, isNot(contains('email')));
      expect(signature, isNot(contains('phone')));
      expect(signature, isNot(contains('profile')));
    });

    test('20. migration grants and revokes match the frozen contract', () {
      expect(migration, contains('v_actor uuid := auth.uid()'));
      expect(migration, contains('bm.role IN (\'OWNER\', \'ADMIN\')'));
      expect(
        migration,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.has_business_management_access(uuid)\n'
          '  FROM PUBLIC, anon, authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'GRANT EXECUTE ON FUNCTION public.list_my_businesses()\n'
          '  TO authenticated;',
        ),
      );
      expect(
        migration,
        contains(
          'GRANT EXECUTE ON FUNCTION public.list_business_members(uuid)\n'
          '  TO authenticated;',
        ),
      );
      expect(migration, isNot(contains('GRANT INSERT')));
      expect(migration, isNot(contains('GRANT UPDATE')));
      expect(migration, isNot(contains('GRANT DELETE')));
    });
  });

  test('typed server errors map P0AUT/P0PER and unknown fail closed', () {
    expect(
      BusinessManagementReadCause.fromServerCode('P0AUT'),
      BusinessManagementReadCause.unauthenticated,
    );
    expect(
      BusinessManagementReadCause.fromServerCode('P0PER'),
      BusinessManagementReadCause.permissionDenied,
    );
    expect(
      BusinessManagementReadCause.fromServerCode('other'),
      BusinessManagementReadCause.unexpected,
    );
    expect(
      BusinessMembershipCapabilities.forRole(
        BusinessRole.unknown,
      ).canManageEntity,
      isFalse,
    );
  });
}
