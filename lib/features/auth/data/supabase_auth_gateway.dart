import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/supabase_service.dart';
import '../domain/entities/auth_error.dart';
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

/// A5.4 — Production Supabase-backed [AuthGateway].
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

  SupabaseClient get _client => Supabase.instance.client;

  @override
  bool get isAvailable =>
      service.isInitialized && service.config.googleServerClientId.isNotEmpty;

  @override
  Future<AuthSession?> restoreSession() async {
    if (!isAvailable) return null;
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
        rethrow;
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
    await _googleSignIn?.signOut();
    await _client.auth.signOut();
  }

  AuthSession _toSession(User user) {
    final metadata = user.userMetadata;
    final googleName = (metadata?['full_name'] ?? metadata?['name']) as String?;
    return AuthSession(
      userId: user.id,
      email: user.email ?? '',
      displayName: googleName ?? user.email ?? '',
    );
  }
}