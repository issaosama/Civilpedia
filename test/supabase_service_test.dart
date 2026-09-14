import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/core/network/remote_operation_policy.dart';

void main() {
  const configured = BackendConfig(
    appEnvRaw: 'development',
    supabaseUrl: 'https://project.supabase.co',
    supabaseAnonKey: 'anon-key',
  );

  const notConfigured = BackendConfig(
    appEnvRaw: '',
    supabaseUrl: '',
    supabaseAnonKey: '',
  );

  group('SupabaseService with no backend configuration', () {
    test('init() completes without calling Supabase.initialize', () async {
      var initializeCalls = 0;
      final service = SupabaseService(config: notConfigured);

      await service.init(
        initialize: ({required url, required publishableKey}) async {
          initializeCalls++;
        },
      );

      expect(initializeCalls, 0);
      expect(service.isAvailable, isFalse);
      expect(service.isInitialized, isFalse);
      expect(service.state, SupabaseServiceState.unavailable);
      expect(
        service.initializationFailure?.kind,
        InfrastructureFailureKind.serviceUnavailable,
      );
    });

    test('missing configuration never causes startup failure', () async {
      // Absent config is the default build path; init() must complete
      // successfully (no throw) so app startup is unaffected.
      final service = SupabaseService(config: notConfigured);
      await expectLater(service.init(), completes);
      expect(service.isInitialized, isFalse);
    });
  });

  group('SupabaseService with valid backend configuration', () {
    test(
      'init() delegates to Supabase.initialize with the correct values',
      () async {
        String? capturedUrl;
        String? capturedKey;
        final service = SupabaseService(config: configured);

        await service.init(
          initialize: ({required url, required publishableKey}) async {
            capturedUrl = url;
            capturedKey = publishableKey;
          },
        );

        expect(capturedUrl, 'https://project.supabase.co');
        expect(capturedKey, 'anon-key');
        expect(service.isAvailable, isTrue);
        expect(service.isInitialized, isTrue);
        expect(service.state, SupabaseServiceState.ready);
        expect(service.initializationFailure, isNull);
      },
    );

    test('init() failure is logged and does not propagate', () async {
      final service = SupabaseService(config: configured);

      await service.init(
        initialize: ({required url, required publishableKey}) async {
          throw Exception('backend unreachable');
        },
      );

      // The service swallows initialization failures to keep the app running.
      expect(service.isInitialized, isFalse);
      expect(service.state, SupabaseServiceState.unavailable);
      expect(
        service.initializationFailure?.kind,
        InfrastructureFailureKind.unknown,
      );
    });

    test(
      'stalled initialization releases local startup at its deadline',
      () async {
        final pending = Completer<void>();
        final service = SupabaseService(config: configured);

        await expectLater(
          service.init(
            initialize: ({required url, required publishableKey}) =>
                pending.future,
            timeout: const Duration(milliseconds: 5),
          ),
          completes,
        );

        expect(service.isInitialized, isFalse);
        expect(service.state, SupabaseServiceState.unavailable);
        expect(
          service.initializationFailure?.kind,
          InfrastructureFailureKind.timeout,
        );

        pending.complete();
        await Future<void>.delayed(Duration.zero);

        expect(
          service.isInitialized,
          isTrue,
          reason: 'late success must update the same dependency graph',
        );
        expect(service.state, SupabaseServiceState.ready);
        expect(service.initializationFailure, isNull);
      },
    );

    test('default startup deadline is the frozen six seconds', () {
      expect(
        RemoteOperationPolicy.serviceInitialization,
        const Duration(seconds: 6),
      );
    });
  });

  group('SupabaseService requires an explicit supported APP_ENV', () {
    test(
      'valid URL/key with missing APP_ENV never calls the initializer',
      () async {
        const urlAndKeyOnly = BackendConfig(
          appEnvRaw: '',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'anon-key',
        );
        var initializeCalls = 0;
        final service = SupabaseService(config: urlAndKeyOnly);

        await service.init(
          initialize: ({required url, required publishableKey}) async {
            initializeCalls++;
          },
        );

        expect(service.isAvailable, isFalse);
        expect(service.isInitialized, isFalse);
        expect(initializeCalls, 0);
      },
    );

    test(
      'valid URL/key with invalid APP_ENV never calls the initializer',
      () async {
        const invalidEnv = BackendConfig(
          appEnvRaw: 'not-a-real-environment',
          supabaseUrl: 'https://project.supabase.co',
          supabaseAnonKey: 'anon-key',
        );
        var initializeCalls = 0;
        final service = SupabaseService(config: invalidEnv);

        await service.init(
          initialize: ({required url, required publishableKey}) async {
            initializeCalls++;
          },
        );

        expect(service.isAvailable, isFalse);
        expect(service.isInitialized, isFalse);
        expect(initializeCalls, 0);
      },
    );
  });

  group('SupabaseService environment separation', () {
    test('different configs are isolated per service instance', () async {
      final dev = SupabaseService(config: configured);
      final prod = SupabaseService(
        config: const BackendConfig(
          appEnvRaw: 'production',
          supabaseUrl: 'https://prod.supabase.co',
          supabaseAnonKey: 'prod-anon',
        ),
      );

      expect(dev.config.environment.name, 'development');
      expect(prod.config.environment.name, 'production');
      expect(dev.config.supabaseUrl, isNot(prod.config.supabaseUrl));
    });
  });
}
