import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

/// Minimal helper to build a core organic-profile JSON without any
/// Monetization plan/access fields.
Map<String, dynamic> _organicJson({
  String verification = 'unverified',
  String id = 'sb-1',
}) {
  return {
    'id': id,
    'name': 'Organic Contractor',
    'type': 'contractor',
    'verificationStatus': verification,
  };
}

ServiceBusinessProfile _coreProfile({
  VerificationStatus v = VerificationStatus.unverified,
}) {
  return ServiceBusinessProfile(
    id: 'sb-1',
    name: 'Organic Contractor',
    type: BusinessType.contractor,
    verificationStatus: v,
  );
}

void main() {
  group('VerificationStatus — approved five-state contract', () {
    test('contains exactly the approved five semantic states', () {
      expect(VerificationStatus.values, [
        VerificationStatus.unverified,
        VerificationStatus.pending,
        VerificationStatus.verified,
        VerificationStatus.rejected,
        VerificationStatus.suspended,
      ]);
    });

    test('rejected and suspended are distinct values', () {
      expect(VerificationStatus.rejected, isNot(VerificationStatus.suspended));
      expect(VerificationStatus.rejected.name, 'rejected');
      expect(VerificationStatus.suspended.name, 'suspended');
    });

    test('serialized spellings are stable and distinct', () {
      final names = VerificationStatus.values.map((s) => s.name).toSet();
      expect(names, {
        'unverified',
        'pending',
        'verified',
        'rejected',
        'suspended',
      });
    });
  });

  group('VerificationStatus — serialization / read compatibility', () {
    test('all five states round-trip through the persisted model contract', () {
      for (final status in VerificationStatus.values) {
        final profile = _coreProfile(v: status);
        final roundTripped = ServiceBusinessProfile.fromJson(profile.toJson());
        expect(
          roundTripped.verificationStatus,
          status,
          reason: 'failed to round-trip ${status.name}',
        );
      }
    });

    test('legacy four-state values remain parseable (read-compatible)', () {
      for (final legacy in ['unverified', 'pending', 'verified', 'rejected']) {
        final fromJson = ServiceBusinessProfile.fromJson(
          _organicJson(verification: legacy),
        );
        expect(
          fromJson.verificationStatus.name,
          legacy,
          reason: 'legacy persisted value "$legacy" no longer reads back',
        );
      }
    });

    test('suspended is representable through serialization', () {
      final json = ServiceBusinessProfile.fromJson(
        _organicJson(verification: 'suspended'),
      );
      expect(json.verificationStatus, VerificationStatus.suspended);
      expect(json.toJson()['verificationStatus'], 'suspended');
    });

    test('unknown verification values fall back safely (existing behavior)', () {
      // Persisted data with an unrecognised verification token must not throw.
      final fromJson = ServiceBusinessProfile.fromJson(
        _organicJson(verification: 'bogus'),
      );
      expect(fromJson.verificationStatus, VerificationStatus.unverified);
    });
  });

  group('Directory de-coupling (B-04) — no Monetization dependency', () {
    test('core entity constructs without any plan/access state', () {
      // No planType and no featured/foundingPartner needed for organic identity.
      final profile = _coreProfile();
      expect(profile.id, 'sb-1');
      expect(profile.name, 'Organic Contractor');
      expect(profile.type, BusinessType.contractor);
      expect(profile.planType, isNull);
      expect(profile.featured, isFalse);
      expect(profile.foundingPartner, isFalse);
    });

    test(
      'organic default Directory data stays usable without sponsorship/plan',
      () {
        final json = ServiceBusinessProfile.fromJson(_organicJson());
        expect(json.id, 'sb-1');
        expect(json.verificationStatus, VerificationStatus.unverified);
        // No Monetization fields present in representative organic persisted data.
        expect(json.planType, isNull);
        expect(json.featured, isFalse);
      },
    );

    test('legacy persisted Monetization-adjacent fields remain readable', () {
      // Persisted legacy data may still carry these fields; they must not break
      // reads and must be preserved through round-trip (read-compat only).
      final json = {
        ..._organicJson(),
        'featured': true,
        'foundingPartner': true,
        'planType': 'company',
      };
      final loaded = ServiceBusinessProfile.fromJson(json);
      expect(loaded.featured, isTrue);
      expect(loaded.foundingPartner, isTrue);
      expect(loaded.planType, 'company');
      // Round-trip preserves them byte-for-byte.
      final re = ServiceBusinessProfile.fromJson(loaded.toJson());
      expect(re.featured, isTrue);
      expect(re.foundingPartner, isTrue);
      expect(re.planType, 'company');
    });
  });
}
