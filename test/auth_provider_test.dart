import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';

import 'fakes/fake_auth_gateway.dart';

void main() {
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

    test('restore failure degrades silently to guest (no error surfaced)',
        () async {
      final gateway = FakeAuthGateway(
        restoreError: Exception('network down'),
      );
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
      expect(provider.error, isNull, reason: 'restore must not set an error');
    });

    test('restore is a no-op when the gateway is unavailable', () async {
      final gateway = FakeAuthGateway(available: false, restoredSession: fakeSession);
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

    test('unavailable gateway surfaces unavailable without calling it', () async {
      final gateway = FakeAuthGateway(available: false);
      final provider = AuthProvider(gateway: gateway);

      await provider.signInWithGoogle();

      expect(gateway.signInCalls, 0);
      expect(provider.status, AuthStatus.error);
      expect(provider.error, AuthError.unavailable);
    });

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

    test('signOut failure never deletes the local guest state', () async {
      final gateway = FakeAuthGateway(
        restoredSession: fakeSession,
        signOutError: Exception('offline'),
      );
      final provider = AuthProvider(gateway: gateway);
      await provider.restoreSession();

      await provider.signOut();

      expect(provider.isLoggedIn, isFalse);
      expect(provider.status, AuthStatus.guest);
    });

    test('signOut as guest does not call the gateway', () async {
      final gateway = FakeAuthGateway();
      final provider = AuthProvider(gateway: gateway);

      await provider.signOut();

      expect(gateway.signOutCalls, 0);
      expect(provider.status, AuthStatus.guest);
    });
  });
}