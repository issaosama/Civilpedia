import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/entities/auth_error.dart';
import '../domain/entities/auth_event.dart';
import '../domain/entities/auth_session.dart';
import '../domain/repositories/auth_gateway.dart';

/// Handles the platform-dependent `GoogleSignIn` lifecycle (singleton
/// initialization + authentication) while keeping the applied behaviour
/// unit-testable without touching the real plugin.
///
/// The real singleton is comprised of:
/// * `initialize(clientId:, serverClientId:)` — must be awaited exactly once
///   before any other call (google_sign_in 7.x singleton contract).
/// * `authenticate()` — completes with the signed-in [GoogleSignInAccount],
///   throwing a `GoogleSignInException` when the user cancels.
/// * `authorization(account, scopes)` — best-effort silent
///   `authorizationForScopes` first, falling back to `authorizeScopes` (the
///   pattern from the official Supabase Flutter guide) to also return a
///   [GoogleSignInClientAuthorization] whose `accessToken` is forwarded to
///   Supabase together with the idToken.
@protected
@visibleForTesting
typedef GoogleSignInApi = ({
  Future<void> Function({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  })
  initialize,
  Future<GoogleSignInAccount> Function(List<String> scopeHint) authenticate,
  Future<GoogleSignInClientAuthorization> Function(
    GoogleSignInAccount account,
    List<String> scopes,
  )
  authorization,
  Future<void> Function() signOut,
});

@protected
@visibleForTesting
GoogleSignInApi wireGoogleSignIn() {
  final google = GoogleSignIn.instance;
  return (
    initialize: ({clientId, serverClientId, nonce, hostedDomain}) =>
        google.initialize(
          clientId: clientId,
          serverClientId: serverClientId,
          nonce: nonce,
          hostedDomain: hostedDomain,
        ),
    authenticate: (scopeHint) => google.authenticate(scopeHint: scopeHint),
    authorization: (account, scopes) async {
      final silent =
          await account.authorizationClient.authorizationForScopes(scopes);
      if (silent != null) return silent;
      return account.authorizationClient.authorizeScopes(scopes);
    },
    signOut: () => google.signOut(),
  );
}

/// A5.4/V1-R08 — Production Supabase-backed [AuthGateway].
///
/// Flow: native [GoogleSignIn] → idToken + Google authorization access token
/// → `signInWithIdToken(OAuthProvider.google)` → Supabase Auth session.
/// Session persistence is owned by Supabase itself (its local storage); this
/// gateway never writes the session to SharedPreferences or other stores.
///
/// The canonical identity exposed to the app is `auth.users.id`
/// ([AuthSession.userId]), taken from the Supabase session — never from the
/// Google account id.
///
/// V1-R08 — [authEvents] is the bounded authoritative Supabase auth-state
/// lifecycle stream (restored/signed-in/signed-out/refreshed/removed). It
/// wraps the existing Supabase client's own auth-state event source; the
/// provider reconciles startup restoration with it rather than relying only on
/// a one-time `currentSession` read.
///
/// Safety guarantees:
/// * Every operation is a strict no-op when [isAvailable] is false, so an
///   unconfigured build stays fully guest/local.
/// * The Google `serverClientId` is a PUBLIC identifier supplied by
///   dart-define — never a client secret.
/// * [signOut] never touches user-local application data.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway({
    required this.service,
    GoogleSignInApi Function()? googleSignInFactory,
  }) : _googleSignInFactory = googleSignInFactory ?? wireGoogleSignIn;

  final SupabaseService service;
  final GoogleSignInApi Function() _googleSignInFactory;

  GoogleSignInApi? _googleSignIn;
  bool _initialized = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  late final StreamController<AuthEvent> _authEvents = StreamController<AuthEvent>.broadcast();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool get isAvailable =>
      service.isInitialized && service.config.googleServerClientId.isNotEmpty;

  @override
  Stream<AuthEvent> get authEvents {
    _ensureAuthStateSubscription();
    return _authEvents.stream;
  }

  void _ensureAuthStateSubscription() {
    if (_authStateSubscription != null || !isAvailable) return;
    _authStateSubscription = _client.auth.onAuthStateChange.listen(
      (state) {
        final event = _mapAuthState(state);
        if (event != null && !_authEvents.isClosed) {
          _authEvents.add(event);
        }
      },
      onError: (_) {
        // The underlying stream failing must never crash the provider; it can
        // re-subscribe on a later access.
        _authStateSubscription = null;
      },
    );
  }

  AuthEvent? _mapAuthState(AuthState state) {
    final session = state.session;
    final event = state.event;
    switch (event) {
      case AuthChangeEvent.initialSession:
        // Startup restoration signal. A non-null session is the restored
        // authenticated state; null simply confirms the guest state we already
        // start in. Also surfaced so the provider can reconcile startup with
        // the canonical stream instead of a one-time currentSession read.
        if (session == null) return null;
        return AuthEvent(
          type: AuthEventType.sessionRestored,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.signedIn:
        if (session == null) return null;
        if (_authEvents.hasListener) {
          // A signedIn event whose user differs from the last emitted session
          // is a session replacement; otherwise it is a regular signed-in
          // signal. The provider decides based on its current session; the
          // gateway always emits the raw signed-in signal.
          return AuthEvent(
            type: AuthEventType.signedIn,
            session: _toSession(session.user),
          );
        }
        return AuthEvent(
          type: AuthEventType.signedIn,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.signedOut:
        return const AuthEvent(type: AuthEventType.signedOut);
      case AuthChangeEvent.tokenRefreshed:
        if (session == null) {
          // A refresh that left no session is treated as an external loss.
          return const AuthEvent(type: AuthEventType.sessionLost);
        }
        return AuthEvent(
          type: AuthEventType.tokenRefreshed,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.userDeleted:
        return const AuthEvent(type: AuthEventType.sessionLost);
      case AuthChangeEvent.passwordRecovery:
        return null;
      case AuthChangeEvent.userUpdated:
        if (session == null) return null;
        return AuthEvent(
          type: AuthEventType.sessionReplaced,
          session: _toSession(session.user),
        );
      case AuthChangeEvent.mfaChallengeVerified:
        if (session == null) return null;
        return AuthEvent(
          type: AuthEventType.tokenRefreshed,
          session: _toSession(session.user),
        );
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (!isAvailable) return null;
    _ensureAuthStateSubscription();
    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) return null;
    return _toSession(user);
  }

  @override
  Future<AuthSession?> signInWithGoogle() async {
    if (!isAvailable) {
      throw const AuthGatewayException(AuthError.unavailable);
    }
    _ensureAuthStateSubscription();

    try {
      final google = _googleSignIn ??= _googleSignInFactory();
      if (!_initialized) {
        await google.initialize(
          serverClientId: service.config.googleServerClientId,
        );
        _initialized = true;
      }

      final GoogleSignInAccount account;
      final GoogleSignInClientAuthorization authorization;
      try {
        account = await google.authenticate(const []);
        // Scopes used by the official Supabase Flutter Google Sign-In guide:
        // the access token is requested together with the idToken.
        authorization = await google.authorization(
          account,
          const ['email', 'profile'],
        );
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled ||
            e.code == GoogleSignInExceptionCode.interrupted) {
          // The user dismissed a sign-in/authorization sheet — not an error.
          return null;
        }
        throw const AuthGatewayException(AuthError.signInFailed);
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthGatewayException(AuthError.signInFailed);
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthGatewayException(AuthError.signInFailed);
      }
      return _toSession(user);
    } on AuthGatewayException {
      rethrow;
    } on GoogleSignInException catch (_) {
      throw const AuthGatewayException(AuthError.signInFailed);
    } catch (_) {
      // Any network/auth failure maps to the single visible error.
      throw const AuthGatewayException(AuthError.signInFailed);
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) return;
    _ensureAuthStateSubscription();
    try {
      // Google sign-out is best-effort: the canonical session lives in
      // Supabase, so a failed Google-side cleanup never fakes a failed
      // canonical sign-out by itself.
      try {
        await _googleSignIn?.signOut();
      } catch (_) {
        // Non-fatal: Supabase is the session authority.
      }
      await _client.auth.signOut();
    } on AuthGatewayException {
      rethrow;
    } catch (_) {
      // The canonical remote sign-out must succeed before the provider may
      // transition to guest. Any failure is a typed, recoverable cause.
      throw const AuthGatewayException(AuthError.signOutFailed);
    }
  }

  AuthSession _toSession(User user) {
    final metadata = user.userMetadata;
    final googleName = (metadata?['full_name'] ?? metadata?['name']) as String?;
    final googlePhoto =
        (metadata?['avatar_url'] ?? metadata?['picture']) as String?;
    return AuthSession(
      userId: user.id,
      email: user.email ?? '',
      displayName: googleName ?? user.email ?? '',
      photoUrl: googlePhoto,
    );
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _authEvents.close();
  }
}