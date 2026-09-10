import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_policy.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';

const _userA = 'auth-users-uuid-A';
const _userB = 'auth-users-uuid-B';
const _entity1 = 'entity-1';
const _entity2 = 'entity-2';

const _reviewerPermissions = {
  'business_applications.review',
  'business_applications.return_for_correction',
  'business_applications.mark_contacted',
  'business_applications.schedule_visit',
  'business_applications.approve',
  'business_applications.reject',
};

/// Shared configuration for the scripted (server-emulating) gateways.
class _ScriptedConfig {
  const _ScriptedConfig({
    required this.actor,
    this.phonePresent = true,
    this.metadataPresent = true,
    this.allowedPermissions = const <String>{},
  });

  /// The acting user derived "server-side". null = unauthenticated session.
  final String? actor;
  final bool phonePresent;
  final bool metadataPresent;
  final Set<String> allowedPermissions;
}

BusinessApplication _app(
  String id, {
  String? applicant = _userA,
  BusinessApplicationType type = BusinessApplicationType.newApplication,
  String? target,
  BusinessApplicationStatus status = BusinessApplicationStatus.draft,
  Map<String, dynamic>? metadata,
}) {
  return BusinessApplication(
    id: id,
    applicantUserId: applicant,
    type: type,
    targetEntityId: target,
    status: status,
    metadata: metadata,
  );
}

/// Scripted applicant gateway emulating the A6.3 server contract (00016).
class _ScriptedApplicantGateway implements BusinessApplicationGateway {
  _ScriptedApplicantGateway({
    required _ScriptedConfig config,
    Map<String, BusinessApplication>? apps,
    Map<String, String>? targetClaimStatus,
  })  : _config = config,
        _apps = apps ?? <String, BusinessApplication>{},
        targetClaimStatus = targetClaimStatus ?? <String, String>{};

  final _ScriptedConfig _config;
  final Map<String, BusinessApplication> _apps;
  final Map<String, String> targetClaimStatus;
  final List<String> auditActions = [];
  final Set<String> membershipWrites = {};

  BusinessApplication _advance(String id, BusinessApplicationStatus status) {
    final old = _apps[id]!;
    final updated = BusinessApplication(
      id: old.id,
      applicantUserId: old.applicantUserId,
      type: old.type,
      targetEntityId: old.targetEntityId,
      metadata: old.metadata,
      status: status,
    );
    _apps[id] = updated;
    return updated;
  }

  /// Shared identity + data + claimability gates for submit semantics.
  BusinessApplicationSubmitCause? _submitGate(
    BusinessApplication application, {
    required BusinessApplicationStatus expectedStatus,
  }) {
    if (_config.actor == null) {
      return BusinessApplicationSubmitCause.unauthenticated;
    }
    final app = _apps[application.id];
    if (app == null) return BusinessApplicationSubmitCause.applicationNotFound;
    if (app.applicantUserId != _config.actor) {
      return BusinessApplicationSubmitCause.notApplicant;
    }
    if (app.status != expectedStatus) {
      return BusinessApplicationSubmitCause.invalidTransition;
    }
    if (!_config.phonePresent) return BusinessApplicationSubmitCause.phoneRequired;
    if (app.type == BusinessApplicationType.newApplication &&
        !_config.metadataPresent) {
      return BusinessApplicationSubmitCause.requiredDataMissing;
    }
    if (app.type == BusinessApplicationType.claim &&
        targetClaimStatus[app.targetEntityId] != 'unclaimed') {
      return BusinessApplicationSubmitCause.targetNotClaimable;
    }
    return null;
  }

  @override
  bool get isAvailable => true;

  @override
  Future<List<BusinessApplication>> listOwnApplications(String userId) async {
    return _apps.values
        .where((a) => a.belongsTo(userId))
        .toList(growable: false);
  }

  @override
  Future<BusinessApplication?> getOwnApplication(
    String userId,
    String applicationId,
  ) async {
    final app = _apps[applicationId];
    return (app != null && app.belongsTo(userId)) ? app : null;
  }

  @override
  Future<BusinessApplicationCreateResult> createNewDraft({
    required String currentUserId,
    Map<String, dynamic>? metadata,
  }) async {
    if (currentUserId.isEmpty) {
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.guestUser,
      );
    }
    final created =
        _app('new-1', applicant: currentUserId, metadata: metadata);
    _apps[created.id] = created;
    return BusinessApplicationCreated(created);
  }

  @override
  Future<BusinessApplicationCreateResult> createClaimDraft({
    required String currentUserId,
    required String targetEntityId,
  }) async {
    if (currentUserId.isEmpty) {
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.guestUser,
      );
    }
    if (targetClaimStatus[targetEntityId] != 'unclaimed') {
      return const BusinessApplicationCreateDenied(
        BusinessApplicationRejectionCause.targetNotClaimable,
      );
    }
    final created = _app(
      'claim-1',
      applicant: currentUserId,
      type: BusinessApplicationType.claim,
      target: targetEntityId,
    );
    _apps[created.id] = created;
    return BusinessApplicationCreated(created);
  }

  @override
  Future<BusinessApplicationSubmitResult> submitApplication(
    BusinessApplication application,
  ) async {
    final gate = _submitGate(
      application,
      expectedStatus: BusinessApplicationStatus.draft,
    );
    if (gate != null) return BusinessApplicationSubmitDenied(gate);
    auditActions.add('BUSINESS_APPLICATION_SUBMIT');
    return BusinessApplicationSubmitted(
      _advance(application.id, BusinessApplicationStatus.submitted),
    );
  }

  @override
  Future<BusinessApplicationSubmitResult> resubmitApplication(
    BusinessApplication application,
  ) async {
    final gate = _submitGate(
      application,
      expectedStatus: BusinessApplicationStatus.needsCorrection,
    );
    if (gate != null) return BusinessApplicationSubmitDenied(gate);
    auditActions.add('BUSINESS_APPLICATION_RESUBMIT');
    return BusinessApplicationSubmitted(
      _advance(application.id, BusinessApplicationStatus.submitted),
    );
  }
}

/// Scripted staff gateway emulating the A6.3 staff server contract (00016).
class _ScriptedStaffGateway implements BusinessApplicationStaffGateway {
  _ScriptedStaffGateway({
    required _ScriptedConfig config,
    Map<String, BusinessApplication>? apps,
  })  : _config = config,
        _apps = apps ?? <String, BusinessApplication>{};

  final _ScriptedConfig _config;
  final Map<String, BusinessApplication> _apps;
  final List<String> auditActions = [];
  final Set<String> membershipWrites = {};
  int contactsCreated = 0;
  int visitsCreated = 0;
  final Set<String> claimStatusChangedTargets = {};

  static const _decisionStatuses = {
    BusinessApplicationStatus.underReview,
    BusinessApplicationStatus.contacted,
    BusinessApplicationStatus.visitScheduled,
  };

  bool get _authed => _config.actor != null;

  bool _hasPermission(String permission) =>
      _config.allowedPermissions.contains(permission);

  BusinessApplicationStaffDenied _denied(BusinessApplicationStaffCause cause) =>
      BusinessApplicationStaffDenied(cause);

  BusinessApplication _advance(String id, BusinessApplicationStatus status) {
    final old = _apps[id]!;
    final updated = BusinessApplication(
      id: old.id,
      applicantUserId: old.applicantUserId,
      type: old.type,
      targetEntityId: old.targetEntityId,
      metadata: old.metadata,
      status: status,
      approvedAt: status == BusinessApplicationStatus.approved
          ? (old.approvedAt ?? DateTime.now())
          : old.approvedAt,
      reviewedAt: status == BusinessApplicationStatus.draft
          ? old.reviewedAt
          : (old.reviewedAt ?? DateTime.now()),
      returnReason: old.returnReason,
      rejectionReason: old.rejectionReason,
    );
    _apps[id] = updated;
    return updated;
  }

  @override
  bool get isAvailable => true;

  @override
  Future<BusinessApplicationStaffResult> beginReview(String applicationId) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.review')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (app.status != BusinessApplicationStatus.submitted) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    auditActions.add('BUSINESS_APPLICATION_REVIEW_BEGIN');
    return BusinessApplicationStaffSucceeded(
      _advance(applicationId, BusinessApplicationStatus.underReview),
    );
  }

  @override
  Future<BusinessApplicationStaffResult> returnForCorrection(
    String applicationId, {
    required String reason,
  }) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.return_for_correction')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    if (reason.trim().isEmpty) {
      return _denied(BusinessApplicationStaffCause.correctionReasonRequired);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (app.status != BusinessApplicationStatus.underReview) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    auditActions.add('BUSINESS_APPLICATION_RETURN_FOR_CORRECTION');
    final updated = _advance(
      applicationId,
      BusinessApplicationStatus.needsCorrection,
    );
    _apps[applicationId] = BusinessApplication(
      id: updated.id,
      applicantUserId: updated.applicantUserId,
      type: updated.type,
      targetEntityId: updated.targetEntityId,
      status: updated.status,
      returnReason: reason.trim(),
      reviewedAt: DateTime.now(),
    );
    return BusinessApplicationStaffSucceeded(_apps[applicationId]!);
  }

  @override
  Future<BusinessApplicationStaffResult> markContacted(
    String applicationId, {
    required String contactType,
    String? result,
    String? notes,
  }) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.mark_contacted')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    if (contactType.trim().isEmpty ||
        !const {'phone', 'whatsapp', 'email', 'visit', 'other'}
            .contains(contactType)) {
      return _denied(BusinessApplicationStaffCause.requiredDataMissing);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (app.status != BusinessApplicationStatus.underReview) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    contactsCreated++;
    auditActions.add('BUSINESS_APPLICATION_CONTACTED');
    return BusinessApplicationStaffSucceeded(
      _advance(applicationId, BusinessApplicationStatus.contacted),
    );
  }

  @override
  Future<BusinessApplicationStaffResult> scheduleVisit(
    String applicationId, {
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.schedule_visit')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (app.status != BusinessApplicationStatus.underReview) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    visitsCreated++;
    auditActions.add('BUSINESS_APPLICATION_VISIT_SCHEDULED');
    return BusinessApplicationStaffSucceeded(
      _advance(applicationId, BusinessApplicationStatus.visitScheduled),
    );
  }

  @override
  Future<BusinessApplicationStaffResult> approve(String applicationId) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.approve')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (!_decisionStatuses.contains(app.status)) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    auditActions.add('BUSINESS_APPLICATION_APPROVED');
    final updated = _advance(applicationId, BusinessApplicationStatus.approved);
    expectApprove(updated);
    return BusinessApplicationStaffSucceeded(_apps[applicationId]!);
  }

  @override
  Future<BusinessApplicationStaffResult> activate(String applicationId) async {
    // A6.3 regression fake intentionally has no A6.4 provisioning behavior.
    return _denied(BusinessApplicationStaffCause.invalidTransition);
  }

  void expectApprove(BusinessApplication app) {
    // Approval is NOT activation and creates no ownership.
    expect(app.status, BusinessApplicationStatus.approved);
    expect(app.approvedAt, isNotNull);
  }

  @override
  Future<BusinessApplicationStaffResult> reject(
    String applicationId, {
    required String reason,
  }) async {
    if (!_authed) return _denied(BusinessApplicationStaffCause.unauthenticated);
    if (!_hasPermission('business_applications.reject')) {
      return _denied(BusinessApplicationStaffCause.staffPermissionDenied);
    }
    if (reason.trim().isEmpty) {
      return _denied(BusinessApplicationStaffCause.rejectionReasonRequired);
    }
    final app = _apps[applicationId];
    if (app == null) {
      return _denied(BusinessApplicationStaffCause.applicationNotFound);
    }
    if (!_decisionStatuses.contains(app.status)) {
      return _denied(BusinessApplicationStaffCause.invalidTransition);
    }
    auditActions.add('BUSINESS_APPLICATION_REJECTED');
    final updated = _advance(applicationId, BusinessApplicationStatus.rejected);
    _apps[applicationId] = BusinessApplication(
      id: updated.id,
      applicantUserId: updated.applicantUserId,
      type: updated.type,
      targetEntityId: updated.targetEntityId,
      status: updated.status,
      rejectionReason: reason.trim(),
      reviewedAt: DateTime.now(),
    );
    return BusinessApplicationStaffSucceeded(_apps[applicationId]!);
  }

  /// Test-only: when the applicant resubmits, the staff-equivalent step goes
  /// back to SUBMITTED (mirrors the resubmit RPC transition).
  Future<void> resubmitVia(String applicationId) async {
    _advance(applicationId, BusinessApplicationStatus.submitted);
  }
}

void main() {
  group('A6.3 SQLSTATE → typed cause mapping', () {
    test('applicant codes map exactly (no invented verification)', () {
      expect(BusinessApplicationSubmitCause.fromServerCode('P0AUT'),
          BusinessApplicationSubmitCause.unauthenticated);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0NAC'),
          BusinessApplicationSubmitCause.notApplicant);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0NOT'),
          BusinessApplicationSubmitCause.applicationNotFound);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0TRA'),
          BusinessApplicationSubmitCause.invalidTransition);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0PHR'),
          BusinessApplicationSubmitCause.phoneRequired);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0DAT'),
          BusinessApplicationSubmitCause.requiredDataMissing);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0CLM'),
          BusinessApplicationSubmitCause.targetNotClaimable);
      expect(BusinessApplicationSubmitCause.fromServerCode(null),
          BusinessApplicationSubmitCause.unexpected);
      expect(BusinessApplicationSubmitCause.fromServerCode('P0PER'),
          BusinessApplicationSubmitCause.unexpected);
      expect(
        BusinessApplicationSubmitCause.values.any(
          (c) => c.name.toLowerCase().contains('verif'),
        ),
        isFalse,
        reason: 'phone presence is not phone verification',
      );
    });

    test('staff codes map exactly', () {
      expect(BusinessApplicationStaffCause.fromServerCode('P0AUT'),
          BusinessApplicationStaffCause.unauthenticated);
      expect(BusinessApplicationStaffCause.fromServerCode('P0PER'),
          BusinessApplicationStaffCause.staffPermissionDenied);
      expect(BusinessApplicationStaffCause.fromServerCode('P0NOT'),
          BusinessApplicationStaffCause.applicationNotFound);
      expect(BusinessApplicationStaffCause.fromServerCode('P0TRA'),
          BusinessApplicationStaffCause.invalidTransition);
      expect(BusinessApplicationStaffCause.fromServerCode('P0COR'),
          BusinessApplicationStaffCause.correctionReasonRequired);
      expect(BusinessApplicationStaffCause.fromServerCode('P0REJ'),
          BusinessApplicationStaffCause.rejectionReasonRequired);
      expect(BusinessApplicationStaffCause.fromServerCode('P0DAT'),
          BusinessApplicationStaffCause.requiredDataMissing);
      expect(BusinessApplicationStaffCause.fromServerCode('X'),
          BusinessApplicationStaffCause.unexpected);
    });
  });

  group('A6.3 applicant contract (server-authoritative)', () {
    test('1. submit moves DRAFT → SUBMITTED and returns the authoritative row',
        () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
      );
      final result = await gateway.submitApplication(apps['app-1']!);
      expect(result, isA<BusinessApplicationSubmitted>());
      final submitted = result as BusinessApplicationSubmitted;
      expect(submitted.application.status,
          BusinessApplicationStatus.submitted);
      expect(submitted.application.id, 'app-1');
      expect(submitted.application.applicantUserId, _userA);
    });

    test('2. submit without authoritative phone fails closed (phoneRequired)',
        () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA, phonePresent: false),
        apps: apps,
      );
      final result = await gateway.submitApplication(apps['app-1']!);
      expect(result, isA<BusinessApplicationSubmitDenied>());
      expect((result as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.phoneRequired);
    });

    test('3. NEW submit without candidate metadata fails closed', () async {
      final apps = {
        'app-1': _app('app-1', metadata: const {'name': 'Candidate'}),
      };
      final missing = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA, metadataPresent: false),
        apps: apps,
      );
      final denied = await missing.submitApplication(apps['app-1']!);
      expect((denied as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.requiredDataMissing);
      final ok = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA, metadataPresent: true),
        apps: apps,
      );
      expect(await ok.submitApplication(apps['app-1']!),
          isA<BusinessApplicationSubmitted>());
    });

    test('4. resubmit is allowed only from NEEDS_CORRECTION', () async {
      final apps = {
        'app-1': _app(
          'app-1',
          status: BusinessApplicationStatus.needsCorrection,
          metadata: const {'name': 'fixed'},
        ),
      };
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
      );
      final result = await gateway.resubmitApplication(apps['app-1']!);
      expect(result, isA<BusinessApplicationSubmitted>());
      expect((result as BusinessApplicationSubmitted).application.status,
          BusinessApplicationStatus.submitted);
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_RESUBMIT'));
    });

    test('5. submit only from DRAFT and resubmit only from NEEDS_CORRECTION',
        () async {
      for (final status in BusinessApplicationStatus.values) {
        if (!status.isKnown) continue;
        final apps = {'a': _app('a', status: status)};
        final gateway = _ScriptedApplicantGateway(
          config: const _ScriptedConfig(actor: _userA),
          apps: apps,
        );
        final submit = await gateway.submitApplication(_app('a', status: status));
        if (status == BusinessApplicationStatus.draft) {
          expect(submit, isA<BusinessApplicationSubmitted>(),
              reason: 'submit is the DRAFT transition');
        } else {
          expect((submit as BusinessApplicationSubmitDenied).cause,
              BusinessApplicationSubmitCause.invalidTransition,
              reason: 'submit from $status must be invalid');
        }
        final resubmit =
            await gateway.resubmitApplication(_app('a', status: status));
        if (status == BusinessApplicationStatus.needsCorrection) {
          expect(resubmit, isA<BusinessApplicationSubmitted>(),
              reason: 'resubmit is the NEEDS_CORRECTION transition');
        } else {
          expect((resubmit as BusinessApplicationSubmitDenied).cause,
              BusinessApplicationSubmitCause.invalidTransition,
              reason: 'resubmit from $status must be invalid');
        }
      }
    });

    test('6. an applicant cannot submit another applicant\'s application',
        () async {
      final apps = {'app-1': _app('app-1', applicant: _userA)};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userB),
        apps: apps,
      );
      final result = await gateway.submitApplication(apps['app-1']!);
      expect((result as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.notApplicant);
    });

    test('7. guest (no session) applicant submit fails closed', () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: null),
        apps: apps,
      );
      final result = await gateway.submitApplication(apps['app-1']!);
      expect((result as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.unauthenticated);
    });

    test('8. CLAIM target that became unclaimable blocks submit', () async {
      final apps = {
        'claim-1': _app(
          'claim-1',
          type: BusinessApplicationType.claim,
          target: _entity1,
        ),
      };
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
        targetClaimStatus: {_entity1: 'pending'},
      );
      final result = await gateway.submitApplication(apps['claim-1']!);
      expect((result as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.targetNotClaimable);
    });

    test('9. missing application fails closed', () async {
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
      );
      final result = await gateway.submitApplication(_app('nope'));
      expect((result as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.applicationNotFound);
    });

    test('10. submit records the audit action for the transition', () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
      );
      await gateway.submitApplication(apps['app-1']!);
      expect(gateway.auditActions, contains('BUSINESS_APPLICATION_SUBMIT'));
    });
  });

  group('A6.3 staff contract (server-authoritative)', () {
    Future<_ScriptedStaffGateway> staff({
      Map<String, BusinessApplication>? apps,
      Set<String> permissions = _reviewerPermissions,
    }) async {
      return _ScriptedStaffGateway(
        config:
            _ScriptedConfig(actor: _userA, allowedPermissions: permissions),
        apps: apps,
      );
    }

    test('11. beginReview moves SUBMITTED → UNDER_REVIEW', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.submitted),
      };
      final gateway = await staff(apps: apps);
      final result = await gateway.beginReview('app-1');
      expect(result, isA<BusinessApplicationStaffSucceeded>());
      expect((result as BusinessApplicationStaffSucceeded).application.status,
          BusinessApplicationStatus.underReview);
    });

    test('12. staff action without the permission is denied (P0PER)', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.submitted),
      };
      final gateway = await staff(apps: apps, permissions: const {});
      final result = await gateway.beginReview('app-1');
      expect((result as BusinessApplicationStaffDenied).cause,
          BusinessApplicationStaffCause.staffPermissionDenied);
    });

    test('13. beginReview only from SUBMITTED', () async {
      for (final status in BusinessApplicationStatus.values) {
        if (!status.isKnown || status == BusinessApplicationStatus.submitted) {
          continue;
        }
        final gateway = await staff(
          apps: {'app-1': _app('app-1', status: status)},
        );
        final result = await gateway.beginReview('app-1');
        expect((result as BusinessApplicationStaffDenied).cause,
            BusinessApplicationStaffCause.invalidTransition,
            reason: 'beginReview from $status must be invalid');
      }
    });

    test('14. returnForCorrection requires a reason', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await staff(apps: apps);
      final result =
          await gateway.returnForCorrection('app-1', reason: '   ');
      expect((result as BusinessApplicationStaffDenied).cause,
          BusinessApplicationStaffCause.correctionReasonRequired);
    });

    test('15. returnForCorrection records the reason and status', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await staff(apps: apps);
      final result =
          await gateway.returnForCorrection('app-1', reason: '  fix name  ');
      final succeeded = result as BusinessApplicationStaffSucceeded;
      expect(succeeded.application.status,
          BusinessApplicationStatus.needsCorrection);
      expect(succeeded.application.returnReason, 'fix name');
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_RETURN_FOR_CORRECTION'));
    });

    test('16. markContacted records the contact and status', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await staff(apps: apps);
      final result = await gateway.markContacted('app-1',
          contactType: 'phone', notes: 'reached');
      expect(result, isA<BusinessApplicationStaffSucceeded>());
      expect((result as BusinessApplicationStaffSucceeded).application.status,
          BusinessApplicationStatus.contacted);
      expect(gateway.contactsCreated, 1);
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_CONTACTED'));
    });

    test('17. scheduleVisit records the visit and status', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await staff(apps: apps);
      final result =
          await gateway.scheduleVisit('app-1', scheduledAt: DateTime.now());
      expect(result, isA<BusinessApplicationStaffSucceeded>());
      expect((result as BusinessApplicationStaffSucceeded).application.status,
          BusinessApplicationStatus.visitScheduled);
      expect(gateway.visitsCreated, 1);
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_VISIT_SCHEDULED'));
    });

    test('18. approve from review/contacted/visit; APPROVED is not ownership',
        () async {
      final appIds = <String>[];
      for (final from in const {
        BusinessApplicationStatus.underReview,
        BusinessApplicationStatus.contacted,
        BusinessApplicationStatus.visitScheduled,
      }) {
        final apps = {'a': _app('a', status: from)};
        final g = await staff(apps: apps);
        final result = await g.approve('a');
        expect(result, isA<BusinessApplicationStaffSucceeded>(),
            reason: 'approve from $from must succeed');
        final approved = (result as BusinessApplicationStaffSucceeded)
            .application;
        expect(approved.status, BusinessApplicationStatus.approved);
        expect(approved.approvedAt, isNotNull,
            reason: 'approved_at recorded on approval');
        expect(approved.reviewedAt, isNotNull,
            reason: 'reviewed_at recorded with reviewer');
        expect(g.membershipWrites, isEmpty,
            reason: 'approval never creates a membership');
        expect(g.claimStatusChangedTargets, isEmpty,
            reason: 'approval never flips claim_status');
        appIds.add(approved.id);
      }
      expect(appIds, ['a', 'a', 'a']);

      final terminal = {
        't': _app('t', status: BusinessApplicationStatus.approved),
      };
      final gTerminal = await staff(apps: terminal);
      final again = await gTerminal.approve('t');
      expect((again as BusinessApplicationStaffDenied).cause,
          BusinessApplicationStaffCause.invalidTransition,
          reason: 'APPROVED is terminal in A6.3');
    });

    test('19. reject requires reason and records it', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await staff(apps: apps);
      final noReason = await gateway.reject('app-1', reason: '');
      expect((noReason as BusinessApplicationStaffDenied).cause,
          BusinessApplicationStaffCause.rejectionReasonRequired);
      final result = await gateway.reject('app-1', reason: '  incomplete  ');
      final succeeded = result as BusinessApplicationStaffSucceeded;
      expect(succeeded.application.status,
          BusinessApplicationStatus.rejected);
      expect(succeeded.application.rejectionReason, 'incomplete');
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_REJECTED'));
    });

    test('20. every sensitive staff transition writes an audit record',
        () async {
      final apps = {
        'c': _app('c', status: BusinessApplicationStatus.submitted),
      };
      final gateway = await staff(apps: apps);
      await gateway.beginReview('c');
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_REVIEW_BEGIN'));
      await gateway.returnForCorrection('c', reason: 'fix');
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_RETURN_FOR_CORRECTION'));
      await gateway.resubmitVia('c');
      await gateway.beginReview('c');
      await gateway.markContacted('c', contactType: 'email');
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_CONTACTED'));
    });
  });

  group('A6.3 state / concurrency contract', () {
    test('21. APPROVED and REJECTED are terminal in A6.3', () async {
      for (final terminal in const {
        BusinessApplicationStatus.approved,
        BusinessApplicationStatus.rejected,
      }) {
        final configured = _ScriptedConfig(
          actor: _userA,
          allowedPermissions: _reviewerPermissions,
        );
        final apps = {'t': _app('t', status: terminal)};
        final g = _ScriptedStaffGateway(config: configured, apps: apps);
        for (final op in <Future<BusinessApplicationStaffResult> Function()>[
          () => g.beginReview('t'),
          () => g.returnForCorrection('t', reason: 'x'),
          () => g.markContacted('t', contactType: 'phone'),
          () => g.scheduleVisit('t', scheduledAt: DateTime.now()),
          () => g.approve('t'),
          () => g.reject('t', reason: 'x'),
        ]) {
          final result = await op();
          expect((result as BusinessApplicationStaffDenied).cause,
              BusinessApplicationStaffCause.invalidTransition,
              reason: '$terminal must reject the operation');
        }
        final aApps = {'t': _app('t', status: terminal)};
        final a = _ScriptedApplicantGateway(
          config: configured,
          apps: aApps,
        );
        final submit = await a.submitApplication(_app('t', status: terminal));
        expect((submit as BusinessApplicationSubmitDenied).cause,
            BusinessApplicationSubmitCause.invalidTransition,
            reason: '$terminal cannot be submitted');
        final resubmit =
            await a.resubmitApplication(_app('t', status: terminal));
        expect((resubmit as BusinessApplicationSubmitDenied).cause,
            BusinessApplicationSubmitCause.invalidTransition,
            reason: '$terminal cannot be resubmitted');
      }
    });

    test('22. double-submit serializes: the second attempt is denied', () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
      );
      final first = await gateway.submitApplication(apps['app-1']!);
      expect(first, isA<BusinessApplicationSubmitted>());
      final second = await gateway.submitApplication(_app('app-1'));
      expect((second as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.invalidTransition,
          reason: 'the second concurrent submission loses on the row lock');
    });

    test('23. concurrent review serializes to a single winner', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.submitted),
      };
      final configured = _ScriptedConfig(
        actor: _userA,
        allowedPermissions: _reviewerPermissions,
      );
      final g1 = _ScriptedStaffGateway(config: configured, apps: apps);
      final g2 = _ScriptedStaffGateway(config: configured, apps: apps);
      final first = await g1.beginReview('app-1');
      expect(first, isA<BusinessApplicationStaffSucceeded>());
      final second = await g2.beginReview('app-1');
      expect((second as BusinessApplicationStaffDenied).cause,
          BusinessApplicationStaffCause.invalidTransition);
      expect(g1.auditActions.length, 1,
          reason: 'exactly one review transition is recorded');
    });

    test('24. beginReview accepts only SUBMITTED (exhaustive matrix)', () async {
      final configured = _ScriptedConfig(
        actor: _userA,
        allowedPermissions: _reviewerPermissions,
      );
      for (final status in BusinessApplicationStatus.values) {
        if (!status.isKnown) continue;
        final apps = {'a': _app('a', status: status)};
        final g = _ScriptedStaffGateway(config: configured, apps: apps);
        final result = await g.beginReview('a');
        final isSubmitted = status == BusinessApplicationStatus.submitted;
        if (isSubmitted) {
          expect(result, isA<BusinessApplicationStaffSucceeded>(),
              reason: 'beginReview from $status');
        } else {
          expect((result as BusinessApplicationStaffDenied).cause,
              BusinessApplicationStaffCause.invalidTransition,
              reason: 'beginReview from $status');
        }
      }
    });

    test('25. A6.3 has no activation RPC; A6.4 owns that boundary', () async {
      final a63Migration = File(
        'supabase/migrations/00016_business_application_server_mutations.sql',
      ).readAsStringSync();
      final domain = File(
        'lib/features/business/domain/business_application_staff_gateway.dart',
      ).readAsStringSync();
      final data = File(
        'lib/features/business/data/supabase_business_application_staff_gateway.dart',
      ).readAsStringSync();
      expect(
        a63Migration.contains('staff_activate_business_application'),
        isFalse,
        reason: 'migration 00016 must remain free of activation behavior',
      );
      expect(
        domain.contains('activate(String applicationId)'),
        isTrue,
        reason: 'A6.4 extends the existing staff gateway explicitly',
      );
      expect(
        data.contains('staff_activate_business_application'),
        isTrue,
        reason: 'activation is routed only through the A6.4 RPC',
      );
      expect(BusinessApplicationStatus.approved.isFinal, isFalse,
          reason: 'APPROVED still awaits the A6.4 atomic provisioning');
    });
  });

  group('A6.3 ownership & identity boundaries', () {
    test('26. submit CLAIM never creates a membership', () async {
      final apps = {
        'claim-1': _app(
          'claim-1',
          type: BusinessApplicationType.claim,
          target: _entity1,
        ),
      };
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
        targetClaimStatus: {_entity1: 'unclaimed'},
      );
      await gateway.submitApplication(apps['claim-1']!);
      expect(gateway.auditActions,
          contains('BUSINESS_APPLICATION_SUBMIT'));
      expect(gateway.membershipWrites, isEmpty);
    });

    test('27. approve never creates a membership', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await _staffConfigured(apps);
      await gateway.approve('app-1');
      expect(gateway.membershipWrites, isEmpty);
    });

    test('28. approve never flips claim_status or verification', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await _staffConfigured(apps);
      await gateway.approve('app-1');
      expect(gateway.claimStatusChangedTargets, isEmpty);
    });

    test('29. reject never creates a membership', () async {
      final apps = {
        'app-1': _app('app-1', status: BusinessApplicationStatus.underReview),
      };
      final gateway = await _staffConfigured(apps);
      await gateway.reject('app-1', reason: 'duplicate claim');
      expect(gateway.membershipWrites, isEmpty);
    });

    test('30. no client table-UPDATE path exists (production gateways)', () {
      final applicant = File(
        'lib/features/business/data/supabase_business_application_gateway.dart',
      ).readAsStringSync();
      final staff = File(
        'lib/features/business/data/supabase_business_application_staff_gateway.dart',
      ).readAsStringSync();
      for (final src in [applicant, staff]) {
        expect(src.contains('.update('), isFalse,
            reason: 'no PostgREST update may exist');
        expect(src.contains('.delete('), isFalse,
            reason: 'no PostgREST delete may exist');
      }
    });

    test('31. staff identity is never a client-supplied parameter', () {
      final domain = File(
        'lib/features/business/domain/business_application_staff_gateway.dart',
      ).readAsStringSync();
      final data = File(
        'lib/features/business/data/supabase_business_application_staff_gateway.dart',
      ).readAsStringSync();
      expect(domain.contains('userId'), isFalse,
          reason: 'staff surface must not accept a user id');
      expect(data.contains("'user_id'"), isFalse,
          reason: 'staff RPC params must not carry a user id');
      expect(data.contains('email'), isFalse,
          reason: 'staff RPC params must not carry an email');
    });

    test('32. authoritative phone present is enforced; verification is not',
        () async {
      final apps = {'app-1': _app('app-1')};
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA, phonePresent: false),
        apps: apps,
      );
      final denied = await gateway.submitApplication(apps['app-1']!);
      expect((denied as BusinessApplicationSubmitDenied).cause,
          BusinessApplicationSubmitCause.phoneRequired);
      final production = File(
        'lib/features/business/domain/business_application_gateway.dart',
      ).readAsStringSync();
      expect(production.contains('phoneRequired'), isTrue);
      expect(production.contains('phoneUnverified'), isFalse,
          reason: 'no phone-verification concept in the applicant contract');
    });
  });

  group('A6.3 regression: A6.2 read/create surface unchanged', () {
    test('33. create NEW draft still works', () async {
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
      );
      final result = await gateway.createNewDraft(
        currentUserId: _userA,
        metadata: const {'name': 'Candidate'},
      );
      expect(result, isA<BusinessApplicationCreated>());
      expect((result as BusinessApplicationCreated).application.type,
          BusinessApplicationType.newApplication);
    });

    test('34. create CLAIM draft still works + claimability enforced',
        () async {
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        targetClaimStatus: {_entity1: 'unclaimed', _entity2: 'claimed'},
      );
      final ok = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity1,
      );
      expect(ok, isA<BusinessApplicationCreated>());
      final claimed = await gateway.createClaimDraft(
        currentUserId: _userA,
        targetEntityId: _entity2,
      );
      expect((claimed as BusinessApplicationCreateDenied).cause,
          BusinessApplicationRejectionCause.targetNotClaimable);
    });

    test('35. list/fetch own applications unchanged', () async {
      final apps = {
        'mine': _app('mine', applicant: _userA),
        'theirs': _app('theirs', applicant: _userB),
      };
      final gateway = _ScriptedApplicantGateway(
        config: const _ScriptedConfig(actor: _userA),
        apps: apps,
      );
      final mine = await gateway.listOwnApplications(_userA);
      expect(mine.map((a) => a.id), ['mine']);
      expect(await gateway.getOwnApplication(_userA, 'theirs'), isNull,
          reason: 'own-read boundary must exclude other applicants');
      expect(await gateway.getOwnApplication(_userA, 'mine'), isNotNull);
    });
  });
}

Future<_ScriptedStaffGateway> _staffConfigured(
  Map<String, BusinessApplication> apps,
) async {
  return _ScriptedStaffGateway(
    config: _ScriptedConfig(
      actor: _userA,
      allowedPermissions: _reviewerPermissions,
    ),
    apps: apps,
  );
}
