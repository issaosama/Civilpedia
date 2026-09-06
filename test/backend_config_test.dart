import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/app_environment.dart';
import 'package:civilpedia/core/backend/backend_config.dart';

void main() {
  group('BackendConfig.isAvailable', () {
    test('false when both url and key are missing', () {
      const config = BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(config.isAvailable, isFalse);
    });

    test('false when url is present but key is missing', () {
      const config = BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: '',
      );
      expect(config.isAvailable, isFalse);
    });

    test('false when key is present but url is missing', () {
      const config = BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: '',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isFalse);
    });

    test('true when url, key and development are configured', () {
      const config = BackendConfig(
        appEnvRaw: 'development',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isTrue);
    });

    test('true when url, key and staging are configured', () {
      const config = BackendConfig(
        appEnvRaw: 'staging',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isTrue);
    });

    test('true when url, key and production are configured', () {
      const config = BackendConfig(
        appEnvRaw: 'production',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isTrue);
    });

    test('false when url and key are present but APP_ENV is missing', () {
      const config = BackendConfig(
        appEnvRaw: '',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isFalse);
    });

    test('false when url and key are present but APP_ENV is invalid', () {
      const config = BackendConfig(
        appEnvRaw: 'not-a-real-environment',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.isAvailable, isFalse);
    });
  });

  group('BackendConfig.environment', () {
    test('reflects the raw appEnvRaw value', () {
      const config = BackendConfig(
        appEnvRaw: 'staging',
        supabaseUrl: '',
        supabaseAnonKey: '',
      );
      expect(config.environment, AppEnvironment.staging);
    });

    test('absent APP_ENV yields unknown, keeping backend unavailable', () {
      const config = BackendConfig(
        appEnvRaw: '',
        supabaseUrl: 'https://project.supabase.co',
        supabaseAnonKey: 'anon-key',
      );
      expect(config.environment, AppEnvironment.unknown);
      expect(config.isAvailable, isFalse);
    });
  });

  group('BackendConfig.fromEnvironment (defaults)', () {
    test('is not available when no dart-define variables are provided', () {
      // Under `flutter test` no SUPABASE_URL / SUPABASE_ANON_KEY are defined,
      // so the compile-time values are empty and the config must be
      // unavailable — the same path a normal unconfigured build follows.
      final config = BackendConfig.fromEnvironment();
      expect(config.isAvailable, isFalse);
      expect(config.supabaseUrl, isEmpty);
      expect(config.supabaseAnonKey, isEmpty);
    });
  });
}
