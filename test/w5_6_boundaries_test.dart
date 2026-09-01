import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/routes/app_routes.dart';

void main() {
  group('W5.6 navigation / boundaries', () {
    test('50. /directory routes are wired through canonical constants only '
        '(no raw literals, no provider detail route)', () {
      final routesFile = File(
        'lib/routes/app_router.dart',
      ).readAsStringSync();
      // W6.3 made /directory a shell branch. The router must reference the
      // canonical AppRoutes constants — never raw literals — and provider
      // detail stays a MaterialPageRoute (no /directory/provider/:id).
      expect(routesFile.contains("'/directory'"), isFalse);
      expect(routesFile.contains('"/directory"'), isFalse);
      expect(routesFile.contains('/directory/provider'), isFalse);
    });

    test('51. shell destinations = W6.3 target shell (5 routes, /directory)',
        () {
      final routes = kShellDestinations.map((d) => d.route).toList();
      expect(routes, [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.projects,
        AppRoutes.directory,
      ]);
      expect(routes.any((r) => r.endsWith('directory')), isTrue);
      expect(kShellDestinations.length, 5);
    });

    test('52. DirectoryQuery is unchanged (no Saved-related members)', () {
      final source = File(
        'lib/features/directory/domain/directory_query.dart',
      ).readAsStringSync();
      // Canonical API surface is intact (text, category, location).
      expect(source.contains('final String text;'), isTrue);
      expect(source.contains('BusinessType? category'), isTrue);
      expect(source.contains('BaghdadArea? location'), isTrue);
      // No Saved coupling symbols anywhere (code or docs).
      for (final symbol in const [
        'SavedReference',
        'SavedReferenceStore',
        'isSaved',
        'savedAt',
        'bookmark',
      ]) {
        expect(source.contains(symbol), isFalse, reason: '$symbol leaked');
      }
    });

    test('53. DirectoryQueryEngine is unchanged (no Saved coupling)', () {
      final source = File(
        'lib/features/directory/domain/directory_query_engine.dart',
      ).readAsStringSync();
      for (final symbol in const [
        'SavedReference',
        'SavedReferenceStore',
        'isSaved',
        'savedAt',
        'bookmark',
        'favorite',
      ]) {
        expect(source.contains(symbol), isFalse, reason: '$symbol leaked');
      }
      // Matching API unchanged: apply(List, DirectoryQuery) is the entry.
      expect(
        source.contains(
          'static List<ServiceBusinessProfile> apply(',
        ),
        isTrue,
      );
    });

    test('54. ServiceBusinessProfile has no Saved state field', () {
      final profile = ServiceBusinessProfile(
        id: 'p-1',
        name: 'Alpha',
        type: BusinessType.supplier,
      );
      expect(profile.toJson().containsKey('isSaved'), isFalse);
      expect(profile.toJson().containsKey('isFavorite'), isFalse);
      expect(profile.toJson().containsKey('bookmarked'), isFalse);
      expect(profile.toJson().containsKey('saved'), isFalse);
      // Save identity is not part of the core entity.
      expect(profile.toJson().containsKey('savedAt'), isFalse);
    });

    test('55. featured/foundingPartner/planType do not affect Saved identity',
        () {
      SavedItemReference refFor(bool featured, String planType) =>
          SavedItemReference(
            ownerDomain: SavedReferenceOwners.directory,
            entityType: SavedReferenceEntityTypes.provider,
            entityId: 'p-1',
          );
      expect(refFor(false, 'free').id, 'directory:provider:p-1');
      expect(refFor(true, 'premium').id, 'directory:provider:p-1');
      // The same profile.id always yields the same canonical id.
      for (final plan in const ['free', 'premium', 'pro']) {
        expect(refFor(false, plan).id, 'directory:provider:p-1');
      }
    });

    test('56. verification states do not affect Saved identity', () {
      String idFor(VerificationStatus status) {
        final profile = ServiceBusinessProfile(
          id: 'p-1',
          name: 'Alpha',
          type: BusinessType.supplier,
          verificationStatus: status,
        );
        return SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: profile.id,
        ).id;
      }

      final all = VerificationStatus.values.map(idFor).toSet();
      expect(all, {'directory:provider:p-1'});
      for (final status in VerificationStatus.values) {
        expect(idFor(status), 'directory:provider:p-1');
      }
    });
  });
}
