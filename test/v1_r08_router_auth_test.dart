import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/services/theme_provider.dart';
import 'package:civilpedia/features/auth/domain/auth_return_destination.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_error.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_event.dart';
import 'package:civilpedia/features/auth/domain/entities/auth_session.dart';
import 'package:civilpedia/features/auth/presentation/auth_refresh_listenable.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/features/profile/domain/user_profile.dart';
import 'package:civilpedia/features/profile/domain/user_profile_repository.dart';
import 'package:civilpedia/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:civilpedia/features/profile/presentation/screens/authenticated_profile_edit_screen.dart';
import 'package:civilpedia/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_router.dart';
import 'package:civilpedia/routes/app_routes.dart';
import 'package:civilpedia/routes/not_found_screen.dart';

import 'fakes/fake_auth_gateway.dart';

const _sessionA = AuthSession(
  userId: 'uuid-0000-0000',
  email: 'a@civilpedia.com',
  displayName: 'Engineer A',
);

class _EmptyUserProfileRepository implements UserProfileRepository {
  @override
  Future<void> clearProfile() async {}

  @override
  Future<LocalUserProfile?> loadProfile() async => null;

  @override
  Future<void> saveProfile(LocalUserProfile profile) async {}
}

/// V1-R08 correction (finding 1) — a restore session parked on a gate lets
/// the route-level test observe the unresolved /profile/edit seam.
class _GatedRestoreGateway extends FakeAuthGateway {
  _GatedRestoreGateway({this.gate});

  final Completer<AuthSession?>? gate;

  @override
  Future<AuthSession?> restoreSession() async {
    if (gate != null) return gate!.future;
    return null;
  }
}

/// V1-R08 correction (finding 3) — the FIRST resolution reports the conflict
/// (blocked), the RETRY (route-level recovery) resolves to a clean guest.
class _RecoveredRestoreGateway extends FakeAuthGateway {
  _RecoveredRestoreGateway() : super(restoredSession: _sessionA);

  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreCalls++;
    return restoreCalls == 1 ? _sessionA : null;
  }
}

/// V1-R08 correction (final) — a retry whose restore PARKED on a gate lets the
/// route-level test fire two recovery taps before the first Future completes,
/// proving the local single-flight guard keeps the provider at exactly one op.
class _GatedRetryGateway extends FakeAuthGateway {
  _GatedRetryGateway(this.retryGate);

  final Completer<AuthSession?> retryGate;
  int restoreCalls = 0;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreCalls++;
    if (restoreCalls == 1) return _sessionA; // setup restore → conflict
    return retryGate.future; // the retry parks until the test completes it
  }
}

Widget _app(AuthProvider auth, UserProfileProvider profileProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: profileProvider),
    ],
    child: MaterialApp.router(routerConfig: appRouter),
  );
}

AuthProvider _guestAuth() => AuthProvider(gateway: FakeAuthGateway());

Future<(AuthProvider, FakeAuthGateway)> _authenticatedAuth() async {
  final gateway = FakeAuthGateway(restoredSession: _sessionA);
  final auth = AuthProvider(
    gateway: gateway,
    onSessionRefresh: AuthRefreshListenable.instance.refresh,
  );
  await auth.restoreSession();
  return (auth, gateway);
}

UserProfileProvider _profileProvider() => UserProfileProvider(
      repository: _EmptyUserProfileRepository(),
    );

Uri _currentUri() => appRouter.routerDelegate.currentConfiguration.uri;

void main() {
  // ------------------------------------------------------------------
  // §12/21 — return-destination allowlist (pure contract)
  // ------------------------------------------------------------------
  group('AuthReturnDestination allowlist', () {
    test('accepts root-relative protected destinations', () {
      expect(
        AuthReturnDestination.resolve(AppRoutes.businessApplications),
        AppRoutes.businessApplications,
      );
      expect(
        AuthReturnDestination.resolve(
          AppRoutes.businessApplicationDetailFor('some-id'),
        ),
        AppRoutes.businessApplicationDetailFor('some-id'),
      );
      expect(
        AuthReturnDestination.resolve(AppRoutes.businessManage),
        AppRoutes.businessManage,
      );
      expect(
        AuthReturnDestination.resolve(AppRoutes.staffApplications),
        AppRoutes.staffApplications,
      );
      expect(
        AuthReturnDestination.resolve(AppRoutes.userProfile),
        AppRoutes.userProfile,
      );
    });

    test('rejects scheme / protocol-relative / authority URLs', () {
      expect(AuthReturnDestination.resolve('https://evil.example/path'), isNull);
      expect(AuthReturnDestination.resolve('//evil.example/path'), isNull);
      expect(AuthReturnDestination.resolve('javascript:alert(1)'), isNull);
      expect(AuthReturnDestination.resolve('file:///etc/passwd'), isNull);
    });

    test('rejects traversal, non-allowlisted paths, and empty values', () {
      expect(AuthReturnDestination.resolve('/../etc/passwd'), isNull);
      expect(AuthReturnDestination.resolve('/encyclopedia'), isNull);
      expect(AuthReturnDestination.resolve('/profile'), isNull);
      expect(AuthReturnDestination.resolve('/'), isNull);
      expect(AuthReturnDestination.resolve(null), isNull);
      expect(AuthReturnDestination.resolve(''), isNull);
    });

    // ----------------------------------------------------------------
    // Final pass (finding 4): EXACT canonical shape matching — a prefix
    // match is not enough, so lookalike paths under an allowed family are
    // rejected, and every canonical parameterized shape is accepted.
    // ----------------------------------------------------------------
    test('accepts every canonical parameterized destination shape', () {
      expect(
        AuthReturnDestination.resolve(AppRoutes.businessApplicationsNew),
        AppRoutes.businessApplicationsNew,
      );
      expect(
        AuthReturnDestination.resolve(AppRoutes.businessApplicationsClaim),
        AppRoutes.businessApplicationsClaim,
      );
      expect(
        AuthReturnDestination.resolve(
          AppRoutes.businessApplicationDetailFor('app-42'),
        ),
        AppRoutes.businessApplicationDetailFor('app-42'),
      );
      expect(
        AuthReturnDestination.resolve(
          AppRoutes.businessManageDetailFor('entity-7'),
        ),
        AppRoutes.businessManageDetailFor('entity-7'),
      );
      expect(
        AuthReturnDestination.resolve(
          AppRoutes.staffApplicationDetailFor('review-9'),
        ),
        AppRoutes.staffApplicationDetailFor('review-9'),
      );
      expect(
        AuthReturnDestination.resolve(AppRoutes.userProfileEdit),
        AppRoutes.userProfileEdit,
      );
    });

    test('rejects lookalike paths that merely share a family prefix', () {
      expect(AuthReturnDestination.resolve('/user/profile-evil'), isNull);
      expect(AuthReturnDestination.resolve('/user/profileevil'), isNull);
      expect(AuthReturnDestination.resolve('/staff/applications-evil'), isNull);
      expect(AuthReturnDestination.resolve('/business/applications-evil'), isNull);
      expect(AuthReturnDestination.resolve('/business/manage-evil'), isNull);
      // deceptively long paths under an allowed family are not canonical
      expect(
        AuthReturnDestination.resolve('/user/profile/edit/extra'),
        isNull,
      );
      expect(
        AuthReturnDestination.resolve('/business/manage/entity-7/extra'),
        isNull,
      );
      expect(
        AuthReturnDestination.resolve('/staff/applications/review-9/extra'),
        isNull,
      );
      // extra root segments before a canonical family are not canonical
      expect(
        AuthReturnDestination.resolve('/user//profile'),
        isNull,
      );
      // only the exact canonical families are accepted, even with scheme
      expect(
        AuthReturnDestination.resolve('https://civilpedia.com/user/profile'),
        isNull,
      );
    });
  });

  // ------------------------------------------------------------------
  // §11 — live protected-route redirect
  // ------------------------------------------------------------------
  group('app router protected redirect', () {
    testWidgets('guest hit on a protected family lands on /auth with an '
        'allowlisted ?return= path', (tester) async {
      final auth = _guestAuth();
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.userProfile);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      final uri = _currentUri();
      expect(uri.path, AppRoutes.auth);
      expect(uri.queryParameters['return'], AppRoutes.userProfile);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('a public family (including /profile) passes through as guest',
        (tester) async {
      final auth = _guestAuth();
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.profile);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      expect(_currentUri().path, AppRoutes.profile);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('an authenticated hit on a protected family stays put',
        (tester) async {
      final (auth, _) = await _authenticatedAuth();
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.userProfile);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      expect(_currentUri().path, AppRoutes.userProfile);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('a live session loss re-evaluates immediately and redirects '
        'an on-screen protected route to /auth preserving ?return=',
        (tester) async {
      final (auth, gateway) = await _authenticatedAuth();
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.userProfile);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();
      expect(_currentUri().path, AppRoutes.userProfile);

      // External session loss (device stream event) must invalidate the
      // protected surface immediately via the router refresh listenable.
      gateway.emit(const AuthEvent(type: AuthEventType.signedOut));
      await tester.pumpAndSettle();

      final uri = _currentUri();
      expect(uri.path, AppRoutes.auth);
      expect(uri.queryParameters['return'], AppRoutes.userProfile);

      profileProvider.dispose();
      auth.dispose();
    });

    // ----------------------------------------------------------------
    // Final pass (finding 5): the router refresh fires when the post-auth
    // pipeline settles on the FINAL authenticated transition, so a sign-in
    // that starts from a protected-route redirect resumes the vetted
    // ?return= destination; without a vetted return the default fallback
    // destination opens.
    // ----------------------------------------------------------------
    testWidgets('sign-in after a protected redirect resumes the allowlisted '
        '?return= destination (F5)', (tester) async {
      final gateway = FakeAuthGateway(signInResult: _sessionA);
      final auth = AuthProvider(
        gateway: gateway,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.userProfile);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      // Guest state => redirected to /auth preserving the vetted return.
      expect(_currentUri().path, AppRoutes.auth);
      expect(_currentUri().queryParameters['return'], AppRoutes.userProfile);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isTrue);
      expect(_currentUri().path, AppRoutes.userProfile);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('sign-in without a vetted return falls back to the default '
        'profile destination (F5)', (tester) async {
      final gateway = FakeAuthGateway(signInResult: _sessionA);
      final auth = AuthProvider(
        gateway: gateway,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();

      appRouter.go(AppRoutes.auth);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();
      expect(_currentUri().path, AppRoutes.auth);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isTrue);
      expect(_currentUri().path, AppRoutes.userProfile);

      profileProvider.dispose();
      auth.dispose();
    });
  });

  // ------------------------------------------------------------------
  // V1-R08 Part 2 correction coverage (findings 1/3/9)
  // ------------------------------------------------------------------
  group('profile-edit route resolution (F1)', () {
    testWidgets('an unresolved restore at /profile/edit renders the resolving '
        'seam and NEVER the guest editor; the settled session lands on the '
        'authenticated editor', (tester) async {
      final gate = Completer<AuthSession?>();
      final gateway = _GatedRestoreGateway(gate: gate);
      final auth = AuthProvider(
        gateway: gateway,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      final pending = auth.restoreSession(); // → resolving, parked on gate

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pump(); // explicit pump: a spinner is mounted unresolved

      expect(find.byType(ProfileEditScreen), findsNothing,
          reason: 'the LEGACY guest editor must never render while the auth '
              'state is unresolved');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text(Ar.profileCloudLoading), findsOneWidget,
          reason: 'the resolving seam is observable without a session');

      gate.complete(_sessionA);
      await pending;
      // The editor may keep its own loader alive, so a plain pumpAndSettle
      // would never settle; pump in steps until the editor mounts instead.
      for (var i = 0;
          i < 15 &&
              tester
                  .widgetList(find.byType(AuthenticatedProfileEditScreen))
                  .isEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(auth.isLoggedIn, isTrue);
      expect(find.byType(AuthenticatedProfileEditScreen), findsOneWidget);
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(_currentUri().path, AppRoutes.profileEdit);
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('an unresolved restore at /profile/edit renders the resolving '
        'seam; a settle to a CLEAN GUEST replaces it with the settled guest '
        'route, never a stale seam (final F1)', (tester) async {
      final gate = Completer<AuthSession?>();
      final gateway = _GatedRestoreGateway(gate: gate);
      final auth = AuthProvider(
        gateway: gateway,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      final pending = auth.restoreSession(); // → resolving, parked on gate

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pump(); // explicit pump: a spinner is mounted unresolved

      expect(find.byType(ProfileEditScreen), findsNothing,
          reason: 'the LEGACY guest editor must never render while unresolved');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text(Ar.profileCloudLoading), findsOneWidget,
          reason: 'the resolving seam is observable without a session');

      // The authoritative restore settles to NO session → clean guest.
      gate.complete(null);
      await pending;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.status, AuthStatus.guest);
      expect(auth.isLoggedIn, isFalse);
      expect(find.text(Ar.profileCloudLoading), findsNothing,
          reason: 'the resolving seam must NOT stay mounted after a guest '
              'settle');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.byType(NotFoundScreen), findsOneWidget,
          reason: 'the settled guest WITHOUT a local profile lands on the '
              'deterministic not-found seam of the legacy guest contract');
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(_currentUri().path, AppRoutes.profileEdit);
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('an unresolved restore at /profile/edit settles into an '
        'ownership conflict and swaps the seam for the fail-closed blocked '
        'surface (final F1)', (tester) async {
      final gate = Completer<AuthSession?>();
      final gateway = _GatedRestoreGateway(gate: gate);
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      final pending = auth.restoreSession(); // → resolving, parked on gate

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pump(); // explicit pump: a spinner is mounted unresolved

      expect(find.text(Ar.profileCloudLoading), findsOneWidget,
          reason: 'the resolving seam is observable while unresolved');
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);

      // The restore surfaces a session whose post-auth pipeline reports the
      // second-account ownership conflict.
      gate.complete(_sessionA);
      await pending;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.status, AuthStatus.ownershipConflict);
      expect(auth.error, AuthError.ownershipConflict);
      expect(find.text(Ar.profileCloudLoading), findsNothing,
          reason: 'the resolving seam must NOT stay mounted after a conflict '
              'settle');
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget,
          reason: 'the fail-closed blocked surface appears instead');
      expect(find.byType(ProfileEditScreen), findsNothing,
          reason: 'no guest editor while the device is conflict-bound');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.byType(NotFoundScreen), findsNothing);
      expect(_currentUri().path, AppRoutes.profileEdit);
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('two rapid Retry taps on the blocked route start exactly ONE '
        'recovery — the local single-flight guard swallows the duplicate '
        '(final F3)', (tester) async {
      final retryGate = Completer<AuthSession?>();
      final gateway = _GatedRetryGateway(retryGate);
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      await auth.restoreSession(); // setup restore → conflict
      expect(auth.isOwnershipBlocked, isTrue);
      expect(gateway.restoreCalls, 1);

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      expect(find.text(Ar.retry), findsOneWidget);

      // Two taps land in the SAME frame (no rebuild between) so both funnel
      // into the recovery handler; the local guard must allow only one.
      await tester.ensureVisible(find.text(Ar.retry));
      await tester.tap(find.text(Ar.retry));
      await tester.tap(find.text(Ar.retry));
      await tester.pump();

      expect(gateway.restoreCalls, 2,
          reason: 'exactly one setup restore + exactly ONE retry — the '
              'duplicate tap must be swallowed by the single-flight guard');

      // The retry resolves to a clean guest → a deterministic guest surface.
      retryGate.complete(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(auth.isOwnershipBlocked, isFalse);
      expect(auth.error, isNull);
      expect(find.byType(NotFoundScreen), findsOneWidget,
          reason: 'the retry settles into the deterministic guest seam — '
              'never a blank blocked shell');
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text(Ar.retry), findsNothing);
      expect(_currentUri().path, AppRoutes.profileEdit);
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('a conflict-blocked /profile/edit shows the recovery surface; '
        'Retry resolves the conflict to a clean guest and NO editor ever '
        'renders (F1/F3)', (tester) async {
      final gateway = _RecoveredRestoreGateway();
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      await auth.restoreSession();
      expect(auth.isOwnershipBlocked, isTrue);

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsNothing,
          reason: 'a blocked /profile/edit must never render an editor');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);

      await tester.ensureVisible(find.text(Ar.retry));
      await tester.tap(find.text(Ar.retry));
      await tester.pumpAndSettle();

      // Retry resolved the account signature to a clean guest.
      expect(auth.isOwnershipBlocked, isFalse);
      expect(auth.error, isNull);
      expect(find.text(Ar.authAccountConflictTitle), findsNothing);
      expect(find.byType(ProfileEditScreen), findsNothing,
          reason: 'the legacy guest editor must not flash while unsettled; '
              'a settled guest without a profile lands on the not-found seam');
      expect(find.byType(NotFoundScreen), findsOneWidget,
          reason: 'the retry settles into a deterministic guest surface — '
              'never a blank blocked shell');
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);
      expect(find.text(Ar.retry), findsNothing);
      expect(_currentUri().path, AppRoutes.profileEdit);
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });

    testWidgets('a conflict resolved upstream (auth event) keeps the typed '
        'conflict error on the blocked route; "Return to sign in" navigates '
        'to /auth (F1/F3)', (tester) async {
      final gateway = FakeAuthGateway(restoredSession: _sessionA);
      final auth = AuthProvider(
        gateway: gateway,
        onPostAuth: (_) async => PostAuthOutcome.ownershipConflict,
        onSessionRefresh: AuthRefreshListenable.instance.refresh,
      );
      final profileProvider = _profileProvider();
      await auth.restoreSession();
      expect(auth.isOwnershipBlocked, isTrue);

      appRouter.go(AppRoutes.profileEdit);
      await tester.pumpWidget(_app(auth, profileProvider));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.text(Ar.authAccountConflictTitle), findsOneWidget);
      expect(find.text(Ar.retry), findsOneWidget);

      // The authoritative stream cleans the temporary session (neutralized).
      gateway.emit(const AuthEvent(type: AuthEventType.signedOut));
      await tester.pumpAndSettle();

      expect(auth.error, AuthError.ownershipConflict);
      expect(auth.isOwnershipBlocked, isTrue,
          reason: 'the neutralized conflict stays blocked until cleared');
      expect(find.text(Ar.ownershipConflictReturnToSignIn), findsOneWidget,
          reason: 'the blocked route keeps the neutralized recovery surface');
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(find.byType(AuthenticatedProfileEditScreen), findsNothing);

      await tester.ensureVisible(find.text(Ar.ownershipConflictReturnToSignIn));
      await tester.tap(find.text(Ar.ownershipConflictReturnToSignIn));
      await tester.pumpAndSettle();

      expect(auth.error, isNull);
      expect(_currentUri().path, AppRoutes.auth,
          reason: 'the blocked route recovers by resolving on the auth surface');
      expect(tester.takeException(), isNull);

      profileProvider.dispose();
      auth.dispose();
    });
  });
}