import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/business/data/supabase_business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_contact_type.dart';
import 'package:civilpedia/features/business/domain/business_membership_capabilities.dart';
import 'package:civilpedia/features/business/domain/business_membership_gateway.dart';
import 'package:civilpedia/features/business/domain/business_profile_management_gateway.dart';
import 'package:civilpedia/features/business/domain/business_profile_validator.dart';
import 'package:civilpedia/features/business/domain/business_role.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile.dart';
import 'package:civilpedia/features/business/domain/managed_business_profile_draft.dart';
import 'package:civilpedia/features/business/domain/managed_business_summary.dart';
import 'package:civilpedia/features/business/domain/managed_selectable_options.dart';
import 'package:civilpedia/features/business/presentation/business_profile_management_messages.dart';
import 'package:civilpedia/features/business/presentation/providers/business_profile_editor_provider.dart';
import 'package:civilpedia/features/business/presentation/providers/managed_businesses_provider.dart';
import 'package:civilpedia/features/business/presentation/screens/business_profile_edit_screen.dart';
import 'package:civilpedia/features/business/presentation/screens/managed_businesses_screen.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'fakes/fake_auth_gateway.dart';
import 'fakes/fake_business_membership_gateway.dart';
import 'fakes/fake_business_profile_management_gateway.dart';
import 'helpers/canonical_directory_test_helpers.dart';

const _entityId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _regionId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const _categoryId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

Future<AuthProvider> _authenticatedAuth() async {
  final auth = AuthProvider(
    gateway: FakeAuthGateway(restoredSession: fakeSession),
    onAuthenticated: (_) async {},
  );
  await auth.restoreSession();
  return auth;
}

Future<AuthProvider> _guestAuth() async {
  final auth = AuthProvider(
    gateway: FakeAuthGateway(restoredSession: null),
    onAuthenticated: (_) async {},
  );
  await auth.restoreSession();
  return auth;
}

ManagedBusinessProfile _sampleProfile({
  String id = _entityId,
  VerificationStatus verification = VerificationStatus.verified,
  String lifecycleStatus = 'active',
  DateTime? updatedAt,
}) {
  return ManagedBusinessProfile(
    id: id,
    entityType: 'company',
    name: 'Test Co',
    lifecycleStatus: lifecycleStatus,
    verificationStatus: verification,
    claimStatus: 'claimed',
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime.utc(2024, 1, 2),
    description: 'A sample business',
    contacts: const [
      ManagedBusinessContact(
        id: 'c1',
        type: BusinessContactType.phone,
        value: '+9647700000000',
        isPrimary: true,
      ),
    ],
    primaryLocation: ManagedBusinessLocation(
      id: 'l1',
      regionId: _regionId,
      regionCode: 'baghdad',
      regionNameAr: 'بغداد',
      regionNameEn: 'Baghdad',
      address: 'Al-Jadriya',
      latitude: 33.3152,
      longitude: 44.3661,
    ),
    categories: const [
      ManagedBusinessCategory(
        categoryId: _categoryId,
        code: 'structural',
        nameAr: 'إنشائي',
        isPrimary: true,
      ),
    ],
  );
}

Map<String, dynamic> _sampleProfileJson() {
  return <String, dynamic>{
    'entity': <String, dynamic>{
      'id': _entityId,
      'entity_type': 'company',
      'name': 'Test Co',
      'lifecycle_status': 'active',
      'claim_status': 'claimed',
      'verification_status': 'verified',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-02T00:00:00Z',
      'description': 'A sample business',
    },
    'contacts': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'c1',
        'contact_type': 'phone',
        'value': '+9647700000000',
        'is_primary': true,
      },
    ],
    'primary_location': <String, dynamic>{
      'id': 'l1',
      'region_id': _regionId,
      'region_code': 'baghdad',
      'region_name_ar': 'بغداد',
      'region_name_en': 'Baghdad',
      'address': 'Al-Jadriya',
      'latitude': 33.3152,
      'longitude': 44.3661,
      'is_primary': true,
    },
    'categories': <Map<String, dynamic>>[
      <String, dynamic>{
        'category_id': _categoryId,
        'code': 'structural',
        'name_ar': 'إنشائي',
        'is_primary': true,
      },
    ],
  };
}

http.Response _jsonResponse(Object? body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _FakeInitializedService extends SupabaseService {
  _FakeInitializedService()
      : super(
          config: const BackendConfig(
            appEnvRaw: 'development',
            supabaseUrl: 'http://localhost:54321',
            supabaseAnonKey: 'anon',
          ),
        );

  @override
  bool get isInitialized => true;
}

class _RecordingHttpClient extends http.BaseClient {
  _RecordingHttpClient({this.onRequest});

  final List<http.BaseRequest> requests = [];
  final Future<http.Response> Function(http.BaseRequest)? onRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = await onRequest?.call(request) ?? _jsonResponse({});
    return http.StreamedResponse(
      Stream.fromIterable([utf8.encode(response.body)]),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

class _ToggleFailureCloudDirectoryRepository implements CloudDirectoryRepository {
  _ToggleFailureCloudDirectoryRepository();

  bool failNext = false;

  @override
  bool get isAvailable => true;

  @override
  Future<DirectoryCachedData?> readCache() async => null;

  @override
  Future<DirectoryRefreshResult> refresh() async {
    if (failNext) {
      failNext = false;
      throw Exception('refresh failed');
    }
    return const DirectoryRefreshResult(
      status: DirectoryRefreshStatus.success,
    );
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async => null;

  @override
  Future<DirectoryLoadResult> load() async => const DirectoryLoadResult(
        state: DirectoryLoadState.empty,
      );
}

Widget _wrapEditor(BusinessProfileEditorProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      home: BusinessProfileEditScreen(entityId: _entityId),
    ),
  );
}

Future<void> _pumpEditor(
  WidgetTester tester,
  BusinessProfileEditorProvider provider,
) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  await tester.pumpWidget(_wrapEditor(provider));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  group('V1-R06 domain parsing', () {
    test('parses a valid management projection', () {
      final profile = ManagedBusinessProfile.tryFromJson(_sampleProfileJson());
      expect(profile, isNotNull);
      expect(profile!.id, _entityId);
      expect(profile.isPubliclyVisible, isTrue);
      expect(profile.contacts.length, 1);
      expect(profile.primaryLocation, isNotNull);
      expect(profile.categories.length, 1);
    });

    test('fail-closed on invalid entity UUID', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['id'] = 'not-a-uuid';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on unknown entity_type', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['entity_type'] = 'spaceship';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on invalid lifecycle_status', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['lifecycle_status'] = 'deleted';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on invalid claim_status', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['claim_status'] = 'stolen';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on invalid verification_status', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['verification_status'] =
          'celeb';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on malformed contact row', () {
      final json = _sampleProfileJson();
      json['contacts'] = [
        <String, dynamic>{'id': 'c1', 'contact_type': 'phone'},
      ];
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on malformed location row', () {
      final json = _sampleProfileJson();
      json['primary_location'] = <String, dynamic>{
        'id': 'l1',
        'latitude': 'not-a-number',
      };
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed on malformed category row', () {
      final json = _sampleProfileJson();
      json['categories'] = [
        <String, dynamic>{'category_id': 'not-a-uuid', 'code': 'x'},
      ];
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('non-active lifecycle is not publicly visible', () {
      final json = _sampleProfileJson();
      (json['entity'] as Map<String, dynamic>)['lifecycle_status'] = 'draft';
      final profile = ManagedBusinessProfile.tryFromJson(json);
      expect(profile, isNotNull);
      expect(profile!.isPubliclyVisible, isFalse);
    });

    test('fail-closed when contacts key is missing', () {
      final json = _sampleProfileJson();
      json.remove('contacts');
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when contacts is null', () {
      final json = _sampleProfileJson();
      json['contacts'] = null;
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when contacts is wrong type', () {
      final json = _sampleProfileJson();
      json['contacts'] = 'not-a-list';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when categories key is missing', () {
      final json = _sampleProfileJson();
      json.remove('categories');
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when categories is null', () {
      final json = _sampleProfileJson();
      json['categories'] = null;
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when categories is wrong type', () {
      final json = _sampleProfileJson();
      json['categories'] = 'not-a-list';
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('fail-closed when primary_location key is missing', () {
      final json = _sampleProfileJson();
      json.remove('primary_location');
      expect(ManagedBusinessProfile.tryFromJson(json), isNull);
    });

    test('accepts explicit JSON null for primary_location', () {
      final json = _sampleProfileJson();
      json['primary_location'] = null;
      final profile = ManagedBusinessProfile.tryFromJson(json);
      expect(profile, isNotNull);
      expect(profile!.primaryLocation, isNull);
    });

  });

  group('V1-R06 draft and validator', () {
    test('draft from profile starts equal to profile editable fields', () {
      final profile = _sampleProfile();
      final draft = ManagedBusinessProfileDraft.fromProfile(profile);
      expect(draft.name, profile.name);
      expect(draft.description, profile.description);
      expect(draft.contacts.length, profile.contacts.length);
      expect(draft.primaryLocation?.regionId, profile.primaryLocation?.regionId);
      expect(draft.categories.length, profile.categories.length);
    });

    test('draft equality ignores child ids and display labels', () {
      final profile = _sampleProfile();
      final draft = ManagedBusinessProfileDraft.fromProfile(profile);
      final renamedContact = ManagedBusinessContact(
        id: 'different-id',
        type: BusinessContactType.phone,
        value: '+9647700000000',
        isPrimary: true,
      );
      final sameCategory = ManagedBusinessCategory(
        categoryId: _categoryId,
        code: 'different-code',
        nameAr: 'different',
        isPrimary: true,
      );
      final equalDraft = draft.copyWith(
        contacts: [renamedContact],
        categories: [sameCategory],
      );
      expect(equalDraft, draft);
    });

    test('empty location is treated as clear', () {
      final empty = ManagedBusinessLocation(
        id: 'l1',
        regionId: null,
        address: '   ',
        latitude: null,
        longitude: null,
      );
      expect(empty.isEmpty, isTrue);
    });

    test('validates a clean profile', () {
      final profile = _sampleProfile();
      final draft = ManagedBusinessProfileDraft.fromProfile(profile);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isTrue);
    });

    test('rejects empty name', () {
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(name: '   ');
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues,
        contains(
          const BusinessProfileValidationIssue(
            field: BusinessProfileValidationField.name,
            code: BusinessProfileValidationIssueCode.required,
          ),
        ),
      );
    });

    test('rejects name too long', () {
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(name: 'A' * 161);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.name &&
            i.code == BusinessProfileValidationIssueCode.tooLong),
        isTrue,
      );
    });

    test('rejects too many contacts', () {
      final contacts = List<ManagedBusinessContact>.generate(
        11,
        (i) => ManagedBusinessContact(
          id: '',
          type: BusinessContactType.email,
          value: 'a$i@example.com',
          isPrimary: false,
        ),
      );
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(contacts: contacts);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
    });

    test('rejects duplicate contacts', () {
      final contacts = [
        const ManagedBusinessContact(
          id: '',
          type: BusinessContactType.email,
          value: 'a@example.com',
          isPrimary: false,
        ),
        const ManagedBusinessContact(
          id: '',
          type: BusinessContactType.email,
          value: 'A@EXAMPLE.COM',
          isPrimary: false,
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(contacts: contacts);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.contacts &&
            i.code == BusinessProfileValidationIssueCode.duplicate),
        isTrue,
      );
    });

    test('rejects invalid email format', () {
      final contacts = [
        const ManagedBusinessContact(
          id: '',
          type: BusinessContactType.email,
          value: 'not-an-email',
          isPrimary: false,
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(contacts: contacts);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
    });

    test('rejects duplicate primary per contact type', () {
      final contacts = [
        const ManagedBusinessContact(
          id: '',
          type: BusinessContactType.phone,
          value: '111',
          isPrimary: true,
        ),
        const ManagedBusinessContact(
          id: '',
          type: BusinessContactType.phone,
          value: '222',
          isPrimary: true,
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(contacts: contacts);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.contacts &&
            i.code == BusinessProfileValidationIssueCode.duplicatePrimary),
        isTrue,
      );
    });

    test('rejects too many categories', () {
      final categories = List<ManagedBusinessCategory>.generate(
        11,
        (i) => ManagedBusinessCategory(
          categoryId: '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}',
          code: 'c$i',
          isPrimary: false,
        ),
      );
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(categories: categories);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
    });

    test('rejects duplicate categories', () {
      final categories = [
        ManagedBusinessCategory(
          categoryId: _categoryId,
          code: 'a',
          isPrimary: false,
        ),
        ManagedBusinessCategory(
          categoryId: _categoryId,
          code: 'b',
          isPrimary: false,
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(categories: categories);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.categories &&
            i.code == BusinessProfileValidationIssueCode.duplicate),
        isTrue,
      );
    });

    test('rejects multiple primary categories', () {
      final categories = [
        ManagedBusinessCategory(
          categoryId: _categoryId,
          code: 'a',
          isPrimary: true,
        ),
        ManagedBusinessCategory(
          categoryId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          code: 'b',
          isPrimary: true,
        ),
      ];
      final result = BusinessProfileValidator.validate(
        draft: ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
            .copyWith(categories: categories),
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.categories &&
            i.code == BusinessProfileValidationIssueCode.multiplePrimary),
        isTrue,
      );
    });

    test('rejects unknown selectable category', () {
      final category = ManagedBusinessCategory(
        categoryId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
        code: 'x',
        isPrimary: false,
      );
      final selectable = [
        ManagedSelectableCategory(
          id: _categoryId,
          code: 'known',
          nameAr: 'معروف',
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(categories: [category]);
      final result = BusinessProfileValidator.validate(
        draft: draft,
        selectableCategories: selectable,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.categories &&
            i.code == BusinessProfileValidationIssueCode.invalidFormat),
        isTrue,
      );
    });

    test('rejects incomplete coordinate pair', () {
      final location = ManagedBusinessLocation(
        id: 'l1',
        latitude: 33.0,
        longitude: null,
      );
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(primaryLocation: () => location);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.coordinates &&
            i.code == BusinessProfileValidationIssueCode.incompletePair),
        isTrue,
      );
    });

    test('rejects out-of-range coordinates', () {
      final location = ManagedBusinessLocation(
        id: 'l1',
        latitude: 99.0,
        longitude: 190.0,
      );
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(primaryLocation: () => location);
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.coordinates &&
            i.code == BusinessProfileValidationIssueCode.outOfRange),
        isTrue,
      );
    });

    test('rejects unknown selectable region', () {
      final location = ManagedBusinessLocation(
        id: 'l1',
        regionId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      );
      final selectable = [
        ManagedSelectableRegion(
          id: _regionId,
          code: 'baghdad',
          nameAr: 'بغداد',
        ),
      ];
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(primaryLocation: () => location);
      final result = BusinessProfileValidator.validate(
        draft: draft,
        selectableRegions: selectable,
      );
      expect(result.isValid, isFalse);
      expect(
        result.issues.any((i) =>
            i.field == BusinessProfileValidationField.address &&
            i.code == BusinessProfileValidationIssueCode.invalidFormat),
        isTrue,
      );
    });

    test('rejects website with only scheme', () {
      for (final url in ['https://', 'http://']) {
        final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
            .copyWith(
          contacts: [
            ManagedBusinessContact(
              id: '',
              type: BusinessContactType.website,
              value: url,
              isPrimary: false,
            ),
          ],
        );
        final result = BusinessProfileValidator.validate(draft: draft);
        expect(result.isValid, isFalse, reason: url);
      }
    });

    test('rejects website containing whitespace', () {
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(
        contacts: [
          ManagedBusinessContact(
            id: '',
            type: BusinessContactType.website,
            value: 'https://example .com',
            isPrimary: false,
          ),
        ],
      );
      final result = BusinessProfileValidator.validate(draft: draft);
      expect(result.isValid, isFalse);
    });

    test('accepts valid HTTP(S) website including international domain', () {
      for (final url in [
        'https://example.com',
        'http://example.com/path',
        'https://مثال.تجربة',
      ]) {
        final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
            .copyWith(
          contacts: [
            ManagedBusinessContact(
              id: '',
              type: BusinessContactType.website,
              value: url,
              isPrimary: false,
            ),
          ],
        );
        final result = BusinessProfileValidator.validate(draft: draft);
        expect(result.isValid, isTrue, reason: url);
      }
    });
  });

  group('V1-R06 gateway cause mapping', () {
    test('maps all server SQLSTATE codes to typed causes', () {
      expect(
        BusinessProfileManagementCause.fromServerCode('P0AUT'),
        BusinessProfileManagementCause.unauthenticated,
      );
      expect(
        BusinessProfileManagementCause.fromServerCode('P0PER'),
        BusinessProfileManagementCause.permissionDenied,
      );
      expect(
        BusinessProfileManagementCause.fromServerCode('P0NOT'),
        BusinessProfileManagementCause.notFound,
      );
      expect(
        BusinessProfileManagementCause.fromServerCode('P0DAT'),
        BusinessProfileManagementCause.invalidData,
      );
      expect(
        BusinessProfileManagementCause.fromServerCode('P0CON'),
        BusinessProfileManagementCause.conflict,
      );
      expect(
        BusinessProfileManagementCause.fromServerCode('P0XYZ'),
        BusinessProfileManagementCause.unexpected,
      );
    });
  });

  group('V1-R06 managed businesses provider', () {
    test('guest user sees sign-in-required state', () async {
      final provider = ManagedBusinessesProvider(
        membershipGateway: FakeBusinessMembershipGateway(),
        auth: await _guestAuth(),
      );
      await provider.load();
      expect(provider.state, ManagedBusinessesState.signInRequired);
      expect(provider.items, isEmpty);
    });

    test('unavailable backend surfaces unavailable state', () async {
      final provider = ManagedBusinessesProvider(
        membershipGateway:
            FakeBusinessMembershipGateway(available: false),
        auth: await _authenticatedAuth(),
      );
      await provider.load();
      expect(provider.state, ManagedBusinessesState.unavailable);
    });

    test('data state exposes capability-derived edit permission', () async {
      final summary = ManagedBusinessSummary(
        entityId: _entityId,
        name: 'Test Co',
        entityType: 'company',
        membershipRole: BusinessRole.owner,
        claimStatus: 'claimed',
        verificationStatus: 'verified',
      );
      final gateway = FakeBusinessMembershipGateway(
        listResult: const ManagedBusinessListAvailable([]),
      );
      gateway.listResult = ManagedBusinessListAvailable([summary]);
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: await _authenticatedAuth(),
      );
      await provider.load();
      expect(provider.state, ManagedBusinessesState.data);
      expect(provider.items.length, 1);
      expect(provider.items.first.canManagePublicProfile, isTrue);
    });

    test('MEMBER role cannot manage public profile', () async {
      final summary = ManagedBusinessSummary(
        entityId: _entityId,
        name: 'Test Co',
        entityType: 'company',
        membershipRole: BusinessRole.member,
        claimStatus: 'claimed',
        verificationStatus: 'verified',
      );
      final gateway = FakeBusinessMembershipGateway(
        listResult: ManagedBusinessListAvailable([summary]),
      );
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: await _authenticatedAuth(),
      );
      await provider.load();
      expect(provider.items.first.canManagePublicProfile, isFalse);
      expect(
        provider.items.first.capabilities,
        BusinessMembershipCapabilities.forRole(BusinessRole.member),
      );
    });

    test('server denial propagates typed cause', () async {
      final gateway = FakeBusinessMembershipGateway(
        listResult: const ManagedBusinessListDenied(
          BusinessManagementReadCause.permissionDenied,
        ),
      );
      final provider = ManagedBusinessesProvider(
        membershipGateway: gateway,
        auth: await _authenticatedAuth(),
      );
      await provider.load();
      expect(provider.state, ManagedBusinessesState.error);
      expect(provider.errorCause, BusinessManagementReadCause.permissionDenied);
    });
  });

  group('V1-R06 profile editor provider', () {
    test('guest user sees sign-in-required state', () async {
      final provider = BusinessProfileEditorProvider(
        gateway: FakeBusinessProfileManagementGateway(),
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _guestAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.signInRequired);
    });

    test('unavailable backend surfaces unavailable state', () async {
      final provider = BusinessProfileEditorProvider(
        gateway: FakeBusinessProfileManagementGateway(available: false),
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.unavailable);
    });

    test('successful load installs draft and taxonomy', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        categories: [
          ManagedSelectableCategory(
            id: _categoryId,
            code: 'structural',
            nameAr: 'إنشائي',
          ),
        ],
        regions: [
          ManagedSelectableRegion(
            id: _regionId,
            code: 'baghdad',
            nameAr: 'بغداد',
          ),
        ],
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.draft, isNotNull);
      expect(provider.isDirty, isFalse);
      expect(provider.selectableCategories.length, 1);
      expect(provider.selectableRegions.length, 1);
    });

    test('editing name marks dirty and enables validation', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setName('New Name');
      expect(provider.isDirty, isTrue);
      expect(provider.lastValidation?.isValid, isTrue);
    });

    test('verification warning appears only for verified + sensitive change',
        () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.verificationResetWarningVisible, isFalse);

      provider.setName('Changed Name');
      expect(provider.verificationResetWarningVisible, isTrue);
    });

    test('description-only change does not trigger verification warning',
        () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setDescription('Updated description');
      expect(provider.verificationResetWarningVisible, isFalse);
    });

    test('save sends expected updated_at and payload shape', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final updated = _sampleProfile().copyWith(name: 'Saved Co');
      gateway.updateResult = ManagedProfileUpdateSuccess(updated);

      final directoryRepo = FakeCloudDirectoryRepository([]);
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: directoryRepo,
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setName('Saved Co');
      final ok = await provider.save();
      expect(ok, isTrue);
      expect(gateway.updateCalls, 1);
      expect(gateway.lastUpdateEntityId, _entityId);
      expect(gateway.lastExpectedUpdatedAt, _sampleProfile().updatedAt);
      expect(gateway.lastUpdateDraft?.name, 'Saved Co');
      expect(directoryRepo.refreshCalls, 1);
      expect(provider.state, BusinessProfileEditorState.saveSuccess);
    });

    test('save with invalid payload is blocked client-side and does not call gateway',
        () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setName('');
      final ok = await provider.save();
      expect(ok, isFalse);
      expect(gateway.updateCalls, 0);
    });

    test('P0CON conflict preserves draft and exposes reload action', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        updateResult: const ManagedProfileUpdateDenied(
          BusinessProfileManagementCause.conflict,
        ),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setName('Changed');
      final ok = await provider.save();
      expect(ok, isFalse);
      expect(provider.lastErrorCause, BusinessProfileManagementCause.conflict);
      expect(provider.draft?.name, 'Changed');

      gateway.updateResult = ManagedProfileUpdateSuccess(_sampleProfile());
      await provider.reloadAuthoritative();
      expect(provider.draft?.name, _sampleProfile().name);
      expect(provider.lastErrorCause, isNull);
    });

    test('network failure is typed and retryable', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        available: true,
        readResult: const ManagedProfileReadDenied(
          BusinessProfileManagementCause.network,
        ),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.error);
      expect(provider.lastErrorCause, BusinessProfileManagementCause.network);
    });

    test('taxonomy load failure keeps editable profile available', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      // Throwing taxonomy reads is simulated by making the future throw.
      // The fake returns normally, so override the methods via a subclass.
      final throwingGateway = _ThrowingTaxonomyGateway(
        base: gateway,
      );
      final provider = BusinessProfileEditorProvider(
        gateway: throwingGateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.categoriesCatalogError, isTrue);
      expect(provider.regionsCatalogError, isTrue);
      expect(provider.selectableCategories, isEmpty);
    });

    test('empty category catalog is reported honestly', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        categories: const [],
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.categoriesCatalogError, isFalse);
      expect(provider.selectableCategories, isEmpty);
    });

    test('discard restores original draft and clears dirty', () async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      provider.setName('Changed');
      expect(provider.isDirty, isTrue);
      provider.discardChanges();
      expect(provider.isDirty, isFalse);
      expect(provider.draft?.name, _sampleProfile().name);
    });
  });

  group('V1-R06 localization and messages', () {
    test('message resolver maps every management cause to Arabic text', () {
      for (final cause in BusinessProfileManagementCause.values) {
        final message = BusinessProfileManagementMessages.messageForCause(cause);
        expect(message.isNotEmpty, isTrue);
      }
    });

    test('message resolver maps every validation code to Arabic text', () {
      for (final code in BusinessProfileValidationIssueCode.values) {
        final issue = BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.name,
          code: code,
        );
        final message =
            BusinessProfileManagementMessages.messageForValidationIssue(issue);
        expect(message.isNotEmpty, isTrue);
      }
    });

    test('required Arabic labels exist', () {
      expect(Ar.businessManageMyBusinesses.isNotEmpty, isTrue);
      expect(Ar.businessProfileEditTitle.isNotEmpty, isTrue);
      expect(Ar.businessProfileSave.isNotEmpty, isTrue);
      expect(Ar.businessProfileConflictReload.isNotEmpty, isTrue);
      expect(Ar.businessProfileVerificationWarning.isNotEmpty, isTrue);
    });
  });

  group('V1-R06 route wiring', () {
    test('AppRoutes expose management list and parameterized edit', () {
      expect(AppRoutes.businessManage, '/business/manage');
      expect(
        AppRoutes.businessManageDetailFor(_entityId),
        '/business/manage/$_entityId',
      );
      expect(
        AppRoutes.businessManageDetailPattern,
        '/business/manage/:entityId',
      );
    });

    testWidgets('router resolves /business/manage to ManagedBusinessesScreen',
        (tester) async {
      final guestAuth = AuthProvider(
        gateway: FakeAuthGateway(),
        onAuthenticated: (_) async {},
      );
      final router = GoRouter(
        initialLocation: AppRoutes.businessManage,
        routes: [
          GoRoute(
            path: AppRoutes.businessManage,
            builder: (_, __) => const ManagedBusinessesScreen(),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => ManagedBusinessesProvider(
                membershipGateway: FakeBusinessMembershipGateway(),
                auth: guestAuth,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ManagedBusinessesScreen), findsOneWidget);
    });

    testWidgets('router resolves /business/manage/:id to BusinessProfileEditScreen',
        (tester) async {
      final guestAuth = AuthProvider(
        gateway: FakeAuthGateway(),
        onAuthenticated: (_) async {},
      );
      final router = GoRouter(
        initialLocation: AppRoutes.businessManageDetailFor(_entityId),
        routes: [
          GoRoute(
            path: AppRoutes.businessManage,
            builder: (_, __) => const ManagedBusinessesScreen(),
          ),
          GoRoute(
            path: AppRoutes.businessManageDetailPattern,
            builder: (_, state) => BusinessProfileEditScreen(
              entityId: state.pathParameters['entityId'] ?? '',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => BusinessProfileEditorProvider(
                gateway: FakeBusinessProfileManagementGateway(),
                directoryRepository: FakeCloudDirectoryRepository([]),
                auth: guestAuth,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BusinessProfileEditScreen), findsOneWidget);
    });
  });

  group('V1-R06 production gateway behavioral coverage', () {
    test('readManagedProfile sends the frozen RPC with entity id', () async {
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('get_managed_business_profile')) {
            expect(request.method, 'POST');
            final body = request is http.Request
                ? jsonDecode(request.body) as Map<String, dynamic>
                : <String, dynamic>{};
            expect(body['p_entity_id'], _entityId);
            return _jsonResponse(_sampleProfileJson());
          }
          return _jsonResponse({});
        },
      );
      final supabase = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: httpClient,
      );
      final gateway = SupabaseBusinessProfileManagementGateway(
        service: _FakeInitializedService(),
        client: supabase,
      );

      final result = await gateway.readManagedProfile(_entityId);
      expect(result, isA<ManagedProfileReadSuccess>());
      final profile = (result as ManagedProfileReadSuccess).profile;
      expect(profile.id, _entityId);
      expect(httpClient.requests.any((r) =>
          r.url.path.endsWith('get_managed_business_profile')), isTrue);
    });

    test('readManagedProfile denies unexpected on malformed projection', () async {
      final malformed = _sampleProfileJson()..remove('categories');
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('get_managed_business_profile')) {
            return _jsonResponse(malformed);
          }
          return _jsonResponse({});
        },
      );
      final supabase = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: httpClient,
      );
      final gateway = SupabaseBusinessProfileManagementGateway(
        service: _FakeInitializedService(),
        client: supabase,
      );

      final result = await gateway.readManagedProfile(_entityId);
      expect(result, isA<ManagedProfileReadDenied>());
      expect(
        (result as ManagedProfileReadDenied).cause,
        BusinessProfileManagementCause.unexpected,
      );
    });

    test('updateManagedProfile sends allowed fields only', () async {
      late Map<String, dynamic> capturedBody;
      final httpClient = _RecordingHttpClient(
        onRequest: (request) async {
          if (request.url.path.endsWith('update_managed_business_profile')) {
            expect(request.method, 'POST');
            capturedBody = request is http.Request
                ? jsonDecode(request.body) as Map<String, dynamic>
                : <String, dynamic>{};
            return _jsonResponse(_sampleProfileJson());
          }
          return _jsonResponse({});
        },
      );
      final supabase = SupabaseClient(
        'http://localhost:54321',
        'anon',
        httpClient: httpClient,
      );
      final gateway = SupabaseBusinessProfileManagementGateway(
        service: _FakeInitializedService(),
        client: supabase,
      );
      final draft = ManagedBusinessProfileDraft.fromProfile(_sampleProfile())
          .copyWith(name: 'Updated Co');

      final result = await gateway.updateManagedProfile(
        entityId: _entityId,
        expectedUpdatedAt: DateTime.utc(2024, 1, 2),
        draft: draft,
      );
      expect(result, isA<ManagedProfileUpdateSuccess>());
      expect(capturedBody.keys.toSet(), {
        'p_entity_id',
        'p_expected_updated_at',
        'p_name',
        'p_description',
        'p_contacts',
        'p_primary_location',
        'p_categories',
      });
      expect(capturedBody['p_entity_id'], _entityId);
      expect(
        capturedBody['p_expected_updated_at'],
        '2024-01-02T00:00:00.000Z',
      );
      expect(capturedBody['p_name'], 'Updated Co');
      expect(capturedBody['p_description'], 'A sample business');
      expect(capturedBody['p_contacts'], isList);
      expect(capturedBody['p_primary_location'], isMap);
      expect(capturedBody['p_categories'], isList);
      expect((result as ManagedProfileUpdateSuccess).profile.id, _entityId);
    });

    final realPathErrorCases = <String, BusinessProfileManagementCause>{
      'P0AUT': BusinessProfileManagementCause.unauthenticated,
      'P0PER': BusinessProfileManagementCause.permissionDenied,
      'P0NOT': BusinessProfileManagementCause.notFound,
      'P0DAT': BusinessProfileManagementCause.invalidData,
      'P0CON': BusinessProfileManagementCause.conflict,
    };
    for (final entry in realPathErrorCases.entries) {
      test('real gateway maps server ${entry.key} to ${entry.value.name}',
          () async {
        final useReadRpc = entry.key == 'P0AUT' || entry.key == 'P0NOT';
        final httpClient = _RecordingHttpClient(
          onRequest: (request) async {
            final expectedRpc = useReadRpc
                ? 'get_managed_business_profile'
                : 'update_managed_business_profile';
            if (request.url.path.endsWith(expectedRpc)) {
              return _jsonResponse(
                {
                  'message': 'typed server rejection',
                  'code': entry.key,
                },
                statusCode: 400,
              );
            }
            return _jsonResponse({});
          },
        );
        final supabase = SupabaseClient(
          'http://localhost:54321',
          'anon',
          httpClient: httpClient,
        );
        final gateway = SupabaseBusinessProfileManagementGateway(
          service: _FakeInitializedService(),
          client: supabase,
        );

        if (useReadRpc) {
          final result = await gateway.readManagedProfile(_entityId);
          expect(result, isA<ManagedProfileReadDenied>());
          expect((result as ManagedProfileReadDenied).cause, entry.value);
        } else {
          final result = await gateway.updateManagedProfile(
            entityId: _entityId,
            expectedUpdatedAt: _sampleProfile().updatedAt,
            draft: ManagedBusinessProfileDraft.fromProfile(_sampleProfile()),
          );
          expect(result, isA<ManagedProfileUpdateDenied>());
          expect((result as ManagedProfileUpdateDenied).cause, entry.value);
        }
      });
    }

    test('returns unavailable when service is not initialized', () async {
      final gateway = SupabaseBusinessProfileManagementGateway(
        service: SupabaseService(
          config: const BackendConfig(
            appEnvRaw: 'development',
            supabaseUrl: 'http://localhost:54321',
            supabaseAnonKey: 'anon',
          ),
        ),
      );
      final read = await gateway.readManagedProfile(_entityId);
      expect(read, isA<ManagedProfileReadUnavailable>());
      final update = await gateway.updateManagedProfile(
        entityId: _entityId,
        expectedUpdatedAt: DateTime.utc(2024),
        draft: ManagedBusinessProfileDraft.fromProfile(_sampleProfile()),
      );
      expect(update, isA<ManagedProfileUpdateDenied>());
      expect(
        (update as ManagedProfileUpdateDenied).cause,
        BusinessProfileManagementCause.unavailable,
      );
    });
  });

  group('V1-R06 editor widget tests', () {
    testWidgets('diagnostic: editor loads data and shows fields',
        (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);
      expect(provider.state, BusinessProfileEditorState.data);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('businessProfileNameField')), findsOneWidget);
    });

    testWidgets('typing address preserves spaces and raw text', (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      const address = 'Al Mansour Street, Baghdad';
      final addressFinder = find.byKey(const Key('businessProfileAddressField'));
      await tester.enterText(addressFinder, address);
      await tester.pump();
      final field = tester.widget<TextField>(addressFinder);
      expect(field.controller!.text, address);
    });

    testWidgets('typing negative latitude keeps the minus sign', (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      final latFinder = find.byKey(const Key('businessProfileLatitudeField'));
      await tester.enterText(latFinder, '-');
      await tester.pump();
      final field = tester.widget<TextField>(latFinder);
      expect(field.controller!.text, '-');

      await tester.enterText(latFinder, '-33.5');
      await tester.pump();
      expect(field.controller!.text, '-33.5');
    });

    testWidgets('unsaved PopScope guard supports stay then discard and leave',
        (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  key: const Key('openBusinessProfileEditor'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BusinessProfileEditScreen(
                        entityId: _entityId,
                      ),
                    ),
                  ),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('openBusinessProfileEditor')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('businessProfileNameField')),
        'Unsaved Local Name',
      );
      await tester.pump();
      expect(provider.isDirty, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(Ar.businessProfileUnsavedTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, Ar.businessCancel));
      await tester.pumpAndSettle();
      expect(find.byType(BusinessProfileEditScreen), findsOneWidget);
      expect(provider.draft?.name, 'Unsaved Local Name');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(Ar.businessProfileUnsavedTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileDiscard),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BusinessProfileEditScreen), findsNothing);
      expect(find.byKey(const Key('openBusinessProfileEditor')), findsOneWidget);
    });

    testWidgets('successful save clears dirty state', (tester) async {
      final savedProfile = _sampleProfile(
        updatedAt: DateTime.utc(2024, 1, 3),
      ).copyWith(name: 'Updated Co');
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        updateResult: ManagedProfileUpdateSuccess(savedProfile),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      await tester.enterText(
        find.byKey(const Key('businessProfileNameField')),
        'Updated Co',
      );
      await tester.pump();
      expect(provider.isDirty, isTrue);

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessProfileSave),
      );
      await tester.pumpAndSettle();
      // Confirm save in the dialog.
      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileSave).last,
      );
      await tester.pumpAndSettle();

      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.isDirty, isFalse);
      expect(provider.profile?.name, 'Updated Co');
    });

    testWidgets('conflict keeps draft edits intact', (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        updateResult: const ManagedProfileUpdateDenied(
          BusinessProfileManagementCause.conflict,
        ),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      await tester.enterText(
        find.byKey(const Key('businessProfileNameField')),
        'My New Name',
      );
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessProfileSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileSave).last,
      );
      await tester.pumpAndSettle();

      expect(
        provider.lastErrorCause,
        BusinessProfileManagementCause.conflict,
      );
      expect(provider.draft?.name, 'My New Name');
      expect(find.text(Ar.businessProfileConflictMessage), findsOneWidget);

      final authoritativeVersionB = _sampleProfile(
        updatedAt: DateTime.utc(2024, 1, 4),
      ).copyWith(name: 'Authoritative Version B');
      gateway.readResult = ManagedProfileReadSuccess(authoritativeVersionB);
      final readsBeforeReload = gateway.readCalls;

      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileConflictReload),
      );
      await tester.pumpAndSettle();

      expect(gateway.readCalls, readsBeforeReload + 1);
      expect(provider.profile?.updatedAt, authoritativeVersionB.updatedAt);
      expect(provider.profile?.name, 'Authoritative Version B');
      expect(provider.draft?.name, 'Authoritative Version B');
      expect(provider.lastErrorCause, isNull);
      expect(provider.isDirty, isFalse);
      expect(find.text(Ar.businessProfileConflictMessage), findsNothing);
    });

    testWidgets('refresh warning banner appears and retry clears it',
        (tester) async {
      final savedProfile = _sampleProfile(updatedAt: DateTime.utc(2024, 1, 3));
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(_sampleProfile()),
        updateResult: ManagedProfileUpdateSuccess(savedProfile),
      );
      final directoryRepo = _ToggleFailureCloudDirectoryRepository()
        ..failNext = true;
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: directoryRepo,
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      await tester.enterText(
        find.byKey(const Key('businessProfileNameField')),
        'Updated Co',
      );
      await tester.pump();
      await tester.tap(
        find.widgetWithText(ElevatedButton, Ar.businessProfileSave),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileSave).last,
      );
      await tester.pumpAndSettle();

      expect(provider.state, BusinessProfileEditorState.data);
      expect(provider.directoryRefreshFailed, isTrue);
      expect(find.text(Ar.businessProfileRefreshWarning), findsOneWidget);
      expect(gateway.updateCalls, 1);

      await tester.tap(
        find.widgetWithText(TextButton, Ar.businessProfileRetryRefresh),
      );
      await tester.pumpAndSettle();

      expect(provider.directoryRefreshFailed, isFalse);
      expect(find.text(Ar.businessProfileRefreshWarning), findsNothing);
      expect(gateway.updateCalls, 1);
    });

    testWidgets('primary contact toggle updates provider state', (tester) async {
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(
          _sampleProfile().copyWith(
            contacts: const [
              ManagedBusinessContact(
                id: 'c1',
                type: BusinessContactType.phone,
                value: '+9647700000000',
                isPrimary: true,
              ),
              ManagedBusinessContact(
                id: 'c2',
                type: BusinessContactType.email,
                value: 'a@example.com',
                isPrimary: false,
              ),
            ],
          ),
        ),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      await _pumpEditor(tester, provider);

      final nonPrimaryButton = find.widgetWithText(
        TextButton,
        Ar.businessProfilePrimary,
      );
      expect(nonPrimaryButton, findsOneWidget);
      await tester.tap(nonPrimaryButton);
      await tester.pumpAndSettle();

      expect(provider.draft?.contacts[0].isPrimary, isTrue);
      expect(provider.draft?.contacts[1].isPrimary, isTrue);
    });

    testWidgets('preview is enabled only for active public profiles',
        (tester) async {
      final publicProfile = _sampleProfile(
        verification: VerificationStatus.verified,
        lifecycleStatus: 'active',
      );
      final gateway = FakeBusinessProfileManagementGateway(
        readResult: ManagedProfileReadSuccess(publicProfile),
      );
      final provider = BusinessProfileEditorProvider(
        gateway: gateway,
        directoryRepository: FakeCloudDirectoryRepository([]),
        auth: await _authenticatedAuth(),
      );
      await provider.load(_entityId);
      String? observedPreviewPath;
      String? observedPreviewEntityId;
      final router = GoRouter(
        initialLocation: AppRoutes.businessManageDetailFor(_entityId),
        routes: [
          GoRoute(
            path: AppRoutes.businessManageDetailPattern,
            builder: (_, state) => BusinessProfileEditScreen(
              entityId: state.pathParameters['entityId'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.directoryEntityPattern,
            builder: (_, state) {
              observedPreviewPath = state.uri.path;
              observedPreviewEntityId = state.pathParameters['id'];
              return Scaffold(
                body: Text(
                  observedPreviewEntityId ?? '',
                  key: const Key('canonicalDirectoryEntityDestination'),
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.binding.setSurfaceSize(const Size(400, 3000));
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final previewAction = find.ancestor(
        of: find.byIcon(Icons.open_in_browser_outlined),
        matching: find.byType(IconButton),
      );
      expect(previewAction, findsOneWidget);
      final previewButton = tester.widget<IconButton>(previewAction);
      expect(previewButton.onPressed, isNotNull);
      await tester.tap(previewAction);
      await tester.pumpAndSettle();

      final expectedPath = '/directory/entity/$_entityId';
      expect(observedPreviewPath, expectedPath);
      expect(observedPreviewEntityId, _entityId);
      expect(
        find.byKey(const Key('canonicalDirectoryEntityDestination')),
        findsOneWidget,
      );
      expect(find.text(_entityId), findsOneWidget);

      for (final lifecycleStatus in ['draft', 'inactive', 'suspended']) {
        final nonPublicProfile = _sampleProfile(
          verification: VerificationStatus.verified,
          lifecycleStatus: lifecycleStatus,
        );
        final nonPublicGateway = FakeBusinessProfileManagementGateway(
          readResult: ManagedProfileReadSuccess(nonPublicProfile),
        );
        final nonPublicProvider = BusinessProfileEditorProvider(
          gateway: nonPublicGateway,
          directoryRepository: FakeCloudDirectoryRepository([]),
          auth: await _authenticatedAuth(),
        );
        await nonPublicProvider.load(_entityId);
        await _pumpEditor(tester, nonPublicProvider);

        expect(
          find.byIcon(Icons.open_in_browser_outlined),
          findsNothing,
          reason: '$lifecycleStatus must not expose public preview',
        );
      }
    });
  });
}

/// Fake gateway whose taxonomy reads throw, used to verify the editor keeps
/// the editable profile available even when selectors fail.
class _ThrowingTaxonomyGateway
    implements BusinessProfileManagementGateway {
  _ThrowingTaxonomyGateway({required this.base});

  final FakeBusinessProfileManagementGateway base;

  @override
  bool get isAvailable => base.isAvailable;

  @override
  Future<ManagedProfileReadResult> readManagedProfile(String entityId) {
    return base.readManagedProfile(entityId);
  }

  @override
  Future<ManagedProfileUpdateResult> updateManagedProfile({
    required String entityId,
    required DateTime expectedUpdatedAt,
    required ManagedBusinessProfileDraft draft,
  }) {
    return base.updateManagedProfile(
      entityId: entityId,
      expectedUpdatedAt: expectedUpdatedAt,
      draft: draft,
    );
  }

  @override
  Future<List<ManagedSelectableCategory>> loadActiveCategories() async {
    throw Exception('network failure');
  }

  @override
  Future<List<ManagedSelectableRegion>> loadActiveRegions() async {
    throw Exception('network failure');
  }
}

extension on ManagedBusinessProfile {
  ManagedBusinessProfile copyWith({
    String? name,
    DateTime? updatedAt,
    String? lifecycleStatus,
    VerificationStatus? verificationStatus,
    List<ManagedBusinessContact>? contacts,
    ManagedBusinessLocation? primaryLocation,
    List<ManagedBusinessCategory>? categories,
  }) {
    return ManagedBusinessProfile(
      id: id,
      entityType: entityType,
      name: name ?? this.name,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      claimStatus: claimStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description,
      contacts: contacts ?? this.contacts,
      primaryLocation: primaryLocation ?? this.primaryLocation,
      categories: categories ?? this.categories,
    );
  }
}
