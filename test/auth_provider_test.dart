import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/presentation/auth_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/timed_profile_gateways.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

import 'fakes/fake_auth_gateway.dart';

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource(this.initial);

  final bool initial;
  final StreamController<bool> changes = StreamController<bool>.broadcast(
    sync: true,
  );

  @override
  Future<bool> checkAvailability() async => initial;

  @override
  Stream<bool> get availabilityChanges => changes.stream;
}

class _PostAuthProfileGateway implements PersonalProfileRemoteGateway {
  Future<CloudProfile?> Function(String userId)? fetch;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) => fetch!(userId);

  @override
  Future<void> createProfile(CloudProfile profile) async {}

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {}

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {}
}

class _RecoveryEmptyProfileRepository implements UserProfileRepository {
  @override
  Future<LocalUserProfile?> loadProfile() async => null;
  @override
  Future<void> saveProfile(LocalUserProfile profile) async {}
  @override
  Future<void> clearProfile() async {}
}

class _TypedRecoveryGateway extends FakeAuthGateway
    implements AuthRecoveryGateway {
  _TypedRecoveryGateway(this.recoveryStatus);
  @override
  AuthRecoveryStatus recoveryStatus;
  int recoveryCalls = 0;
  Completer<AuthRecoveryResult>? retryGate;
  @override
  bool get canAccountAuthorityBeGranted =>
      recoveryStatus == AuthRecoveryStatus.none;
  @override
  bool get isLogoutCleanupBlocked => recoveryStatus != AuthRecoveryStatus.none;
  @override
  Future<AuthRecoveryResult> retryAuthRecovery() async {
    recoveryCalls++;
    return retryGate == null
        ? AuthRecoveryResult.blocked
        : await retryGate!.future;
  }
}

void main() {
  group('C2 typed recovery action and routing', () {
    for (final arabic in [false, true]) {
      for (final status in [
        AuthRecoveryStatus.remotePending,
        AuthRecoveryStatus.cleanupRequired,
        AuthRecoveryStatus.blockedCleanupFailure,
        AuthRecoveryStatus.restartRequired,
      ]) {
        testWidgets(
          '$status has reachable safe ${arabic ? "Arabic" : "English"} recovery UI',
          (tester) async {
            final gateway = _TypedRecoveryGateway(status);
            final auth = AuthProvider(gateway: gateway);
            addTearDown(auth.dispose);
            addTearDown(gateway.close);
            await auth.restoreSession();
            // restartRequired is a process latch in production. Establish its
            // provider notification just as the real gateway does.
            if (status == AuthRecoveryStatus.restartRequired) {
              gateway.emit(
                const AuthEvent(type: AuthEventType.authRecoveryChanged),
              );
            }
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: auth),
                  ChangeNotifierProvider(
                    create: (_) => LanguageProvider(isArabic: arabic),
                  ),
                ],
                child: const MaterialApp(home: AuthScreen()),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              find.text(arabic ? Ar.continueWithGoogle : En.continueWithGoogle),
              findsNothing,
            );
            final retry = find.text(
              arabic ? Ar.retryAuthRecovery : En.retryAuthRecovery,
            );
            if (status == AuthRecoveryStatus.restartRequired) {
              expect(retry, findsNothing);
              expect(
                find.text(
                  arabic
                      ? Ar.authRecoveryRestartMessage
                      : En.authRecoveryRestartMessage,
                ),
                findsOneWidget,
              );
            } else {
              expect(retry, findsOneWidget);
              gateway.retryGate = Completer<AuthRecoveryResult>();
              await tester.ensureVisible(retry);
              await tester.tap(retry);
              await tester.pump();
              expect(auth.isRecoveryRetryBusy, isTrue);
              await tester.tap(retry);
              expect(gateway.recoveryCalls, 1);
              gateway.retryGate!.complete(AuthRecoveryResult.blocked);
              await tester.pumpAndSettle();
              expect(auth.isRecoveryRetryBusy, isFalse);
              expect(auth.isAuthorityBlocked, isTrue);
            }
            expect(gateway.signInCalls, 0);
          },
        );
      }
    }

    for (final path in [AppRoutes.profileEdit, AppRoutes.userProfile]) {
      testWidgets(
        '$path reaches recovery instead of an editor or indefinite resolving UI',
        (tester) async {
          final gateway = _TypedRecoveryGateway(
            AuthRecoveryStatus.remotePending,
          );
          final auth = AuthProvider(gateway: gateway);
          addTearDown(auth.dispose);
          addTearDown(gateway.close);
          await auth.restoreSession();
          appRouter.go(path);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: auth),
                ChangeNotifierProvider(create: (_) => ThemeProvider()),
                ChangeNotifierProvider(
                  create: (_) => UserProfileProvider(
                    repository: _RecoveryEmptyProfileRepository(),
                    auth: auth,
                  ),
                ),
                ChangeNotifierProvider(
                  create: (_) => LanguageProvider(isArabic: false),
                ),
              ],
              child: MaterialApp.router(routerConfig: appRouter),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AuthScreen), findsOneWidget);
          final retry = find.text(En.retryAuthRecovery);
          expect(retry, findsOneWidget);
          await tester.ensureVisible(retry);
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(gateway.recoveryCalls, 1);
          expect(find.text(En.continueWithGoogle), findsNothing);
          if (path == AppRoutes.userProfile) {
            expect(
              appRouter
                  .routerDelegate
                  .currentConfiguration
                  .uri
                  .queryParameters['return'],
              path,
            );
          }
        },
      );
    }

    test(
      'typed cleanup completion for stale operation cannot clear current recovery',
      () async {
        final gateway = _TypedRecoveryGateway(
          AuthRecoveryStatus.cleanupRequired,
        );
        final auth = AuthProvider(gateway: gateway);
        addTearDown(auth.dispose);
        addTearDown(gateway.close);
        gateway.emit(
          const AuthEvent(
            type: AuthEventType.logoutCleanupRequired,
            operationId: 'B',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        gateway.recoveryStatus = AuthRecoveryStatus.none;
        gateway.emit(
          const AuthEvent(
            type: AuthEventType.logoutCleanupCleared,
            operationId: 'A',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(auth.status, AuthStatus.cleanupRecovery);
        gateway.emit(
          const AuthEvent(
            type: AuthEventType.logoutCleanupCleared,
            operationId: 'B',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(auth.status, AuthStatus.guest);
      },
    );
  });

  group('AuthProvider initial state (guest without a gateway)', () {
    test('bare provider is guest and not available', () {
      final provider = AuthProvider();
      expect(provider.isLoggedIn, isFalse);
      expect(provider.isAvailable, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.currentName, isNull);
      expect(provider.currentEmail, isNull);
    });
  });

  group('session restore (fire-and-forget, never blocks)', () {
    test('restores an existing session to authenticated', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final provider = AuthProvider(gateway: gateway)..restoreSession();

      await Future<void>.delayed(Duration.zero);

      expect(provider.isLoggedIn, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.session, fakeSession);
      expect(provider.currentName, 'م. أحمد');
      expect(provider.currentEmail, 'eng@civilpedia.com');
      expect(provider.userName, 'م. أحمد');
    });

    test('no session stays guest', () async {
      final provider = AuthProvider(gateway: FakeAuthGateway());
      await provider.restoreSession();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.error, isNull);
    });

    test(
      'restore failure degrades silently to guest (no error surfaced)',
      () async {
        final gateway = FakeAuthGateway(
          restoreError: Exception('network down'),
        );
        final provider = AuthProvider(gateway: gateway);
        await provider.restoreSession();

        expect(provider.isLoggedIn, isFalse);
        expect(provider.status, AuthStatus.guest);
        expect(provider.error, isNull, reason: 'restore must not set an error');
      },
    );

    test('restore is a no-op when the gateway is unavailable', () async {
      final gateway = FakeAuthGateway(
        available: false,
        restoredSession: fakeSession,
      );
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();

      expect(provider.status, AuthStatus.guest);
      expect(provider.isLoggedIn, isFalse);
    });
  });

  group('Google sign-in', () {
    test('available gateway + successful result authenticates', () async {
      final gateway = FakeAuthGateway(signInResult: fakeSession);
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(gateway.signInCalls, 1);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.session, fakeSession);
      expect(provider.error, isNull);
    });

    test('null result (user cancelled) stays guest without error', () async {
      final gateway = FakeAuthGateway(signInResult: null);
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.error, isNull);
    });

    test('gateway exception maps to the visible error state', () async {
      final gateway = FakeAuthGateway(
        signInError: const AuthGatewayException(AuthError.signInFailed),
      );
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.error);
      expect(provider.error, AuthError.signInFailed);
    });

    test(
      'unavailable gateway surfaces unavailable without calling it',
      () async {
        final gateway = FakeAuthGateway(available: false);
        final provider = AuthProvider(gateway: gateway);

        await provider.signInWithGoogle();

        expect(gateway.signInCalls, 0);
        expect(provider.status, AuthStatus.error);
        expect(provider.error, AuthError.unavailable);
      },
    );

    test('unexpected error maps to signInFailed', () async {
      final gateway = FakeAuthGateway(signInError: Exception('boom'));
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(provider.status, AuthStatus.error);
      expect(provider.error, AuthError.signInFailed);
    });

    test('clearError returns to plain guest without an error', () async {
      final gateway = FakeAuthGateway(
        signInError: const AuthGatewayException(AuthError.signInFailed),
      );
      final provider = AuthProvider(gateway: gateway);
      await provider.signInWithGoogle();
      expect(provider.status, AuthStatus.error);

      provider.clearError();
      expect(provider.status, AuthStatus.guest);
      expect(provider.error, isNull);
    });
  });

  group('sign out', () {
    test('signOut flips to guest and delegates to the gateway', () async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      await provider.signOut();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.currentName, isNull);
      expect(gateway.signOutCalls, 1);
    });

    test('signOut failure re-resolves the session, never fakes a guest '
        '(fail-closed)', () async {
      final gateway = FakeAuthGateway(
        restoredSession: fakeSession,
        signOutError: Exception('offline'),
      );
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();
      expect(provider.isLoggedIn, isTrue);

      await provider.signOut();

      expect(
        provider.isLoggedIn,
        isTrue,
        reason: 'a failed remote sign-out must never fake a guest session',
      );
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.error, AuthError.signOutFailed);
      expect(provider.session, fakeSession);
      expect(gateway.signOutCalls, 1);
    });

    test('signOut as guest does not call the gateway', () async {
      final gateway = FakeAuthGateway();
      final provider = AuthProvider(gateway: gateway);

      await provider.signOut();

      expect(gateway.signOutCalls, 0);
      expect(provider.status, AuthStatus.guest);
    });
  });

  group('V1-R09 network-loss safety', () {
    test(
      'post-auth timeout keeps the session and a later retry succeeds',
      () async {
        var timeoutFirstRun = true;
        final profileDelegate = _PostAuthProfileGateway()
          ..fetch = (_) => timeoutFirstRun
              ? Completer<CloudProfile?>().future
              : Future<CloudProfile?>.value(null);
        final profile = TimedPersonalProfileRemoteGateway(
          delegate: profileDelegate,
          readTimeout: const Duration(milliseconds: 5),
        );
        final gateway = FakeAuthGateway(signInResult: fakeSession);
        final provider = AuthProvider(
          gateway: gateway,
          onPostAuth: (session) async {
            await profile.fetchByUserId(session.userId);
            return PostAuthOutcome.success;
          },
        );

        await provider.signInWithGoogle();

        expect(provider.isLoggedIn, isTrue);
        expect(provider.session, fakeSession);
        expect(provider.postAuthState, PostAuthLifecycleState.retryableFailure);

        timeoutFirstRun = false;
        await provider.retryPostAuth();

        expect(provider.isLoggedIn, isTrue);
        expect(provider.postAuthState, PostAuthLifecycleState.success);
      },
    );

    test(
      'transport loss alone never logs out or advances auth generation',
      () async {
        var resets = 0;
        final auth = AuthProvider(
          gateway: FakeAuthGateway(restoredSession: fakeSession),
          onAccountBoundReset: () => resets++,
        );
        await auth.restoreSession();
        final generation = auth.generation;
        final source = _FakeTransportSource(true);
        final connectivity = ConnectivityProvider(source: source);
        await connectivity.initialization;

        source.changes.add(false);

        expect(connectivity.state, TransportState.unavailable);
        expect(auth.isLoggedIn, isTrue);
        expect(auth.session, fakeSession);
        expect(auth.generation, generation);
        expect(resets, 0);

        connectivity.dispose();
        await source.changes.close();
        auth.dispose();
      },
    );
  });
}
