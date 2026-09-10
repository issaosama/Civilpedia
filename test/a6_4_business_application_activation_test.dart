import 'dart:async';
import 'dart:io';

import 'package:civilpedia/features/business/domain/business_application.dart';
import 'package:civilpedia/features/business/domain/business_application_metadata.dart';
import 'package:civilpedia/features/business/domain/business_application_staff_gateway.dart';
import 'package:civilpedia/features/business/domain/business_application_status.dart';
import 'package:civilpedia/features/business/domain/business_application_type.dart';
import 'package:flutter_test/flutter_test.dart';

const _applicantA = '10000000-0000-0000-0000-000000000001';
const _applicantB = '10000000-0000-0000-0000-000000000002';
const _target = '20000000-0000-0000-0000-000000000001';

const _entityTypes = <String>{
  'company',
  'engineering_office',
  'contractor',
  'supplier',
  'store',
  'technician',
  'laboratory',
  'equipment_provider',
  'service_provider',
};

BusinessApplication _application({
  required String id,
  required BusinessApplicationType type,
  BusinessApplicationStatus status = BusinessApplicationStatus.approved,
  String applicant = _applicantA,
  String? target,
  Map<String, dynamic>? metadata,
  DateTime? activatedAt,
}) {
  return BusinessApplication(
    id: id,
    applicantUserId: applicant,
    type: type,
    targetEntityId: target,
    metadata: metadata,
    status: status,
    approvedAt: DateTime.utc(2026, 9, 10),
    activatedAt: activatedAt,
  );
}

BusinessApplication _copyApplication(
  BusinessApplication app, {
  String? target,
  BusinessApplicationStatus? status,
  DateTime? activatedAt,
}) {
  return BusinessApplication(
    id: app.id,
    applicantUserId: app.applicantUserId,
    type: app.type,
    targetEntityId: target ?? app.targetEntityId,
    metadata: app.metadata,
    status: status ?? app.status,
    reviewedByUserId: app.reviewedByUserId,
    reviewedAt: app.reviewedAt,
    returnReason: app.returnReason,
    rejectionReason: app.rejectionReason,
    approvedAt: app.approvedAt,
    activatedAt: activatedAt ?? app.activatedAt,
    createdAt: app.createdAt,
    updatedAt: app.updatedAt,
  );
}

class _Entity {
  _Entity({
    required this.id,
    required this.entityType,
    required this.name,
    this.claimStatus = 'unclaimed',
    this.verificationStatus = 'unverified',
  });

  final String id;
  final String entityType;
  final String name;
  String claimStatus;
  final String verificationStatus;

  _Entity copy() => _Entity(
    id: id,
    entityType: entityType,
    name: name,
    claimStatus: claimStatus,
    verificationStatus: verificationStatus,
  );
}

class _Denied implements Exception {
  const _Denied(this.cause);

  final BusinessApplicationStaffCause cause;
}

/// Transactional server emulator for behavioral contract tests. Source tests
/// below separately pin the real SQL authorization, lock, and grant details.
class _ActivationHarness {
  _ActivationHarness({
    this.actor = 'staff-user',
    this.hasActivatePermission = true,
    Map<String, BusinessApplication>? applications,
    Map<String, _Entity>? entities,
  }) : applications = applications ?? <String, BusinessApplication>{},
       entities = entities ?? <String, _Entity>{};

  final String? actor;
  final bool hasActivatePermission;
  final Map<String, BusinessApplication> applications;
  final Map<String, _Entity> entities;
  final Map<String, String> memberships = <String, String>{};
  final List<String> audits = <String>[];
  int subscriptionWrites = 0;
  bool failAudit = false;
  int _nextEntity = 0;
  Future<void> _tail = Future<void>.value();

  String _membershipKey(String user, String entity) => '$user|$entity';

  Future<BusinessApplicationStaffResult> activate(String applicationId) {
    final completer = Completer<void>();
    final previous = _tail;
    _tail = completer.future;
    return previous.then((_) {
      try {
        return _activateTransaction(applicationId);
      } finally {
        completer.complete();
      }
    });
  }

  BusinessApplicationStaffResult _activateTransaction(String applicationId) {
    final appsBefore = applications.map(
      (key, value) => MapEntry(key, _copyApplication(value)),
    );
    final entitiesBefore = entities.map(
      (key, value) => MapEntry(key, value.copy()),
    );
    final membershipsBefore = Map<String, String>.from(memberships);
    final auditsBefore = List<String>.from(audits);
    final entityCounterBefore = _nextEntity;

    try {
      if (actor == null) {
        throw const _Denied(BusinessApplicationStaffCause.unauthenticated);
      }
      if (!hasActivatePermission) {
        throw const _Denied(
          BusinessApplicationStaffCause.staffPermissionDenied,
        );
      }
      final app = applications[applicationId];
      if (app == null) {
        throw const _Denied(BusinessApplicationStaffCause.applicationNotFound);
      }

      if (app.status == BusinessApplicationStatus.activated) {
        final entityId = app.targetEntityId;
        final entity = entityId == null ? null : entities[entityId];
        final ownerRole = app.applicantUserId == null || entityId == null
            ? null
            : memberships[_membershipKey(app.applicantUserId!, entityId)];
        if (entityId == null ||
            app.activatedAt == null ||
            entity == null ||
            entity.claimStatus != 'claimed' ||
            ownerRole != 'OWNER') {
          throw const _Denied(
            BusinessApplicationStaffCause.ownershipProvisioningConflict,
          );
        }
        return BusinessApplicationStaffSucceeded(app);
      }

      if (app.status != BusinessApplicationStatus.approved) {
        throw const _Denied(BusinessApplicationStaffCause.invalidTransition);
      }
      final applicant = app.applicantUserId;
      if (applicant == null) {
        throw const _Denied(
          BusinessApplicationStaffCause.ownershipProvisioningConflict,
        );
      }

      late final String entityId;
      if (app.type == BusinessApplicationType.newApplication) {
        final metadata = app.metadata;
        final name = metadata?[BusinessApplicationMetadata.name];
        final entityType = metadata?[BusinessApplicationMetadata.entityType];
        if (name is! String ||
            name.trim().isEmpty ||
            entityType is! String ||
            !_entityTypes.contains(entityType)) {
          throw const _Denied(
            BusinessApplicationStaffCause.requiredDataMissing,
          );
        }
        entityId = 'new-entity-${++_nextEntity}';
        entities[entityId] = _Entity(
          id: entityId,
          entityType: entityType,
          name: name.trim(),
        );
      } else if (app.type == BusinessApplicationType.claim) {
        entityId = app.targetEntityId ?? '';
        if (entityId.isEmpty) {
          throw const _Denied(
            BusinessApplicationStaffCause.requiredDataMissing,
          );
        }
        final entity = entities[entityId];
        if (entity == null) {
          throw const _Denied(
            BusinessApplicationStaffCause.applicationNotFound,
          );
        }
        if (entity.claimStatus != 'unclaimed') {
          throw const _Denied(BusinessApplicationStaffCause.targetNotClaimable);
        }
        if (memberships.containsKey(_membershipKey(applicant, entityId)) ||
            memberships.entries.any(
              (entry) =>
                  entry.key.endsWith('|$entityId') && entry.value == 'OWNER',
            )) {
          throw const _Denied(
            BusinessApplicationStaffCause.ownershipProvisioningConflict,
          );
        }
      } else {
        throw const _Denied(BusinessApplicationStaffCause.requiredDataMissing);
      }

      memberships[_membershipKey(applicant, entityId)] = 'OWNER';
      entities[entityId]!.claimStatus = 'claimed';
      final activated = _copyApplication(
        app,
        target: entityId,
        status: BusinessApplicationStatus.activated,
        activatedAt: DateTime.utc(2026, 9, 10, 12),
      );
      applications[applicationId] = activated;
      audits.add('BUSINESS_APPLICATION_ACTIVATED:$applicationId');
      if (failAudit) throw StateError('controlled audit failure');
      return BusinessApplicationStaffSucceeded(activated);
    } on _Denied catch (error) {
      applications
        ..clear()
        ..addAll(appsBefore);
      entities
        ..clear()
        ..addAll(entitiesBefore);
      memberships
        ..clear()
        ..addAll(membershipsBefore);
      audits
        ..clear()
        ..addAll(auditsBefore);
      _nextEntity = entityCounterBefore;
      return BusinessApplicationStaffDenied(error.cause);
    } catch (_) {
      applications
        ..clear()
        ..addAll(appsBefore);
      entities
        ..clear()
        ..addAll(entitiesBefore);
      memberships
        ..clear()
        ..addAll(membershipsBefore);
      audits
        ..clear()
        ..addAll(auditsBefore);
      _nextEntity = entityCounterBefore;
      return const BusinessApplicationStaffDenied(
        BusinessApplicationStaffCause.unexpected,
      );
    }
  }
}

BusinessApplicationStaffCause _deniedCause(
  BusinessApplicationStaffResult result,
) => (result as BusinessApplicationStaffDenied).cause;

BusinessApplication _succeededApplication(
  BusinessApplicationStaffResult result,
) => (result as BusinessApplicationStaffSucceeded).application;

void main() {
  group('A6.4 SQL and security contract', () {
    late String migration;
    late String directorySchema;
    late String gateway;
    late String staffDomain;

    setUpAll(() {
      migration = File(
        'supabase/migrations/'
        '00018_business_application_activation_ownership_provisioning.sql',
      ).readAsStringSync();
      directorySchema = File(
        'supabase/migrations/00005_directory_entities_and_categories.sql',
      ).readAsStringSync();
      gateway = File(
        'lib/features/business/data/'
        'supabase_business_application_staff_gateway.dart',
      ).readAsStringSync();
      staffDomain = File(
        'lib/features/business/domain/business_application_staff_gateway.dart',
      ).readAsStringSync();
    });

    test('permission is additive, independent, and assigned to reviewer', () {
      expect(migration, contains("'business_applications.activate'"));
      expect(migration, contains("r.code = 'application_reviewer'"));
      expect(
        migration,
        contains(
          "has_staff_application_permission(\n       'business_applications.activate')",
        ),
      );
      expect(
        migration,
        isNot(contains("p_permission = 'business_applications.approve'")),
      );
    });

    test('RPC accepts only application id and derives actor from auth.uid', () {
      expect(
        migration,
        contains(
          'staff_activate_business_application(\n  p_application_id uuid',
        ),
      );
      expect(migration, contains('v_actor uuid := auth.uid()'));
      expect(migration, isNot(contains('p_user_id')));
      expect(migration, isNot(contains('p_owner')));
      expect(migration, isNot(contains('p_entity_id')));
      expect(gateway, contains("'staff_activate_business_application'"));
      expect(gateway, contains("'p_application_id': applicationId"));
    });

    test('NEW creation enforces canonical metadata server-side', () {
      expect(BusinessApplicationMetadata.name, 'name');
      expect(BusinessApplicationMetadata.entityType, 'entity_type');
      expect(migration, contains("p_metadata -> 'name'"));
      expect(migration, contains("p_metadata -> 'entity_type'"));
      expect(migration, contains("ERRCODE = 'P0DAT'"));
      expect(migration, isNot(contains("p_metadata -> 'type'")));
    });

    test('entity-type validator exactly mirrors migration 00005', () {
      for (final entityType in _entityTypes) {
        expect(migration, contains("'$entityType'"));
        expect(directorySchema, contains("'$entityType'"));
      }
      expect(migration, isNot(contains("'equipment_owner'")));
      expect(migration, isNot(contains("'construction_company'")));
      expect(migration, isNot(contains("'testing_lab'")));
    });

    test('application then entity lock order and replay are explicit', () {
      final appLock = migration.indexOf(
        'FROM public.business_applications ba\n   WHERE ba.id = p_application_id\n   FOR UPDATE',
      );
      final entityLock = migration.indexOf(
        'FROM public.directory_entities de\n     WHERE de.id = v_entity_id\n     FOR UPDATE',
      );
      expect(appLock, greaterThan(-1));
      expect(entityLock, greaterThan(appLock));
      expect(migration, contains("IF v_row.status = 'ACTIVATED' THEN"));
      expect(migration, contains("ERRCODE = 'P0OWN'"));
    });

    test('audit, atomic writes, and privilege posture are narrow', () {
      expect(migration, contains("'BUSINESS_APPLICATION_ACTIVATED'"));
      expect(migration, contains("'business_application'"));
      expect(migration, contains('INSERT INTO public.business_memberships'));
      expect(migration, contains("SET claim_status = 'claimed'"));
      expect(migration, contains("status = 'ACTIVATED'"));
      expect(migration, isNot(contains('INSERT INTO public.subscriptions')));
      expect(migration, isNot(contains("verification_status = 'verified'")));
      expect(
        migration,
        contains(
          'GRANT EXECUTE ON FUNCTION public.staff_activate_business_application(uuid)',
        ),
      );
      expect(
        migration,
        isNot(contains('GRANT UPDATE ON public.business_applications')),
      );
      expect(
        migration,
        isNot(contains('GRANT INSERT ON public.business_applications')),
      );
    });

    test('Flutter maps activation-specific typed failures', () {
      expect(
        BusinessApplicationStaffCause.fromServerCode('P0OWN'),
        BusinessApplicationStaffCause.ownershipProvisioningConflict,
      );
      expect(
        BusinessApplicationStaffCause.fromServerCode('P0CLM'),
        BusinessApplicationStaffCause.targetNotClaimable,
      );
      expect(staffDomain, contains('activate(String applicationId)'));
      expect(staffDomain, contains('ownershipProvisioningConflict'));
    });
  });

  group('A6.4 authorization and transition', () {
    test('unauthenticated and unauthorized callers fail closed', () async {
      final app = _application(
        id: 'new',
        type: BusinessApplicationType.newApplication,
        metadata: const {'name': 'Acme', 'entity_type': 'company'},
      );
      final noAuth = _ActivationHarness(
        actor: null,
        applications: {'new': app},
      );
      final noPermission = _ActivationHarness(
        hasActivatePermission: false,
        applications: {'new': app},
      );
      expect(
        _deniedCause(await noAuth.activate('new')),
        BusinessApplicationStaffCause.unauthenticated,
      );
      expect(
        _deniedCause(await noPermission.activate('new')),
        BusinessApplicationStaffCause.staffPermissionDenied,
      );
      expect(noAuth.entities, isEmpty);
      expect(noPermission.entities, isEmpty);
    });

    test('every non-APPROVED/non-ACTIVATED source returns P0TRA', () async {
      for (final status in BusinessApplicationStatus.values.where(
        (value) =>
            value != BusinessApplicationStatus.approved &&
            value != BusinessApplicationStatus.activated,
      )) {
        final harness = _ActivationHarness(
          applications: {
            'app': _application(
              id: 'app',
              type: BusinessApplicationType.claim,
              status: status,
              target: _target,
            ),
          },
        );
        expect(
          _deniedCause(await harness.activate('app')),
          BusinessApplicationStaffCause.invalidTransition,
          reason: status.name,
        );
      }
    });
  });

  group('A6.4 NEW provisioning', () {
    test(
      'valid stored snapshot creates minimum claimed owned entity',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'new': _application(
              id: 'new',
              type: BusinessApplicationType.newApplication,
              metadata: const {
                'name': '  Canonical Company  ',
                'entity_type': 'company',
                'ignored_contact': 'not provisioned',
              },
            ),
          },
        );

        final result = await harness.activate('new');
        final activated = _succeededApplication(result);
        final entity = harness.entities[activated.targetEntityId]!;
        expect(activated.status, BusinessApplicationStatus.activated);
        expect(activated.targetEntityId, isNotNull);
        expect(activated.activatedAt, isNotNull);
        expect(entity.name, 'Canonical Company');
        expect(entity.entityType, 'company');
        expect(entity.claimStatus, 'claimed');
        expect(entity.verificationStatus, 'unverified');
        expect(harness.memberships['$_applicantA|${entity.id}'], 'OWNER');
        expect(harness.entities, hasLength(1));
        expect(harness.memberships, hasLength(1));
        expect(harness.audits, ['BUSINESS_APPLICATION_ACTIVATED:new']);
        expect(harness.subscriptionWrites, 0);
      },
    );

    test(
      'missing, blank, non-string, and unknown metadata fail P0DAT',
      () async {
        final invalid = <Map<String, dynamic>?>[
          null,
          const {'entity_type': 'company'},
          const {'name': '   ', 'entity_type': 'company'},
          const {'name': 'Acme'},
          const {'name': 'Acme', 'entity_type': 7},
          const {'name': 'Acme', 'entity_type': 'construction_company'},
        ];
        for (var index = 0; index < invalid.length; index++) {
          final harness = _ActivationHarness(
            applications: {
              'new': _application(
                id: 'new',
                type: BusinessApplicationType.newApplication,
                metadata: invalid[index],
              ),
            },
          );
          expect(
            _deniedCause(await harness.activate('new')),
            BusinessApplicationStaffCause.requiredDataMissing,
            reason: 'invalid metadata case $index',
          );
          expect(harness.entities, isEmpty);
          expect(harness.memberships, isEmpty);
          expect(harness.audits, isEmpty);
        }
      },
    );
  });

  group('A6.4 CLAIM provisioning', () {
    test('stored unclaimed target is claimed and owned atomically', () async {
      final harness = _ActivationHarness(
        applications: {
          'claim': _application(
            id: 'claim',
            type: BusinessApplicationType.claim,
            target: _target,
          ),
        },
        entities: {
          _target: _Entity(id: _target, entityType: 'supplier', name: 'Target'),
        },
      );
      final activated = _succeededApplication(await harness.activate('claim'));
      expect(activated.targetEntityId, _target);
      expect(activated.status, BusinessApplicationStatus.activated);
      expect(harness.entities[_target]!.claimStatus, 'claimed');
      expect(harness.memberships['$_applicantA|$_target'], 'OWNER');
      expect(harness.audits, ['BUSINESS_APPLICATION_ACTIVATED:claim']);
    });

    test('any applicant role or another OWNER is P0OWN', () async {
      for (final role in const ['MEMBER', 'ADMIN', 'OWNER']) {
        final harness = _ActivationHarness(
          applications: {
            'claim': _application(
              id: 'claim',
              type: BusinessApplicationType.claim,
              target: _target,
            ),
          },
          entities: {
            _target: _Entity(id: _target, entityType: 'store', name: 'Target'),
          },
        )..memberships['$_applicantA|$_target'] = role;
        expect(
          _deniedCause(await harness.activate('claim')),
          BusinessApplicationStaffCause.ownershipProvisioningConflict,
          reason: role,
        );
        expect(harness.entities[_target]!.claimStatus, 'unclaimed');
      }

      final otherOwner = _ActivationHarness(
        applications: {
          'claim': _application(
            id: 'claim',
            type: BusinessApplicationType.claim,
            target: _target,
          ),
        },
        entities: {
          _target: _Entity(id: _target, entityType: 'store', name: 'Target'),
        },
      )..memberships['$_applicantB|$_target'] = 'OWNER';
      expect(
        _deniedCause(await otherOwner.activate('claim')),
        BusinessApplicationStaffCause.ownershipProvisioningConflict,
      );
    });

    test(
      'claimed target returns P0CLM and leaves application approved',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'claim': _application(
              id: 'claim',
              type: BusinessApplicationType.claim,
              target: _target,
            ),
          },
          entities: {
            _target: _Entity(
              id: _target,
              entityType: 'store',
              name: 'Target',
              claimStatus: 'claimed',
            ),
          },
        );
        expect(
          _deniedCause(await harness.activate('claim')),
          BusinessApplicationStaffCause.targetNotClaimable,
        );
        expect(
          harness.applications['claim']!.status,
          BusinessApplicationStatus.approved,
        );
        expect(harness.memberships, isEmpty);
        expect(harness.audits, isEmpty);
      },
    );
  });

  group('A6.4 replay, concurrency, and rollback', () {
    test(
      'valid replay returns same entity/timestamp with zero new effects',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'new': _application(
              id: 'new',
              type: BusinessApplicationType.newApplication,
              metadata: const {'name': 'Acme', 'entity_type': 'company'},
            ),
          },
        );
        final first = _succeededApplication(await harness.activate('new'));
        final firstTimestamp = first.activatedAt;
        final second = _succeededApplication(await harness.activate('new'));
        expect(second.targetEntityId, first.targetEntityId);
        expect(second.activatedAt, firstTimestamp);
        expect(harness.entities, hasLength(1));
        expect(harness.memberships, hasLength(1));
        expect(harness.audits, hasLength(1));
      },
    );

    test(
      'broken replay entity, claim, or OWNER invariant returns P0OWN',
      () async {
        Future<void> expectBroken(
          void Function(_ActivationHarness) corrupt,
        ) async {
          final harness = _ActivationHarness(
            applications: {
              'new': _application(
                id: 'new',
                type: BusinessApplicationType.newApplication,
                metadata: const {'name': 'Acme', 'entity_type': 'company'},
              ),
            },
          );
          final first = _succeededApplication(await harness.activate('new'));
          corrupt(harness);
          expect(
            _deniedCause(await harness.activate('new')),
            BusinessApplicationStaffCause.ownershipProvisioningConflict,
          );
          expect(harness.audits, hasLength(1));
          expect(first.targetEntityId, isNotNull);
        }

        await expectBroken((h) => h.entities.clear());
        await expectBroken(
          (h) => h.entities.values.single.claimStatus = 'unclaimed',
        );
        await expectBroken((h) => h.memberships.clear());
      },
    );

    test(
      'concurrent same NEW activation creates one entity/owner/audit',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'new': _application(
              id: 'new',
              type: BusinessApplicationType.newApplication,
              metadata: const {'name': 'Acme', 'entity_type': 'company'},
            ),
          },
        );
        final results = await Future.wait([
          harness.activate('new'),
          harness.activate('new'),
        ]);
        final entityIds = results
            .map(_succeededApplication)
            .map((app) => app.targetEntityId);
        expect(entityIds.toSet(), hasLength(1));
        expect(harness.entities, hasLength(1));
        expect(harness.memberships, hasLength(1));
        expect(harness.audits, hasLength(1));
      },
    );

    test(
      'competing CLAIMs produce one winner and APPROVED P0CLM loser',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'a': _application(
              id: 'a',
              type: BusinessApplicationType.claim,
              target: _target,
            ),
            'b': _application(
              id: 'b',
              applicant: _applicantB,
              type: BusinessApplicationType.claim,
              target: _target,
            ),
          },
          entities: {
            _target: _Entity(
              id: _target,
              entityType: 'supplier',
              name: 'Target',
            ),
          },
        );
        final results = await Future.wait([
          harness.activate('a'),
          harness.activate('b'),
        ]);
        expect(
          results.whereType<BusinessApplicationStaffSucceeded>(),
          hasLength(1),
        );
        final loser = results
            .whereType<BusinessApplicationStaffDenied>()
            .single;
        expect(loser.cause, BusinessApplicationStaffCause.targetNotClaimable);
        expect(
          harness.applications['b']!.status,
          BusinessApplicationStatus.approved,
        );
        expect(harness.memberships, hasLength(1));
        expect(harness.audits, hasLength(1));
      },
    );

    test(
      'controlled audit failure rolls back every provisioning write',
      () async {
        final harness = _ActivationHarness(
          applications: {
            'new': _application(
              id: 'new',
              type: BusinessApplicationType.newApplication,
              metadata: const {'name': 'Acme', 'entity_type': 'company'},
            ),
          },
        )..failAudit = true;
        expect(
          _deniedCause(await harness.activate('new')),
          BusinessApplicationStaffCause.unexpected,
        );
        expect(harness.entities, isEmpty);
        expect(harness.memberships, isEmpty);
        expect(harness.audits, isEmpty);
        expect(
          harness.applications['new']!.status,
          BusinessApplicationStatus.approved,
        );
        expect(harness.applications['new']!.targetEntityId, isNull);
        expect(harness.applications['new']!.activatedAt, isNull);
      },
    );
  });
}
