import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/auth/presentation/auth_screen.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'fakes/fake_auth_gateway.dart';

/// A fresh router per test — GoRouter keeps its last location on a shared
/// instance, which would leak navigation state between tests.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    routes: [
      GoRoute(
        path: '/public',
        builder: (_, __) => const Scaffold(body: Text('public-content')),
      ),
      GoRoute(path: AppRoutes.auth, builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (_, __) => const Scaffold(body: Text('profile-target')),
      ),
    ],
  );
}

Widget _app(AuthProvider auth, {bool isArabic = true}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(isArabic: isArabic),
      ),
      ChangeNotifierProvider.value(value: auth),
    ],
    child: MaterialApp.router(routerConfig: _buildRouter()),
  );
}

void main() {
  testWidgets('guest + unavailable gateway shows the notice, not the button', (
    tester,
  ) async {
    final auth = AuthProvider(gateway: FakeAuthGateway(available: false));
    await tester.pumpWidget(_app(auth));

    expect(find.text(Ar.googleSignInGuestNotice), findsOneWidget);
    expect(find.text(Ar.continueWithGoogle), findsNothing);
    expect(find.text(Ar.googleSignInUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest + available gateway shows Continue with Google', (
    tester,
  ) async {
    final auth = AuthProvider(gateway: FakeAuthGateway());
    await tester.pumpWidget(_app(auth));

    expect(find.text(Ar.continueWithGoogle), findsOneWidget);
    expect(find.text(Ar.googleSignInUnavailable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap triggers the gateway and navigates to the profile', (
    tester,
  ) async {
    final gateway = FakeAuthGateway(signInResult: fakeSession);
    final auth = AuthProvider(gateway: gateway);
    await tester.pumpWidget(_app(auth));

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(gateway.signInCalls, 1);
    expect(auth.isLoggedIn, isTrue);
    expect(find.text('profile-target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in failure surfaces a localized error and stays usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final failing = AuthProvider(
      gateway: FakeAuthGateway(signInError: Exception('network')),
    );
    await tester.pumpWidget(_app(failing));

    await failing.signInWithGoogle();
    await tester.pumpAndSettle();

    expect(failing.isLoggedIn, isFalse);
    expect(find.text(Ar.googleSignInFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final isArabic in [true, false]) {
    testWidgets(
      'unattributed reset is explicit and localized (Arabic=$isArabic)',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final gateway = _ResetGateway(
          AuthRecoveryStatus.exchangeBlockedUnattributed,
        );
        final auth = AuthProvider(gateway: gateway);
        await tester.pumpWidget(_app(auth, isArabic: isArabic));
        expect(
          find.text(
            isArabic
                ? Ar.authUnattributedResetMessage
                : En.authUnattributedResetMessage,
          ),
          findsOneWidget,
        );
        expect(find.text(Ar.continueWithGoogle), findsNothing);
        expect(find.text(En.continueWithGoogle), findsNothing);
        expect(gateway.resetCalls, 0);
        await tester.tap(
          find.text(isArabic ? Ar.resetDeviceSignIn : En.resetDeviceSignIn),
        );
        await tester.pumpAndSettle();
        expect(gateway.resetCalls, 1);
        expect(
          find.text(
            isArabic
                ? Ar.authLocalResetRestartMessage
                : En.authLocalResetRestartMessage,
          ),
          findsOneWidget,
        );
        expect(
          find.text(isArabic ? Ar.resetDeviceSignIn : En.resetDeviceSignIn),
          findsNothing,
        );
        expect(auth.isLoggedIn, isFalse);
        expect(auth.isRecoveryRetryBusy, isFalse);
        expect(gateway.signInCalls, 0);
        expect(gateway.signOutCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'timeout recovery hides Google and leaves public navigation (Arabic=$isArabic)',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final gateway = _ResetGateway(
          AuthRecoveryStatus.exchangeTimedOutPending,
        );
        final auth = AuthProvider(gateway: gateway);
        await tester.pumpWidget(_app(auth, isArabic: isArabic));
        expect(
          find.text(
            isArabic
                ? Ar.authExchangeTimedOutPendingMessage
                : En.authExchangeTimedOutPendingMessage,
          ),
          findsOneWidget,
        );
        expect(find.text(Ar.continueWithGoogle), findsNothing);
        expect(find.text(En.continueWithGoogle), findsNothing);
        expect(
          find.text(isArabic ? Ar.resetDeviceSignIn : En.resetDeviceSignIn),
          findsNothing,
        );
        GoRouter.of(tester.element(find.byType(AuthScreen))).go('/public');
        await tester.pumpAndSettle();
        expect(find.text('public-content'), findsOneWidget);
        expect(auth.isSigningIn, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _ResetGateway extends FakeAuthGateway
    implements AuthRecoveryGateway, QuarantinedDeviceSignInGateway {
  _ResetGateway(this.recoveryStatus);
  @override
  AuthRecoveryStatus recoveryStatus;
  int resetCalls = 0;
  @override
  bool get canAccountAuthorityBeGranted => false;
  @override
  Future<AuthRecoveryResult> retryAuthRecovery() async =>
      AuthRecoveryResult.busy;
  @override
  Future<AuthRecoveryResult> resetQuarantinedDeviceSignIn() async {
    resetCalls++;
    recoveryStatus = AuthRecoveryStatus.localResetRestartRequired;
    emit(const AuthEvent(type: AuthEventType.authRecoveryChanged));
    return AuthRecoveryResult.restartRequired;
  }
}
