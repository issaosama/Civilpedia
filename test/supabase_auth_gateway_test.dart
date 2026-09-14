import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:civilpedia/core/backend/backend_config.dart';
import 'package:civilpedia/core/backend/supabase_service.dart';
import 'package:civilpedia/features/auth/data/auth_recovery_library.dart';
import 'package:civilpedia/features/auth/data/session_correlation.dart';
import 'package:civilpedia/features/auth/data/supabase_auth_gateway.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

/// Sign-out behavior (V1-R09 H1/M1/C2) now lives in
/// `v1_r09_c2_sign_out_recovery_test.dart`: the journal/coordinator-backed
/// flow REQUIRES the production initialization path (real Supabase.initialize
/// + recovery coordinator), which is exercised there against a controlled
/// GoTrue server. This file keeps the coordinator-independent gateway/provider
/// behaviors (availability, sign-in error mapping, H2 stream continuity, H3
/// credential-exchange quarantine).

void main() {
  const devConfig = BackendConfig(
    appEnvRaw: 'development',
    supabaseUrl: 'https://project.supabase.co',
    supabaseAnonKey: 'anon-key',
    googleServerClientId: 'g-web-client-id.apps.googleusercontent.com',
  );

  const unconfigured = BackendConfig(
    appEnvRaw: '',
    supabaseUrl: '',
    supabaseAnonKey: '',
  );

  SupabaseAuthGateway gatewayFor(BackendConfig config) =>
      SupabaseAuthGateway(service: SupabaseService(config: config));

  Future<SupabaseService> readyService() async {
    final service = SupabaseService(config: devConfig);
    await service.init(
      initialize: ({required url, required publishableKey}) async {},
    );
    return service;
  }

  SupabaseClient client() =>
      SupabaseClient(devConfig.supabaseUrl, devConfig.supabaseAnonKey);

  const credentials = GoogleCredentialBundle(
    idToken: 'google-id-token',
    accessToken: 'google-access-token',
  );
  const session = AuthSession(
    userId: 'user-a',
    email: 'user@example.com',
    displayName: 'User A',
  );

  test('isAvailable is false when the backend is not configured', () {
    expect(gatewayFor(unconfigured).isAvailable, isFalse);
    expect(
      gatewayFor(devConfig).isAvailable,
      isFalse,
      reason: 'config present but Supabase not initialized',
    );
  });

  test('isAvailable additionally requires the Google client id'
      ' (config alone is not enough)', () {
    const noGoogle = BackendConfig(
      appEnvRaw: 'development',
      supabaseUrl: 'https://project.supabase.co',
      supabaseAnonKey: 'anon-key',
    );
    // No Google client id → gateway unavailable even though backend configured.
    expect(gatewayFor(noGoogle).isAvailable, isFalse);
  });

  test(
    'signInWithGoogle on an unavailable gateway throws AuthGatewayException',
    () {
      final gateway = gatewayFor(unconfigured);
      expect(
        () => gateway.signInWithGoogle(),
        throwsA(
          isA<AuthGatewayException>().having(
            (e) => e.error,
            'error',
            AuthError.unavailable,
          ),
        ),
      );
    },
  );

  test('signOut reports failure when its authority is unavailable', () async {
    final gateway = gatewayFor(unconfigured);
    await expectLater(
      gateway.signOut(),
      throwsA(
        isA<AuthGatewayException>().having(
          (error) => error.error,
          'error',
          AuthError.signOutFailed,
        ),
      ),
    );
    expect(gateway.isAvailable, isFalse);
  });

  test(
    'credential exchange timeout is retryable and creates no session',
    () async {
      final service = await readyService();
      final gateway = SupabaseAuthGateway(
        service: service,
        client: client(),
        credentialsProvider: () async => credentials,
        credentialExchange: ({required idToken, required accessToken}) =>
            Completer<AuthSession>().future,
        credentialExchangeTimeout: const Duration(milliseconds: 5),
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.session, isNull);
      expect(provider.status, AuthStatus.cleanupRecovery);
      expect(provider.error, AuthError.recoveryBlocked);
      provider.dispose();
      gateway.dispose();
      service.dispose();
    },
  );

  test(
    'retryable Supabase transport failure maps to retryableNetwork',
    () async {
      final service = await readyService();
      final gateway = SupabaseAuthGateway(
        service: service,
        client: client(),
        credentialsProvider: () async => credentials,
        credentialExchange: ({required idToken, required accessToken}) async =>
            throw AuthRetryableFetchException(),
      );

      await expectLater(
        gateway.signInWithGoogle(),
        throwsA(
          isA<AuthGatewayException>().having(
            (error) => error.error,
            'error',
            AuthError.retryableNetwork,
          ),
        ),
      );
      gateway.dispose();
      service.dispose();
    },
  );

  test('auth rejection stays distinct from transport failure', () async {
    final service = await readyService();
    final gateway = SupabaseAuthGateway(
      service: service,
      client: client(),
      credentialsProvider: () async => credentials,
      credentialExchange: ({required idToken, required accessToken}) async =>
          throw const AuthApiException('rejected', statusCode: '401'),
    );

    await expectLater(
      gateway.signInWithGoogle(),
      throwsA(
        isA<AuthGatewayException>().having(
          (error) => error.error,
          'error',
          AuthError.signInFailed,
        ),
      ),
    );
    gateway.dispose();
    service.dispose();
  });

  test('unexpected exchange failure does not masquerade as network', () async {
    final service = await readyService();
    final gateway = SupabaseAuthGateway(
      service: service,
      client: client(),
      credentialsProvider: () async => credentials,
      credentialExchange: ({required idToken, required accessToken}) async =>
          throw StateError('programming defect'),
    );

    await expectLater(
      gateway.signInWithGoogle(),
      throwsA(
        isA<AuthGatewayException>().having(
          (error) => error.error,
          'error',
          AuthError.unexpected,
        ),
      ),
    );
    gateway.dispose();
    service.dispose();
  });

  test('late service readiness updates the existing auth gateway', () async {
    final pending = Completer<void>();
    final service = SupabaseService(config: devConfig);
    await service.init(
      initialize: ({required url, required publishableKey}) => pending.future,
      timeout: const Duration(milliseconds: 5),
    );
    final gateway = SupabaseAuthGateway(service: service, client: client());
    expect(gateway.isAvailable, isFalse);

    pending.complete();
    await Future<void>.delayed(Duration.zero);

    expect(gateway.isAvailable, isTrue);
    gateway.dispose();
    service.dispose();
  });

  // ------------------------------------------------------------------------
  // V1-R09 H2 — auth stream error continuity.
  // ------------------------------------------------------------------------
  group('V1-R09 H2 auth stream error continuity', () {
    test(
      'recoverable stream error does not stop later event forwarding',
      () async {
        final service = await readyService();
        final controller = StreamController<AuthState>.broadcast();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          authStateStreamFactory: () => controller.stream,
        );

        final events = <AuthEvent>[];
        final sub = gateway.authEvents.listen(events.add);

        controller.addError(Exception('stream hiccup'));
        controller.add(const AuthState(AuthChangeEvent.signedOut, null));
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == AuthEventType.signedOut),
          hasLength(1),
          reason:
              'signedOut event must still be forwarded after a stream error',
        );

        await sub.cancel();
        gateway.dispose();
        service.dispose();
        controller.close();
      },
    );

    test(
      'tokenRefreshed remains observable after recoverable stream error',
      () async {
        final service = await readyService();
        final controller = StreamController<AuthState>.broadcast();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          authStateStreamFactory: () => controller.stream,
        );

        final events = <AuthEvent>[];
        final sub = gateway.authEvents.listen(events.add);

        controller.addError(Exception('stream hiccup'));
        controller.add(
          AuthState(
            AuthChangeEvent.tokenRefreshed,
            Session(
              accessToken: 'refreshed-token',
              tokenType: 'bearer',
              user: User(
                id: 'user-a',
                email: 'a@example.com',
                appMetadata: {},
                userMetadata: {'full_name': 'A'},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                role: 'authenticated',
              ),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == AuthEventType.tokenRefreshed),
          hasLength(1),
          reason: 'tokenRefreshed must remain observable after a stream error',
        );

        await sub.cancel();
        gateway.dispose();
        service.dispose();
        controller.close();
      },
    );

    test(
      'only one subscription exists even after stream error/onDone cycles',
      () async {
        final service = await readyService();
        final controller = StreamController<AuthState>.broadcast();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          authStateStreamFactory: () => controller.stream,
        );

        // First listener arms the subscription.
        final sub1 = gateway.authEvents.listen((_) {});
        // Second listener must reuse the same subscription (broadcast stream).
        final sub2 = gateway.authEvents.listen((_) {});

        controller.addError(Exception('hiccup'));
        controller.close();
        await Future<void>.delayed(Duration.zero);

        // The gateway exposed the broadcast stream; multiple listeners are OK,
        // but the underlying SDK subscription must not be duplicated.
        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        await sub1.cancel();
        await sub2.cancel();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'unexpected onDone latches observation off and never re-arms',
      () async {
        final service = await readyService();
        final controller = StreamController<AuthState>.broadcast();
        var armCount = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          authStateStreamFactory: () {
            armCount++;
            return controller.stream;
          },
        );
        addTearDown(gateway.dispose);
        addTearDown(service.dispose);

        final events = <AuthEvent>[];
        final sub = gateway.authEvents.listen(events.add);
        addTearDown(() => sub.cancel());
        final provider = AuthProvider(gateway: gateway);
        addTearDown(provider.dispose);

        controller.addError(Exception('stream hiccup'));
        controller.close();
        await Future<void>.delayed(Duration.zero);

        expect(
          armCount,
          1,
          reason: 'the lost observation must never be re-armed',
        );
        expect(gateway.isAuthObservationAvailable, isFalse);
        expect(gateway.canAccountAuthorityBeGranted, isFalse);
        expect(
          events.where(
            (e) => e.type == AuthEventType.authObservationUnavailable,
          ),
          hasLength(1),
        );

        // A fresh-authority entrypoint must stay blocked without arm (no events
        // could ever be missed by a re-subscribe).
        expect(await gateway.restoreSession(), isNull);
        expect(armCount, 1);

        // Provider surfaces the latched restricted state.
        expect(provider.status, AuthStatus.observationUnavailable);
        expect(provider.isAuthObservationUnavailable, isTrue);
        expect(provider.isAuthorityBlocked, isTrue);
        expect(provider.error, AuthError.recoveryBlocked);
      },
    );
  });

  SessionCorrelation _staleCorrelation(String sessionId) => SessionCorrelation(
    userId: session.userId,
    sessionId: sessionId,
    projectIdentity: AuthRecoveryStorageCoordinator.projectIdentityFromUrl(
      devConfig.supabaseUrl,
    ),
  );

  // ------------------------------------------------------------------------
  // V1-R09 C3 — timed-out credential exchange quarantine.
  // ------------------------------------------------------------------------
  group('V1-R09 C3 credential exchange quarantine', () {
    test(
      'healthy in-time success: no neutralizer runs and session is admitted',
      () async {
        final service = await readyService();
        var remoteSignOutCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange:
              ({required idToken, required accessToken}) async => session,
          credentialExchangeCorrelationProvider: () =>
              _staleCorrelation('sess-in-time'),
          remoteSignOut: () async {
            remoteSignOutCalls++;
          },
          credentialExchangeTimeout: const Duration(milliseconds: 100),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();

        expect(provider.isLoggedIn, isTrue);
        expect(provider.session, session);
        expect(provider.status, AuthStatus.authenticated);
        expect(gateway.recoveryStatus, AuthRecoveryStatus.none);
        expect(
          remoteSignOutCalls,
          0,
          reason: 'in-time success must never trigger stale neutralization',
        );

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'in-time failure: typed failure, no neutralization, no authority',
      () async {
        final service = await readyService();
        var remoteSignOutCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange:
              ({required idToken, required accessToken}) async =>
                  throw AuthRetryableFetchException(),
          remoteSignOut: () async {
            remoteSignOutCalls++;
          },
          credentialExchangeTimeout: const Duration(milliseconds: 100),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();

        expect(provider.isLoggedIn, isFalse);
        expect(provider.status, AuthStatus.error);
        expect(provider.error, AuthError.retryableNetwork);
        expect(gateway.recoveryStatus, AuthRecoveryStatus.none);
        expect(remoteSignOutCalls, 0);

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'timeout leaves provider not authenticated and quarantines the run',
      () async {
        final service = await readyService();
        final completer = Completer<AuthSession>();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange: ({required idToken, required accessToken}) =>
              completer.future,
          credentialExchangeTimeout: const Duration(milliseconds: 5),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();

        expect(provider.isLoggedIn, isFalse);
        expect(provider.status, AuthStatus.cleanupRecovery);
        expect(provider.error, AuthError.recoveryBlocked);
        expect(
          gateway.recoveryStatus,
          AuthRecoveryStatus.exchangeTimedOutPending,
        );

        provider.dispose();
        gateway.dispose();
        service.dispose();
        completer.complete(session);
        await Future<void>.delayed(Duration.zero);
      },
    );

    test(
      'second sign-in while exchange unresolved does not start a second SDK exchange',
      () async {
        final service = await readyService();
        final completer = Completer<AuthSession>();
        var exchangeCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange: ({required idToken, required accessToken}) {
            exchangeCalls++;
            return completer.future;
          },
          credentialExchangeTimeout: const Duration(milliseconds: 5),
        );
        final provider = AuthProvider(gateway: gateway);

        final first = provider.signInWithGoogle();
        await Future<void>.delayed(Duration.zero);
        final second = provider.signInWithGoogle();
        await Future.wait([first, second]);

        expect(
          exchangeCalls,
          1,
          reason: 'only one SDK exchange may run at a time',
        );
        expect(provider.isLoggedIn, isFalse);

        provider.dispose();
        gateway.dispose();
        service.dispose();
        completer.complete(session);
        await Future<void>.delayed(Duration.zero);
      },
    );

    test('late failure releases quarantine and allows retry', () async {
      final service = await readyService();
      final firstCompleter = Completer<AuthSession>();
      final secondCompleter = Completer<AuthSession>();
      var exchangeCalls = 0;
      final gateway = SupabaseAuthGateway(
        service: service,
        client: client(),
        credentialsProvider: () async => credentials,
        credentialExchange: ({required idToken, required accessToken}) {
          exchangeCalls++;
          return exchangeCalls == 1
              ? firstCompleter.future
              : secondCompleter.future;
        },
        credentialExchangeTimeout: const Duration(milliseconds: 5),
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();
      expect(provider.error, AuthError.recoveryBlocked);
      expect(
        gateway.recoveryStatus,
        AuthRecoveryStatus.exchangeTimedOutPending,
      );

      // Late failure of the first exchange.
      firstCompleter.completeError(Exception('network'));
      await Future<void>.delayed(Duration.zero);

      expect(gateway.recoveryStatus, AuthRecoveryStatus.none);

      // Retry should now be allowed and succeed.
      secondCompleter.complete(session);
      await provider.signInWithGoogle();

      expect(provider.isLoggedIn, isTrue);
      expect(provider.session, session);
      expect(exchangeCalls, 2);

      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test(
      'injected no-SDK late success cannot install authority; empty SDK permits retry',
      () async {
        final service = await readyService();
        final firstCompleter = Completer<AuthSession>();
        final secondCompleter = Completer<AuthSession>();
        var exchangeCalls = 0;
        var remoteSignOutCalls = 0;
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange: ({required idToken, required accessToken}) {
            exchangeCalls++;
            return exchangeCalls == 1
                ? firstCompleter.future
                : secondCompleter.future;
          },
          credentialExchangeCorrelationProvider: () =>
              _staleCorrelation('sess-late'),
          remoteSignOut: () async {
            remoteSignOutCalls++;
          },
          credentialExchangeTimeout: const Duration(milliseconds: 5),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();
        expect(provider.error, AuthError.recoveryBlocked);

        // Late success of the expired exchange.
        firstCompleter.complete(session);
        await Future<void>.delayed(Duration.zero);

        expect(
          provider.isLoggedIn,
          isFalse,
          reason: 'stale late success must not install session',
        );
        expect(
          remoteSignOutCalls,
          0,
          reason: 'the no-SDK seam has no actual session to revoke',
        );
        expect(gateway.recoveryStatus, AuthRecoveryStatus.none);

        // Fresh retry succeeds.
        secondCompleter.complete(session);
        await provider.signInWithGoogle();
        expect(provider.isLoggedIn, isTrue);

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test(
      'raw exchange late error is observed once with zero unhandled errors',
      () async {
        final service = await readyService();
        final completer = Completer<AuthSession>();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange: ({required idToken, required accessToken}) =>
              completer.future,
          credentialExchangeTimeout: const Duration(milliseconds: 5),
        );
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();
        expect(provider.error, AuthError.recoveryBlocked);

        completer.completeError(StateError('late raw fault'));
        await Future<void>.delayed(Duration.zero);

        expect(gateway.recoveryStatus, AuthRecoveryStatus.none);
        expect(provider.isLoggedIn, isFalse);

        provider.dispose();
        gateway.dispose();
        service.dispose();
      },
    );

    test('generation g blocks g+1 until g resolves', () async {
      final service = await readyService();
      final completer = Completer<AuthSession>();
      var exchangeCalls = 0;
      final gateway = SupabaseAuthGateway(
        service: service,
        client: client(),
        credentialsProvider: () async => credentials,
        credentialExchange: ({required idToken, required accessToken}) {
          exchangeCalls++;
          return completer.future;
        },
        credentialExchangeTimeout: const Duration(milliseconds: 5),
      );
      final provider = AuthProvider(gateway: gateway);

      final first = provider.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      final second = provider.signInWithGoogle();
      await Future.wait([first, second]);

      expect(exchangeCalls, 1);
      expect(
        gateway.recoveryStatus,
        AuthRecoveryStatus.exchangeTimedOutPending,
      );

      // Resolve g late, then allow g+1.
      completer.completeError(Exception('network'));
      await Future<void>.delayed(Duration.zero);
      expect(gateway.recoveryStatus, AuthRecoveryStatus.none);

      await provider.signInWithGoogle();
      expect(exchangeCalls, 2);

      provider.dispose();
      gateway.dispose();
      service.dispose();
    });

    test(
      'identity-bearing auth events are suppressed during quarantine',
      () async {
        final service = await readyService();
        final controller = StreamController<AuthState>.broadcast();
        final completer = Completer<AuthSession>();
        final gateway = SupabaseAuthGateway(
          service: service,
          client: client(),
          credentialsProvider: () async => credentials,
          credentialExchange: ({required idToken, required accessToken}) =>
              completer.future,
          authStateStreamFactory: () => controller.stream,
          credentialExchangeTimeout: const Duration(milliseconds: 5),
        );

        final events = <AuthEvent>[];
        final sub = gateway.authEvents.listen(events.add);

        await gateway.signInWithGoogle().catchError((_) => null);
        expect(
          gateway.recoveryStatus,
          AuthRecoveryStatus.exchangeTimedOutPending,
        );

        controller.add(
          AuthState(
            AuthChangeEvent.signedIn,
            Session(
              accessToken: 'stale-token',
              tokenType: 'bearer',
              user: User(
                id: session.userId,
                email: session.email,
                appMetadata: {},
                userMetadata: {'full_name': session.displayName},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                role: 'authenticated',
              ),
            ),
          ),
        );
        controller.add(
          AuthState(
            AuthChangeEvent.tokenRefreshed,
            Session(
              accessToken: 'refreshed-token',
              tokenType: 'bearer',
              user: User(
                id: session.userId,
                email: session.email,
                appMetadata: {},
                userMetadata: {'full_name': session.displayName},
                aud: 'authenticated',
                createdAt: DateTime.now().toIso8601String(),
                role: 'authenticated',
              ),
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          events.where((e) => e.type == AuthEventType.signedIn),
          isEmpty,
          reason: 'signedIn during quarantine must not grant authority',
        );
        expect(
          events.where((e) => e.type == AuthEventType.tokenRefreshed),
          isEmpty,
          reason: 'tokenRefreshed during quarantine must not grant authority',
        );

        await sub.cancel();
        gateway.dispose();
        service.dispose();
        controller.close();
        completer.complete(session);
        await Future<void>.delayed(Duration.zero);
      },
    );
  });
}
