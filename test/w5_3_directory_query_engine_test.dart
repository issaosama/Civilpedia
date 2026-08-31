import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/location/baghdad_area.dart';
import 'package:civilpedia/features/directory/domain/directory_query.dart';
import 'package:civilpedia/features/directory/domain/directory_query_engine.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

ServiceBusinessProfile _p({
  required String id,
  String name = '',
  BusinessType type = BusinessType.other,
  List<String> categories = const [],
  List<String> subCategories = const [],
  BaghdadArea baghdadArea = BaghdadArea.unknown,
  String address = '',
  List<String> phones = const [],
  String whatsapp = '',
  String description = '',
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  bool featured = false,
  bool foundingPartner = false,
  String? planType,
}) {
  return ServiceBusinessProfile(
    id: id,
    name: name,
    type: type,
    categories: categories,
    subCategories: subCategories,
    baghdadArea: baghdadArea,
    address: address,
    phones: phones,
    whatsapp: whatsapp,
    description: description,
    verificationStatus: verificationStatus,
    featured: featured,
    foundingPartner: foundingPartner,
    planType: planType,
  );
}

void main() {
  group('W5.3 QUERY ENGINE — baseline & ordering', () {
    test('1. empty query + no filters returns all', () {
      final profiles = [_p(id: 'a'), _p(id: 'b'), _p(id: 'c')];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(),
      );
      expect(result.map((p) => p.id), ['a', 'b', 'c']);
    });

    test('2. source order preserved', () {
      final profiles = [
        _p(id: 'x', name: 'X Profile'),
        _p(id: 'y', name: 'Y Profile'),
        _p(id: 'z', name: 'Z Profile'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'y'),
      );
      expect(result.map((p) => p.id), ['y']);
    });
  });

  group('W5.3 QUERY ENGINE — text matching', () {
    test('3. query trims whitespace', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha Contracting'),
        _p(id: 'b', name: 'Beta Supply'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: '  alpha  '),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('4. query is case-insensitive for Latin', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha Contracting'),
        _p(id: 'b', name: 'Beta Supply'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'ALPHA'),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('5. name substring matches', () {
      final profiles = [
        _p(id: 'a', name: 'Al Basra Contracting'),
        _p(id: 'b', name: 'Baghdad Materials'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'basra'),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('6. category string entry matches', () {
      final profiles = [
        _p(id: 'a', categories: ['steel']),
        _p(id: 'b', categories: ['cement']),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'steel'),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('7. subCategory string entry matches', () {
      final profiles = [
        _p(id: 'a', subCategories: ['rebar']),
        _p(id: 'b', subCategories: ['paint']),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'rebar'),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('8. unmatched text excludes profile', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha'),
        _p(id: 'b', name: 'Beta'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'zzzz'),
      );
      expect(result, isEmpty);
    });

    test('9. no Arabic normalization occurs beyond raw contains', () {
      // Arabic 'أ' and 'ا' remain distinct: applying 'ا' must NOT match 'ألف'.
      final profiles = [
        _p(id: 'a', name: 'ألف شركة'),
        _p(id: 'b', name: 'باء'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'ا'),
      );
      expect(result.map((p) => p.id), isNot(contains('a')));
    });
  });

  group('W5.3 QUERY ENGINE — category filter', () {
    test('10. category filter exact BusinessType match', () {
      final profiles = [
        _p(id: 'a', type: BusinessType.supplier),
        _p(id: 'b', type: BusinessType.contractor),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(category: BusinessType.supplier),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('11. null category means all', () {
      final profiles = [
        _p(id: 'a', type: BusinessType.supplier),
        _p(id: 'b', type: BusinessType.contractor),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(),
      );
      expect(result.length, 2);
    });

    test('12. BusinessType.other works normally', () {
      final profiles = [
        _p(id: 'a', type: BusinessType.other),
        _p(id: 'b', type: BusinessType.supplier),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(category: BusinessType.other),
      );
      expect(result.map((p) => p.id), ['a']);
    });
  });

  group('W5.3 QUERY ENGINE — location filter', () {
    test('13. location filter exact BaghdadArea match', () {
      final profiles = [
        _p(id: 'a', baghdadArea: BaghdadArea.karrada),
        _p(id: 'b', baghdadArea: BaghdadArea.mansour),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(location: BaghdadArea.karrada),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('14. null location means all', () {
      final profiles = [
        _p(id: 'a', baghdadArea: BaghdadArea.karrada),
        _p(id: 'b', baghdadArea: BaghdadArea.mansour),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(),
      );
      expect(result.length, 2);
    });
  });

  group('W5.3 QUERY ENGINE — AND composition', () {
    test('15. text + category = AND', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha', type: BusinessType.supplier),
        _p(id: 'b', name: 'Alpha', type: BusinessType.contractor),
        _p(id: 'c', name: 'Beta', type: BusinessType.supplier),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(
          text: 'alpha',
          category: BusinessType.supplier,
        ),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('16. text + location = AND', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha', baghdadArea: BaghdadArea.karrada),
        _p(id: 'b', name: 'Alpha', baghdadArea: BaghdadArea.mansour),
        _p(id: 'c', name: 'Beta', baghdadArea: BaghdadArea.karrada),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'alpha', location: BaghdadArea.karrada),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('17. category + location = AND', () {
      final profiles = [
        _p(id: 'a', type: BusinessType.supplier, baghdadArea: BaghdadArea.karrada),
        _p(id: 'b', type: BusinessType.supplier, baghdadArea: BaghdadArea.mansour),
        _p(id: 'c', type: BusinessType.contractor, baghdadArea: BaghdadArea.karrada),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(
          category: BusinessType.supplier,
          location: BaghdadArea.karrada,
        ),
      );
      expect(result.map((p) => p.id), ['a']);
    });

    test('18. text + category + location = AND', () {
      final profiles = [
        _p(
          id: 'a',
          name: 'Alpha',
          type: BusinessType.supplier,
          baghdadArea: BaghdadArea.karrada,
        ),
        _p(
          id: 'b',
          name: 'Alpha',
          type: BusinessType.contractor,
          baghdadArea: BaghdadArea.karrada,
        ),
        _p(
          id: 'c',
          name: 'Alpha',
          type: BusinessType.supplier,
          baghdadArea: BaghdadArea.mansour,
        ),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(
          text: 'alpha',
          category: BusinessType.supplier,
          location: BaghdadArea.karrada,
        ),
      );
      expect(result.map((p) => p.id), ['a']);
    });
  });

  group('W5.3 QUERY ENGINE — immutability & non-search fields', () {
    test('19. engine does not mutate input list', () {
      final profiles = [
        _p(id: 'a', name: 'Alpha', type: BusinessType.supplier),
        _p(id: 'b', name: 'Beta', type: BusinessType.contractor),
      ];
      final original = List<ServiceBusinessProfile>.from(profiles);
      DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'alpha', category: BusinessType.supplier),
      );
      expect(profiles.length, original.length);
      expect(profiles.map((p) => p.id), original.map((p) => p.id));
    });

    test('20. engine does not reorder input', () {
      final profiles = [
        _p(id: 'a', name: 'Zulu'),
        _p(id: 'b', name: 'Alpha'),
        _p(id: 'c', name: 'Mike'),
      ];
      final result = DirectoryQueryEngine.apply(profiles, const DirectoryQuery());
      expect(result.map((p) => p.id), ['a', 'b', 'c']);
    });

    test('21. featured has no effect on filtering', () {
      final profiles = [
        _p(id: 'a', featured: true),
        _p(id: 'b', featured: false),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'nomatch'),
      );
      expect(result, isEmpty);
    });

    test('22. foundingPartner has no effect on filtering', () {
      final profiles = [
        _p(id: 'a', foundingPartner: true),
        _p(id: 'b', foundingPartner: false),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'nomatch'),
      );
      expect(result, isEmpty);
    });

    test('23. planType has no effect on filtering', () {
      final profiles = [
        _p(id: 'a', planType: 'premium'),
        _p(id: 'b', planType: 'basic'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'premium'),
      );
      expect(result, isEmpty);
    });

    test('24. verificationStatus has no effect on filtering', () {
      final profiles = [
        _p(id: 'a', verificationStatus: VerificationStatus.verified),
        _p(id: 'b', verificationStatus: VerificationStatus.unverified),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'verified'),
      );
      expect(result, isEmpty);
    });

    test('25. address does not text-match', () {
      final profiles = [_p(id: 'a', address: 'Al Mansour street 12')];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'mansour'),
      );
      expect(result, isEmpty);
    });

    test('26. description does not text-match', () {
      final profiles = [_p(id: 'a', description: 'rebar specialist company')];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: 'rebar'),
      );
      expect(result, isEmpty);
    });

    test('27. phone/whatsapp do not text-match', () {
      final profiles = [
        _p(id: 'a', phones: ['07701234567'], whatsapp: '07801234567'),
      ];
      final result = DirectoryQueryEngine.apply(
        profiles,
        const DirectoryQuery(text: '07701234567'),
      );
      expect(result, isEmpty);
    });
  });
}
