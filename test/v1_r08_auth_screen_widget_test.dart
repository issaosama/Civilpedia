import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/domain/repositories/auth_gateway.dart';
import 'package:civilpedia/features/auth/presentation/auth_screen.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/localization/en.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'fakes/fake_auth_gateway.dart';

class _FakeRepo implements UserProfileRepository {
  @override
  Future<LocalUserProfile?> loadProfile() async => null;

  @override
  Future<void> saveProfile(LocalUserProfile value) async {}

  @override
  Future<void> clearProfile() async {}
}

/// V1-R08 correction (finding 4) — a Google sign-in whose remote call parked
/// lets the test observe the single-flight in-flight state.
class _GatedSignInGateway extends FakeAuthGateway {
  _GatedSignInGateway({required this.result, this.gate});

  final AuthSession? result;
  final Completer<void>? gate;

  @override
  Future<AuthSession?> signInWithGoogle() async {
    signInCalls++;
    if (gate != null) await gate!.future;
    return result;
  }
}

/// V1-R08 correction (finding 3) — the FIRST resolution reports the conflict
/// (stuck), the RETRY resolves to a clean guest so the auth surface can show
/// the Return-to-sign-in recovery action.
class _RecoveredRestoreGateway extends FakeAuthGateway {
  _RecoveredRestoreGateway() : super(restoredSession: fakeSession);

  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreCalls++;
    return restoreCalls == 1 ? fakeSession : null;
  }
}

String _topMatchedLocation() =>
    appRouter.routerDelegate.currentConfiguration.matches.last.matchedLocation;

/// V1-R08 (Part 2) — production states of the AuthScreen guest/sign-in surface.
///
/// A5.4 — Google Sign-In, typed [AuthError] mapping, and the post-auth
/// claim/bootstrap seams (running / retryable / provisioning / ownership
/// conflict). Navigation on success/retry must only resume a protected
/// destination after the pipeline has FULLY settled.
Future<void> _pumpAuth(
  WidgetTester tester,
  AuthProvider auth, {
  bool isArabic = true,
}) async {
  await auth.restoreSession();
  appRouter.go(AppRoutes.auth);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(isArabic: isArabic),
        ),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(
          value: UserProfileProvider(repository: _FakeRepo()),
        ),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final arabic in [true, false]) {
    final cases = [
      (
        PostAuthOutcome.permissionDenied,
        Ar.profileCausePermissionDenied,
        En.profileCausePermissionDenied,
      ),
      (
        PostAuthOutcome.invalidData,
        Ar.profileCauseInvalidData,
        En.profileCauseInvalidData,
      ),
      (
        PostAuthOutcome.malformedResponse,
        Ar.profileCauseMalformed,
        En.profileCauseMalformed,
      ),
      (
        PostAuthOutcome.authFailure,
        Ar.profileCauseAuthFailure,
        En.profileCauseAuthFailure,
      ),
      (
        PostAuthOutcome.unexpected,
        Ar.profileCauseUnexpected,
        En.profileCauseUnexpected,
      ),
    ];
    for (final entry in cases) {
      testWidgets(
        'C4 ${entry.$1} Arabic=$arabic has typed copy and no network retry',
        (tester) async {
          final gateway = FakeAuthGateway(restoredSession: fakeSession);
          final auth = AuthProvider(
            gateway: gateway,
            onPostAuth: (_) async => entry.$1,
          );
          await _pumpAuth(tester, auth, isArabic: arabic);
          expect(find.text(arabic ? entry.$2 : entry.$3), findsOneWidget);
          expect(find.text(arabic ? Ar.retry : En.retry), findsNothing);
          expect(auth.isLoggedIn, isTrue);
          expect(gateway.signOutCalls, 0);
          expect(tester.takeException(), isNull);
          auth.dispose();
        },
      );
    }
  }
  group('V1-R08 AuthScreen', () {
    testWidgets('a quiet guest sees the Continue-with-Google affordance and '
        'no error row', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway());
      await _pumpAuth(tester, auth);

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text(Ar.continueWithGoogle), findsOneWidget);
      expect(find.text(Ar.googleSignInFailed), findsNothing);
      expect(_topMatchedLocation(), AppRoutes.auth);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a successful sign-in navigates to /user/profile ONLY after '
        'the post-auth pipeline settles', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(signInResult: fakeSession),
      );
      await _pumpAuth(tester, auth);

      await tester.tap(find.text(Ar.continueWithGoogle));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.postAuthState, PostAuthLifecycleState.success);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a cancelled sign-in returns to the quiet guest state without '
        'navigating', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(signInResult: null));
      await _pumpAuth(tester, auth);

      await tester.tap(find.text(Ar.continueWithGoogle));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.continueWithGoogle), findsOneWidget);
      expect(
        find.text(Ar.googleSignInFailed),
        findsNothing,
        reason: 'cancellation is not an error',
      );
      expect(_topMatchedLocation(), AppRoutes.auth);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a failed sign-in maps to the localized error row', (
      tester,
    ) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(
          signInError: const AuthGatewayException(AuthError.signInFailed),
        ),
      );
      await _pumpAuth(tester, auth);

      await tester.tap(find.text(Ar.continueWithGoogle));
      await tester.pumpAndSettle();

      expect(find.text(Ar.googleSignInFailed), findsOneWidget);
      expect(_topMatchedLocation(), AppRoutes.auth);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a retryable post-auth failure keeps the session, shows the '
        'explicit seam, and Retry resumes navigation', (tester) async {
      var pipelineCalls = 0;
      final auth = AuthProvider(
        gateway: FakeAuthGateway(signInResult: fakeSession),
        onPostAuth: (_) async {
          pipelineCalls++;
          return pipelineCalls == 1
              ? PostAuthOutcome.retryableFailure
              : PostAuthOutcome.success;
        },
      );
      await _pumpAuth(tester, auth);

      await tester.tap(find.text(Ar.continueWithGoogle));
      await tester.pumpAndSettle();

      // Authenticated and authoritative — but the claim/bootstrap failed
      // transiently, so the screen MUST NOT navigate away.
      expect(auth.isLoggedIn, isTrue);
      expect(auth.postAuthState, PostAuthLifecycleState.retryableFailure);
      expect(find.text(Ar.authPostSetupRetryable), findsOneWidget);
      expect(
        _topMatchedLocation(),
        AppRoutes.auth,
        reason: 'never dump into the app before the pipeline settles',
      );

      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      expect(auth.postAuthState, PostAuthLifecycleState.success);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('the running seam renders while a post-auth retry is in '
        'flight, then resolves to the signed-in card', (tester) async {
      final gate = Completer<PostAuthOutcome>();
      var pipelineCalls = 0;
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onPostAuth: (_) async {
          pipelineCalls++;
          if (pipelineCalls == 1) return PostAuthOutcome.retryableFailure;
          return gate.future;
        },
      );
      await _pumpAuth(tester, auth);

      expect(auth.postAuthState, PostAuthLifecycleState.retryableFailure);
      expect(find.text(Ar.authPostSetupRetryable), findsOneWidget);

      final retry = auth.retryPostAuth();
      // Explicit pumps: an indeterminate spinner never settles.
      await tester.pump();
      expect(
        find.text(Ar.authPostSetupRunning),
        findsOneWidget,
        reason:
            'the claim/bootstrap progress seam is observable while a '
            'retry is in flight',
      );

      gate.complete(PostAuthOutcome.success);
      await retry;
      await tester.pumpAndSettle();

      expect(auth.postAuthState, PostAuthLifecycleState.success);
      expect(
        find.textContaining(Ar.signedInAs),
        findsOneWidget,
        reason: 'the signed-in card appears once the pipeline has settled',
      );
      expect(
        _topMatchedLocation(),
        AppRoutes.auth,
        reason:
            'a direct pipeline retry does not navigate; only the '
            'screen-level Retry action does',
      );
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a provisioning failure renders its typed recovery seam', (
      tester,
    ) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onPostAuth: (_) async => PostAuthOutcome.provisioningFailure,
      );
      await _pumpAuth(tester, auth);

      expect(auth.isLoggedIn, isTrue);
      expect(auth.postAuthState, PostAuthLifecycleState.provisioningFailure);
      expect(find.text(Ar.authPostSetupProvisioning), findsOneWidget);
      expect(find.text(Ar.goToProfile), findsOneWidget);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a second-account ownership conflict blocks sign-in entirely '
        '(fail closed)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      await _pumpAuth(tester, auth);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.authAccountConflictMessage), findsOneWidget);
      expect(
        find.text(Ar.continueWithGoogle),
        findsNothing,
        reason:
            'no new Google session while blockingly bound to another '
            'account',
      );
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('an unavailable gateway renders the notice and NO sign-in '
        'button', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway(available: false));
      await _pumpAuth(tester, auth);

      expect(find.text(Ar.googleSignInUnavailable), findsOneWidget);
      expect(find.text(Ar.continueWithGoogle), findsNothing);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    // ---------------------------------------------------------------
    // V1-R08 Part 2 correction coverage (findings 1/3/4/9)
    // ---------------------------------------------------------------
    testWidgets('a sign-in in flight is single-flight: a second tap cannot '
        'start a duplicate Google attempt', (tester) async {
      final gate = Completer<void>();
      final gateway = _GatedSignInGateway(result: fakeSession, gate: gate);
      final auth = AuthProvider(gateway: gateway);
      await _pumpAuth(tester, auth);

      await tester.tap(find.text(Ar.continueWithGoogle));
      await tester.pump();

      expect(auth.isSigningIn, isTrue);
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'the in-flight progress is observable',
      );

      // Duplicate tap on the same affordance must NOT re-enter the gateway.
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is OutlinedButton),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(
        gateway.signInCalls,
        1,
        reason: 'single-flight: no duplicate sign-in may start',
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.postAuthState, PostAuthLifecycleState.success);
      expect(_topMatchedLocation(), AppRoutes.userProfile);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('ownership-conflict Retry re-runs resolution; a resolved '
        'conflict returns to the quiet guest sign-in (no dead-end)', (
      tester,
    ) async {
      final gateway = _RecoveredRestoreGateway();
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      await _pumpAuth(tester, auth);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);
      expect(find.text(Ar.continueWithGoogle), findsNothing);

      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      // Retry resolved the account signature to a clean guest.
      expect(auth.isOwnershipBlocked, isFalse);
      expect(auth.error, isNull);
      expect(
        find.text(Ar.continueWithGoogle),
        findsOneWidget,
        reason: 'a resolved conflict returns to a quiet guest',
      );
      expect(find.text(Ar.retry), findsNothing);
      expect(_topMatchedLocation(), AppRoutes.auth);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('a conflict resolved upstream (auth event) keeps the typed '
        'conflict error until cleared — the Return-to-sign-in recovery '
        'action unblocks the guest', (tester) async {
      final gateway = FakeAuthGateway(restoredSession: fakeSession);
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      await _pumpAuth(tester, auth);

      expect(auth.isOwnershipBlocked, isTrue);
      expect(find.text(Ar.retry), findsOneWidget);

      // The authoritative stream cleans the temporary session: the device is
      // still conflict-bound (error retained) but no longer blockingly so.
      gateway.emit(const AuthEvent(type: AuthEventType.signedOut));
      await tester.pumpAndSettle();

      expect(auth.error, AuthError.ownershipConflict);
      expect(
        auth.isOwnershipBlocked,
        isTrue,
        reason: 'the neutralized conflict stays blocked until cleared',
      );
      expect(
        find.text(Ar.ownershipConflictReturnToSignIn),
        findsOneWidget,
        reason:
            'the neutralized conflict exposes the forward recovery '
            'action instead of a bare retry',
      );
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsNothing);
      expect(
        find.text(Ar.continueWithGoogle),
        findsNothing,
        reason:
            'a Google sign-in is never available while the device is '
            'still conflict-bound',
      );

      await tester.ensureVisible(find.text(Ar.ownershipConflictReturnToSignIn));
      await tester.tap(find.text(Ar.ownershipConflictReturnToSignIn));
      await tester.pumpAndSettle();

      expect(auth.error, isNull);
      expect(
        find.text(Ar.continueWithGoogle),
        findsOneWidget,
        reason: 'clearing the conflict error unblocks the quiet guest',
      );
      expect(
        _topMatchedLocation(),
        AppRoutes.auth,
        reason: 'on the auth surface the recovery stays put (no navigation)',
      );
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('English locale renders the English AppBar title and guest '
        'copy (no forced Arabic)', (tester) async {
      final auth = AuthProvider(gateway: FakeAuthGateway());
      await _pumpAuth(tester, auth, isArabic: false);

      expect(
        find.text(En.login),
        findsOneWidget,
        reason: 'the AppBar title follows the active locale',
      );
      expect(find.text(En.continueWithGoogle), findsOneWidget);
      expect(find.text(Ar.login), findsNothing);
      expect(find.text(Ar.continueWithGoogle), findsNothing);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });

    testWidgets('English locale renders the English conflict copy and Retry '
        'action (no forced Arabic)', (tester) async {
      final auth = AuthProvider(
        gateway: FakeAuthGateway(restoredSession: fakeSession),
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
      );
      await _pumpAuth(tester, auth, isArabic: false);

      expect(find.text(En.authAccountConflictTitle), findsOneWidget);
      expect(find.text(En.authAccountConflictMessage), findsOneWidget);
      expect(find.text(En.retry), findsOneWidget);
      expect(find.text(Ar.authAccountConflictTitle), findsNothing);
      expect(tester.takeException(), isNull);
      auth.dispose();
    });
  });
}
