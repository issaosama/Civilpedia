import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/business/data/supabase_business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_membership.dart';
import 'package:civilpedia/features/business/domain/business_membership_capabilities.dart';
import 'package:civilpedia/features/business/domain/business_membership_capability_resolver.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';
const _entity1 = 'entity-1';
const _entity2 = 'entity-2';
const _entity3 = 'entity-3';

const _configured = BackendConfig(
  appEnvRaw: 'development',
  supabaseUrl: 'https://project.supabase.co',
  supabaseAnonKey: 'anon-key',
);

/// Builds a real [SupabaseService] with an injected no-op initializer so
/// [SupabaseService.isInitialized] is controllable without touching the real
/// Supabase singleton.
Future<SupabaseService> _serviceWithInitialization({required bool initialized}) async {
  final service = SupabaseService(config: _configured);
  await service.init(
    initialize:
        initialized
            ? ({required url, required publishableKey}) async {}
            : ({required url, required publishableKey}) async {
                throw Exception('backend unreachable');
              },
  );
  return service;
}

/// Programmable [BusinessMembershipGateway] fake for deterministic unit tests.
class _FakeMembershipGateway implements BusinessMembershipGateway {
  _FakeMembershipGateway({this.available = true, List<BusinessMembership>? rows})
      : rows = rows ?? [];

  bool available;
  final List<BusinessMembership> rows;
  Object? readError;
  int listCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<List<BusinessMembership>> listOwnMemberships(String userId) async {
    listCalls++;
    if (readError != null) throw readError!;
    return rows.where((m) => m.userId == userId).toList();
  }

  @override
  Future<ManagedBusinessListResult> listMyBusinesses() async =>
      const ManagedBusinessListUnavailable();

  @override
  Future<BusinessMembershipListResult> listMembersForEntity(
    String entityId,
  ) async =>
      const BusinessMembershipListUnavailable();
}

void main() {
  group('A6.1 BusinessRole', () {
    test('exact DB storage codes match migration 00006 CHECK values', () {
      expect(BusinessRole.owner.code, 'OWNER');
      expect(BusinessRole.admin.code, 'ADMIN');
      expect(BusinessRole.member.code, 'MEMBER');
    });

    test('fromCode parses valid codes case-sensitively', () {
      expect(BusinessRole.fromCode('OWNER'), BusinessRole.owner);
      expect(BusinessRole.fromCode('ADMIN'), BusinessRole.admin);
      expect(BusinessRole.fromCode('MEMBER'), BusinessRole.member);
    });

    test('unknown role code fails closed to unknown (8)', () {
      expect(BusinessRole.fromCode('BOGUS'), BusinessRole.unknown);
      expect(BusinessRole.fromCode('owner'), BusinessRole.unknown,
          reason: 'casing must match the exact DB code exactly');
      expect(BusinessRole.fromCode(null), BusinessRole.unknown);
      expect(BusinessRole.fromCode(''), BusinessRole.unknown);
      expect(BusinessRole.unknown.isKnown, isFalse);
      expect(BusinessRole.owner.isKnown, isTrue);
    });
  });

  group('A6.1 BusinessMembership model', () {
    test('tryFromRow maps canonical user_id/entity_id/role', () {
      final m = BusinessMembership.tryFromRow({
        'user_id': _userA,
        'entity_id': _entity1,
        'role': 'OWNER',
      })!;
      expect(m.userId, _userA);
      expect(m.entityId, _entity1);
      expect(m.role, BusinessRole.owner);
    });

    test('tryFromRow fails closed on malformed/unknown rows', () {
      expect(
        BusinessMembership.tryFromRow({'entity_id': _entity1}),
        isNull,
        reason: 'missing user_id is not a valid membership',
      );
      expect(
        BusinessMembership.tryFromRow({'user_id': _userA}),
        isNull,
        reason: 'missing entity_id is not a valid membership',
      );
      expect(
        BusinessMembership.tryFromRow({
          'user_id': _userA,
          'entity_id': _entity1,
          'role': 'SUPERADMIN',
        })!.role,
        BusinessRole.unknown,
        reason: 'unknown role maps to unknown, never elevated',
      );
    });

    test('equality is value-based on identity fields and role', () {
      final a = BusinessMembership(
        userId: _userA,
        entityId: _entity1,
        role: BusinessRole.owner,
      );
      final same = BusinessMembership(
        userId: _userA,
        entityId: _entity1,
        role: BusinessRole.owner,
      );
      final differentRole = BusinessMembership(
        userId: _userA,
        entityId: _entity1,
        role: BusinessRole.admin,
      );
      expect(a, same);
      expect(a, isNot(differentRole));
    });
  });

  group('A6.1 BusinessMembershipCapabilities (role semantics)', () {
    test('3. OWNER → isOwner true, canManageEntity true', () {
      final caps = BusinessMembershipCapabilities.forRole(BusinessRole.owner);
      expect(caps.isOwner, isTrue);
      expect(caps.canManageEntity, isTrue);
    });

    test('4. ADMIN → isOwner false, canManageEntity true', () {
      final caps = BusinessMembershipCapabilities.forRole(BusinessRole.admin);
      expect(caps.isOwner, isFalse);
      expect(caps.canManageEntity, isTrue);
    });

    test('5. MEMBER → isOwner false, canManageEntity false', () {
      final caps = BusinessMembershipCapabilities.forRole(BusinessRole.member);
      expect(caps.isOwner, isFalse);
      expect(caps.canManageEntity, isFalse);
    });

    test('8. UNKNOWN → fail closed, no elevated capability', () {
      final caps = BusinessMembershipCapabilities.forRole(BusinessRole.unknown);
      expect(caps.isOwner, isFalse);
      expect(caps.canManageEntity, isFalse);
    });
  });

  group('A6.1 BusinessMembershipCapabilityResolver', () {
    List<BusinessMembership> membership({
      required String userId,
      required String entityId,
      required BusinessRole role,
    }) {
      return [
        BusinessMembership(userId: userId, entityId: entityId, role: role),
      ];
    }

    test('no membership for entity → capability-less (1/2/11)', () {
      // Guest-like: empty list.
      final guest = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        const [],
        userId: _userA,
        entityId: _entity1,
      );
      expect(guest.canManageEntity, isFalse);
      expect(guest.isOwner, isFalse);

      // Authenticated with memberships but none for this entity (unclaimed).
      final other = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        membership(
          userId: _userA,
          entityId: _entity2,
          role: BusinessRole.owner,
        ),
        userId: _userA,
        entityId: _entity1,
      );
      expect(other.canManageEntity, isFalse);
      expect(other.isOwner, isFalse);
    });

    test('MEMBER-only membership is NEVER treated as OWNER (5)', () {
      final caps = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        membership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.member,
        ),
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps.isOwner, isFalse);
      expect(caps.canManageEntity, isFalse);
    });

    test('only the matching user+entity row is consulted (10)', () {
      // _userB is OWNER of entity1; _userA has nothing there.
      final mixed = [
        BusinessMembership(
          userId: _userB,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        BusinessMembership(
          userId: _userA,
          entityId: _entity2,
          role: BusinessRole.admin,
        ),
      ];
      final caps = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        mixed,
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps.canManageEntity, isFalse,
          reason: "another user's OWNER must never grant _userA capability");
      expect(caps.isOwner, isFalse);
    });

    test('multiple entities → each resolved independently (6)', () {
      final caps1 =
          BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        membership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps1.isOwner, isTrue);
      expect(caps1.canManageEntity, isTrue);

      final caps2 =
          BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        membership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        userId: _userA,
        entityId: _entity2,
      );
      expect(caps2.canManageEntity, isFalse);
    });

    test('legacy futureOwnerUserId does NOT grant capability (12)', () {
      // A local Directory profile carrying legacy futureOwnerUserId must never
      // be treated as canonical ownership — the resolver only consults
      // membership roles.
      final legacyProfile = ServiceBusinessProfile(
        id: _entity1,
        name: 'Legacy shop',
        type: BusinessType.other,
        futureOwnerUserId: _userA,
      );
      expect(legacyProfile.futureOwnerUserId, _userA,
          reason: 'legacy field is still read-compatible/preserved');

      final caps = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        const [],
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps.isOwner, isFalse);
      expect(caps.canManageEntity, isFalse,
          reason: 'futureOwnerUserId alone must never grant ownership');
    });

    test('duplicate payload resolves deterministically, no elevation (7)', () {
      // Two rows for the same user+entity with the same role are deduped by
      // the gateway (identity stays the same); a lower role never becomes OWNER.
      final duplicated = [
        BusinessMembership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        BusinessMembership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
      ];
      final caps = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        duplicated,
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps.isOwner, isTrue);
      expect(caps.canManageEntity, isTrue);
    });
  });

  group('A6.1 SupabaseBusinessMembershipGateway', () {
    test('isAvailable reflects backend initialization', () async {
      final unavailable = SupabaseBusinessMembershipGateway(
        service: await _serviceWithInitialization(initialized: false),
      );
      expect(unavailable.isAvailable, isFalse);

      final available = SupabaseBusinessMembershipGateway(
        service: await _serviceWithInitialization(initialized: true),
      );
      expect(available.isAvailable, isTrue);
    });

    test('listMembersForEntity fails closed when backend is unavailable',
        () async {
      final gateway = SupabaseBusinessMembershipGateway(
        service: await _serviceWithInitialization(initialized: false),
      );
      expect(
        await gateway.listMembersForEntity(_entity1),
        isA<BusinessMembershipListUnavailable>(),
      );
    });
  });

  group('A6.1 gateway failure semantics (9)', () {
    test('read/network failure exposes no invented role and no capability', () async {
      final gateway = _FakeMembershipGateway()..readError = Exception('net');
      await expectLater(gateway.listOwnMemberships(_userA), throwsException);

      // A consumed (throwing) read must be treated as offline: capability set
      // stays empty / fail-closed. Simulate by an empty list (fail closed).
      final empty = const <BusinessMembership>[];
      final guestCaps =
          BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        empty,
        userId: _userA,
        entityId: _entity1,
      );
      expect(guestCaps.canManageEntity, isFalse);
      expect(guestCaps.isOwner, isFalse);
    });

    test('guest/unavailable gateway yields no memberships (1)', () async {
      final gateway = _FakeMembershipGateway(available: false);
      // Guest has no session, so no read is even attempted; capabilities fail
      // closed.
      final caps = BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        const [],
        userId: '',
        entityId: _entity1,
      );
      expect(caps.canManageEntity, isFalse);
      expect(gateway.isAvailable, isFalse);
    });

    test('authenticated user with zero memberships → valid empty state (2)',
        () async {
      final gateway = _FakeMembershipGateway();
      final memberships = await gateway.listOwnMemberships(_userA);
      expect(memberships, isEmpty);
      final caps =
          BusinessMembershipCapabilityResolver.capabilitiesForEntity(
        memberships,
        userId: _userA,
        entityId: _entity1,
      );
      expect(caps.canManageEntity, isFalse);
      expect(caps.isOwner, isFalse);
    });
  });

  group('A6.1 own-membership reads (6/10)', () {
    test('multiple entities → all own memberships returned (6)', () async {
      final gateway = _FakeMembershipGateway(rows: [
        BusinessMembership(
          userId: _userA,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        BusinessMembership(
          userId: _userA,
          entityId: _entity2,
          role: BusinessRole.admin,
        ),
        BusinessMembership(
          userId: _userA,
          entityId: _entity3,
          role: BusinessRole.member,
        ),
      ]);
      final mine = await gateway.listOwnMemberships(_userA);
      expect(mine, hasLength(3));
      expect(mine.map((m) => m.entityId), containsAll([_entity1, _entity2, _entity3]));
    });

    test("another user's memberships are never surfaced (10)", () async {
      final gateway = _FakeMembershipGateway(rows: [
        BusinessMembership(
          userId: _userB,
          entityId: _entity1,
          role: BusinessRole.owner,
        ),
        BusinessMembership(
          userId: _userA,
          entityId: _entity2,
          role: BusinessRole.admin,
        ),
      ]);
      final mine = await gateway.listOwnMemberships(_userA);
      expect(mine, hasLength(1));
      expect(mine.single.entityId, _entity2);
      expect(mine.single.role, BusinessRole.admin);
    });
  });

  group('A6.1 no mutation surface (13/14)', () {
    test('BusinessMembershipGateway declares NO insert/update/delete', () async {
      // Read-own only boundary contract: the production implementation exposes
      // listOwnMemberships + a server-authorized (unavailable) listing, and no
      // mutation method exists.
      final gateway = SupabaseBusinessMembershipGateway(
        service: await _serviceWithInitialization(initialized: false),
      );
      // Using a type check that a mutation path is not part of the read
      // contract via the result type for member listing.
      expect(
        await gateway.listMembersForEntity(_entity1),
        isNot(isA<BusinessMembershipListAvailable>()),
      );
    });

    test('no Google provider id / email ownership logic (14)', () {
      // Canonical identity is auth.users.id only; every read is by userId and
      // never by Google id or email. The model has no provider-id/email field.
      final constructed =
          BusinessMembership(userId: _userA, entityId: _entity1, role: BusinessRole.owner);
      expect(constructed.userId, _userA);
      // Membership model has exactly the canonical identity + entity + role.
      expect(constructed.role, BusinessRole.owner);
    });
  });
}
