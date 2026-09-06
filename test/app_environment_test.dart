import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/app_environment.dart';

void main() {
  group('AppEnvironment.fromName', () {
    test('parses the three supported logical environments', () {
      expect(AppEnvironment.fromName('development'), AppEnvironment.development);
      expect(AppEnvironment.fromName('staging'), AppEnvironment.staging);
      expect(AppEnvironment.fromName('production'), AppEnvironment.production);
    });

    test('is case-insensitive', () {
      expect(AppEnvironment.fromName('Development'), AppEnvironment.development);
      expect(AppEnvironment.fromName('STAGING'), AppEnvironment.staging);
      expect(AppEnvironment.fromName('Production'), AppEnvironment.production);
    });

    test('ignores surrounding whitespace', () {
      expect(
        AppEnvironment.fromName('  staging  '),
        AppEnvironment.staging,
      );
    });

    test('absent or unrecognised values resolve to unknown, not production', () {
      expect(AppEnvironment.fromName(''), AppEnvironment.unknown);
      expect(AppEnvironment.fromName('prod'), AppEnvironment.unknown);
      expect(AppEnvironment.fromName('dev'), AppEnvironment.unknown);
      expect(AppEnvironment.fromName('anything-else'), AppEnvironment.unknown);
      expect(AppEnvironment.fromName('Development!'), AppEnvironment.unknown);
    });
  });
}
