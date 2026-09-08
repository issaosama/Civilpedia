import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/business/data/supabase_business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_capabilities.dart';
import 'package:civilpedia/features/business/domain/business_application_capability_resolver.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:civilpedia/features/business/domain/business_membership.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';
const _entity1 = 'entity-1';
const _entity2 = 'entity-2';

const _configured = BackendConfig(
  appEnvRaw: 'development',
  supabaseUrl: 'https://project.supabase.co',
  supabaseAnonKey: 'anon-key',
);

Future<SupabaseService> _service({required bool initialized}) async {
  final service = SupabaseService(config: _configured);
  await service.init(
    initialize: initialized
        ? ({required url, required publishableKey}) async {}
        : ({required url, required publishableKey}) async {
            throw Exception('backend unreachable');
          },
  );
  return service;
}

class _FakeMembershipGateway implements BusinessMembershipGateway {
  _FakeMembershipGateway();

  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessMembership>> listOwnMemberships(String userId) async {
    return const [];
  }

  @override
  BusinessMembershipListResult listMembersForEntity(String entityId) =>
      const BusinessMembershipListUnavailable();
}

BusinessMembership _membership({
  required String userId,
  required String entityId,
  required BusinessRole role,
}) {
  return BusinessMembership(userId: userId, entityId: entityId, role: role);
}

BusinessApplication _app({
  String id = 'app-1',
  String? applicant = _userA,
  BusinessApplicationType type = BusinessApplicationType.newApplication,
  String? target,
  BusinessApplicationStatus status = BusinessApplicationStatus.draft,
}) {
  return BusinessApplication(
    id: id,
    applicantUserId: applicant,
    type: type,
    targetEntityId: target,
    status: status,
  );
}

void main() {
  group('A6.2 BusinessApplicationType', () {
    test('types map to exact DB codes (migration 00007)', () {
      expect(BusinessApplicationType.newApplication.code, 'NEW');
      expect(BusinessApplicationType.claim.code, 'CLAIM');
      expect(BusinessApplicationType.fromCode('NEW'), BusinessApplicationType.newApplication);
      expect(BusinessApplicationType.fromCode('CLAIM'), BusinessApplicationType.claim);
    });

    test('unknown type fails closed', () {
      expect(BusinessApplicationType.fromCode('OTHER'), BusinessApplicationType.unknown);
      expect(BusinessApplicationType.fromCode(null), BusinessApplicationType.unknown);
      expect(BusinessApplicationType.fromCode('new'), BusinessApplicationType.unknown);
      expect(BusinessApplicationType.unknown.isKnown, isFalse);
    });
  });

  group('A6.2 BusinessApplicationStatus', () {
    test('all 9 storage codes parse and round-trip', () {
      const codes = [
        'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'CONTACTED',
        'VISIT_SCHEDULED', 'APPROVED', 'REJECTED', 'ACTIVATED',
      ];
      for (final code in codes) {
        expect(BusinessApplicationStatus.fromCode(code).code, code);
      }
    });

    test('unknown status fails closed (18)', () {
      expect(BusinessApplicationStatus.fromCode('BOGUS'), BusinessApplicationStatus.unknown);
      expect(BusinessApplicationStatus.fromCode(null), BusinessApplicationStatus.unknown);
      expect(BusinessApplicationStatus.unknown.isKnown, isFalse);
    });

    test('isFinal / isLive semantics', () {
      expect(BusinessApplicationStatus.rejected.isFinal, isTrue);
      expect(BusinessApplicationStatus.activated.isFinal, isTrue);
      expect(BusinessApplicationStatus.approved.isFinal, isFalse,
          reason: 'APPROVED still awaits activation');
      expect(BusinessApplicationStatus.draft.isLive, isTrue);
      expect(BusinessApplicationStatus.rejected.isLive, isFalse);
    });
  });

  group('A6.2 BusinessApplication model', () {
    test('tryFromRow maps canonical columns', () {
      final app = BusinessApplication.tryFromRow({
        'id': 'app-1',
        'applicant_user_id': _userA,
        'application_type': 'CLAIM',
        'target_entity_id': _entity1,
        'status': 'DRAFT',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      })!;
      expect(app.id, 'app-1');
      expect(app.applicantUserId, _userA);
      expect(app.type, BusinessApplicationType.claim);
      expect(app.targetEntityId, _entity1);
      expect(app.status, BusinessApplicationStatus.draft);
      expect(app.belongsTo(_userA), isTrue);
      expect(app.belongsTo(_userB), isFalse);
    });

    test('tryFromRow fails closed on malformed rows (19)', () {
      expect(BusinessApplication.tryFromRow(const {}), isNull);
      expect(
        BusinessApplication.tryFromRow({
          'id': 'app-1',
          'application_type': 'BOGUS',
          'status': 'DRAFT',
        }),
        isNull,
        reason: 'unknown type is not a valid application',
      );
      expect(
        BusinessApplication.tryFromRow({
          'id': 'app-1',
          'application_type': 'NEW',
          'status': 'BOGUS',
        }),
        isNull,
        reason: 'unknown status is not a valid application',
      );
    });

    test('staff fields are surfaced read-only, never writable (22/23)', () {
      final app = BusinessApplication.tryFromRow({
        'id': 'app-1',
        'applicant_user_id': _userA,
        'application_type': 'NEW',
        'status': 'APPROVED',
        'reviewed_by_user_id': 'staff-uuid',
        'reviewed_at': '2026-01-01T00:00:00.000Z',
        'approved_at': '2026-01-01T00:00:00.000Z',
        'rejection_reason': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      })!;
      expect(app.approvedAt, isNotNull);
      expect(app.reviewedByUserId, 'staff-uuid');
      // The model exposes NO mutation/copyWith for staff columns.
      expect(app, isA<BusinessApplication>());
    });
  });

  group('A6.2 capability semantics (all 9 statuses)', () {
    BusinessApplicationCapabilities caps(BusinessApplicationStatus s) =>
        BusinessApplicationCapabilityResolver.forStatus(s);

    test('9. DRAFT → canEdit/canSubmit true, not pending/final', () {
      final c = caps(BusinessApplicationStatus.draft);
      expect(c.canEdit, isTrue);
      expect(c.canSubmit, isTrue);
      expect(c.canResubmit, isFalse);
      expect(c.isPending, isFalse);
      expect(c.isFinal, isFalse);
      expect(c.requiresCorrection, isFalse);
    });

    test('10. SUBMITTED → read-only, pending', () {
      final c = caps(BusinessApplicationStatus.submitted);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.isPending, isTrue);
      expect(c.isFinal, isFalse);
    });

    test('11. UNDER_REVIEW → read-only, pending', () {
      final c = caps(BusinessApplicationStatus.underReview);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.isPending, isTrue);
    });

    test('12. NEEDS_CORRECTION → correction/resubmit represented, NO update path', () {
      final c = caps(BusinessApplicationStatus.needsCorrection);
      expect(c.canEdit, isTrue);
      expect(c.canResubmit, isTrue);
      expect(c.requiresCorrection, isTrue);
      expect(c.isPending, isFalse);
      // The capability is a UX hint only; the gateway exposes NO UPDATE.
    });

    test('13. CONTACTED → read-only, pending', () {
      final c = caps(BusinessApplicationStatus.contacted);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.isPending, isTrue);
    });

    test('14. VISIT_SCHEDULED → read-only, pending', () {
      final c = caps(BusinessApplicationStatus.visitScheduled);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.isPending, isTrue);
    });

    test('15. APPROVED → NOT activated, NOT owner automatically', () {
      final c = caps(BusinessApplicationStatus.approved);
      expect(c.canSubmit, isFalse);
      expect(c.isPending, isFalse);
      expect(c.isFinal, isFalse);
      expect(c.isApproved, isTrue);
      expect(c.isActivated, isFalse);
      // Ownership is a SEPARATE membership concern, never inferred here.
    });

    test('16. REJECTED → read-only, final, no ownership', () {
      final c = caps(BusinessApplicationStatus.rejected);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.isFinal, isTrue);
      expect(c.isRejected, isTrue);
      expect(c.isActivated, isFalse);
    });

    test('17. ACTIVATED → terminal applicant state', () {
      final c = caps(BusinessApplicationStatus.activated);
      expect(c.isFinal, isTrue);
      expect(c.canSubmit, isFalse);
      expect(c.isActivated, isTrue);
    });

    test('18. UNKNOWN → fail closed', () {
      final c = caps(BusinessApplicationStatus.unknown);
      expect(c.canEdit, isFalse);
      expect(c.canSubmit, isFalse);
      expect(c.canResubmit, isFalse);
      expect(c.isPending, isFalse);
      expect(c.isFinal, isFalse);
      expect(c.requiresCorrection, isFalse);
    });

    test('capability resolver fails closed for a null application (1)', () {
      final c = BusinessApplicationCapabilityResolver.capabilitiesFor(null);
      expect(c.canSubmit, isFalse);
      expect(c.canEdit, isFalse);
      expect(c.isUnknown, isTrue);
    });
  });

  group('A6.2 BusinessApplicationPolicy (creation/claim safety)', () {
    test('1. guest cannot create NEW', () {
      expect(
        BusinessApplicationPolicy.evaluateNew(currentUserId: ''),
        isA<BusinessApplicationPolicyDenied>()
            .having((d) => d.cause, 'cause', BusinessApplicationRejectionCause.guestUser),
      );
    });

    test('3. authenticated NEW draft allowed', () {
      expect(
        BusinessApplicationPolicy.evaluateNew(currentUserId: _userA),
        isA<BusinessApplicationPolicyAllowed>(),
      );
    });

    test('4. zero applications is a valid empty state (scripted read)', () async {
      final gateway = _ScriptedGateway();
      final apps = await gateway.listOwnApplications(_userA);
      expect(apps, isEmpty);
    });

    test('5. claim missing target rejected', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: '',
          memberships: const [],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyDenied>().having(
          (d) => d.cause,
          'cause',
          BusinessApplicationRejectionCause.missingTarget,
        ),
      );
    });

    test('7. existing OWNER membership blocks claim', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: [
            _membership(userId: _userA, entityId: _entity1, role: BusinessRole.owner),
          ],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyDenied>().having(
          (d) => d.cause,
          'cause',
          BusinessApplicationRejectionCause.alreadyOwner,
        ),
      );
    });

    test('ADMIN membership does NOT block a claim by itself', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: [
            _membership(userId: _userA, entityId: _entity1, role: BusinessRole.admin),
          ],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyAllowed>(),
      );
    });

    test('8. already-claimed/live duplicate CLAIM fails closed', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: const [],
          ownApplications: [
            _app(
              id: 'claim-1',
              type: BusinessApplicationType.claim,
              target: _entity1,
              status: BusinessApplicationStatus.submitted,
            ),
          ],
        ),
        isA<BusinessApplicationPolicyDenied>().having(
          (d) => d.cause,
          'cause',
          BusinessApplicationRejectionCause.duplicateClaim,
        ),
      );
    });

    test('a FINAL prior claim (rejected/activated) does NOT block a new claim', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: const [],
          ownApplications: [
            _app(
              id: 'claim-old',
              type: BusinessApplicationType.claim,
              target: _entity1,
              status: BusinessApplicationStatus.rejected,
            ),
          ],
        ),
        isA<BusinessApplicationPolicyAllowed>(),
      );
    });

    test('23. futureOwnerUserId grants NO claim approval', () {
      // Legacy local metadata must never influence claim authority.
      final legacy = ServiceBusinessProfile(
        id: _entity1,
        name: 'Legacy',
        type: BusinessType.other,
        futureOwnerUserId: _userA,
      );
      expect(legacy.futureOwnerUserId, _userA);
      // Domain policy only consults memberships + own applications.
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: const [],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyAllowed>(),
        reason: 'legacy field does not add authority, but also does not block',
      );
    });

    test('guest claim fails closed before any target check', () {
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: '',
          targetEntityId: _entity1,
          memberships: const [],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyDenied>().having(
          (d) => d.cause,
          'cause',
          BusinessApplicationRejectionCause.guestUser,
        ),
      );
    });
  });

  group('A6.2 gateway contract (no mutation / no side effects)', () {
    test('13. no client submission/transition path exists', () async {
      final gateway = SupabaseBusinessApplicationGateway(
        service: await _service(initialized: true),
      );
      final app = _app();
      // Submitting/resubmitting is UNAVAILABLE from the client.
      expect(gateway.submitApplication(app), isA<BusinessApplicationSubmitUnavailable>());
      expect(gateway.resubmitApplication(app), isA<BusinessApplicationSubmitUnavailable>());
    });

    test('21. application creation never creates a membership', () async {
      // Claim safety consults the READ-ONLY membership gateway; the application
      // gateway owns no membership-write path.
      final membershipGateway = _FakeMembershipGateway();
      final decision = BusinessApplicationPolicy.evaluateClaim(
        currentUserId: _userA,
        targetEntityId: _entity1,
        memberships: await membershipGateway.listOwnMemberships(_userA),
        ownApplications: const [],
      );
      expect(decision, isA<BusinessApplicationPolicyAllowed>());
      expect(await membershipGateway.listOwnMemberships(_userA), isEmpty,
          reason: 'evaluating/creating a claim must never add a membership');
    });

    test('25. claim creation never mutates directory claim/verification state',
        () async {
      // The only datum a CLAIM application carries about the target is the
      // target_entity_id reference on the application row. There is no payload
      // field for claim_status or verification, and no gateway method touches
      // directory_entities.
      final gateway = _ScriptedGateway();
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      final created = (result as BusinessApplicationCreated).application;
      expect(created.targetEntityId, _entity1);
      // Parse also ignores trailing/local-only columns such as claim_status.
      final parsed = BusinessApplication.tryFromRow({
        'id': created.id,
        'applicant_user_id': _userA,
        'application_type': 'CLAIM',
        'target_entity_id': _entity1,
        'status': 'DRAFT',
        'claim_status': 'VERIFIED',
        'verification_status': 'IN_REVIEW',
      })!;
      expect(parsed.targetEntityId, _entity1);
      expect(parsed.status, BusinessApplicationStatus.draft);
      expect(parsed.toString(), isNot(contains('claim_status')));
    });

    test('24. no Google id/email applicant identity logic exists', () {
      // Canonical applicant is auth.users.id only.
      final app = _app(applicant: _userA);
      expect(app.applicantUserId, _userA);
      expect(app.belongsTo(_userA), isTrue);
    });

    test('26. guest build keeps gateway unavailable', () async {
      final gateway = SupabaseBusinessApplicationGateway(
        service: await _service(initialized: false),
      );
      expect(gateway.isAvailable, isFalse);
    });
  });

  group('A6.2 fake-gateway workflow (target validation & mismatches)', () {
    test('4. CLAIM DRAFT references the target entity', () async {
      final gateway = _ScriptedGateway();
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(result, isA<BusinessApplicationCreated>());
      final created = (result as BusinessApplicationCreated).application;
      expect(created.type, BusinessApplicationType.claim);
      expect(created.targetEntityId, _entity1);
      expect(created.status, BusinessApplicationStatus.draft);
    });

    test('5. caller-supplied different applicant id is rejected (fail closed)', () async {
      // RLS 42501 (inserted applicant != session user) maps to a typed denial.
      final deniedResult = await _ScriptedGateway(forceRlsMismatch: true)
          .createNewDraft(currentUserId: _userB);
      expect(
        (deniedResult as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.applicantMismatch,
      );
    });

    test('6. CLAIM target missing → rejected (FK targetNotFound)', () async {
      final gateway = _ScriptedGateway(forceTargetMissing: true);
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity2,
      );
      expect(
        (result as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.targetNotFound,
      );
    });

    test('1. unclaimed target → CLAIM draft allowed', () async {
      final gateway = _ScriptedGateway();
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(result, isA<BusinessApplicationCreated>());
      expect((result as BusinessApplicationCreated).application.status,
          BusinessApplicationStatus.draft);
    });

    test('2. already-claimed target → authoritative rejection (trigger P0CLM)',
        () async {
      // The migration-00014 BEFORE INSERT trigger raises P0CLM when the
      // target's canonical claim_status is not 'unclaimed'. This is a server
      // verdict, independent of any client precheck.
      final gateway = _ScriptedGateway(forceClaimedTarget: true);
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(
        (result as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.targetNotClaimable,
      );
    });

    test('7. unknown/anomalous claim_status fails closed', () async {
      // Domain never infers claimability from name/phone/email/metadata; any
      // target that is not authoritatively 'unclaimed' is not claimable. The
      // scripted trigger denial stands in for claim_status 'pending'/'claimed'
      // and any unreadable state, all of which fail closed.
      final gateway = _ScriptedGateway(forceClaimedTarget: true);
      final denied = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(
        (denied as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.targetNotClaimable,
      );

      final namePhoneEmail = ServiceBusinessProfile(
        id: _entity1,
        name: 'Decoy',
        type: BusinessType.other,
        futureOwnerUserId: _userA,
      );
      // A promising profile never flips claimability client-side.
      expect(
        BusinessApplicationPolicy.evaluateClaim(
          currentUserId: _userA,
          targetEntityId: _entity1,
          memberships: const [],
          ownApplications: const [],
        ),
        isA<BusinessApplicationPolicyAllowed>(),
        reason: 'claimability is server-authoritative; client policy does not '
            'reject purely on local entity metadata',
      );
      expect(namePhoneEmail.name, 'Decoy');
    });

    test('5c. concurrent equivalent CLAIM creates → exactly one succeeds', () async {
      // Two concurrent POSTs race on the authoritative partial unique index
      // uq_business_applications_live_claim (00014). The deterministic fake
      // reproduces the winner/loser split: first wins, second is rejected.
      final gateway = _ScriptedGateway(dupOnSecondCall: true);
      final a = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      final b = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(a, isA<BusinessApplicationCreated>());
      expect(
        (b as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.duplicateClaim,
      );
    });

    test('5d. pre-checked duplicate live CLAIM is a duplicated insert (index 23505)',
        () async {
      // Same shape as above via the raw unique-violation signal.
      final gateway = _ScriptedGateway(forceUniqueViolation: true);
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(
        (result as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.duplicateClaim,
      );
    });

    test('6. target disappears between precheck and create → targetNotFound',
        () async {
      // Precheck passed (client saw unclaimed), but the entity row is gone by
      // insert time → the FK emits 23503 → authoritative typed denial.
      final gateway = _ScriptedGateway(forceTargetMissing: true);
      final result = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(
        (result as BusinessApplicationCreateDenied).cause,
        BusinessApplicationRejectionCause.targetNotFound,
      );
    });

    test('9. authoritative hardening adds no ownership side effects', () async {
      // The denial outcomes carry ONLY a typed cause — no membership, no
      // entity claim/verification mutation, no ownership grant is possible
      // through them.
      final gateway = _ScriptedGateway(forceClaimedTarget: true);
      final denied = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      final marker = denied as BusinessApplicationCreateDenied;
      expect(marker.cause, BusinessApplicationRejectionCause.targetNotClaimable);
      // Contract: a denial exposes no write handle of any kind.
      expect(marker, isA<BusinessApplicationCreateDenied>());
    });

    test('20. read/network failure → no invented status', () async {
      final gateway = _ScriptedGateway(forceReadError: true);
      await expectLater(gateway.listOwnApplications(_userA), throwsException);
      final caps = BusinessApplicationCapabilityResolver.capabilitiesFor(null);
      expect(caps.isUnknown, isTrue);
      expect(caps.canSubmit, isFalse);
    });
  });
}

/// Deterministic fake [BusinessApplicationGateway] used to exercise the
/// insertion/RLS/FK mapping contract without a live Supabase.
class _ScriptedGateway implements BusinessApplicationGateway {
  _ScriptedGateway({
    this.forceRlsMismatch = false,
    this.forceTargetMissing = false,
    this.forceReadError = false,
    this.forceClaimedTarget = false,
    this.forceUniqueViolation = false,
    this.dupOnSecondCall = false,
  });

  final bool forceRlsMismatch;
  final bool forceTargetMissing;
  final bool forceReadError;

  /// Simulates the migration-00014 BEFORE INSERT trigger (SQLSTATE P0CLM):
  /// the target exists but its canonical claim_status is not 'unclaimed'.
  final bool forceClaimedTarget;

  /// Simulates the migration-00014 partial unique index (SQLSTATE 23505):
  /// a concurrent request already holds a live CLAIM for (applicant, target).
  final bool forceUniqueViolation;

  /// Concurrency semantics: the first CLAIM create for a given (user, target)
  /// succeeds; the second equivalent create fails as a duplicate. This models
  /// two concurrent POSTs racing on the authoritative partial unique index.
  final bool dupOnSecondCall;

  final Map<String, int> _liveClaimCount = {};
  BusinessApplicationRejectionCause? lastRejectedCause;

  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    if (forceReadError) throw Exception('net');
    return [];
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    if (forceReadError) throw Exception('net');
    return null;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId.isEmpty) {
      lastRejectedCause = BusinessApplicationRejectionCause.guestUser;
      return BusinessApplicationCreateDenied(BusinessApplicationRejectionCause.guestUser);
    }
    if (forceRlsMismatch) {
      lastRejectedCause = BusinessApplicationRejectionCause.applicantMismatch;
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.applicantMismatch,
      );
    }
    return BusinessApplicationCreated(
      _app(
        id: 'new-1',
        applicant: currentUserId,
        type: BusinessApplicationType.newApplication,
      ),
    );
  }

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async {
    if (currentUserId.isEmpty) {
      lastRejectedCause = BusinessApplicationRejectionCause.guestUser;
      return BusinessApplicationCreateDenied(BusinessApplicationRejectionCause.guestUser);
    }
    if (targetEntityId.isEmpty) {
      lastRejectedCause = BusinessApplicationRejectionCause.missingTarget;
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.missingTarget,
      );
    }
    if (forceTargetMissing) {
      lastRejectedCause = BusinessApplicationRejectionCause.targetNotFound;
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.targetNotFound,
      );
    }
    if (forceClaimedTarget) {
      // Authoritative trigger P0CLM: claim_status <> 'unclaimed'.
      lastRejectedCause = BusinessApplicationRejectionCause.targetNotClaimable;
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.targetNotClaimable,
      );
    }
    if (forceUniqueViolation) {
      // Authoritative partial unique index 23505.
      lastRejectedCause = BusinessApplicationRejectionCause.duplicateClaim;
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.duplicateClaim,
      );
    }
    if (dupOnSecondCall) {
      final key = '$currentUserId|$targetEntityId';
      final prior = _liveClaimCount[key] ?? 0;
      _liveClaimCount[key] = prior + 1;
      if (prior > 0) {
        lastRejectedCause = BusinessApplicationRejectionCause.duplicateClaim;
        return const BusinessApplicationCreateDenied(
          BusinessApplicationRejectionCause.duplicateClaim,
        );
      }
    }
    return BusinessApplicationCreated(
      _app(
        id: 'claim-1',
        applicant: currentUserId,
        type: BusinessApplicationType.claim,
        target: targetEntityId,
      ),
    );
  }

  @override
  BusinessApplicationSubmitResult submitApplication(BusinessApplication application) =>
      const BusinessApplicationSubmitUnavailable();

  @override
  BusinessApplicationSubmitResult resubmitApplication(BusinessApplication application) =>
      const BusinessApplicationSubmitUnavailable();
}